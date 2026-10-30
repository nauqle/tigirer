class_name EconomyFixtures
extends RefCounted
## Ekonomi testleri için KODLA kurulan ayar, olay, şablon ve hasat sonucu üreticileri. Gerçek veriye bağlı değildir.
##
## Ayar: borsa 10 sn'de bir güncellenir, oynaklık 0 (deterministik), ortalamaya dönüş %50, arz etkisi birim başına
## 0.05, toparlanma 0.01/sn, taban 0.4; olaylar 50 sn'de bir; 2 sipariş yeri, ödül çarpanı 2.0, seviye başına 2 itibar.

const FRUITS: Array[StringName] = [GeneticsFixtures.FRUIT_A, GeneticsFixtures.FRUIT_B, GeneticsFixtures.FRUIT_R]


static func make_config() -> EconomyConfig:
	var config: EconomyConfig = EconomyConfig.new()
	config.starting_credits = 100
	config.cross_cost = 40
	config.offspring_per_cross = 2
	config.discovery_bonus_species = 60
	config.discovery_bonus_variant = 12
	config.market_update_seconds = 10.0
	config.price_volatility = 0.0
	config.price_reversion = 0.5
	config.price_min = 0.5
	config.price_max = 2.0
	config.supply_impact_per_unit = 0.05
	config.supply_recovery_per_second = 0.01
	config.supply_floor = 0.4
	config.event_interval_min_seconds = 50.0
	config.event_interval_max_seconds = 50.0
	config.max_active_events = 2
	config.news_history_size = 5
	config.order_slots = 2
	config.order_interval_seconds = 30.0
	config.order_duration_seconds = 200.0
	config.order_reward_multiplier = 2.0
	config.reputation_per_order = 1
	config.reputation_per_level = 2
	config.reputation_reward_bonus = 0.1
	return config


static func make_event(id: StringName, scope: MarketEventDef.Scope, targets: Array[StringName], multiplier: float, duration: float = 60.0, weight: float = 10.0) -> MarketEventDef:
	var event_def: MarketEventDef = MarketEventDef.new()
	event_def.id = id
	event_def.headline = "Haber %s" % id
	event_def.scope = scope
	event_def.target_ids = targets
	event_def.price_multiplier = multiplier
	event_def.duration_seconds = duration
	event_def.weight = weight
	return event_def


static func make_template(
	id: StringName,
	fruit_ids: Array[StringName],
	mutation_id: StringName = &"",
	quantity: int = 2,
	reward_multiplier: float = 1.0,
	weight: float = 10.0,
	min_level: int = 0,
	min_unit_value: float = 0.0
) -> OrderTemplateDef:
	var template: OrderTemplateDef = OrderTemplateDef.new()
	template.id = id
	template.title = "Sözleşme %s" % id
	template.customers = PackedStringArray(["Müşteri"])
	template.fruit_ids = fruit_ids
	template.mutation_id = mutation_id
	template.min_quantity = quantity
	template.max_quantity = quantity
	template.reward_multiplier = reward_multiplier
	template.weight = weight
	template.min_reputation_level = min_level
	template.min_unit_value = min_unit_value
	return template


## Hasat sonucu: gen, adet ve birim değer verilir; fenotip kural setinden hesaplanır.
static func make_result(gene: PlantGene, quantity: int, unit_value: float, ruleset: GeneticsRuleset) -> HarvestResult:
	var result: HarvestResult = HarvestResult.new()
	result.gene = gene
	result.phenotype = GeneticsEngine.express(gene, ruleset)
	result.quantity = quantity
	result.unit_value = unit_value
	return result


static func make_market(config: EconomyConfig = null, events: Array[MarketEventDef] = [], rng_seed: int = 1) -> MarketService:
	var market: MarketService = MarketService.new()
	var used_config: EconomyConfig = config if config != null else make_config()
	market.setup(used_config, events, GeneticsFixtures.make_rng(rng_seed), FRUITS)
	return market


static func make_inventory(ruleset: GeneticsRuleset = null) -> InventoryService:
	var inventory: InventoryService = InventoryService.new()
	inventory.setup(ruleset if ruleset != null else GeneticsFixtures.make_ruleset())
	return inventory
