extends TestCase
## GrowthModel: evreler, su/ışık çarpanları, büyüme hızı, aşırı olgunluk ve kombo formülleri (saf fonksiyonlar).

const EPSILON: float = 0.0001

var _config: FarmConfig


func before_each() -> void:
	_config = FarmFixtures.make_config()


func _phenotype(growth_speed: float = 1.0, water_use: float = 1.0) -> PlantPhenotype:
	var phenotype: PlantPhenotype = PlantPhenotype.new()
	phenotype.growth_speed = growth_speed
	phenotype.water_use = water_use
	return phenotype


func test_stage_changes_at_the_sprout_threshold_and_at_full_growth() -> void:
	assert_eq(GrowthModel.stage_of(0.0, _config), GrowthModel.Stage.SEED, "yeni dikildi")
	assert_eq(GrowthModel.stage_of(0.24, _config), GrowthModel.Stage.SEED, "eşiğin hemen altı")
	assert_eq(GrowthModel.stage_of(0.25, _config), GrowthModel.Stage.SPROUT, "eşik")
	assert_eq(GrowthModel.stage_of(0.99, _config), GrowthModel.Stage.SPROUT, "olgunlaşmadan önce")
	assert_eq(GrowthModel.stage_of(1.0, _config), GrowthModel.Stage.MATURE, "olgun")


func test_water_factor_is_zero_below_threshold_one_above_ramp_and_smooth_between() -> void:
	assert_almost_eq(GrowthModel.water_factor(0.0, _config), 0.0, EPSILON, "kuru")
	assert_almost_eq(GrowthModel.water_factor(0.15, _config), 0.0, EPSILON, "tam eşikte durur")
	assert_almost_eq(GrowthModel.water_factor(0.20, _config), 0.5, EPSILON, "rampanın ortası")
	assert_almost_eq(GrowthModel.water_factor(0.25, _config), 1.0, EPSILON, "rampa sonu")
	assert_almost_eq(GrowthModel.water_factor(1.0, _config), 1.0, EPSILON, "dolu")


func test_light_multiplier_grows_with_the_uv_level_and_ignores_negative_levels() -> void:
	assert_almost_eq(GrowthModel.light_multiplier(0, _config), 1.0, EPSILON)
	assert_almost_eq(GrowthModel.light_multiplier(2, _config), 2.0, EPSILON, "2 seviye = +%100")
	assert_almost_eq(GrowthModel.light_multiplier(-3, _config), 1.0, EPSILON, "negatif seviye yok sayılır")


func test_growth_rate_multiplies_base_speed_water_and_light() -> void:
	# 1/40 = 0.025 taban; gen hızı 2.0 x ışık 2.0 (2 seviye UV) = 0.1
	var rate: float = GrowthModel.growth_rate(_phenotype(2.0), 1.0, 2, _config)

	assert_almost_eq(rate, 0.1, EPSILON)
	assert_almost_eq(GrowthModel.growth_rate(_phenotype(1.0), 0.0, 0, _config), 0.0, EPSILON, "susuz bitki büyümez")


func test_water_drain_scales_with_the_water_use_of_the_gene() -> void:
	assert_almost_eq(GrowthModel.water_drain(_phenotype(1.0, 1.0), _config), 0.012, EPSILON)
	assert_almost_eq(GrowthModel.water_drain(_phenotype(1.0, 2.0), _config), 0.024, EPSILON, "su tüketimi 2x")


func test_overgrowth_factor_has_a_grace_period_a_linear_loss_and_a_floor() -> void:
	assert_almost_eq(GrowthModel.overgrowth_factor(0.0, _config), 1.0, EPSILON, "yeni olgun")
	assert_almost_eq(GrowthModel.overgrowth_factor(60.0, _config), 1.0, EPSILON, "ek süre sonu")
	assert_almost_eq(GrowthModel.overgrowth_factor(120.0, _config), 0.9, EPSILON, "bir dakika geç = -%10")
	assert_almost_eq(GrowthModel.overgrowth_factor(1000000.0, _config), 0.5, EPSILON, "alt sınır")


func test_combo_bonus_grows_per_step_and_stops_at_the_cap() -> void:
	assert_almost_eq(GrowthModel.combo_bonus(0, _config), 0.0, EPSILON, "ilk bitkide bonus yok")
	assert_almost_eq(GrowthModel.combo_bonus(2, _config), 0.1, EPSILON)
	assert_almost_eq(GrowthModel.combo_bonus(100, _config), 0.5, EPSILON, "tavan")
	assert_almost_eq(GrowthModel.combo_bonus(-4, _config), 0.0, EPSILON, "negatif adım yok sayılır")
