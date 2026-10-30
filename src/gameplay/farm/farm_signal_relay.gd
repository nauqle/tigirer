class_name FarmSignalRelay
extends RefCounted
## `FarmService` sinyallerini SignalBus'a iletir. Çiftlik mantığı SignalBus'a bağımlı kalmaz (testler Autoload'suz
## çalışır); bağlantıyı oyunu kuran taraf (GameSession ya da geliştirme sahnesi) bu sınıfla yapar.
## `enabled` kapatılınca olaylar iletilmez: çevrimdışı simülasyon yüzlerce hasat/olgunlaşma üretir, ses ve efekt boğulmasın.
##
## Uygular: design/game-brief.md, "Modülerlik ve sinyaller" (çiftlik olayları SignalBus üzerinden duyurulur).
##
## [codeblock]
## var relay: FarmSignalRelay = FarmSignalRelay.new()
## relay.connect_to(farm_service)   # artık SignalBus.plant_harvested vb. yayınlanır
## relay.enabled = false            # sessiz mod (çevrimdışı hesap)
## [/codeblock]

## Kapalıyken hiçbir olay iletilmez.
var enabled: bool = true


## Servisin dört olayını SignalBus'a bağlar.
func connect_to(farm: FarmService) -> void:
	farm.planted.connect(_on_planted)
	farm.matured.connect(_on_matured)
	farm.watered.connect(_on_watered)
	farm.harvested.connect(_on_harvested)


func _on_planted(floor_index: int, pot_index: int) -> void:
	if enabled:
		SignalBus.plant_planted.emit(floor_index, pot_index)


func _on_matured(floor_index: int, pot_index: int) -> void:
	if enabled:
		SignalBus.plant_matured.emit(floor_index, pot_index)


func _on_watered(floor_index: int, pot_index: int) -> void:
	if enabled:
		SignalBus.pot_watered.emit(floor_index, pot_index)


func _on_harvested(result: HarvestResult) -> void:
	if enabled:
		SignalBus.plant_harvested.emit(result)
