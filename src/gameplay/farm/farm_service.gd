class_name FarmService
extends RefCounted
## Çiftlik kuralları: ekim, sulama, zaman içinde büyüme, olgunlaşma, aşırı olgunluk ve hasat.
## Sahneden bağımsızdır (saf mantık): `GameSession` her karede `tick()` çağırır, arayüz yalnızca sinyalleri dinler.
## Envanter ve para bu sınıfın işi değildir: hasat bir `HarvestResult` döndürür/yayınlar, işleyen çağırandır.
##
## Uygular: design/game-brief.md, "Core loop" ve FAZ 2 (büyüme evreleri, su/ışık çarpanları, hasat).
## Formüller: `GrowthModel`. Sayılar: `FarmConfig`.
##
## [codeblock]
## var farm: FarmService = FarmService.new()
## farm.setup(config, ruleset, floors)
## farm.plant(0, 0, gene)
## farm.tick(40.0)                       # oyun saniyesi
## var result: HarvestResult = farm.harvest(0, 0)
## [/codeblock]

## Saksıya tohum dikildi.
signal planted(floor_index: int, pot_index: int)
## Bitki olgunlaştı (hasada hazır).
signal matured(floor_index: int, pot_index: int)
## Saksı sulandı (elle).
signal watered(floor_index: int, pot_index: int)
## Bitki hasat edildi.
signal harvested(result: HarvestResult)

## Büyük `tick` değerleri bu uzunlukta adımlara bölünür: formüller sabit hız varsayar, uzun adım yanılır.
const MAX_STEP_SECONDS: float = 0.5

var config: FarmConfig
var ruleset: GeneticsRuleset
var floors: Array[FloorState] = []


## Kuralları ve kat durumlarını bağlar.
func setup(farm_config: FarmConfig, genetics_ruleset: GeneticsRuleset, floor_states: Array[FloorState]) -> void:
	config = farm_config
	ruleset = genetics_ruleset
	floors = floor_states


## Katı döndürür; indeks geçersizse null.
func get_floor(floor_index: int) -> FloorState:
	if floor_index < 0 or floor_index >= floors.size():
		return null
	return floors[floor_index]


## Saksıyı döndürür; kat ya da saksı geçersizse null.
func get_pot(floor_index: int, pot_index: int) -> PotState:
	var floor_state: FloorState = get_floor(floor_index)
	if floor_state == null or pot_index < 0 or pot_index >= floor_state.pots.size():
		return null
	return floor_state.pots[pot_index]


## Boş bir saksıya tohum diker. Kat kilitliyse, saksı doluysa ya da girdi geçersizse false.
func plant(floor_index: int, pot_index: int, gene: PlantGene) -> bool:
	var floor_state: FloorState = get_floor(floor_index)
	var pot: PotState = get_pot(floor_index, pot_index)
	if floor_state == null or pot == null or gene == null or not floor_state.unlocked or not pot.is_empty():
		return false
	pot.gene = gene
	pot.phenotype = GeneticsEngine.express(gene, ruleset)
	pot.growth = 0.0
	pot.overgrowth_seconds = 0.0
	planted.emit(floor_index, pot_index)
	return true


## Saksıyı doldurur (elle sulama). Kat kilitliyse ya da saksı geçersizse false.
func water(floor_index: int, pot_index: int) -> bool:
	var floor_state: FloorState = get_floor(floor_index)
	var pot: PotState = get_pot(floor_index, pot_index)
	if floor_state == null or pot == null or not floor_state.unlocked:
		return false
	pot.water = 1.0
	watered.emit(floor_index, pot_index)
	return true


## Katta bitkisi olup suyu eksik her saksıyı doldurur; sulanan saksı sayısını döndürür.
func water_floor(floor_index: int) -> int:
	var floor_state: FloorState = get_floor(floor_index)
	if floor_state == null or not floor_state.unlocked:
		return 0
	var count: int = 0
	for pot_index: int in floor_state.pots.size():
		var pot: PotState = floor_state.pots[pot_index]
		if not pot.is_empty() and pot.water < 1.0:
			water(floor_index, pot_index)
			count += 1
	return count


