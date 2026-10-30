class_name FarmFixtures
extends RefCounted
## Çiftlik testleri için KODLA kurulan yapılandırma, kat ve servis. Gerçek veri dosyalarına bağlı değildir:
## sayılar burada açıkça yazılıdır, testler beklenen değeri elle hesaplayabilir.
##
## Meyve değerleri (GeneticsFixtures): FRUIT_A = 10, FRUIT_B = 20, FRUIT_R = 50. Genlerin sayısal alelleri nötr (1.0).

## Taban büyüme 40 sn, su tüketimi 0.012/sn, UV seviyesi başına +%50, sulama 0.25/sn, hasat 3 meyve + 1 tohum.
static func make_config() -> FarmConfig:
	var config: FarmConfig = FarmConfig.new()
	config.base_grow_seconds = 40.0
	config.sprout_threshold = 0.25
	config.water_drain_per_second = 0.012
	config.water_growth_threshold = 0.15
	config.water_growth_ramp = 0.10
	config.water_start = 1.0
	config.uv_growth_bonus_per_level = 0.5
	config.irrigation_refill_per_second = 0.25
	config.base_yield_units = 3
	config.seeds_returned_per_harvest = 1
	config.overgrowth_grace_seconds = 60.0
	config.overgrowth_loss_per_minute = 0.10
	config.overgrowth_min_factor = 0.5
	config.combo_bonus_per_step = 0.05
	config.combo_bonus_cap = 0.5
	config.day_length_seconds = 300.0
	config.max_speed = 5.0
	config.offline_max_hours = 8.0
	config.offline_min_report_seconds = 60.0
	config.offline_step_seconds = 5.0
	config.offline_yield_factor = 1.0
	return config


static func make_def(index: int = 0, cols: int = 2, rows: int = 2, unlock_cost: int = 0) -> FloorDef:
	var def: FloorDef = FloorDef.new()
	def.index = index
	def.display_name = "Kat %d" % index
	def.cols = cols
	def.rows = rows
	def.unlock_cost = unlock_cost
	return def


static func make_floor(cols: int = 2, rows: int = 2, unlocked: bool = true, index: int = 0) -> FloorState:
	return FloorState.from_def(make_def(index, cols, rows), unlocked)


## Tek açık kat (2x2) ve ikinci kilitli kat içeren servis.
static func make_farm(cols: int = 2, rows: int = 2) -> FarmService:
	var farm: FarmService = FarmService.new()
	var floor_states: Array[FloorState] = [make_floor(cols, rows, true, 0), make_floor(cols, rows, false, 1)]
	farm.setup(make_config(), GeneticsFixtures.make_ruleset(), floor_states)
	return farm


## Nötr alelli homozigot bitki; meyve türü seçilebilir (varsayılan değer 10).
static func make_gene(fruit: StringName = GeneticsFixtures.FRUIT_A, uid: String = "g") -> PlantGene:
	return GeneticsFixtures.make_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, fruit, uid)


## Verilen oyun saniyesini tek `tick` ile ilerletir.
static func advance(farm: FarmService, seconds: float) -> void:
	farm.tick(seconds)
