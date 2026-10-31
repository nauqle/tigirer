extends TestCase
## HapticsService: ayarlardaki "Titreşim" anahtarı gerçekten bir şey yapar. Olaylar kısa titreşim darbelerine çevrilir; kapalıyken
## hiç titreşim istenmez; hasat darbesi komboyla uzar (tavanlı). Titreşim çağrısı enjekte edilir (masaüstünde gerçek titreşim yok).

var _service: HapticsService
var _calls: Array[int] = []


func before_each() -> void:
	_calls = []
	_service = HapticsService.new()
	_service.vibrate = func(milliseconds: int) -> void: _calls.append(milliseconds)
	add_to_tree(_service)


func test_a_harvest_pulse_grows_with_the_combo_but_is_capped() -> void:
	assert_true(HapticsService.harvest_milliseconds(0) < HapticsService.harvest_milliseconds(3), "kombo uzatır")
	assert_eq(HapticsService.harvest_milliseconds(500), HapticsService.harvest_milliseconds(HapticsService.MAX_COMBO_STEPS), "tavanlı")
	assert_true(HapticsService.harvest_milliseconds(500) <= HapticsService.REWARD_MS, "hasat ödülden uzun olmaz")


func test_events_trigger_pulses_when_enabled() -> void:
	var gene: PlantGene = PlantGene.homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry", 0.3)
	var result: HarvestResult = HarvestResult.new()
	result.gene = gene
	result.combo_step = 2

	SignalBus.plant_harvested.emit(result)
	SignalBus.item_sold.emit(&"x", 1, 10)
	SignalBus.goal_completed.emit(&"first_harvest", 40)
	SignalBus.toast_requested.emit("ERR_SEED_MISSING", [])

	assert_eq(_calls, [HapticsService.harvest_milliseconds(2), HapticsService.REWARD_MS, HapticsService.REWARD_MS, HapticsService.ERROR_MS] as Array[int])


func test_nothing_vibrates_when_the_setting_is_off() -> void:
	_service.enabled = false

	SignalBus.item_sold.emit(&"x", 1, 10)
	SignalBus.toast_requested.emit("ERR_SEED_MISSING", [])
	_service.pulse(HapticsService.REWARD_MS)

	assert_true(_calls.is_empty(), "kapalıyken titreşim yok")


func test_ordinary_toasts_do_not_vibrate_only_errors() -> void:
	SignalBus.toast_requested.emit("MSG_SAVED", [])

	assert_true(_calls.is_empty())
