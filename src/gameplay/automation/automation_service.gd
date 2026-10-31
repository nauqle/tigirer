class_name AutomationService
extends RefCounted
## Donanım ve kat satın alma: satır başına otomatik sulama ve UV lambası, kat başına hasat dronu, genel laboratuvar UV odası
## ve yeni gökdelen katı açma. Her satın alma bir `CommandResult` döndürür; para yetmezse ya da sınıra gelinmişse
## hiçbir şey değişmez. Donanımın ETKİSİ burada değil `FarmService` (sulama, UV) ve `DroneService` (dron) içindedir.
##
## Uygular: design/game-brief.md, FAZ 4 "otomatik sulama/ışıklandırma matrisi, yeni gökdelen katları açma".
##
## [codeblock]
## var result: CommandResult = automation.buy_irrigation(0, 1)   # kat 0, satır 1
## if not result.ok:
##     show_toast(tr(result.message_key) % result.args)
## [/codeblock]

## Donanım satın alındı: tür, kat, hedef (satır ya da -1) ve yeni seviye.
signal purchased(kind: EquipmentDef.Kind, floor_index: int, target: int, level: int)
## Yeni kat açıldı.
signal floor_unlocked(floor_index: int)

var farm: FarmService
var wallet: WalletService
var floor_defs: Array[FloorDef] = []
var equipment_defs: Array[EquipmentDef] = []
## Laboratuvar UV odası seviyesi (genel).
var lab_uv_level: int = 0


## Servisleri ve veri tanımlarını bağlar.
func setup(farm_service: FarmService, wallet_service: WalletService, floors: Array[FloorDef], equipment: Array[EquipmentDef]) -> void:
	farm = farm_service
	wallet = wallet_service
	floor_defs = floors
	equipment_defs = equipment


## Türe göre donanım tanımı; yoksa null.
func equipment_for(kind: EquipmentDef.Kind) -> EquipmentDef:
	for def: EquipmentDef in equipment_defs:
		if def.kind == kind:
			return def
	return null


# -------------------------------------------------------------- satın alma


## Katın `row`. satırına otomatik sulama kurar.
func buy_irrigation(floor_index: int, row: int) -> CommandResult:
	var floor_state: FloorState = _usable_floor(floor_index, row)
	if floor_state == null:
		return _invalid_target(floor_index)
	var def: EquipmentDef = equipment_for(EquipmentDef.Kind.IRRIGATION)
	var level: int = 1 if floor_state.irrigation_rows[row] else 0
	var failure: CommandResult = _charge(def, level)
	if failure != null:
		return failure
	floor_state.irrigation_rows[row] = true
	purchased.emit(def.kind, floor_index, row, 1)
	return CommandResult.success("MSG_IRRIGATION_BUILT")


## Katın `row`. satırına bir UV lambası seviyesi ekler.
func buy_uv_lamp(floor_index: int, row: int) -> CommandResult:
	var floor_state: FloorState = _usable_floor(floor_index, row)
	if floor_state == null:
		return _invalid_target(floor_index)
	var def: EquipmentDef = equipment_for(EquipmentDef.Kind.UV_LAMP)
	var failure: CommandResult = _charge(def, floor_state.uv_rows[row])
	if failure != null:
		return failure
	floor_state.uv_rows[row] += 1
	purchased.emit(def.kind, floor_index, row, floor_state.uv_rows[row])
	return CommandResult.success("MSG_UV_BUILT", [floor_state.uv_rows[row]])


## Kata bir hasat dronu ekler.
func buy_drone(floor_index: int) -> CommandResult:
	var floor_state: FloorState = _usable_floor(floor_index, 0)
	if floor_state == null:
		return _invalid_target(floor_index)
	var def: EquipmentDef = equipment_for(EquipmentDef.Kind.DRONE)
	var failure: CommandResult = _charge(def, floor_state.drones)
	if failure != null:
		return failure
	floor_state.drones += 1
	purchased.emit(def.kind, floor_index, -1, floor_state.drones)
	return CommandResult.success("MSG_DRONE_BUILT", [floor_state.drones])


## Laboratuvar UV odasının seviyesini artırır (yeni mutasyon olasılığı yükselir).
func buy_lab_uv() -> CommandResult:
	var def: EquipmentDef = equipment_for(EquipmentDef.Kind.LAB_UV)
	if def == null:
		return CommandResult.failure("ERR_INVALID_TARGET")
	var failure: CommandResult = _charge(def, lab_uv_level)
	if failure != null:
		return failure
	lab_uv_level += 1
	purchased.emit(def.kind, -1, -1, lab_uv_level)
	return CommandResult.success("MSG_LAB_UV_BUILT", [lab_uv_level])


## Yeni mutasyon olasılığına eklenen oran (UV odası seviyesi x seviye başına bonus).
func lab_mutation_bonus() -> float:
	var def: EquipmentDef = equipment_for(EquipmentDef.Kind.LAB_UV)
	return float(lab_uv_level) * (def.mutation_bonus_per_level if def != null else 0.0)


