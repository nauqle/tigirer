extends TestCase
## Gerçek ekonomi verisi: ayar aralıkları, olay ve sipariş şablonlarının kural setindeki kimliklere uyması,
## ve gerçek veriyle bir saatlik borsa simülasyonu.

const CONFIG_PATH: String = "res://assets/data/economy/default_economy_config.tres"
const EVENTS_DIR: String = "res://assets/data/economy/events"
const ORDERS_DIR: String = "res://assets/data/economy/orders"
const RULESET_PATH: String = "res://assets/data/genetics/default_ruleset.tres"

var _config: EconomyConfig
var _ruleset: GeneticsRuleset
var _events: Array[MarketEventDef] = []
var _templates: Array[OrderTemplateDef] = []


func before_each() -> void:
	_config = load(CONFIG_PATH) as EconomyConfig
	_ruleset = load(RULESET_PATH) as GeneticsRuleset
	_events.clear()
	_templates.clear()
	for file_name: String in DirAccess.get_files_at(EVENTS_DIR):
		if file_name.ends_with(".tres"):
			_events.append(load(EVENTS_DIR.path_join(file_name)) as MarketEventDef)
	for file_name: String in DirAccess.get_files_at(ORDERS_DIR):
		if file_name.ends_with(".tres"):
			_templates.append(load(ORDERS_DIR.path_join(file_name)) as OrderTemplateDef)


func _fruit_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for part: PlantPartDef in _ruleset.get_parts_for_layer(PlantPartDef.Layer.FRUIT):
		ids.append(part.id)
	return ids


func test_the_default_economy_config_loads_with_sane_ranges() -> void:
	assert_not_null(_config)
	assert_true(_config.price_min < 1.0 and _config.price_max > 1.0, "eğilim 1.0'ı kapsar")
	assert_true(_config.event_interval_min_seconds <= _config.event_interval_max_seconds)
	assert_true(_config.supply_floor > 0.0 and _config.supply_floor <= 1.0)
	assert_true(_config.starting_credits >= _config.cross_cost, "başlangıç parası bir çaprazlamaya yeter")
	assert_true(_config.order_slots >= 1)
	assert_true(_config.offspring_per_cross >= 1)


func test_every_event_is_well_formed_and_points_at_known_ids() -> void:
	assert_true(_events.size() >= 6, "yeterli olay çeşitliliği")
	var seen: Dictionary = {}
	var fruits: Array[StringName] = _fruit_ids()
	for event_def: MarketEventDef in _events:
		assert_not_null(event_def)
		assert_true(event_def.id != &"" and event_def.headline != "", "kimlik ve başlık dolu: %s" % event_def.id)
		assert_false(seen.has(event_def.id), "yinelenen olay kimliği: %s" % event_def.id)
		seen[event_def.id] = true
		assert_true(event_def.weight > 0.0 and event_def.duration_seconds > 0.0)
		assert_true(absf(event_def.price_multiplier - 1.0) > 0.05, "etkisiz olay yok: %s" % event_def.id)
		match event_def.scope:
			MarketEventDef.Scope.FRUIT:
				assert_false(event_def.target_ids.is_empty(), "hedefi var: %s" % event_def.id)
				for target: StringName in event_def.target_ids:
					assert_true(fruits.has(target), "%s: bilinmeyen meyve %s" % [event_def.id, target])
			MarketEventDef.Scope.MUTATION:
				assert_false(event_def.target_ids.is_empty())
				for target: StringName in event_def.target_ids:
					assert_not_null(_ruleset.get_mutation(target), "%s: bilinmeyen mutasyon %s" % [event_def.id, target])


func test_events_cover_both_booms_and_busts() -> void:
	var up: int = 0
	var down: int = 0
	for event_def: MarketEventDef in _events:
		if event_def.is_positive():
			up += 1
		else:
			down += 1

	assert_true(up >= 3 and down >= 1, "hem zam hem düşüş haberi var")


func test_every_order_template_is_well_formed_and_points_at_known_ids() -> void:
	assert_true(_templates.size() >= 6)
	var seen: Dictionary = {}
	var fruits: Array[StringName] = _fruit_ids()
	var level_zero_templates: int = 0
	for template: OrderTemplateDef in _templates:
		assert_not_null(template)
		assert_false(seen.has(template.id), "yinelenen şablon kimliği: %s" % template.id)
		seen[template.id] = true
		assert_true(template.customers.size() > 0 and template.title != "", "müşteri ve başlık: %s" % template.id)
		assert_true(template.min_quantity >= 1 and template.max_quantity >= template.min_quantity)
		assert_true(template.weight > 0.0)
		for fruit_id: StringName in template.fruit_ids:
			assert_true(fruits.has(fruit_id), "%s: bilinmeyen meyve %s" % [template.id, fruit_id])
		if template.mutation_id != &"":
			assert_not_null(_ruleset.get_mutation(template.mutation_id), "%s: bilinmeyen mutasyon" % template.id)
		if template.min_reputation_level == 0:
			level_zero_templates += 1

	assert_true(level_zero_templates >= 2, "yeni oyuncu için en az iki açık şablon")


func test_a_one_hour_simulation_with_real_data_keeps_prices_sane_and_runs_events() -> void:
	var market: MarketService = MarketService.new()
	market.setup(_config, _events, GeneticsFixtures.make_rng(2024), _fruit_ids())
	var started: Dictionary = {"n": 0}
	market.event_started.connect(func(_event_def: MarketEventDef) -> void: started["n"] += 1)

	for i: int in 3600:
		market.tick(1.0)
		if i % 60 == 0:
			for fruit_id: StringName in _fruit_ids():
				assert_between(market.trend_of(fruit_id), _config.price_min, _config.price_max)
				assert_true(market.active_events.size() <= _config.max_active_events)

	assert_true(started["n"] >= 15, "bir saatte düzenli haber akışı (%d)" % started["n"])


func test_orders_generated_from_real_data_are_always_payable_and_reachable() -> void:
	var service: OrderService = OrderService.new()
	service.setup(_config, _templates, _ruleset, GeneticsFixtures.make_rng(77))

	for level: int in 4:
		for i: int in 40:
			service.orders.clear()
			service.tick(_config.order_interval_seconds + 1.0, 0.0, level)
			var order: Order = service.orders[0]
			assert_true(order.reward > 0, "ödül pozitif: %s" % order.title)
			assert_true(order.quantity >= 1)
			assert_true(order.customer != "")
