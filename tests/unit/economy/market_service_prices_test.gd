extends TestCase
## MarketService: fiyat = ortalama değer x eğilim x arz x olay; satış arzı düşürür, zaman toparlar; eğilim ortalamaya döner.
## Ayar (EconomyFixtures): 10 sn'de bir güncelleme, oynaklık 0, dönüş %50, arz etkisi 0.05/birim, toparlanma 0.01/sn, taban 0.4.

const EPSILON: float = 0.001
const FRUIT: StringName = GeneticsFixtures.FRUIT_A

var _ruleset: GeneticsRuleset
var _inventory: InventoryService
var _wallet: WalletService
var _market: MarketService


func before_each() -> void:
	_ruleset = GeneticsFixtures.make_ruleset()
	_inventory = EconomyFixtures.make_inventory(_ruleset)
	_wallet = WalletService.new()
	_market = EconomyFixtures.make_market()


## Envantere `quantity` birim, birim değeri `unit_value` olan düz bir ürün koyar; yığını döndürür.
func _stock(quantity: int, unit_value: float, fruit: StringName = FRUIT) -> ProduceStack:
	var gene: PlantGene = FarmFixtures.make_gene(fruit, "g-%s" % fruit)
	_inventory.add_produce(EconomyFixtures.make_result(gene, quantity, unit_value, _ruleset))
	return _inventory.stacks()[0]


func test_a_new_market_is_neutral() -> void:
	assert_almost_eq(_market.trend_of(FRUIT), 1.0, EPSILON)
	assert_almost_eq(_market.supply_of(FRUIT), 1.0, EPSILON)
	assert_almost_eq(_market.multiplier(FRUIT, []), 1.0, EPSILON)


func test_unit_price_is_the_average_value_times_the_trend() -> void:
	var stack: ProduceStack = _stock(5, 10.0)
	_market.load_dict({"trend": {"fruit_a": 1.5}})

	assert_eq(_market.unit_price(stack), 15)


func test_the_unit_price_and_the_multiplier_include_the_saturated_supply() -> void:
	var stack: ProduceStack = _stock(6, 10.0)
	_market.sell(_inventory, _wallet, stack.signature, 4)  # arz 1.0 - 0.20 = 0.80

	assert_almost_eq(_market.multiplier(FRUIT, []), 0.8, EPSILON, "çarpan = eğilim x arz x olay")
	assert_eq(_market.unit_price(_inventory.stack(stack.signature)), 8, "kalan birimler doymuş piyasada 8")


func test_a_bulk_quote_falls_unit_by_unit_as_supply_saturates() -> void:
	var stack: ProduceStack = _stock(5, 10.0)

	# 1.00 + 0.95 + 0.90 + 0.85 = 3.7 -> 37
	assert_eq(_market.quote(stack, 4), 37)
	assert_eq(_market.quote(stack, 1), 10)
	assert_eq(_market.quote(stack, 0), 0)
	assert_eq(_market.quote(stack, 99), _market.quote(stack, 5), "yığından fazlası sayılmaz")


func test_the_supply_floor_stops_the_price_from_collapsing() -> void:
	var stack: ProduceStack = _stock(20, 10.0)

	# k = 0..12 için 1 - 0.05k (toplam 9.1) + 7 birim x 0.4 (2.8) = 11.9 -> 119
	assert_eq(_market.quote(stack, 20), 119)


func test_selling_pays_the_wallet_removes_the_units_and_lowers_supply() -> void:
	var stack: ProduceStack = _stock(6, 10.0)
	var sales: Array[String] = []
	_market.sold.connect(func(signature: StringName, quantity: int, credits: int) -> void: sales.append("%s:%d:%d" % [signature, quantity, credits]))

	var credits: int = _market.sell(_inventory, _wallet, stack.signature, 4)

	assert_eq(credits, 37)
	assert_eq(_wallet.credits, 37)
	assert_eq(_inventory.stack(stack.signature).count, 2, "kalan 2 birim")
	assert_almost_eq(_market.supply_of(FRUIT), 0.8, EPSILON, "4 birim = -0.20")
	assert_eq(sales.size(), 1, "satış olayı yayınlandı")
	assert_true(sales[0].ends_with(":4:37"))


