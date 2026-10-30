class_name InventoryService
extends RefCounted
## Envanter: tohum yığınları (genotip başına) ve ürün yığınları (imza başına). Saf mantık; sahneye bağlı değil.
## Her değişiklikte `changed` yayınlanır; arayüz yalnızca bunu dinleyip yeniden çizer.
##
## Uygular: design/game-brief.md, FAZ 3 "envanter yönetimi" ("meyve ve tohum envantere girer").
##
## [codeblock]
## inventory.add_seed(gene, 2)
## var gene: PlantGene = inventory.take_seed(gene.uid)   # ekim için bir tohum harca
## inventory.add_produce(harvest_result)                  # hasat ürünü yığına katılır
## [/codeblock]

## Tohum ya da ürün yığınları değişti.
signal changed

var ruleset: GeneticsRuleset

var _seeds: Dictionary = {}  # uid (String) -> SeedItem
var _produce: Dictionary = {}  # signature (StringName) -> ProduceStack


## Fenotip hesabı için kural setini bağlar.
func setup(genetics_ruleset: GeneticsRuleset) -> void:
	ruleset = genetics_ruleset


# ------------------------------------------------------------------- tohum


## Tohum ekler; aynı `uid` mevcut yığına eklenir.
func add_seed(gene: PlantGene, count: int = 1) -> void:
	if gene == null or count <= 0:
		return
	var item: SeedItem = _seeds.get(gene.uid, null) as SeedItem
	if item == null:
		_seeds[gene.uid] = SeedItem.new(gene, count)
	else:
		item.count += count
	changed.emit()


## Bir tohum harcar ve genotipini döndürür; yoksa null.
func take_seed(uid: String) -> PlantGene:
	var item: SeedItem = _seeds.get(uid, null) as SeedItem
	if item == null or item.count <= 0:
		return null
	item.count -= 1
	var gene: PlantGene = item.gene
	if item.count <= 0:
		_seeds.erase(uid)
	changed.emit()
	return gene


func seed_count(uid: String) -> int:
	var item: SeedItem = _seeds.get(uid, null) as SeedItem
	return item.count if item != null else 0


## Verilen kimlikli tohumun genotipi (harcamadan); yoksa null.
func peek_seed(uid: String) -> PlantGene:
	var item: SeedItem = _seeds.get(uid, null) as SeedItem
	return item.gene if item != null else null


## Tüm tohum yığınları: önce nesil (eski → yeni), sonra kimliğe göre; sıra kararlıdır.
func seeds() -> Array[SeedItem]:
	var result: Array[SeedItem] = []
	for item: SeedItem in _seeds.values():
		result.append(item)
	result.sort_custom(
		func(a: SeedItem, b: SeedItem) -> bool:
			if a.gene.generation != b.gene.generation:
				return a.gene.generation < b.gene.generation
			return a.gene.uid < b.gene.uid
	)
	return result


## Toplam tohum adedi.
func seed_total() -> int:
	var total: int = 0
	for item: SeedItem in _seeds.values():
		total += item.count
	return total


# -------------------------------------------------------------------- ürün


## Hasat sonucunu ürün yığınına ekler (adet ve toplam değer).
func add_produce(result: HarvestResult) -> void:
	var signature: StringName = result.phenotype.signature
	var stack: ProduceStack = _produce.get(signature, null) as ProduceStack
	if stack == null:
		stack = ProduceStack.new()
		stack.signature = signature
		stack.gene = result.gene
		stack.phenotype = result.phenotype
		_produce[signature] = stack
	stack.count += result.quantity
	stack.total_value += result.total_value()
	changed.emit()


func stack(signature: StringName) -> ProduceStack:
	return _produce.get(signature, null) as ProduceStack


## Tüm ürün yığınları: ortalama değeri yüksek olan önce.
func stacks() -> Array[ProduceStack]:
	var result: Array[ProduceStack] = []
	for item: ProduceStack in _produce.values():
		if item.count > 0:
			result.append(item)
	result.sort_custom(func(a: ProduceStack, b: ProduceStack) -> bool: return a.average_value() > b.average_value())
	return result


## Yığından en çok `quantity` birim çıkarır; çıkarılan birimlerin toplam değerini (ortalama x adet) döndürür.
func remove_produce(signature: StringName, quantity: int) -> float:
	var item: ProduceStack = _produce.get(signature, null) as ProduceStack
	if item == null or quantity <= 0:
		return 0.0
	var removed: int = mini(quantity, item.count)
	var value: float = item.average_value() * float(removed)
	item.count -= removed
	item.total_value = maxf(item.total_value - value, 0.0)
	if item.count <= 0:
		_produce.erase(signature)
	changed.emit()
	return value


func produce_count() -> int:
	var total: int = 0
	for item: ProduceStack in _produce.values():
		total += item.count
	return total


func produce_value() -> float:
	var total: float = 0.0
	for item: ProduceStack in _produce.values():
		total += item.total_value
	return total


# -------------------------------------------------------------------- kayıt


## JSON uyumlu sözlük (kayıt dosyası).
func to_dict() -> Dictionary:
	var seed_data: Array = []
	for item: SeedItem in seeds():
		seed_data.append(item.to_dict())
	var produce_data: Array = []
	for item: ProduceStack in stacks():
		produce_data.append(item.to_dict())
	return {"seeds": seed_data, "produce": produce_data}


## Kayıttan yükler (mevcut içeriğin yerine); bozuk girdiler atlanır.
func load_dict(data: Dictionary) -> void:
	_seeds.clear()
	_produce.clear()
	for entry: Variant in data.get("seeds", []) as Array:
		if entry is Dictionary:
			var item: SeedItem = SeedItem.from_dict(entry as Dictionary)
			if item != null and item.count > 0:
				_seeds[item.gene.uid] = item
	for entry: Variant in data.get("produce", []) as Array:
		if entry is Dictionary:
			var item: ProduceStack = ProduceStack.from_dict(entry as Dictionary, ruleset)
			if item != null and item.count > 0:
				_produce[item.signature] = item
	changed.emit()
