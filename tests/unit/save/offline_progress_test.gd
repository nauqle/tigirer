extends TestCase
## OfflineProgress: çevrimdışı büyüme, susuzlukta durma, dron hasadı (kapasite sınırlı), aşırı olgunlaşma ve süre sınırı.
## Ayar (Fixtures): taban büyüme 40 sn, su tüketimi 0.012/sn, aşırı olgunluk 60 sn sonra dakikada %10 (taban %50),
## çevrimdışı adım 5 sn, en çok 8 saat; dron döngüsü 4 sn; meyve değeri 10, verim 3.

const EPSILON: float = 0.001

var _farm: FarmService
var _automation: AutomationConfig


func before_each() -> void:
	_farm = FarmFixtures.make_farm(3, 3)  # 3x3 kat, kat 0 açık
	_automation = AutomationFixtures.make_config()


func _plant(pot_index: int, uid: String = "g") -> void:
	_farm.plant(0, pot_index, FarmFixtures.make_gene(GeneticsFixtures.FRUIT_A, "%s-%d" % [uid, pot_index]))


func _irrigate_all() -> void:
	for row: int in 3:
		_farm.get_floor(0).irrigation_rows[row] = true


func test_an_empty_farm_reports_nothing_and_a_zero_gap_changes_nothing() -> void:
	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, 3600.0)

	assert_false(report.has_news())
	assert_eq(report.harvests, 0)
	assert_almost_eq(report.seconds_simulated, 3600.0, EPSILON)

	_plant(0)
	var none: OfflineReport = OfflineProgress.apply(_farm, _automation, 0.0)
	assert_almost_eq(_farm.get_pot(0, 0).growth, 0.0, EPSILON, "süre yok, büyüme yok")
	assert_eq(none.harvests, 0)


func test_a_plant_matures_while_away_and_then_overgrows_while_waiting() -> void:
	_irrigate_all()
	_plant(0)

	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, 7200.0)

	assert_true(_farm.get_pot(0, 0).is_mature())
	assert_eq(report.waiting_mature, 1)
	assert_eq(report.overgrown, 1, "uzun süre beklediği için aşırı olgun")
	# kayıp: (1 - 0.5) x 3 meyve x 10 değer = 15
	assert_almost_eq(report.value_lost, 15.0, 0.01)
	assert_true(report.has_news())


func test_a_just_matured_plant_is_waiting_but_not_overgrown() -> void:
	_irrigate_all()
	_plant(0)

	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, 60.0)  # 40 sn'de olgunlaşır, ek süre 20 sn < 60

	assert_eq(report.waiting_mature, 1)
	assert_eq(report.overgrown, 0)
	assert_almost_eq(report.value_lost, 0.0, EPSILON)


func test_a_dry_pot_stops_growing_when_its_water_runs_out_even_after_hours() -> void:
	_plant(0)
	_farm.get_pot(0, 0).water = 0.2  # eşiğe (0.15) 4 sn'lik su

	OfflineProgress.apply(_farm, _automation, 3600.0)

	assert_true(_farm.get_pot(0, 0).growth < 0.3, "susuz kalan bitki saatlerce durdu (%f)" % _farm.get_pot(0, 0).growth)
	assert_false(_farm.get_pot(0, 0).is_mature())


func test_drones_harvest_replant_and_keep_producing_while_the_player_is_away() -> void:
	_irrigate_all()
	_farm.get_floor(0).drones = 1
	for pot_index: int in 4:
		_plant(pot_index)
	var seen: Array[HarvestResult] = []
	_farm.harvested.connect(func(result: HarvestResult) -> void: seen.append(result))

	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, 600.0)

	assert_true(report.harvests >= 30 and report.harvests <= 60, "4 saksı x ~13 tur (%d)" % report.harvests)
	assert_eq(report.harvested_units, report.harvests * 3)
	assert_eq(seen.size(), report.harvests, "her hasat olayı yayınlandı (envantere akar)")
	assert_almost_eq(report.harvested_value, float(report.harvests) * 30.0, 0.5, "her hasat 3 x 10")
	for pot_index: int in 4:
		assert_false(_farm.get_pot(0, pot_index).is_empty(), "dronlar yeniden dikti")


func test_offline_harvests_use_the_offline_yield_factor_and_restore_the_normal_yield() -> void:
	_farm.config.offline_yield_factor = 0.5  # verim 3 x 0.5 = 1.5 -> 2 birim
	_irrigate_all()
	_farm.get_floor(0).drones = 1
	_plant(0)
	_farm.get_pot(0, 0).growth = 1.0

	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, 20.0)

	assert_true(report.harvests >= 1)
	assert_eq(report.harvested_units, report.harvests * 2, "çevrimdışı hasat 2 birim")
	assert_almost_eq(_farm.yield_factor, 1.0, 0.0001, "normal verim geri yüklendi")


