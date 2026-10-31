class_name HapticsService
extends Node
## Dokunsal geri bildirim: SignalBus olaylarını kısa titreşim darbelerine çevirir (hasat, satış, ödül, hata). Ayarlardaki "Titreşim"
## anahtarı kapalıysa hiçbir şey titremez. "Hareketi azalt" titreşimi etkilemez (ayrı bir tercih). Masaüstünde `Input.vibrate_handheld`
## işlem yapmaz. Titreşim çağrısı enjekte edilebilir (testler).
##
## Uygular: design/design-language.md, "Geri bildirim" (dokunsal); şablon kuralı: UI tercihlerine saygı.
##
## [codeblock]
## var haptics: HapticsService = HapticsService.new()
## add_child(haptics)               # SignalBus olaylarına kendiliğinden bağlanır
## haptics.enabled = settings.vibration_on
## [/codeblock]

## Darbe süreleri (milisaniye).
const HARVEST_BASE_MS: int = 14
const HARVEST_STEP_MS: int = 4
const MAX_COMBO_STEPS: int = 6
const REWARD_MS: int = 45
const ERROR_MS: int = 70
const MUTATION_MS: int = 90

## Kapalıysa hiç titreşim istenmez.
var enabled: bool = true
## Titreşim çağrısı: `func(milliseconds: int)`. Varsayılan gerçek cihaz titreşimidir.
var vibrate: Callable = _device_vibrate


func _ready() -> void:
	SignalBus.plant_harvested.connect(_on_harvested)
	SignalBus.item_sold.connect(_on_item_sold)
	SignalBus.order_completed.connect(_on_order_completed)
	SignalBus.goal_completed.connect(_on_goal_completed)
	SignalBus.dex_discovery.connect(_on_dex_discovery)
	SignalBus.mutation_discovered.connect(_on_mutation)
	SignalBus.floor_unlocked.connect(_on_floor_unlocked)
	SignalBus.equipment_purchased.connect(_on_purchased)
	SignalBus.toast_requested.connect(_on_toast)


## Hasat darbesi: kombo adımıyla uzar, tavanlıdır.
static func harvest_milliseconds(combo_step: int) -> int:
	return HARVEST_BASE_MS + HARVEST_STEP_MS * clampi(combo_step, 0, MAX_COMBO_STEPS)


## Bir darbe ister (kapalıysa yok sayılır).
func pulse(milliseconds: int) -> void:
	if enabled:
		vibrate.call(milliseconds)


func _on_harvested(result: HarvestResult) -> void:
	pulse(harvest_milliseconds(result.combo_step))


func _on_item_sold(_signature: StringName, _quantity: int, _credits: int) -> void:
	pulse(REWARD_MS)


func _on_order_completed(_order: Order) -> void:
	pulse(REWARD_MS)


func _on_goal_completed(_goal_id: StringName, _reward: int) -> void:
	pulse(REWARD_MS)


func _on_dex_discovery(_morph_id: StringName, _new_species: bool, _bonus: int) -> void:
	pulse(REWARD_MS)


func _on_mutation(_child: PlantGene, _mutation_id: StringName) -> void:
	pulse(MUTATION_MS)


func _on_floor_unlocked(_floor_index: int) -> void:
	pulse(REWARD_MS)


func _on_purchased(_kind: EquipmentDef.Kind, _floor_index: int, _target: int, _level: int) -> void:
	pulse(REWARD_MS)


func _on_toast(message_key: String, _args: Array) -> void:
	if message_key.begins_with("ERR_"):
		pulse(ERROR_MS)


static func _device_vibrate(milliseconds: int) -> void:
	Input.vibrate_handheld(milliseconds)
