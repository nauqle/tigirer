extends TestCase
## FarmService: ekim, sulama, büyüme, olgunlaşma, otomasyon etkisi, aşırı olgunluk ve hasat.
## Sayılar FarmFixtures'tan: taban büyüme 40 sn, su tüketimi 0.012/sn, meyve değeri 10.

const EPSILON: float = 0.001

var _farm: FarmService


func before_each() -> void:
	_farm = FarmFixtures.make_farm()


# ------------------------------------------------------------------- ekim


func test_planting_into_an_empty_pot_fills_it_and_announces_it() -> void:
	var events: Array[String] = []
	_farm.planted.connect(func(floor_index: int, pot_index: int) -> void: events.append("%d:%d" % [floor_index, pot_index]))

	var ok: bool = _farm.plant(0, 1, FarmFixtures.make_gene())

	assert_true(ok)
	var pot: PotState = _farm.get_pot(0, 1)
	assert_false(pot.is_empty(), "saksı dolu")
	assert_not_null(pot.phenotype, "fenotip önbelleği kuruldu")
	assert_almost_eq(pot.growth, 0.0, EPSILON, "tohum evresinde başlar")
	assert_eq(events, ["0:1"] as Array[String])


func test_planting_is_refused_for_a_full_pot_a_locked_floor_or_bad_indices() -> void:
	_farm.plant(0, 0, FarmFixtures.make_gene())

	assert_false(_farm.plant(0, 0, FarmFixtures.make_gene()), "dolu saksı")
	assert_false(_farm.plant(1, 0, FarmFixtures.make_gene()), "kilitli kat")
	assert_false(_farm.plant(0, 99, FarmFixtures.make_gene()), "geçersiz saksı")
	assert_false(_farm.plant(7, 0, FarmFixtures.make_gene()), "geçersiz kat")
	assert_false(_farm.plant(0, 1, null), "gen yok")


# ----------------------------------------------------------------- büyüme


func test_a_plant_grows_linearly_and_matures_once_after_the_base_time() -> void:
	var matured: Array[String] = []
	_farm.matured.connect(func(floor_index: int, pot_index: int) -> void: matured.append("%d:%d" % [floor_index, pot_index]))
	_farm.plant(0, 0, FarmFixtures.make_gene())

	_farm.tick(20.0)
	assert_almost_eq(_farm.get_pot(0, 0).growth, 0.5, EPSILON, "yarı yolda yarı büyüme")
	assert_false(_farm.get_pot(0, 0).is_mature())

	_farm.tick(25.0)
	assert_true(_farm.get_pot(0, 0).is_mature(), "40 sn sonra olgun")
	_farm.tick(10.0)

	assert_eq(matured, ["0:0"] as Array[String], "olgunlaşma olayı yalnızca bir kez")


func test_a_faster_gene_matures_in_proportionally_less_time() -> void:
	var fast: PlantGene = FarmFixtures.make_gene()
	fast.growth_alleles = PackedFloat32Array([2.0, 2.0])
	_farm.plant(0, 0, fast)

	_farm.tick(10.0)

	assert_almost_eq(_farm.get_pot(0, 0).growth, 0.5, EPSILON, "2x hız: 10 sn'de yarı")


func test_growth_is_independent_of_how_the_time_is_sliced() -> void:
	var sliced: FarmService = FarmFixtures.make_farm()
	_farm.plant(0, 0, FarmFixtures.make_gene())
	sliced.plant(0, 0, FarmFixtures.make_gene())

	_farm.tick(12.0)
	for i: int in 120:
		sliced.tick(0.1)

	assert_almost_eq(sliced.get_pot(0, 0).growth, _farm.get_pot(0, 0).growth, 0.001, "tek büyük adım = çok küçük adım")


func test_a_long_tick_is_split_so_a_pot_that_dries_out_mid_step_stops_growing() -> void:
	# Su 0.3'ten başlar ve büyürken kurur: tek 20 sn'lik adım, 200 küçük adımla aynı sonucu vermeli
	var sliced: FarmService = FarmFixtures.make_farm()
	_farm.plant(0, 0, FarmFixtures.make_gene())
	sliced.plant(0, 0, FarmFixtures.make_gene())
	_farm.get_pot(0, 0).water = 0.3
	sliced.get_pot(0, 0).water = 0.3

	_farm.tick(20.0)
	for i: int in 200:
		sliced.tick(0.1)

	assert_almost_eq(_farm.get_pot(0, 0).growth, sliced.get_pot(0, 0).growth, 0.01, "uzun adım bölünerek hesaplanır")
	assert_true(_farm.get_pot(0, 0).growth < 0.35, "ortada kuruyan bitki, sabit hızla (0.5) büyüyenden az büyüdü")


