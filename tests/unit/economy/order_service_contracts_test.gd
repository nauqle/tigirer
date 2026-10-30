extends TestCase
## OrderService: sipariş üretimi (yer, aralık, itibar), ödül formülü, süre dolumu, teslim kuralları ve kayıt.
## Ayar (EconomyFixtures): 2 sipariş yeri, 30 sn aralık, 200 sn süre, ödül çarpanı 2.0, seviye başına 2 itibar, seviye bonusu %10.

const EPSILON: float = 0.001
const FRUIT_A: StringName = GeneticsFixtures.FRUIT_A

var _ruleset: GeneticsRuleset
var _inventory: InventoryService
var _wallet: WalletService


func before_each() -> void:
	_ruleset = GeneticsFixtures.make_ruleset()
	_inventory = EconomyFixtures.make_inventory(_ruleset)
	_wallet = WalletService.new()


func _service(templates: Array[OrderTemplateDef], rng_seed: int = 1) -> OrderService:
	var service: OrderService = OrderService.new()
	service.setup(EconomyFixtures.make_config(), templates, _ruleset, GeneticsFixtures.make_rng(rng_seed))
	return service


func _stock(gene: PlantGene, quantity: int, unit_value: float) -> void:
	_inventory.add_produce(EconomyFixtures.make_result(gene, quantity, unit_value, _ruleset))


func _plain(fruit: StringName = FRUIT_A, uid: String = "p") -> PlantGene:
	return FarmFixtures.make_gene(fruit, uid)


# --------------------------------------------------------------------- üretim


func test_the_first_order_arrives_at_once_and_later_ones_follow_the_interval_until_slots_are_full() -> void:
	var templates: Array[OrderTemplateDef] = [EconomyFixtures.make_template(&"t1", [FRUIT_A] as Array[StringName])]
	var service: OrderService = _service(templates)

	service.tick(0.1, 0.1, 0)
	assert_eq(service.orders.size(), 1, "ilk sipariş hemen")

	service.tick(29.0, 29.1, 0)
	assert_eq(service.orders.size(), 1, "aralık dolmadı")

	service.tick(2.0, 31.1, 0)
	assert_eq(service.orders.size(), 2)

	service.tick(40.0, 71.1, 0)
	assert_eq(service.orders.size(), 2, "yer yok (2 sipariş yeri)")


func test_the_reward_is_quantity_times_reference_times_multipliers() -> void:
	var templates: Array[OrderTemplateDef] = [EconomyFixtures.make_template(&"t1", [FRUIT_A] as Array[StringName], &"", 2, 1.5)]
	var service: OrderService = _service(templates)

	service.tick(0.1, 0.0, 0)

	var order: Order = service.orders[0]
	assert_eq(order.quantity, 2)
	assert_eq(order.fruit_id, FRUIT_A)
	# 2 adet x referans 10 (FRUIT_A taban değeri) x ayar çarpanı 2.0 x şablon 1.5 = 60
	assert_eq(order.reward, 60)
	assert_almost_eq(order.expires_at, 200.0, EPSILON, "süre = oyun saati + 200")


func test_a_higher_reputation_level_raises_the_reward_by_the_configured_bonus() -> void:
	var templates: Array[OrderTemplateDef] = [EconomyFixtures.make_template(&"t1", [FRUIT_A] as Array[StringName])]
	var service: OrderService = _service(templates)

	service.tick(0.1, 0.0, 3)  # seviye 3: +%30

	assert_eq(service.orders[0].reward, 52, "2 x 10 x 2.0 x 1.3 = 52")


func test_templates_above_the_reputation_level_are_locked() -> void:
	var templates: Array[OrderTemplateDef] = [
		EconomyFixtures.make_template(&"easy", [FRUIT_A] as Array[StringName], &"", 2, 1.0, 10.0, 0),
		EconomyFixtures.make_template(&"hard", [FRUIT_A] as Array[StringName], &"", 2, 1.0, 1000.0, 2),
	]
	var service: OrderService = _service(templates)

	var seen: Array[StringName] = []
	for i: int in 12:
		service.orders.clear()
		service.tick(31.0, 0.0, 0)
		seen.append(service.orders[0].template_id)
	assert_false(seen.has(&"hard"), "seviye 0'da kilitli şablon çıkmaz")

	var unlocked: Array[StringName] = []
	for i: int in 12:
		service.orders.clear()
		service.tick(31.0, 0.0, 2)
		unlocked.append(service.orders[0].template_id)
	assert_true(unlocked.has(&"hard"), "seviye 2'de açılır (ağırlığı çok yüksek)")