func test_drone_capacity_limits_how_many_plants_are_cut() -> void:
	_irrigate_all()
	_farm.get_floor(0).drones = 1
	for pot_index: int in 9:
		_plant(pot_index)
		_farm.get_pot(0, pot_index).growth = 1.0  # hepsi olgun

	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, 20.0)  # 20 sn / 4 sn = 5 hasat hakkı

	assert_eq(report.harvests, 5, "tek dron 20 sn'de 5 bitki biçer")
	assert_eq(report.waiting_mature, 4, "kalan 4 bitki bekliyor")


func test_more_drones_cut_proportionally_more() -> void:
	_irrigate_all()
	_farm.get_floor(0).drones = 2
	for pot_index: int in 9:
		_plant(pot_index)
		_farm.get_pot(0, pot_index).growth = 1.0

	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, 20.0)

	assert_eq(report.harvests, 9, "2 dron x 5 = 10 hak, 9 olgun bitki")


func test_without_drones_nothing_is_harvested_offline() -> void:
	_irrigate_all()
	for pot_index: int in 3:
		_plant(pot_index)

	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, 3600.0)

	assert_eq(report.harvests, 0)
	assert_eq(report.waiting_mature, 3)


func test_the_away_time_is_capped_at_the_configured_maximum() -> void:
	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, 100.0 * 3600.0)

	assert_true(report.capped)
	assert_almost_eq(report.seconds_simulated, 8.0 * 3600.0, EPSILON)
	assert_almost_eq(report.seconds_away, 100.0 * 3600.0, EPSILON)


func test_a_locked_floor_does_nothing_offline() -> void:
	_farm.get_floor(1).drones = 3
	_farm.get_floor(1).pots[0].gene = FarmFixtures.make_gene()
	_farm.get_floor(1).pots[0].phenotype = GeneticsEngine.express(_farm.get_floor(1).pots[0].gene, GeneticsFixtures.make_ruleset())
	_farm.get_floor(1).pots[0].growth = 1.0

	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, 600.0)

	assert_eq(report.harvests, 0)
	assert_eq(report.waiting_mature, 0, "kilitli kat sayılmaz")


func test_the_capped_flag_is_set_just_past_the_limit_and_not_at_it() -> void:
	var limit: float = _farm.config.offline_max_hours * 3600.0

	var past: OfflineReport = OfflineProgress.apply(_farm, _automation, limit + 1.0)
	var exact: OfflineReport = OfflineProgress.apply(_farm, _automation, limit)

	assert_true(past.capped, "sınırı 1 sn aşınca kırpıldı")
	assert_almost_eq(past.seconds_simulated, limit, EPSILON)
	assert_false(exact.capped, "tam sınırda kırpma yok")


func test_a_negative_gap_is_treated_as_no_time_at_all() -> void:
	_irrigate_all()
	_plant(0)

	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, -500.0)

	assert_almost_eq(report.seconds_away, 0.0, EPSILON)
	assert_almost_eq(report.seconds_simulated, 0.0, EPSILON)
	assert_almost_eq(_farm.get_pot(0, 0).growth, 0.0, EPSILON, "saat geri alınınca bitki büyümez")


func test_a_gap_that_is_not_a_multiple_of_the_step_simulates_exactly_that_long() -> void:
	_irrigate_all()
	_plant(0)
	var reference: FarmService = FarmFixtures.make_farm(3, 3)
	for row: int in 3:
		reference.get_floor(0).irrigation_rows[row] = true
	reference.plant(0, 0, FarmFixtures.make_gene(GeneticsFixtures.FRUIT_A, "g-0"))
	var gap: float = _farm.config.offline_step_seconds + 2.0  # bir tam adım + 2 sn'lik kısa son adım
	reference.tick_with_step(gap, gap)

	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, gap)

	assert_almost_eq(report.seconds_simulated, gap, EPSILON)
	assert_almost_eq(_farm.get_pot(0, 0).growth, reference.get_pot(0, 0).growth, 0.0005, "son adım kısaltıldı, fazladan süre işlenmedi")


func test_a_drone_cuts_the_plant_that_has_waited_longest_first() -> void:
	_irrigate_all()
	_farm.get_floor(0).drones = 1
	for pot_index: int in 9:
		_plant(pot_index)
		_farm.get_pot(0, pot_index).growth = 1.0
	_farm.get_pot(0, 5).overgrowth_seconds = 500.0
	_farm.get_pot(0, 2).overgrowth_seconds = 200.0

	var report: OfflineReport = OfflineProgress.apply(_farm, _automation, _automation.offline_drone_cycle_seconds)  # tek hasat hakkı

	assert_eq(report.harvests, 1)
	assert_false(_farm.get_pot(0, 5).is_mature(), "en uzun bekleyen kesilip yeniden dikildi")
	assert_true(_farm.get_pot(0, 2).is_mature(), "daha az bekleyen sırada")
	assert_true(_farm.get_pot(0, 0).is_mature())
