class_name MarketService
extends RefCounted
## Dinamik borsa: meyve türü başına fiyat EĞİLİMİ (rastgele yürüyüş + ortalamaya dönüş), satışla düşen ARZ çarpanı
## ve haber bülteni OLAYLARI. Fiyat = ortalama birim değer x eğilim x arz x olay çarpanları.
## Saf mantık: rastgelelik (RandomNumberGenerator) dışarıdan verilir, testler deterministiktir.
##
## Uygular: design/game-brief.md, FAZ 3 "arz-talep dalgalanmaları, haber bülteni etkinlikleri".
## Formüller: docs/architecture/floralab-architecture.md, "Ekonomi kuralları".
##
## [codeblock]
## market.setup(economy_config, event_defs, rng, fruit_ids)
## market.tick(delta)                                   # her karede (oyun saniyesi)
## var credits: int = market.sell(inventory, wallet, stack.signature, 5)
## [/codeblock]

## Fiyat eğilimleri ya da çarpanlar değişti (arayüz fiyat listesini yeniler).
signal prices_changed
## Bir haber olayı başladı.
signal event_started(event_def: MarketEventDef)
## Bir haber olayı bitti.
signal event_ended(event_def: MarketEventDef)
## Satış yapıldı: yığın imzası, adet, kazanılan kredi.
signal sold(signature: StringName, quantity: int, credits: int)


## Süren bir olay ve kalan süresi.
class ActiveEvent:
	extends RefCounted
	var def: MarketEventDef
	var remaining: float = 0.0

	func _init(event_def: MarketEventDef = null, seconds: float = 0.0) -> void:
		def = event_def
		remaining = seconds


## Çok büyük `tick` değerlerinde (uzun çevrimdışı) eğilim güncellemesi bu sayıda adımla sınırlanır.
const _MAX_TREND_STEPS_PER_TICK: int = 50

var config: EconomyConfig
var event_defs: Array[MarketEventDef] = []
var active_events: Array[ActiveEvent] = []
## Haber başlıkları, en yeni önce.
var news: Array[String] = []

var _rng: RandomNumberGenerator
var _trend: Dictionary = {}  # fruit_id (StringName) -> float
var _supply: Dictionary = {}  # fruit_id (StringName) -> float
var _update_timer: float = 0.0
var _next_event_in: float = 0.0


## Ayarları, olay tanımlarını, rastgele üreticiyi ve borsada işlem gören meyve kimliklerini bağlar.
func setup(economy_config: EconomyConfig, events: Array[MarketEventDef], rng: RandomNumberGenerator, fruit_ids: Array[StringName]) -> void:
	config = economy_config
	event_defs = events
	_rng = rng
	_trend.clear()
	_supply.clear()
	for fruit_id: StringName in fruit_ids:
		_trend[fruit_id] = 1.0
		_supply[fruit_id] = 1.0
	active_events.clear()
	news.clear()
	_update_timer = config.market_update_seconds
	_next_event_in = _rng.randf_range(config.event_interval_min_seconds, config.event_interval_max_seconds)


# ------------------------------------------------------------------- fiyatlar


## Meyve türünün talep eğilimi (1.0 = nötr).
func trend_of(fruit_id: StringName) -> float:
	return float(_trend.get(fruit_id, 1.0))


## Meyve türünün arz çarpanı (1.0 = doymamış, düşük = piyasa doymuş).
func supply_of(fruit_id: StringName) -> float:
	return float(_supply.get(fruit_id, 1.0))


## Süren olayların bu ürüne uygulanan birleşik çarpanı.
func event_multiplier(fruit_id: StringName, mutations: Array[StringName]) -> float:
	var factor: float = 1.0
	for active: ActiveEvent in active_events:
		if active.def.affects(fruit_id, mutations):
			factor *= active.def.price_multiplier
	return factor


## Bu ürün için toplam fiyat çarpanı: eğilim x arz x olaylar.
func multiplier(fruit_id: StringName, mutations: Array[StringName]) -> float:
	return trend_of(fruit_id) * supply_of(fruit_id) * event_multiplier(fruit_id, mutations)


## Yığının BİR biriminin şu anki satış fiyatı (kredi).
func unit_price(stack: ProduceStack) -> int:
	return int(round(stack.average_value() * multiplier(stack.fruit_id(), stack.phenotype.mutations)))


## `quantity` birimin toplam satış bedeli: her ek birim arzı düşürdüğü için fiyat birimden birime iner (taban: `supply_floor`).
func quote(stack: ProduceStack, quantity: int) -> int:
	var units: int = clampi(quantity, 0, stack.count)
	if units == 0:
		return 0
	var fruit_id: StringName = stack.fruit_id()
	var base: float = stack.average_value() * trend_of(fruit_id) * event_multiplier(fruit_id, stack.phenotype.mutations)
	var supply: float = supply_of(fruit_id)
	var total: float = 0.0
	for k: int in units:
		total += base * maxf(supply - float(k) * config.supply_impact_per_unit, config.supply_floor)
	return int(round(total))


## Yığından `quantity` birim satar: envanterden düşer, para cüzdana girer, arz çarpanı düşer. Kazanılan krediyi döndürür.
func sell(inventory: InventoryService, wallet: WalletService, signature: StringName, quantity: int) -> int:
	var stack: ProduceStack = inventory.stack(signature)
	if stack == null or quantity <= 0:
		return 0
	var units: int = mini(quantity, stack.count)
	var fruit_id: StringName = stack.fruit_id()
	var credits: int = quote(stack, units)
	inventory.remove_produce(signature, units)
	wallet.add_credits(credits)
	_supply[fruit_id] = maxf(config.supply_floor, supply_of(fruit_id) - config.supply_impact_per_unit * float(units))
	sold.emit(signature, units, credits)
	prices_changed.emit()
	return credits


