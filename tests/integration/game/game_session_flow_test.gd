extends TestCase
## GameSession: gerçek katalogla uçtan uca oyun akışı. Ekim -> büyüme -> hasat -> satış, kaydırma kombosu, VIP sipariş,
## çaprazlama + Seed-Dex ödülü, donanım/kat satın alma, kaydet/yükle, çevrimdışı ilerleme ve sıfırlama.

const CATALOG_PATH: String = "res://assets/data/game_catalog.tres"
const TEST_SAVE: String = "user://test_game_session.dat"
const REED: String = "starter_reed_berry"
const VINE: String = "starter_vine_tulip"
const BAMBOO: String = "starter_bamboo_pod"
const CARRIER: String = "starter_cyber_carrier"

var _catalog: GameCatalog


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as GameCatalog
	SaveManager.new(TEST_SAVE).delete_save()


func after_each() -> void:
	SaveManager.new(TEST_SAVE).delete_save()


func _session(rng_seed: int = 7) -> GameSession:
	var session: GameSession = GameSession.new()
	add_to_tree(session)
	session.autosave_enabled = false
	session.simulate_enabled = false
	session.setup(_catalog, TEST_SAVE, rng_seed)
	return session


## Taban büyüme süresinden uzun bir süre geçirir (tek sulama yetmez: tüm satırlara sulama kurulur).
func _grow(session: GameSession, seconds: float) -> void:
	for row: int in session.farm.get_floor(0).rows:
		session.farm.get_floor(0).irrigation_rows[row] = true
	session.tick(seconds)


# ------------------------------------------------------------------ yeni oyun


func test_a_new_game_starts_with_credits_seeds_an_open_ground_floor_and_a_seeded_dex() -> void:
	var session: GameSession = _session()

	assert_eq(session.wallet.credits, _catalog.economy_config.starting_credits)
	assert_eq(session.inventory.seed_count(REED), 3)
	assert_eq(session.inventory.seed_count(CARRIER), 1)
	assert_true(session.farm.get_floor(0).unlocked)
	assert_false(session.farm.get_floor(1).unlocked)
	assert_eq(session.dex.species_count(), 4, "başlangıç türleri Seed-Dex'te")
	assert_eq(session.time.day(), 1)
	assert_eq(session.orders.orders.size(), 0, "ilk sipariş ilk tikte gelir")


# ------------------------------------------------------------------- ekim


func test_planting_spends_a_seed_and_fills_the_pot() -> void:
	var session: GameSession = _session()

	var result: CommandResult = session.plant_seed(0, 0, REED)

	assert_true(result.ok)
	assert_eq(session.inventory.seed_count(REED), 2)
	assert_false(session.farm.get_pot(0, 0).is_empty())


func test_planting_refusals_name_the_reason_and_change_nothing() -> void:
	var session: GameSession = _session()
	session.plant_seed(0, 0, REED)

	assert_eq(session.plant_seed(0, 0, REED).message_key, "ERR_POT_OCCUPIED")
	assert_eq(session.plant_seed(0, 1, "yok").message_key, "ERR_SEED_MISSING")
	assert_eq(session.plant_seed(1, 0, REED).message_key, "ERR_FLOOR_LOCKED")
	assert_eq(session.plant_seed(9, 0, REED).message_key, "ERR_INVALID_TARGET")
	assert_eq(session.inventory.seed_count(REED), 2, "başarısız komutlar tohum harcamadı")


func test_plant_all_fills_empty_pots_only_as_far_as_the_seeds_reach() -> void:
	var session: GameSession = _session()

	var result: CommandResult = session.plant_all(0, REED)  # 3 tohum, 6 saksı

	assert_true(result.ok)
	assert_eq(result.args, [3] as Array)
	assert_eq(session.inventory.seed_count(REED), 0)
	assert_eq(session.farm.empty_pot_indices(0).size(), 3)
	assert_eq(session.plant_all(0, REED).message_key, "ERR_SEED_MISSING", "tohum bitti")


# --------------------------------------------------------- büyüme, hasat, satış