func test_selling_more_than_owned_sells_what_exists_and_unknown_stacks_sell_nothing() -> void:
	var stack: ProduceStack = _stock(3, 10.0)

	var credits: int = _market.sell(_inventory, _wallet, stack.signature, 50)

	assert_eq(credits, 29, "1.00 + 0.95 + 0.90 = 2.85 -> 28.5 -> 29")
	assert_eq(_inventory.produce_count(), 0)
	assert_eq(_market.sell(_inventory, _wallet, &"yok", 1), 0)
	assert_eq(_market.sell(_inventory, _wallet, stack.signature, 0), 0)


func test_supply_recovers_over_time_but_never_above_one() -> void:
	var stack: ProduceStack = _stock(6, 10.0)
	_market.sell(_inventory, _wallet, stack.signature, 6)  # arz 1.0 - 0.30 = 0.70

	_market.tick(10.0)
	assert_almost_eq(_market.supply_of(FRUIT), 0.80, EPSILON, "10 sn x 0.01")

	_market.tick(1000.0)
	assert_almost_eq(_market.supply_of(FRUIT), 1.0, EPSILON, "tavan")


func test_the_trend_reverts_toward_neutral_each_update() -> void:
	_market.load_dict({"trend": {"fruit_a": 2.0}})

	_market.tick(10.0)  # 2.0 + 0.5 x (1 - 2.0) = 1.5
	assert_almost_eq(_market.trend_of(FRUIT), 1.5, EPSILON)

	_market.tick(10.0)  # 1.5 + 0.5 x (1 - 1.5) = 1.25
	assert_almost_eq(_market.trend_of(FRUIT), 1.25, EPSILON)


func test_trends_stay_inside_the_configured_band_even_with_wild_volatility() -> void:
	var config: EconomyConfig = EconomyFixtures.make_config()
	config.price_volatility = 0.5
	var market: MarketService = EconomyFixtures.make_market(config, [], 7)

	for i: int in 400:
		market.tick(10.0)
		for fruit: StringName in EconomyFixtures.FRUITS:
			assert_between(market.trend_of(fruit), config.price_min, config.price_max, "eğilim bandı")


func test_the_same_seed_gives_the_same_price_history() -> void:
	var config: EconomyConfig = EconomyFixtures.make_config()
	config.price_volatility = 0.1
	var first: MarketService = EconomyFixtures.make_market(config, [], 99)
	var second: MarketService = EconomyFixtures.make_market(config, [], 99)
	var other: MarketService = EconomyFixtures.make_market(config, [], 100)

	for i: int in 30:
		first.tick(10.0)
		second.tick(10.0)
		other.tick(10.0)

	assert_almost_eq(first.trend_of(FRUIT), second.trend_of(FRUIT), 0.000001, "aynı tohum")
	assert_true(absf(first.trend_of(FRUIT) - other.trend_of(FRUIT)) > 0.000001, "farklı tohum farklı geçmiş")


func test_a_huge_tick_such_as_an_offline_return_finishes_and_stays_valid() -> void:
	_market.tick(1000000.0)

	for fruit: StringName in EconomyFixtures.FRUITS:
		assert_between(_market.trend_of(fruit), 0.5, 2.0)
		assert_almost_eq(_market.supply_of(fruit), 1.0, EPSILON)


func test_market_state_survives_a_json_round_trip() -> void:
	var stack: ProduceStack = _stock(6, 10.0)
	_market.load_dict({"trend": {"fruit_a": 1.7}})
	_market.sell(_inventory, _wallet, stack.signature, 6)
	var restored: MarketService = EconomyFixtures.make_market()

	restored.load_dict(JSON.parse_string(JSON.stringify(_market.to_dict())) as Dictionary)

	assert_almost_eq(restored.trend_of(FRUIT), 1.7, EPSILON)
	assert_almost_eq(restored.supply_of(FRUIT), 0.7, EPSILON)
