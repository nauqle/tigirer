extends TestCase
## MarketService fiyat geçmişi: pazar sekmesindeki mini grafik için her meyvenin son N "fiyat endeksi" (eğilim x olay) örneği.
## Ayar (EconomyFixtures): 10 sn'de bir eğilim güncellemesi, oynaklık 0, ortalamaya dönüş %50.

const EPSILON: float = 0.001
const FRUIT: StringName = GeneticsFixtures.FRUIT_A

var _config: EconomyConfig
var _market: MarketService


func before_each() -> void:
	_config = EconomyFixtures.make_config()
	_config.price_history_size = 4
	_market = EconomyFixtures.make_market(_config)


func test_a_new_market_starts_every_history_with_one_neutral_sample() -> void:
	var history: PackedFloat32Array = _market.history_of(FRUIT)

	assert_eq(history.size(), 1)
	assert_almost_eq(history[0], 1.0, EPSILON)


func test_each_trend_update_appends_the_current_price_index() -> void:
	_market.start_event(EconomyFixtures.make_event(&"boom", MarketEventDef.Scope.FRUIT, [FRUIT] as Array[StringName], 1.5))

	_market.tick(10.0)  # bir güncelleme: eğilim 1.0 kalır (oynaklık 0), olay x1.5 sürüyor

	var history: PackedFloat32Array = _market.history_of(FRUIT)
	assert_eq(history.size(), 3, "başlangıç + olay başlangıcı + bir güncelleme")
	assert_almost_eq(history[2], _market.trend_of(FRUIT) * 1.5, EPSILON, "endeks = eğilim x olay çarpanı")


func test_the_history_keeps_only_the_newest_samples() -> void:
	for i: int in 6:
		_market.tick(10.0)

	var history: PackedFloat32Array = _market.history_of(FRUIT)

	assert_eq(history.size(), _config.price_history_size, "en çok ayarlanan örnek sayısı")


func test_unknown_fruit_has_an_empty_history_and_the_returned_copy_is_detached() -> void:
	assert_true(_market.history_of(&"yok").is_empty())

	var copy: PackedFloat32Array = _market.history_of(FRUIT)
	copy[0] = 99.0
	assert_almost_eq(_market.history_of(FRUIT)[0], 1.0, EPSILON, "kopya orijinali bozmaz")


func test_the_history_survives_a_save_and_an_old_save_without_it_restarts_neutral() -> void:
	_market.start_event(EconomyFixtures.make_event(&"boom", MarketEventDef.Scope.FRUIT, [FRUIT] as Array[StringName], 2.0))
	_market.tick(10.0)
	_market.tick(10.0)
	var saved: Dictionary = _market.to_dict()
	var restored: MarketService = EconomyFixtures.make_market(_config)

	restored.load_dict(JSON.parse_string(JSON.stringify(saved)) as Dictionary)

	assert_eq(restored.history_of(FRUIT).size(), 4, "başlangıç + olay başlangıcı + iki güncelleme")
	assert_almost_eq(restored.history_of(FRUIT)[3], _market.history_of(FRUIT)[3], EPSILON)

	var legacy: Dictionary = saved.duplicate()
	legacy.erase("history")
	var fresh: MarketService = EconomyFixtures.make_market(_config)
	fresh.load_dict(legacy)
	assert_eq(fresh.history_of(FRUIT).size(), 1, "eski kayıtta geçmiş yok: tek örnekle başlar")


func test_a_saved_history_longer_than_the_current_limit_is_trimmed_to_the_newest_samples_on_load() -> void:
	var saved: Dictionary = _market.to_dict()
	var long_history: Array = [9.0, 8.0, 7.0, 1.1, 1.2, 1.3, 1.4]  # sınırın (4) üstünde; en yeniler sonda
	(saved["history"] as Dictionary)[String(FRUIT)] = long_history
	var restored: MarketService = EconomyFixtures.make_market(_config)

	restored.load_dict(saved)

	var history: PackedFloat32Array = restored.history_of(FRUIT)
	assert_eq(history.size(), 4, "ayarlanan sınıra kırpıldı")
	assert_almost_eq(history[0], 1.1, EPSILON, "en eski örnekler atıldı")
	assert_almost_eq(history[3], 1.4, EPSILON, "en yeni örnek korundu")


func test_an_event_starting_or_ending_records_the_new_index_immediately() -> void:
	_market.start_event(EconomyFixtures.make_event(&"boom", MarketEventDef.Scope.FRUIT, [FRUIT] as Array[StringName], 1.5, 5.0))
	assert_eq(_market.history_of(FRUIT).size(), 2, "olay başlayınca fiyat sıçraması grafikte görünür")
	assert_almost_eq(_market.history_of(FRUIT)[1], 1.5, EPSILON)

	_market.tick(6.0)  # olay 5 sn sürdü ve bitti
	var history: PackedFloat32Array = _market.history_of(FRUIT)
	assert_almost_eq(history[history.size() - 1], 1.0, EPSILON, "olay bitince endeks eğilime döner")
