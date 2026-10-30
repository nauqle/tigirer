class_name FloorState
extends RefCounted
## Bir katın oyun durumu: açık mı, saksılar, satır başına sulama/UV donanımı, dron sayısı. Saf veri.
## Izgara satır satır numaralanır: saksı indeksi = satır x sütun sayısı + sütun.
##
## Uygular: design/game-brief.md, FAZ 2 (saksı ızgarası) ve FAZ 4 (sulama/UV matrisi, dron, yeni kat).
##
## [codeblock]
## var floor_state: FloorState = FloorState.from_def(floor_def, true)
## var pot: PotState = floor_state.pot_at(1, 0)   # sütun 1, satır 0
## [/codeblock]

var index: int = 0
var cols: int = 1
var rows: int = 1
var unlocked: bool = false
var pots: Array[PotState] = []
## Satır başına otomatik sulama kurulu mu?
var irrigation_rows: Array[bool] = []
## Satır başına UV lamba seviyesi (0 = yok).
var uv_rows: Array[int] = []
## Katta çalışan hasat dronu sayısı.
var drones: int = 0


## Kat tanımından yeni durum kurar: boş saksılar, donanım yok.
static func from_def(def: FloorDef, is_unlocked: bool, water_start: float = 1.0) -> FloorState:
	var state: FloorState = FloorState.new()
	state.index = def.index
	state.cols = def.cols
	state.rows = def.rows
	state.unlocked = is_unlocked
	for i: int in def.cols * def.rows:
		var pot: PotState = PotState.new()
		pot.water = water_start
		state.pots.append(pot)
	for r: int in def.rows:
		state.irrigation_rows.append(false)
		state.uv_rows.append(0)
	return state


func pot_count() -> int:
	return pots.size()


## Saksı indeksinin satırı.
func row_of(pot_index: int) -> int:
	return pot_index / cols


## Saksı indeksinin sütunu.
func col_of(pot_index: int) -> int:
	return pot_index % cols


## Sütun ve satırdan saksı; sınır dışıysa null.
func pot_at(col: int, row: int) -> PotState:
	if col < 0 or col >= cols or row < 0 or row >= rows:
		return null
	return pots[row * cols + col]


## JSON uyumlu sözlük (kayıt dosyası).
func to_dict() -> Dictionary:
	var pot_data: Array = []
	for pot: PotState in pots:
		pot_data.append(pot.to_dict())
	var irrigation: Array = []
	for installed: bool in irrigation_rows:
		irrigation.append(installed)
	var uv: Array = []
	for level: int in uv_rows:
		uv.append(level)
	return {
		"index": index,
		"cols": cols,
		"rows": rows,
		"unlocked": unlocked,
		"pots": pot_data,
		"irrigation": irrigation,
		"uv": uv,
		"drones": drones,
	}


## Sözlükten kat kurar. Ölçüler `def`'ten alınır (kayıt eski bir sürümden gelse bile ızgara tanımla uyumlu kalır);
## kayıttaki saksı/donanım listeleri bu ölçülere kırpılır ya da boşla tamamlanır.
static func from_dict(data: Dictionary, def: FloorDef, ruleset: GeneticsRuleset) -> FloorState:
	var state: FloorState = FloorState.from_def(def, bool(data.get("unlocked", false)))
	var pot_data: Array = data.get("pots", []) as Array
	for i: int in mini(pot_data.size(), state.pots.size()):
		var entry: Variant = pot_data[i]
		if entry is Dictionary:
			state.pots[i] = PotState.from_dict(entry as Dictionary, ruleset)
	var irrigation: Array = data.get("irrigation", []) as Array
	for r: int in mini(irrigation.size(), state.rows):
		state.irrigation_rows[r] = bool(irrigation[r])
	var uv: Array = data.get("uv", []) as Array
	for r: int in mini(uv.size(), state.rows):
		state.uv_rows[r] = maxi(int(uv[r]), 0)
	state.drones = maxi(int(data.get("drones", 0)), 0)
	return state