func test_the_full_loop_plant_grow_harvest_and_sell() -> void:
	var session: GameSession = _session()
	session.goals.setup([] as Array[GoalDef], session.wallet)  # hedef ödülleri satış gelirini karıştırmasın
	var start_credits: int = session.wallet.credits
	session.plant_all(0, REED)
	_grow(session, _catalog.farm_config.base_grow_seconds + 5.0)

	for pot_index: int in 3:
		assert_true(session.harvest_pot(0, pot_index).ok, "olgun bitki biçildi")

	var units: int = _catalog.farm_config.base_yield_units
	assert_eq(session.inventory.produce_count(), 3 * units, "3 bitki x verim")
	assert_eq(session.inventory.seed_count(REED), 3, "her hasat tohumu geri verdi")
	var sold: CommandResult = session.sell_everything()
	assert_true(sold.ok)
	assert_eq(session.inventory.produce_count(), 0)
	var earned: int = session.wallet.credits - start_credits
	# Kamış meyvesi 8 değerinde; taban = 3 bitki x verim x 8. Piyasa eğilimi ve arz etkisiyle bir bantta
	var base_value: float = 3.0 * float(units) * 8.0
	assert_between(float(earned), base_value * 0.5, base_value * 1.5, "satıştan kazanç (%d, taban %.0f)" % [earned, base_value])


func test_harvesting_an_immature_plant_is_refused() -> void:
	var session: GameSession = _session()
	session.plant_seed(0, 0, REED)

	assert_eq(session.harvest_pot(0, 0).message_key, "ERR_NOT_MATURE")
	assert_eq(session.harvest_pot(0, 5).message_key, "ERR_NOT_MATURE", "boş saksı")


func test_a_swipe_builds_a_combo_and_announces_the_swipe_total() -> void:
	var session: GameSession = _session()
	session.plant_all(0, REED)
	_grow(session, _catalog.farm_config.base_grow_seconds + 5.0)
	var summaries: Array[String] = []
	var listener: Callable = func(count: int, value: float) -> void: summaries.append("%d:%d" % [count, int(value)])
	SignalBus.harvest_swipe_finished.connect(listener)

	session.begin_swipe()
	assert_true(session.swipe_harvest(0, 0))
	assert_true(session.swipe_harvest(0, 1))
	assert_true(session.swipe_harvest(0, 2))
	assert_false(session.swipe_harvest(0, 3), "boş saksı biçilmez")
	session.end_swipe()
	SignalBus.harvest_swipe_finished.disconnect(listener)

	assert_eq(summaries.size(), 1)
	assert_true(summaries[0].begins_with("3:"), "3 bitkilik kombo")
	# kombo: 0, +%5, +%10 -> ikinci ve üçüncü bitki daha değerli: toplam >= taban (3 bitki x verim x 8)
	var base_total: float = 3.0 * float(_catalog.farm_config.base_yield_units) * 8.0
	assert_true(float(summaries[0].split(":")[1]) >= base_total, "kombo bonusu işledi")


func test_an_empty_swipe_announces_nothing() -> void:
	var session: GameSession = _session()
	var count: Dictionary = {"n": 0}
	var listener: Callable = func(_c: int, _v: float) -> void: count["n"] += 1
	SignalBus.harvest_swipe_finished.connect(listener)

	session.begin_swipe()
	session.end_swipe()
	SignalBus.harvest_swipe_finished.disconnect(listener)

	assert_eq(count["n"], 0)


# ------------------------------------------------------------------ sipariş


func test_an_open_order_is_fulfilled_from_the_inventory_for_its_reward_and_reputation() -> void:
	var session: GameSession = _session()
	session.tick(0.5)  # ilk sipariş gelir
	assert_true(session.orders.orders.size() >= 1, "sipariş geldi")
	var order: Order = session.orders.orders[0]
	var gene: PlantGene = PlantGene.homozygous(&"stem_reed", &"leaf_oval", order.fruit_id, 0.3)
	gene.uid = "order-gene"
	var result: HarvestResult = HarvestResult.new()
	result.gene = gene
	result.phenotype = GeneticsEngine.express(gene, _catalog.ruleset)
	result.quantity = order.quantity
	result.unit_value = 100.0
	session.inventory.add_produce(result)
	var before: int = session.wallet.credits

	var done: CommandResult = session.fulfil_order(order.id)

	assert_true(done.ok)
	assert_eq(session.wallet.credits, before + order.reward)
	assert_eq(session.wallet.reputation, 1)
	assert_null(session.orders.get_order(order.id), "sipariş kapandı")
	assert_eq(session.inventory.produce_count(), 0)