## Bir sonraki katı açar. Katlar sırayla açılır; önceki kat açık olmalı.
func unlock_floor(floor_index: int) -> CommandResult:
	var floor_state: FloorState = farm.get_floor(floor_index)
	if floor_state == null or floor_index >= floor_defs.size():
		return CommandResult.failure("ERR_INVALID_TARGET")
	if floor_state.unlocked:
		return CommandResult.failure("ERR_ALREADY_UNLOCKED")
	if floor_index > 0 and not farm.get_floor(floor_index - 1).unlocked:
		return CommandResult.failure("ERR_PREVIOUS_FLOOR_LOCKED")
	var cost: int = floor_defs[floor_index].unlock_cost
	if not wallet.spend(cost):
		return CommandResult.failure("ERR_NOT_ENOUGH_CREDITS", [cost])
	floor_state.unlocked = true
	floor_unlocked.emit(floor_index)
	return CommandResult.success("MSG_FLOOR_UNLOCKED", [floor_defs[floor_index].display_name])


# ----------------------------------------------------------------- sorgular


## Bir sonraki seviyenin maliyeti (arayüz düğmesi için); sınıra gelindiyse ya da geçersizse -1.
func next_cost(kind: EquipmentDef.Kind, floor_index: int = 0, row: int = 0) -> int:
	var def: EquipmentDef = equipment_for(kind)
	if def == null:
		return -1
	var level: int = current_level(kind, floor_index, row)
	if level < 0 or level >= def.max_level:
		return -1
	return def.cost_for_level(level)


## Hedefin şu anki seviyesi (satır/kat/genel); hedef geçersizse -1.
func current_level(kind: EquipmentDef.Kind, floor_index: int = 0, row: int = 0) -> int:
	if kind == EquipmentDef.Kind.LAB_UV:
		return lab_uv_level
	var floor_state: FloorState = farm.get_floor(floor_index)
	if floor_state == null:
		return -1
	match kind:
		EquipmentDef.Kind.IRRIGATION:
			if row < 0 or row >= floor_state.rows:
				return -1
			return 1 if floor_state.irrigation_rows[row] else 0
		EquipmentDef.Kind.UV_LAMP:
			if row < 0 or row >= floor_state.rows:
				return -1
			return floor_state.uv_rows[row]
		EquipmentDef.Kind.DRONE:
			return floor_state.drones
	return -1


## En ucuz ALINABİLİR yükseltmenin maliyeti (sınıra gelmiş donanım ve kilitli katın donanımı sayılmaz; bir sonraki kapalı katın açma
## bedeli sayılır); hiçbir şey kalmadıysa -1. Arayüz "yeni bir şey alınabilir" rozeti için kullanır.
func cheapest_purchase_cost() -> int:
	var best: int = _cheaper(-1, next_cost(EquipmentDef.Kind.LAB_UV))
	for def: FloorDef in floor_defs:
		var floor_state: FloorState = farm.get_floor(def.index)
		if floor_state == null:
			continue
		if floor_state.unlocked:
			for row: int in floor_state.rows:
				best = _cheaper(best, next_cost(EquipmentDef.Kind.IRRIGATION, def.index, row))
				best = _cheaper(best, next_cost(EquipmentDef.Kind.UV_LAMP, def.index, row))
			best = _cheaper(best, next_cost(EquipmentDef.Kind.DRONE, def.index))
		elif def.index > 0 and farm.get_floor(def.index - 1).unlocked:
			best = _cheaper(best, def.unlock_cost)
	return best


## Katı açmanın maliyeti; geçersizse -1.
func floor_unlock_cost(floor_index: int) -> int:
	if floor_index < 0 or floor_index >= floor_defs.size():
		return -1
	return floor_defs[floor_index].unlock_cost


# ------------------------------------------------------------------ yardımcı


## İki maliyetten küçüğü; -1 "yok" demektir ve hiçbir zaman seçilmez.
static func _cheaper(current: int, candidate: int) -> int:
	if candidate < 0:
		return current
	if current < 0 or candidate < current:
		return candidate
	return current


## Açık kat ve geçerli satır varsa katı döndürür; yoksa null.
func _usable_floor(floor_index: int, row: int) -> FloorState:
	var floor_state: FloorState = farm.get_floor(floor_index)
	if floor_state == null or not floor_state.unlocked or row < 0 or row >= floor_state.rows:
		return null
	return floor_state


func _invalid_target(floor_index: int) -> CommandResult:
	var floor_state: FloorState = farm.get_floor(floor_index)
	if floor_state != null and not floor_state.unlocked:
		return CommandResult.failure("ERR_FLOOR_LOCKED")
	return CommandResult.failure("ERR_INVALID_TARGET")


## Seviye sınırını ve parayı denetler, parayı düşer. Başarısızsa nedeni verir; başarılıysa null.
func _charge(def: EquipmentDef, current_level: int) -> CommandResult:
	if def == null:
		return CommandResult.failure("ERR_INVALID_TARGET")
	if current_level >= def.max_level:
		return CommandResult.failure("ERR_MAX_LEVEL")
	var cost: int = def.cost_for_level(current_level)
	if not wallet.spend(cost):
		return CommandResult.failure("ERR_NOT_ENOUGH_CREDITS", [cost])
	return null


# --------------------------------------------------------------------- kayıt


## JSON uyumlu sözlük (kayıt dosyası). Satır/kat donanımı `FloorState` içinde saklanır.
func to_dict() -> Dictionary:
	return {"lab_uv": lab_uv_level}


func load_dict(data: Dictionary) -> void:
	lab_uv_level = maxi(int(data.get("lab_uv", 0)), 0)