# ----------------------------------------------------------------------- zaman


## Borsayı `delta` oyun saniyesi ilerletir: arz toparlanır, eğilimler güncellenir, olaylar başlar/biter.
func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	var recovery: float = config.supply_recovery_per_second * delta
	for fruit_id: StringName in _supply.keys():
		_supply[fruit_id] = minf(1.0, float(_supply[fruit_id]) + recovery)

	_update_timer -= delta
	var steps: int = 0
	while _update_timer <= 0.0 and steps < _MAX_TREND_STEPS_PER_TICK:
		_update_timer += config.market_update_seconds
		_update_trends()
		steps += 1
	if _update_timer <= 0.0:
		_update_timer = config.market_update_seconds

	_expire_events(delta)
	_next_event_in -= delta
	if _next_event_in <= 0.0:
		_try_start_event()
		_next_event_in = _rng.randf_range(config.event_interval_min_seconds, config.event_interval_max_seconds)


func _update_trends() -> void:
	for fruit_id: StringName in _trend.keys():
		var trend: float = float(_trend[fruit_id])
		trend += config.price_reversion * (1.0 - trend) + config.price_volatility * _rng.randfn(0.0, 1.0)
		_trend[fruit_id] = clampf(trend, config.price_min, config.price_max)
	prices_changed.emit()


func _expire_events(delta: float) -> void:
	var finished: Array[ActiveEvent] = []
	for active: ActiveEvent in active_events:
		active.remaining -= delta
		if active.remaining <= 0.0:
			finished.append(active)
	for active: ActiveEvent in finished:
		active_events.erase(active)
		event_ended.emit(active.def)
	if not finished.is_empty():
		prices_changed.emit()


## Süren olaylar dışında kalanlar arasından ağırlıklı seçimle yeni bir olay başlatır.
func _try_start_event() -> void:
	if active_events.size() >= config.max_active_events:
		return
	var candidates: Array[MarketEventDef] = []
	for event_def: MarketEventDef in event_defs:
		if not _is_active(event_def):
			candidates.append(event_def)
	if candidates.is_empty():
		return
	var total: float = 0.0
	for candidate: MarketEventDef in candidates:
		total += maxf(candidate.weight, 0.0)
	var picked: MarketEventDef = candidates[candidates.size() - 1]
	if total > 0.0:
		var target: float = _rng.randf() * total
		var running: float = 0.0
		for candidate: MarketEventDef in candidates:
			running += maxf(candidate.weight, 0.0)
			if target < running:
				picked = candidate
				break
	start_event(picked)


## Bir olayı hemen başlatır (haber akışı, test ve geliştirici aracı için de kullanılır).
func start_event(event_def: MarketEventDef) -> void:
	active_events.append(ActiveEvent.new(event_def, event_def.duration_seconds))
	news.push_front(event_def.headline)
	while news.size() > config.news_history_size:
		news.pop_back()
	event_started.emit(event_def)
	prices_changed.emit()


func _is_active(event_def: MarketEventDef) -> bool:
	for active: ActiveEvent in active_events:
		if active.def == event_def:
			return true
	return false


# ------------------------------------------------------------------------ kayıt


## JSON uyumlu sözlük (kayıt dosyası).
func to_dict() -> Dictionary:
	var trends: Dictionary = {}
	for fruit_id: StringName in _trend.keys():
		trends[String(fruit_id)] = _trend[fruit_id]
	var supplies: Dictionary = {}
	for fruit_id: StringName in _supply.keys():
		supplies[String(fruit_id)] = _supply[fruit_id]
	var events: Array = []
	for active: ActiveEvent in active_events:
		events.append({"id": String(active.def.id), "remaining": active.remaining})
	return {
		"trend": trends,
		"supply": supplies,
		"events": events,
		"next_event_in": _next_event_in,
		"update_timer": _update_timer,
		"news": news.duplicate(),
	}


## Kayıttan yükler. Bilinmeyen meyve/olay kimlikleri atlanır.
func load_dict(data: Dictionary) -> void:
	var trends: Dictionary = data.get("trend", {}) as Dictionary
	for key: Variant in trends.keys():
		var fruit_id: StringName = StringName(String(key))
		if _trend.has(fruit_id):
			_trend[fruit_id] = clampf(float(trends[key]), config.price_min, config.price_max)
	var supplies: Dictionary = data.get("supply", {}) as Dictionary
	for key: Variant in supplies.keys():
		var fruit_id: StringName = StringName(String(key))
		if _supply.has(fruit_id):
			_supply[fruit_id] = clampf(float(supplies[key]), config.supply_floor, 1.0)
	active_events.clear()
	for entry: Variant in data.get("events", []) as Array:
		if entry is Dictionary:
			var event_def: MarketEventDef = _find_event(StringName(String((entry as Dictionary).get("id", ""))))
			if event_def != null:
				active_events.append(ActiveEvent.new(event_def, float((entry as Dictionary).get("remaining", 0.0))))
	_next_event_in = maxf(float(data.get("next_event_in", _next_event_in)), 1.0)
	_update_timer = maxf(float(data.get("update_timer", _update_timer)), 0.1)
	news.clear()
	for headline: Variant in data.get("news", []) as Array:
		news.append(String(headline))
	prices_changed.emit()


func _find_event(id: StringName) -> MarketEventDef:
	for event_def: MarketEventDef in event_defs:
		if event_def.id == id:
			return event_def
	return null