func test_mutation_only_templates_accept_any_fruit() -> void:
	var templates: Array[OrderTemplateDef] = [EconomyFixtures.make_template(&"glow", [] as Array[StringName], GeneticsFixtures.M_GLOW, 1, 2.0)]
	var service: OrderService = _service(templates)

	service.tick(0.1, 0.0, 0)

	var order: Order = service.orders[0]
	assert_eq(order.fruit_id, &"", "meyve serbest")
	assert_eq(order.mutation_id, GeneticsFixtures.M_GLOW)
	# referans: üç meyvenin ortalaması (10 + 20 + 50) / 3 = 26.67; 1 x 26.67 x 2.0 x 2.0 = 106.67
	assert_eq(order.reward, 107)


func test_the_minimum_unit_value_lifts_the_reference_for_the_reward() -> void:
	var templates: Array[OrderTemplateDef] = [EconomyFixtures.make_template(&"premium", [FRUIT_A] as Array[StringName], &"", 1, 1.0, 10.0, 0, 40.0)]
	var service: OrderService = _service(templates)

	service.tick(0.1, 0.0, 0)

	assert_eq(service.orders[0].reward, 80, "referans max(10, 40) = 40; 1 x 40 x 2.0")


func test_orders_expire_and_free_their_slot() -> void:
	var templates: Array[OrderTemplateDef] = [EconomyFixtures.make_template(&"t1", [FRUIT_A] as Array[StringName])]
	var service: OrderService = _service(templates)
	var expired: Array[int] = []
	service.order_expired.connect(func(order: Order) -> void: expired.append(order.id))
	service.tick(0.1, 0.0, 0)

	service.tick(1.0, 199.0, 0)
	assert_eq(service.orders.size(), 1, "süre dolmadı")
	service.tick(1.0, 200.0, 0)

	assert_eq(expired, [1] as Array[int], "sipariş 1 süresi doldu")
	assert_false(service.orders.any(func(order: Order) -> bool: return order.id == 1), "kalktı")


# ---------------------------------------------------------------------- teslim


func test_fulfilling_consumes_the_goods_and_pays_credits_and_reputation() -> void:
	var templates: Array[OrderTemplateDef] = [EconomyFixtures.make_template(&"t1", [FRUIT_A] as Array[StringName])]
	var service: OrderService = _service(templates)
	service.tick(0.1, 0.0, 0)
	_stock(_plain(), 3, 10.0)
	var completed: Array[int] = []
	service.order_completed.connect(func(order: Order) -> void: completed.append(order.id))
	var order: Order = service.orders[0]

	assert_true(service.can_fulfil(order, _inventory))
	var ok: bool = service.fulfil(order.id, _inventory, _wallet)

	assert_true(ok)
	assert_eq(_wallet.credits, 40, "2 x 10 x 2.0")
	assert_eq(_wallet.reputation, 1)
	assert_eq(_inventory.produce_count(), 1, "3 - 2 birim")
	assert_eq(completed, [order.id] as Array[int])
	assert_null(service.get_order(order.id), "sipariş kapandı")


func test_too_few_units_leave_everything_untouched() -> void:
	var templates: Array[OrderTemplateDef] = [EconomyFixtures.make_template(&"t1", [FRUIT_A] as Array[StringName])]
	var service: OrderService = _service(templates)
	service.tick(0.1, 0.0, 0)
	_stock(_plain(), 1, 10.0)
	var order: Order = service.orders[0]

	assert_false(service.can_fulfil(order, _inventory))
	assert_false(service.fulfil(order.id, _inventory, _wallet))

	assert_eq(_inventory.produce_count(), 1)
	assert_eq(_wallet.credits, 0)
	assert_not_null(service.get_order(order.id), "sipariş açık kalır")
	assert_false(service.fulfil(999, _inventory, _wallet), "olmayan sipariş")