func test_fulfilling_without_the_goods_is_refused() -> void:
	var session: GameSession = _session()
	session.tick(0.5)

	assert_eq(session.fulfil_order(session.orders.orders[0].id).message_key, "ERR_ORDER_NOT_READY")
	assert_eq(session.fulfil_order(12345).message_key, "ERR_ORDER_NOT_READY")


# ------------------------------------------------------------- çaprazlama


func test_crossbreeding_charges_the_fee_adds_children_and_rewards_a_new_species() -> void:
	var session: GameSession = _session()
	var credits: int = session.wallet.credits
	var seeds: int = session.inventory.seed_total()
	var species: int = session.dex.species_count()

	var result: CommandResult = session.crossbreed(REED, VINE)

	assert_true(result.ok)
	assert_eq(session.last_breed.children.size(), _catalog.economy_config.offspring_per_cross)
	assert_eq(session.inventory.seed_total(), seeds + session.last_breed.children.size())
	assert_eq(session.dex.species_count(), species + 1, "kamış x sarmaşık: yeni bir tür")
	var net: int = session.wallet.credits - credits
	# -40 ücret + 60 yeni tür ödülü (+ aynı türün farklı tonu için en çok 12)
	assert_between(float(net), 20.0, 32.0, "ücret ve keşif ödülü (%d)" % net)


func test_crossbreeding_without_credits_or_seeds_is_refused() -> void:
	var session: GameSession = _session()
	assert_eq(session.crossbreed(REED, "yok").message_key, "ERR_SEED_MISSING")

	session.wallet.spend(session.wallet.credits - 10)
	var poor: CommandResult = session.crossbreed(REED, VINE)

	assert_false(poor.ok)
	assert_eq(poor.message_key, "ERR_NOT_ENOUGH_CREDITS")
	assert_eq(poor.args, [_catalog.economy_config.cross_cost] as Array)


# ------------------------------------------------------- donanım ve katlar


func test_equipment_and_floor_purchases_go_through_the_wallet() -> void:
	var session: GameSession = _session()
	session.wallet.add_credits(10000)
	var before: int = session.wallet.credits

	assert_true(session.buy_irrigation(0, 0).ok)
	assert_true(session.buy_uv_lamp(0, 1).ok)
	assert_true(session.buy_drone(0).ok)
	assert_true(session.unlock_floor(1).ok)

	assert_true(session.farm.get_floor(0).irrigation_rows[0])
	assert_eq(session.farm.get_floor(0).uv_rows[1], 1)
	assert_eq(session.farm.get_floor(0).drones, 1)
	assert_true(session.farm.get_floor(1).unlocked)
	assert_true(session.wallet.credits < before)
	assert_true(session.plant_seed(1, 0, BAMBOO).ok, "yeni katta ekim yapılır")


func test_the_lab_uv_room_raises_the_mutation_chance_used_by_crossbreeding() -> void:
	var session: GameSession = _session()
	session.wallet.add_credits(100000)
	for i: int in 3:
		assert_true(session.buy_lab_uv().ok)

	assert_almost_eq(session.automation.lab_mutation_bonus(), 0.09, 0.0001)


# --------------------------------------------------------- zaman ve hız


