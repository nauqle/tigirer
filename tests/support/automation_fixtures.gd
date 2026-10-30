class_name AutomationFixtures
extends RefCounted
## Otomasyon testleri için KODLA kurulan donanım, kat ve dron ayarı. Gerçek veriye bağlı değildir.
##
## Donanım: sulama 100 (1 seviye), UV 200 x 2.0 büyüme (en çok 2), dron 300 x 2.0 (en çok 3), laboratuvar UV 400 x 2.0 (en çok 3,
## seviye başına +%3). Katlar: 0 açık, 1 ve 2 kilitli (maliyet 500 ve 1000). Dron: 2 hücre/sn, 0.5 sn biçme, 0.5 sn bekleme.

static func make_equipment(id: StringName, kind: EquipmentDef.Kind, cost: int, growth: float, max_level: int, bonus: float = 0.0) -> EquipmentDef:
	var def: EquipmentDef = EquipmentDef.new()
	def.id = id
	def.kind = kind
	def.display_name = String(id)
	def.cost = cost
	def.cost_growth = growth
	def.max_level = max_level
	def.mutation_bonus_per_level = bonus
	return def


static func make_equipment_set() -> Array[EquipmentDef]:
	return [
		make_equipment(&"irrigation", EquipmentDef.Kind.IRRIGATION, 100, 1.0, 1),
		make_equipment(&"uv", EquipmentDef.Kind.UV_LAMP, 200, 2.0, 2),
		make_equipment(&"drone", EquipmentDef.Kind.DRONE, 300, 2.0, 3),
		make_equipment(&"lab_uv", EquipmentDef.Kind.LAB_UV, 400, 2.0, 3, 0.03),
	]


static func make_floor_defs() -> Array[FloorDef]:
	return [FarmFixtures.make_def(0, 2, 2, 0), FarmFixtures.make_def(1, 2, 2, 500), FarmFixtures.make_def(2, 3, 2, 1000)]


static func make_config() -> AutomationConfig:
	var config: AutomationConfig = AutomationConfig.new()
	config.drone_speed = 2.0
	config.drone_harvest_seconds = 0.5
	config.drone_idle_seconds = 0.5
	config.dock_position = Vector2(-1.0, 0.0)
	config.offline_drone_cycle_seconds = 4.0
	return config


## Üç katlı çiftlik (ilki açık) kurar; floor_defs'e uygun durumlar.
static func make_farm() -> FarmService:
	var defs: Array[FloorDef] = make_floor_defs()
	var floors: Array[FloorState] = []
	for def: FloorDef in defs:
		floors.append(FloorState.from_def(def, def.index == 0))
	var farm: FarmService = FarmService.new()
	farm.setup(FarmFixtures.make_config(), GeneticsFixtures.make_ruleset(), floors)
	return farm


static func make_service(farm: FarmService, wallet: WalletService) -> AutomationService:
	var service: AutomationService = AutomationService.new()
	service.setup(farm, wallet, make_floor_defs(), make_equipment_set())
	return service