func test_goods_below_the_minimum_unit_value_do_not_count() -> void:
	var templates: Array[OrderTemplateDef] = [EconomyFixtures.make_template(&"premium", [FRUIT_A] as Array[StringName], &"", 2, 1.0, 10.0, 0, 24.0)]
	var service: OrderService = _service(templates)
	service.tick(0.1, 0.0, 0)
	_stock(_plain(), 5, 10.0)
	var order: Order = service.orders[0]

	assert_false(service.can_fulfil(order, _inventory), "ortalama 10 < 24")

	_stock(_plain(FRUIT_A, "rich-gene"), 2, 30.0)
	assert_false(service.can_fulfil(order, _inventory), "farklı imza gerekir: aynı gen aynı yığın, ortalama düşük")


func test_the_cheapest_qualifying_stack_is_consumed_first() -> void:
	var templates: Array[OrderTemplateDef] = [EconomyFixtures.make_template(&"t1", [FRUIT_A] as Array[StringName])]
	var service: OrderService = _service(templates)
	service.tick(0.1, 0.0, 0)
	var cheap: PlantGene = _plain(FRUIT_A, "cheap")
	var rich: PlantGene = _plain(FRUIT_A, "rich")
	rich.mutations = [GeneticsFixtures.M_FAST]  # farklı imza: ayrı yığın
	_stock(cheap, 1, 10.0)
	_stock(rich, 3, 30.0)
	var order: Order = service.orders[0]

	service.fulfil(order.id, _inventory, _wallet)

	var remaining_values: Array[float] = []
	for stack: ProduceStack in _inventory.stacks():
		remaining_values.append(stack.average_value())
	assert_eq(_inventory.produce_count(), 2, "4 - 2")
	assert_eq(remaining_values, [30.0] as Array[float], "ucuz yığın tükendi, değerli yığından 1 birim alındı")


func test_a_mutation_order_only_accepts_goods_that_carry_the_mutation() -> void:
	var templates: Array[OrderTemplateDef] = [EconomyFixtures.make_template(&"glow", [] as Array[StringName], GeneticsFixtures.M_GLOW, 1)]
	var service: OrderService = _service(templates)
	service.tick(0.1, 0.0, 0)
	var order: Order = service.orders[0]
	_stock(_plain(FRUIT_A, "plain"), 5, 10.0)
	assert_false(service.can_fulfil(order, _inventory), "düz ürün uymaz")

	var glowing: PlantGene = _plain(GeneticsFixtures.FRUIT_B, "glow")
	glowing.mutations = [GeneticsFixtures.M_GLOW]
	_stock(glowing, 1, 25.0)

	assert_true(service.can_fulfil(order, _inventory), "mutasyonlu ürün uyar (meyve fark etmez)")


func test_reputation_level_follows_the_points() -> void:
	var service: OrderService = _service([] as Array[OrderTemplateDef])

	assert_eq(service.reputation_level(0), 0)
	assert_eq(service.reputation_level(1), 0)
	assert_eq(service.reputation_level(2), 1)
	assert_eq(service.reputation_level(5), 2)


func test_open_orders_survive_a_json_round_trip() -> void:
	var templates: Array[OrderTemplateDef] = [EconomyFixtures.make_template(&"t1", [FRUIT_A] as Array[StringName])]
	var service: OrderService = _service(templates)
	service.tick(0.1, 0.0, 0)
	service.tick(31.0, 31.0, 0)
	var restored: OrderService = _service(templates)

	restored.load_dict(JSON.parse_string(JSON.stringify(service.to_dict())) as Dictionary)

	assert_eq(restored.orders.size(), 2)
	assert_eq(restored.orders[1].id, service.orders[1].id)
	assert_eq(restored.orders[0].reward, service.orders[0].reward)
	restored.tick(31.0, 62.0, 0)
	assert_true(restored.orders.size() <= 2)
