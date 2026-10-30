extends TestCase
## Haber olayları: kapsam (hepsi/meyve/mutasyon), çarpanlar, süre, zamanlama, üst sınır, ağırlıklı seçim, haber akışı.

const EPSILON: float = 0.001
const FRUIT_A: StringName = GeneticsFixtures.FRUIT_A
const FRUIT_B: StringName = GeneticsFixtures.FRUIT_B
const NO_MUTATIONS: Array[StringName] = []


func _event(id: StringName, scope: MarketEventDef.Scope, targets: Array[StringName], multiplier: float, duration: float = 60.0, weight: float = 10.0) -> MarketEventDef:
	return EconomyFixtures.make_event(id, scope, targets, multiplier, duration, weight)


func test_scopes_decide_which_products_an_event_touches() -> void:
	var everything: MarketEventDef = _event(&"all", MarketEventDef.Scope.ALL, [], 2.0)
	var fruit_only: MarketEventDef = _event(&"fruit", MarketEventDef.Scope.FRUIT, [FRUIT_A], 2.0)
	var mutation_only: MarketEventDef = _event(&"mutation", MarketEventDef.Scope.MUTATION, [GeneticsFixtures.M_GLOW], 2.0)

	assert_true(everything.affects(FRUIT_B, NO_MUTATIONS))
	assert_true(fruit_only.affects(FRUIT_A, NO_MUTATIONS))
	assert_false(fruit_only.affects(FRUIT_B, NO_MUTATIONS))
	assert_true(mutation_only.affects(FRUIT_B, [GeneticsFixtures.M_GLOW] as Array[StringName]))
	assert_false(mutation_only.affects(FRUIT_B, [GeneticsFixtures.M_GOLD] as Array[StringName]))
	assert_false(mutation_only.affects(FRUIT_B, NO_MUTATIONS))


func test_an_active_event_multiplies_only_the_products_it_affects() -> void:
	var market: MarketService = EconomyFixtures.make_market()

	market.start_event(_event(&"craze", MarketEventDef.Scope.FRUIT, [FRUIT_A], 2.0))

	assert_almost_eq(market.event_multiplier(FRUIT_A, NO_MUTATIONS), 2.0, EPSILON)
	assert_almost_eq(market.event_multiplier(FRUIT_B, NO_MUTATIONS), 1.0, EPSILON)
	assert_almost_eq(market.multiplier(FRUIT_A, NO_MUTATIONS), 2.0, EPSILON, "toplam çarpana yansır")


func test_simultaneous_events_stack_multiplicatively() -> void:
	var market: MarketService = EconomyFixtures.make_market()

	market.start_event(_event(&"a", MarketEventDef.Scope.ALL, [], 1.5))
	market.start_event(_event(&"b", MarketEventDef.Scope.FRUIT, [FRUIT_A], 0.5))

	assert_almost_eq(market.event_multiplier(FRUIT_A, NO_MUTATIONS), 0.75, EPSILON, "1.5 x 0.5")
	assert_almost_eq(market.event_multiplier(FRUIT_B, NO_MUTATIONS), 1.5, EPSILON)


func test_an_event_ends_after_its_duration_and_announces_both_edges() -> void:
	var market: MarketService = EconomyFixtures.make_market()
	var log: Array[String] = []
	market.event_started.connect(func(event_def: MarketEventDef) -> void: log.append("+" + String(event_def.id)))
	market.event_ended.connect(func(event_def: MarketEventDef) -> void: log.append("-" + String(event_def.id)))

	market.start_event(_event(&"flash", MarketEventDef.Scope.ALL, [], 2.0, 30.0))
	market.tick(29.0)
	assert_eq(market.active_events.size(), 1, "süre dolmadı")

	market.tick(2.0)

	assert_eq(market.active_events.size(), 0)
	assert_eq(log, ["+flash", "-flash"] as Array[String])
	assert_almost_eq(market.event_multiplier(FRUIT_A, NO_MUTATIONS), 1.0, EPSILON, "etki bitti")