# --------------------------------------------------------------------- su


func test_water_drains_while_growing_and_a_thirstier_gene_drains_faster() -> void:
	var thirsty: PlantGene = FarmFixtures.make_gene()
	thirsty.water_alleles = PackedFloat32Array([2.0, 2.0])
	_farm.plant(0, 0, FarmFixtures.make_gene())
	_farm.plant(0, 1, thirsty)

	_farm.tick(10.0)

	assert_almost_eq(_farm.get_pot(0, 0).water, 1.0 - 0.012 * 10.0, EPSILON, "normal: 0.12 kayıp")
	assert_almost_eq(_farm.get_pot(0, 1).water, 1.0 - 0.024 * 10.0, EPSILON, "2x susuz: 0.24 kayıp")


func test_a_dry_pot_stops_growing_and_stops_draining() -> void:
	_farm.plant(0, 0, FarmFixtures.make_gene())
	_farm.get_pot(0, 0).water = 0.0

	_farm.tick(30.0)

	assert_almost_eq(_farm.get_pot(0, 0).growth, 0.0, EPSILON, "susuz bitki büyümez")


func test_an_empty_pot_neither_grows_nor_loses_water() -> void:
	_farm.tick(60.0)

	assert_almost_eq(_farm.get_pot(0, 0).water, 1.0, EPSILON)
	assert_true(_farm.get_pot(0, 0).is_empty())


func test_watering_refills_the_pot_and_announces_it() -> void:
	var count: Dictionary = {"n": 0}
	_farm.watered.connect(func(_floor_index: int, _pot_index: int) -> void: count["n"] += 1)
	_farm.plant(0, 0, FarmFixtures.make_gene())
	_farm.get_pot(0, 0).water = 0.1

	var ok: bool = _farm.water(0, 0)

	assert_true(ok)
	assert_almost_eq(_farm.get_pot(0, 0).water, 1.0, EPSILON)
	assert_eq(count["n"], 1)
	assert_false(_farm.water(1, 0), "kilitli katta sulama yok")


func test_water_floor_refills_only_planted_pots_that_need_it() -> void:
	_farm.plant(0, 0, FarmFixtures.make_gene())
	_farm.plant(0, 1, FarmFixtures.make_gene())
	_farm.get_pot(0, 0).water = 0.3
	_farm.get_pot(0, 2).water = 0.2  # boş saksı: sulanmaz

	var watered: int = _farm.water_floor(0)

	assert_eq(watered, 1, "yalnızca eksik sulu, dolu saksı")
	assert_almost_eq(_farm.get_pot(0, 0).water, 1.0, EPSILON)
	assert_almost_eq(_farm.get_pot(0, 2).water, 0.2, EPSILON, "boş saksı dokunulmadı")


# ----------------------------------------------------------------- otomasyon


func test_uv_lamps_on_a_row_speed_up_only_that_row() -> void:
	_farm.get_floor(0).uv_rows[0] = 2  # satır 0: +%100
	_farm.plant(0, 0, FarmFixtures.make_gene())  # satır 0
	_farm.plant(0, 2, FarmFixtures.make_gene())  # satır 1

	_farm.tick(10.0)

	assert_almost_eq(_farm.get_pot(0, 0).growth, 0.5, EPSILON, "UV'li satır 2x")
	assert_almost_eq(_farm.get_pot(0, 2).growth, 0.25, EPSILON, "UV'siz satır normal")


func test_irrigation_keeps_a_row_watered_so_the_plant_never_stalls() -> void:
	_farm.get_floor(0).irrigation_rows[0] = true
	_farm.plant(0, 0, FarmFixtures.make_gene())

	_farm.tick(100.0)

	assert_true(_farm.get_pot(0, 0).is_mature(), "40 sn'de olgunlaştı")
	assert_true(_farm.get_pot(0, 0).water > 0.99, "sulama suyu dolu tutar")


func test_irrigation_also_refills_empty_pots_of_its_row() -> void:
	_farm.get_floor(0).irrigation_rows[1] = true
	_farm.get_pot(0, 2).water = 0.2

	_farm.tick(4.0)

	assert_almost_eq(_farm.get_pot(0, 2).water, 1.0, EPSILON)
	assert_almost_eq(_farm.get_pot(0, 0).water, 1.0, EPSILON, "diğer satır etkilenmedi (zaten dolu)")


