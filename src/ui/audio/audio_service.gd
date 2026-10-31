class_name AudioService
extends Node
## Ses olayı servisi: SignalBus olaylarını dinleyip ilgili efekti çalar. Arayüz ve oyun sesi doğrudan çalmaz;
## "bir şey oldu" der (sinyal), burası "hangi ses" kararını verir (şablon kuralı: UI sesi ses olayı sistemiyle).
## Eşzamanlı sesler için küçük bir oynatıcı havuzu kullanır (hızlı kaydırmada üst üste biner).
##
## Uygular: design/game-brief.md, FAZ 2 "ASMR hasat sesleri".
##
## [codeblock]
## var audio: AudioService = AudioService.new()
## add_child(audio)               # SignalBus olaylarına kendiliğinden bağlanır
## audio.enabled = settings.sound_on
## [/codeblock]

const POOL_SIZE: int = 8
## Kombo başına perde artışı ve en çok kaç adım sayılacağı.
const _COMBO_PITCH_STEP: float = 0.06
const _COMBO_PITCH_MAX_STEPS: int = 12

## Kapalıysa hiçbir ses çalmaz.
var enabled: bool = true
## Ana ses düzeyi (dB).
var volume_db: float = -4.0

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _next_player: int = 0


func _ready() -> void:
	for i: int in POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	for id: SfxBank.Id in SfxBank.Id.values():
		_streams[id] = SfxBank.make(id)
	SignalBus.plant_harvested.connect(_on_plant_harvested)
	SignalBus.plant_planted.connect(_on_plant_planted)
	SignalBus.pot_watered.connect(_on_pot_watered)
	SignalBus.plant_matured.connect(_on_plant_matured)
	SignalBus.mutation_discovered.connect(_on_mutation_discovered)
	SignalBus.ui_tapped.connect(_on_ui_tapped)
	SignalBus.item_sold.connect(_on_item_sold)
	SignalBus.order_completed.connect(_on_order_completed)
	SignalBus.equipment_purchased.connect(_on_equipment_purchased)
	SignalBus.floor_unlocked.connect(_on_floor_unlocked)
	SignalBus.dex_discovery.connect(_on_dex_discovery)
	SignalBus.toast_requested.connect(_on_toast_requested)
	SignalBus.goal_completed.connect(_on_goal_completed)


## Bir efekti çalar. `pitch`: 1.0 = özgün perde.
func play(id: SfxBank.Id, pitch: float = 1.0) -> void:
	if not enabled or _players.is_empty():
		return
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = _streams[id] as AudioStreamWAV
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


func _on_plant_harvested(result: HarvestResult) -> void:
	play(SfxBank.Id.SNIP, 1.0 + _COMBO_PITCH_STEP * float(mini(result.combo_step, _COMBO_PITCH_MAX_STEPS)))


func _on_plant_planted(_floor_index: int, _pot_index: int) -> void:
	play(SfxBank.Id.PLANT)


func _on_pot_watered(_floor_index: int, _pot_index: int) -> void:
	play(SfxBank.Id.WATER)


func _on_plant_matured(_floor_index: int, _pot_index: int) -> void:
	play(SfxBank.Id.MATURE)


func _on_mutation_discovered(_child: PlantGene, _mutation_id: StringName) -> void:
	play(SfxBank.Id.MUTATION)


func _on_ui_tapped() -> void:
	play(SfxBank.Id.TAP)


func _on_item_sold(_signature: StringName, _quantity: int, _credits: int) -> void:
	play(SfxBank.Id.COIN)


func _on_order_completed(_order: Order) -> void:
	play(SfxBank.Id.ORDER)


func _on_equipment_purchased(_kind: EquipmentDef.Kind, _floor_index: int, _target: int, _level: int) -> void:
	play(SfxBank.Id.UPGRADE)


func _on_floor_unlocked(_floor_index: int) -> void:
	play(SfxBank.Id.UPGRADE)


func _on_dex_discovery(_morph_id: StringName, new_species: bool, _bonus: int) -> void:
	play(SfxBank.Id.MUTATION if new_species else SfxBank.Id.MATURE)


func _on_goal_completed(_goal_id: StringName, _reward: int) -> void:
	play(SfxBank.Id.ORDER)


## Hata bildirimleri alçak "olmaz" sesi çıkarır.
func _on_toast_requested(message_key: String, _args: Array) -> void:
	if message_key.begins_with("ERR_"):
		play(SfxBank.Id.ERROR)
