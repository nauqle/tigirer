class_name OrderService
extends RefCounted
## VIP müşteri sözleşmeleri: şablonlardan rastgele sipariş üretir, süresi dolanları kaldırır, teslimi envanterden karşılar.
## Ödül, piyasa fiyatının üstünde bir primdir ve itibar seviyesiyle artar; itibar yüksek şablonları açar.
## Saf mantık: rastgelelik dışarıdan verilir.
##
## Uygular: design/game-brief.md, FAZ 3 "VIP müşteri kontratları".
## Formüller: docs/architecture/floralab-architecture.md, "Ekonomi kuralları".
##
## [codeblock]
## orders.setup(economy_config, templates, ruleset, rng)
## orders.tick(delta, time.game_seconds, orders.reputation_level(wallet.reputation))
## if orders.can_fulfil(order, inventory):
##     orders.fulfil(order.id, inventory, wallet)
## [/codeblock]

## Yeni sipariş açıldı.
signal order_added(order: Order)
## Sipariş teslim edildi.
signal order_completed(order: Order)
## Sipariş süresi dolup kaldırıldı.
signal order_expired(order: Order)

var config: EconomyConfig
var templates: Array[OrderTemplateDef] = []
var orders: Array[Order] = []

var _ruleset: GeneticsRuleset
var _rng: RandomNumberGenerator
var _next_id: int = 1
var _timer: float = 0.0


## Ayarları, şablonları, kural setini ve rastgele üreticiyi bağlar. İlk sipariş hemen gelir.
func setup(economy_config: EconomyConfig, order_templates: Array[OrderTemplateDef], genetics_ruleset: GeneticsRuleset, rng: RandomNumberGenerator) -> void:
	config = economy_config
	templates = order_templates
	_ruleset = genetics_ruleset
	_rng = rng
	orders.clear()
	_timer = 0.0


## İtibar puanından itibar seviyesi.
func reputation_level(reputation: int) -> int:
	return reputation / maxi(config.reputation_per_level, 1)


## Zamanı ilerletir: süresi dolanlar kalkar, boş yer varsa ve sayaç dolduysa yeni sipariş gelir.
## `game_seconds`: oyun saati (son teslim zamanı karşılaştırması), `level`: itibar seviyesi.
func tick(delta: float, game_seconds: float, level: int) -> void:
	var expired: Array[Order] = []
	for order: Order in orders:
		if game_seconds >= order.expires_at:
			expired.append(order)
	for order: Order in expired:
		orders.erase(order)
		order_expired.emit(order)
	_timer -= delta
	if _timer <= 0.0 and orders.size() < config.order_slots:
		var created: Order = _generate(game_seconds, level)
		if created != null:
			orders.append(created)
			order_added.emit(created)
		_timer = config.order_interval_seconds
	elif _timer <= 0.0:
		_timer = config.order_interval_seconds


func get_order(order_id: int) -> Order:
	for order: Order in orders:
		if order.id == order_id:
			return order
	return null


## Envanter bu siparişi karşılıyor mu?
func can_fulfil(order: Order, inventory: InventoryService) -> bool:
	return _eligible_count(order, inventory) >= order.quantity


## Envanterdeki uygun ürünlerden (önce en düşük değerliler) siparişi karşılar; ödül ve itibar verir.
## Sipariş yoksa ya da ürün yetmiyorsa hiçbir şey değişmez ve false döner.
func fulfil(order_id: int, inventory: InventoryService, wallet: WalletService) -> bool:
	var order: Order = get_order(order_id)
	if order == null or not can_fulfil(order, inventory):
		return false
	var remaining: int = order.quantity
	for stack: ProduceStack in _matching_stacks(order, inventory):
		if remaining <= 0:
			break
		var take: int = mini(remaining, stack.count)
		inventory.remove_produce(stack.signature, take)
		remaining -= take
	wallet.add_credits(order.reward)
	wallet.add_reputation(order.reputation_reward)
	orders.erase(order)
	order_completed.emit(order)
	return true