func test_events_start_on_their_own_schedule() -> void:
	var defs: Array[MarketEventDef] = [_event(&"only", MarketEventDef.Scope.ALL, [], 2.0, 500.0)]
	var market: MarketService = EconomyFixtures.make_market(null, defs)

	market.tick(49.0)
	assert_eq(market.active_events.size(), 0, "ilk olay 50. saniyede")

	market.tick(2.0)

	assert_eq(market.active_events.size(), 1)
	assert_eq(market.news[0], "Haber only", "haber akışına düştü")


func test_no_more_than_the_configured_number_of_events_run_at_once() -> void:
	var defs: Array[MarketEventDef] = [
		_event(&"a", MarketEventDef.Scope.ALL, [], 1.1, 5000.0),
		_event(&"b", MarketEventDef.Scope.ALL, [], 1.2, 5000.0),
		_event(&"c", MarketEventDef.Scope.ALL, [], 1.3, 5000.0),
	]
	var market: MarketService = EconomyFixtures.make_market(null, defs)

	for i: int in 10:
		market.tick(51.0)

	assert_eq(market.active_events.size(), 2, "üst sınır 2")


func test_the_same_event_is_not_started_twice_while_it_is_running() -> void:
	var defs: Array[MarketEventDef] = [_event(&"solo", MarketEventDef.Scope.ALL, [], 1.1, 5000.0)]
	var market: MarketService = EconomyFixtures.make_market(null, defs)

	for i: int in 6:
		market.tick(51.0)

	assert_eq(market.active_events.size(), 1)


func test_zero_weight_events_are_never_picked() -> void:
	var defs: Array[MarketEventDef] = [
		_event(&"never", MarketEventDef.Scope.ALL, [], 1.1, 10.0, 0.0),
		_event(&"always", MarketEventDef.Scope.ALL, [], 1.2, 10.0, 5.0),
	]
	var market: MarketService = EconomyFixtures.make_market(null, defs, 5)
	var started: Array[StringName] = []
	market.event_started.connect(func(event_def: MarketEventDef) -> void: started.append(event_def.id))

	for i: int in 40:
		market.tick(51.0)

	assert_true(started.size() > 5, "olaylar başladı")
	assert_false(started.has(&"never"), "ağırlığı 0 olan seçilmez")


func test_heavier_events_are_picked_proportionally_more_often() -> void:
	var defs: Array[MarketEventDef] = [
		_event(&"light", MarketEventDef.Scope.ALL, [], 1.1, 1.0, 1.0),
		_event(&"heavy", MarketEventDef.Scope.ALL, [], 1.2, 1.0, 9.0),
	]
	var market: MarketService = EconomyFixtures.make_market(null, defs, 21)
	var counts: Dictionary = {&"light": 0, &"heavy": 0}
	market.event_started.connect(func(event_def: MarketEventDef) -> void: counts[event_def.id] += 1)

	for i: int in 400:
		market.tick(51.0)  # her adımda önceki olay (1 sn) biter, yenisi seçilir

	assert_true(counts[&"light"] > 0, "hafif olay da seçilir")
	assert_true(counts[&"heavy"] > counts[&"light"] * 4, "ağırlık 9:1 -> ağır olay çok daha sık (%d : %d)" % [counts[&"heavy"], counts[&"light"]])


func test_the_news_history_is_capped_and_newest_first() -> void:
	var market: MarketService = EconomyFixtures.make_market()

	for i: int in 8:
		market.start_event(_event(StringName("e%d" % i), MarketEventDef.Scope.ALL, [], 1.0))

	assert_eq(market.news.size(), 5, "news_history_size = 5")
	assert_eq(market.news[0], "Haber e7", "en yeni önce")


func test_running_events_survive_a_json_round_trip() -> void:
	var defs: Array[MarketEventDef] = [_event(&"keep", MarketEventDef.Scope.FRUIT, [FRUIT_A], 2.0, 100.0)]
	var market: MarketService = EconomyFixtures.make_market(null, defs)
	market.start_event(defs[0])
	market.tick(10.0)
	var restored: MarketService = EconomyFixtures.make_market(null, defs)

	restored.load_dict(JSON.parse_string(JSON.stringify(market.to_dict())) as Dictionary)

	assert_eq(restored.active_events.size(), 1)
	assert_almost_eq(restored.active_events[0].remaining, 90.0, 0.01, "kalan süre korunur")
	assert_almost_eq(restored.event_multiplier(FRUIT_A, NO_MUTATIONS), 2.0, EPSILON)