## Olgun bir bitkiyi hasat eder; saksı boşalır. Olgun değilse ya da saksı boşsa null.
## `combo_step`: tek kaydırmadaki sıra (0 = ilk), değere kombo bonusu ekler. `replant`: dönen tohumu hemen aynı saksıya diker (dron).
func harvest(floor_index: int, pot_index: int, combo_step: int = 0, replant: bool = false) -> HarvestResult:
	var pot: PotState = get_pot(floor_index, pot_index)
	if pot == null or not pot.is_mature():
		return null
	var result: HarvestResult = HarvestResult.new()
	result.floor_index = floor_index
	result.pot_index = pot_index
	result.gene = pot.gene
	result.phenotype = pot.phenotype
	result.quantity = config.base_yield_units
	result.combo_step = combo_step
	result.overgrowth_factor = GrowthModel.overgrowth_factor(pot.overgrowth_seconds, config)
	result.unit_value = pot.phenotype.market_value * result.overgrowth_factor * (1.0 + GrowthModel.combo_bonus(combo_step, config))
	result.seeds_returned = config.seeds_returned_per_harvest
	pot.clear()
	if replant and result.seeds_returned > 0:
		plant(floor_index, pot_index, result.gene)
		result.seeds_returned -= 1
	harvested.emit(result)
	return result


## Katta hasada hazır saksıların indeksleri.
func mature_pot_indices(floor_index: int) -> Array[int]:
	var result: Array[int] = []
	var floor_state: FloorState = get_floor(floor_index)
	if floor_state == null or not floor_state.unlocked:
		return result
	for pot_index: int in floor_state.pots.size():
		if floor_state.pots[pot_index].is_mature():
			result.append(pot_index)
	return result


## Katta boş saksıların indeksleri.
func empty_pot_indices(floor_index: int) -> Array[int]:
	var result: Array[int] = []
	var floor_state: FloorState = get_floor(floor_index)
	if floor_state == null or not floor_state.unlocked:
		return result
	for pot_index: int in floor_state.pots.size():
		if floor_state.pots[pot_index].is_empty():
			result.append(pot_index)
	return result


## Oyunu `delta` oyun saniyesi ilerletir (uzun süreler küçük adımlara bölünür).
func tick(delta: float) -> void:
	tick_with_step(delta, MAX_STEP_SECONDS)


## `tick` ile aynıdır ama adım uzunluğunu çağıran seçer: çevrimdışı simülasyon büyük adımlarla (hızlı, kaba) ilerler.
func tick_with_step(delta: float, max_step: float) -> void:
	var limit: float = maxf(max_step, 0.01)
	var remaining: float = delta
	while remaining > 0.0:
		var step: float = minf(remaining, limit)
		_step(step)
		remaining -= step


func _step(delta: float) -> void:
	for floor_state: FloorState in floors:
		if not floor_state.unlocked:
			continue
		for pot_index: int in floor_state.pots.size():
			var pot: PotState = floor_state.pots[pot_index]
			var row: int = floor_state.row_of(pot_index)
			if floor_state.irrigation_rows[row]:
				pot.water = minf(1.0, pot.water + config.irrigation_refill_per_second * delta)
			if pot.is_empty():
				continue
			if pot.is_mature():
				pot.overgrowth_seconds += delta
				continue
			var rate: float = GrowthModel.growth_rate(pot.phenotype, pot.water, floor_state.uv_rows[row], config)
			pot.growth = minf(1.0, pot.growth + rate * delta)
			pot.water = maxf(0.0, pot.water - GrowthModel.water_drain(pot.phenotype, config) * delta)
			if pot.growth >= 1.0:
				matured.emit(floor_state.index, pot_index)