func test_tick_advances_growth_and_respects_speed_and_pause() -> void:
	var session: GameSession = _session()
	session.plant_seed(0, 0, REED)
	session.plant_seed(0, 1, REED)
	session.plant_seed(0, 2, REED)

	session.tick(10.0)
	var normal: float = session.farm.get_pot(0, 0).growth
	session.set_speed(5.0)
	session.tick(2.0)  # 2 sn x 5 = 10 oyun sn
	var boosted: float = session.farm.get_pot(0, 0).growth - normal
	session.time.paused = true
	var frozen: float = session.farm.get_pot(0, 0).growth
	session.tick(30.0)

	var expected: float = 10.0 / _catalog.farm_config.base_grow_seconds
	assert_almost_eq(normal, expected, 0.01, "10 sn / taban süre")
	assert_almost_eq(boosted, expected, 0.02, "hız x5: 2 gerçek sn = 10 oyun sn")
	assert_almost_eq(session.farm.get_pot(0, 0).growth, frozen, 0.0001, "duraklatılmış oyun ilerlemez")


# -------------------------------------------------------- kaydet / yükle


func test_save_and_load_restore_the_whole_state() -> void:
	var first: GameSession = _session()
	first.plant_all(0, REED)
	first.wallet.add_credits(3000)
	first.buy_irrigation(0, 0)
	first.crossbreed(REED, VINE)
	_grow(first, 20.0)
	first.tick(3.0)
	assert_true(first.save_game())

	var second: GameSession = _session(99)
	var loaded: bool = second.load_game()

	assert_true(loaded)
	assert_eq(second.wallet.credits, first.wallet.credits)
	assert_eq(second.inventory.seed_total(), first.inventory.seed_total())
	assert_eq(second.dex.species_count(), first.dex.species_count())
	assert_eq(second.farm.get_floor(0).irrigation_rows[0], true)
	for pot_index: int in 3:
		assert_eq(second.farm.get_pot(0, pot_index).gene.uid, first.farm.get_pot(0, pot_index).gene.uid, "saksı %d tohumu" % pot_index)
		assert_almost_eq(second.farm.get_pot(0, pot_index).growth, first.farm.get_pot(0, pot_index).growth, 0.01)
	assert_almost_eq(second.time.game_seconds, first.time.game_seconds, 1.0)


func test_start_loads_a_save_when_there_is_one_and_begins_fresh_when_there_is_not() -> void:
	var fresh: GameSession = _session()
	assert_false(fresh.start(), "kayıt yok: yeni oyun")

	fresh.wallet.add_credits(777)
	fresh.save_game()
	var again: GameSession = _session()

	assert_true(again.start(), "kayıt var: yüklendi")
	assert_eq(again.wallet.credits, fresh.wallet.credits)


func test_a_corrupt_save_falls_back_to_a_new_game() -> void:
	var file: FileAccess = FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string("bozuk")
	file.close()
	var session: GameSession = _session()

	assert_false(session.start())
	assert_eq(session.wallet.credits, _catalog.economy_config.starting_credits)


func test_reset_game_deletes_the_save_and_restores_the_start() -> void:
	var session: GameSession = _session()
	session.wallet.add_credits(5000)
	session.save_game()

	session.reset_game()

	assert_false(session.saves.has_save())
	assert_eq(session.wallet.credits, _catalog.economy_config.starting_credits)
	assert_eq(session.inventory.seed_count(REED), 3)


# -------------------------------------------------------------- çevrimdışı


func test_offline_progress_lets_drones_harvest_into_the_inventory_and_advances_the_clock() -> void:
	var session: GameSession = _session()
	session.wallet.add_credits(5000)
	session.buy_irrigation(0, 0)
	session.buy_irrigation(0, 1)
	session.buy_drone(0)
	session.plant_all(0, REED)
	var clock_before: float = session.time.game_seconds
	var reports: Array[OfflineReport] = []
	var listener: Callable = func(report: OfflineReport) -> void: reports.append(report)
	SignalBus.offline_report_ready.connect(listener)

	var report: OfflineReport = session.apply_offline(1800.0)
	SignalBus.offline_report_ready.disconnect(listener)

	assert_not_null(report)
	assert_true(report.harvests > 0, "dron hasat etti (%d)" % report.harvests)
	assert_true(session.inventory.produce_count() > 0, "ürün envantere aktı")
	assert_almost_eq(session.time.game_seconds - clock_before, 1800.0, 1.0, "oyun saati ilerledi")
	assert_eq(reports.size(), 1, "rapor olayı yayınlandı")
	assert_eq(session.last_offline_report, report)


