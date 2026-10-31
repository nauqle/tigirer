class_name GamePanel
extends Control
## Alt sekmelerin ortak tabanı: oturumu alır, arayüzü kurar, olaylarda yeniler. Panel OYUN DURUMUNU TUTMAZ ve doğrudan
## değiştirmez: oyuncu eylemleri `GameSession` komutlarıdır, güncel durum `session`'dan okunup çizilir.
##
## Uygular: şablon UI kuralı: "UI must NEVER own or directly modify game state — display only, use commands/events".

## Panel başka bir sekmeye geçilmesini ister (örn. "Geliştir'e git").
signal tab_requested(index: int)

var session: GameSession


## Oturumu verir, arayüzü kurar ve ilk kez çizer.
func setup(game_session: GameSession) -> void:
	session = game_session
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	refresh()


## Alt sınıf: düğüm ağacını kurar (bir kez).
func _build() -> void:
	pass


## Alt sınıf: gösterilen durumu yeniden çizer.
func refresh() -> void:
	pass


## Sekme görünür olunca çağrılır.
func on_shown() -> void:
	refresh()