## Siparişe uyan ürün yığınları, ortalama değeri düşük olan önce (değerli ürün gereksiz harcanmasın).
func _matching_stacks(order: Order, inventory: InventoryService) -> Array[ProduceStack]:
	var result: Array[ProduceStack] = []
	for stack: ProduceStack in inventory.stacks():
		if order.fruit_id != &"" and stack.fruit_id() != order.fruit_id:
			continue
		if order.mutation_id != &"" and not stack.phenotype.mutations.has(order.mutation_id):
			continue
		if stack.average_value() < order.min_unit_value:
			continue
		result.append(stack)
	result.sort_custom(func(a: ProduceStack, b: ProduceStack) -> bool: return a.average_value() < b.average_value())
	return result


func _eligible_count(order: Order, inventory: InventoryService) -> int:
	var total: int = 0
	for stack: ProduceStack in _matching_stacks(order, inventory):
		total += stack.count
	return total


# ------------------------------------------------------------------- üretim


func _generate(game_seconds: float, level: int) -> Order:
	var candidates: Array[OrderTemplateDef] = []
	var total: float = 0.0
	for template: OrderTemplateDef in templates:
		if template.min_reputation_level <= level and template.weight > 0.0:
			candidates.append(template)
			total += template.weight
	if candidates.is_empty():
		return null
	var target: float = _rng.randf() * total
	var running: float = 0.0
	var picked: OrderTemplateDef = candidates[candidates.size() - 1]
	for candidate: OrderTemplateDef in candidates:
		running += candidate.weight
		if target < running:
			picked = candidate
			break

	var order: Order = Order.new()
	order.id = _next_id
	_next_id += 1
	order.template_id = picked.id
	order.title = picked.title
	if picked.customers.size() > 0:
		order.customer = picked.customers[_rng.randi() % picked.customers.size()]
	if picked.fruit_ids.size() > 0:
		order.fruit_id = picked.fruit_ids[_rng.randi() % picked.fruit_ids.size()]
	order.mutation_id = picked.mutation_id
	order.min_unit_value = picked.min_unit_value
	order.quantity = _rng.randi_range(picked.min_quantity, maxi(picked.min_quantity, picked.max_quantity))
	var reference: float = _reference_value(order.fruit_id, picked.min_unit_value)
	var bonus: float = 1.0 + float(level) * config.reputation_reward_bonus
	order.reward = int(round(float(order.quantity) * reference * config.order_reward_multiplier * picked.reward_multiplier * bonus))
	order.reputation_reward = config.reputation_per_order
	order.expires_at = game_seconds + config.order_duration_seconds
	return order


## Ödül hesabının referans birim değeri: meyvenin taban değeri (ya da herhangi bir meyve için ortalaması) ve koşuldaki asgari değerin büyüğü.
func _reference_value(fruit_id: StringName, min_unit_value: float) -> float:
	var base: float = 0.0
	if fruit_id != &"":
		var part: PlantPartDef = _ruleset.get_part(fruit_id)
		base = part.base_value if part != null else 0.0
	else:
		var fruit_parts: Array[PlantPartDef] = _ruleset.get_parts_for_layer(PlantPartDef.Layer.FRUIT)
		for part: PlantPartDef in fruit_parts:
			base += part.base_value
		base = base / float(maxi(fruit_parts.size(), 1))
	return maxf(base, min_unit_value)


# ------------------------------------------------------------------------ kayıt


## JSON uyumlu sözlük (kayıt dosyası).
func to_dict() -> Dictionary:
	var order_data: Array = []
	for order: Order in orders:
		order_data.append(order.to_dict())
	return {"orders": order_data, "next_id": _next_id, "timer": _timer}


## Kayıttan yükler (mevcut siparişlerin yerine).
func load_dict(data: Dictionary) -> void:
	orders.clear()
	for entry: Variant in data.get("orders", []) as Array:
		if entry is Dictionary:
			orders.append(Order.from_dict(entry as Dictionary))
	_next_id = maxi(int(data.get("next_id", 1)), 1)
	for order: Order in orders:
		_next_id = maxi(_next_id, order.id + 1)
	_timer = float(data.get("timer", 0.0))