# -------------------------------------------------------------- aşırı olgunluk


func test_a_mature_plant_left_unharvested_loses_value_after_the_grace_period() -> void:
	_farm.get_floor(0).irrigation_rows[0] = true
	_farm.plant(0, 0, FarmFixtures.make_gene())
	_farm.tick(40.0)

	_farm.tick(120.0)  # 60 sn ek süre + 60 sn gecikme = -%10
	var result: HarvestResult = _farm.harvest(0, 0)

	assert_almost_eq(result.overgrowth_factor, 0.9, 0.01)
	assert_almost_eq(result.unit_value, 9.0, 0.1, "10 x 0.9")


# ----------------------------------------------------------------------- hasat


func test_harvesting_a_mature_plant_yields_fruit_seeds_and_empties_the_pot() -> void:
	var seen: Array[HarvestResult] = []
	_farm.harvested.connect(func(result: HarvestResult) -> void: seen.append(result))
	_farm.get_floor(0).irrigation_rows[0] = true
	_farm.plant(0, 0, FarmFixtures.make_gene(GeneticsFixtures.FRUIT_B))
	_farm.tick(45.0)

	var result: HarvestResult = _farm.harvest(0, 0)

	assert_not_null(result)
	assert_eq(result.quantity, 3, "taban verim")
	assert_almost_eq(result.unit_value, 20.0, 0.1, "FRUIT_B değeri")
	assert_almost_eq(result.total_value(), 60.0, 0.5)
	assert_eq(result.seeds_returned, 1, "bir tohum döner")
	assert_true(_farm.get_pot(0, 0).is_empty(), "saksı boşaldı")
	assert_eq(seen.size(), 1, "harvested olayı yayınlandı")


func test_harvest_is_refused_for_an_immature_or_empty_pot() -> void:
	_farm.plant(0, 0, FarmFixtures.make_gene())
	_farm.tick(10.0)

	assert_null(_farm.harvest(0, 0), "olgun değil")
	assert_null(_farm.harvest(0, 1), "boş saksı")
	assert_false(_farm.get_pot(0, 0).is_empty(), "başarısız hasat bitkiyi bozmaz")


func test_combo_steps_raise_the_unit_value_up_to_the_cap() -> void:
	for pot_index: int in 4:
		_farm.get_floor(0).irrigation_rows[pot_index / 2] = true
		_farm.plant(0, pot_index, FarmFixtures.make_gene())
	_farm.tick(45.0)

	var first: HarvestResult = _farm.harvest(0, 0, 0)
	var fourth: HarvestResult = _farm.harvest(0, 1, 3)
	var capped: HarvestResult = _farm.harvest(0, 2, 100)

	assert_almost_eq(first.unit_value, 10.0, 0.1, "ilk bitki: bonus yok")
	assert_almost_eq(fourth.unit_value, 11.5, 0.1, "3. adım: +%15")
	assert_almost_eq(capped.unit_value, 15.0, 0.1, "tavan: +%50")


func test_replanting_on_harvest_restarts_the_same_gene_and_keeps_the_seed_count_even() -> void:
	_farm.get_floor(0).irrigation_rows[0] = true
	var gene: PlantGene = FarmFixtures.make_gene(GeneticsFixtures.FRUIT_A, "drone-gene")
	_farm.plant(0, 0, gene)
	_farm.tick(45.0)

	var result: HarvestResult = _farm.harvest(0, 0, 0, true)

	var pot: PotState = _farm.get_pot(0, 0)
	assert_false(pot.is_empty(), "aynı gen yeniden dikildi")
	assert_eq(pot.gene.uid, "drone-gene")
	assert_almost_eq(pot.growth, 0.0, EPSILON)
	assert_eq(result.seeds_returned, 0, "dönen tohum yeniden ekimde harcandı")


# -------------------------------------------------------------------- sorgular


func test_mature_and_empty_pot_queries_list_the_right_pots() -> void:
	_farm.get_floor(0).irrigation_rows[0] = true
	_farm.plant(0, 0, FarmFixtures.make_gene())
	_farm.plant(0, 3, FarmFixtures.make_gene())
	_farm.get_pot(0, 0).growth = 1.0

	assert_eq(_farm.mature_pot_indices(0), [0] as Array[int])
	assert_eq(_farm.empty_pot_indices(0), [1, 2] as Array[int])
	assert_eq(_farm.mature_pot_indices(1), [] as Array[int], "kilitli katta hiçbiri")