func test_a_short_gap_is_ignored() -> void:
	var session: GameSession = _session()

	assert_null(session.apply_offline(20.0))
	assert_null(session.last_offline_report)


func test_gap_without_news_does_not_announce_a_report() -> void:
	var session: GameSession = _session()
	var count: Dictionary = {"n": 0}
	var listener: Callable = func(_report: OfflineReport) -> void: count["n"] += 1
	SignalBus.offline_report_ready.connect(listener)

	var report: OfflineReport = session.apply_offline(600.0)  # boş çiftlik: haber yok
	SignalBus.offline_report_ready.disconnect(listener)

	assert_not_null(report)
	assert_false(report.has_news())
	assert_eq(count["n"], 0)


# --------------------------------------------------------------------- hedefler


func test_a_fresh_game_starts_on_the_first_goal_with_nothing_done() -> void:
	var session: GameSession = _session()

	assert_eq(session.goals.current().id, &"first_harvest")
	assert_eq(session.goals.completed_count(), 0)
	assert_eq(session.goals.defs.size(), _catalog.goals.size())
	assert_true(_catalog.goals.size() >= 10, "yeterince hedef var")


func test_harvesting_three_plants_completes_the_first_goal_and_pays_its_reward() -> void:
	var session: GameSession = _session()
	var announced: Array[StringName] = []
	var listener: Callable = func(id: StringName, _reward: int) -> void: announced.append(id)
	SignalBus.goal_completed.connect(listener)
	session.plant_all(0, REED)
	_grow(session, 100.0)
	var credits: int = session.wallet.credits
	var reward: int = session.goals.current().reward

	for pot_index: int in 3:
		session.harvest_pot(0, pot_index)
	SignalBus.goal_completed.disconnect(listener)

	assert_eq(announced, [&"first_harvest"] as Array[StringName], "hedef duyuruldu")
	assert_eq(session.wallet.credits, credits + reward, "ödül yazıldı")
	assert_eq(session.goals.current().id, &"first_sale", "sıradaki hedef etkin")


func test_selling_crossbreeding_and_buying_equipment_feed_their_goals() -> void:
	var session: GameSession = _session()
	session.wallet.add_credits(2000)

	session.crossbreed(REED, VINE)
	session.buy_irrigation(0, 0)

	assert_eq(session.goals.progress_of(_goal(session, &"first_cross")), 1, "çaprazlama sayıldı")
	assert_eq(session.goals.progress_of(_goal(session, &"irrigation_online")), 1, "donanım alımı sayıldı")

	session.plant_all(0, REED)
	_grow(session, 100.0)
	for pot_index: int in 3:
		session.harvest_pot(0, pot_index)
	session.sell_everything()
	assert_true(session.goals.progress_of(_goal(session, &"first_sale")) > 0, "satış geliri sayıldı")


func test_the_goal_chain_survives_save_and_load() -> void:
	var session: GameSession = _session()
	session.goals.note(GoalDef.Kind.HARVEST, 3)
	session.goals.note(GoalDef.Kind.SELL_CREDITS, 25)
	assert_true(session.save_game())
	var loaded: GameSession = _session(9)

	assert_true(loaded.load_game())

	assert_eq(loaded.goals.completed_count(), 1)
	assert_eq(loaded.goals.current().id, &"first_sale")
	assert_eq(loaded.goals.progress_of(loaded.goals.current()), 25)


func test_reset_game_restarts_the_goal_chain() -> void:
	var session: GameSession = _session()
	session.goals.note(GoalDef.Kind.HARVEST, 3)

	session.reset_game()

	assert_eq(session.goals.completed_count(), 0)
	assert_eq(session.goals.current().id, &"first_harvest")


func _goal(session: GameSession, id: StringName) -> GoalDef:
	for def: GoalDef in session.goals.defs:
		if def.id == id:
			return def
	return null
