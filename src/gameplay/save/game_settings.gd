class_name GameSettings
extends RefCounted
## Oyuncu ayarları: ses, titreşim, hareketi azalt, yazı boyutu, renk körlüğü kipi, öğretici durumu. Kayıt dosyasıyla birlikte saklanır.
## `changed` yayınlanır; arayüz ve ses servisi buna göre güncellenir.
##
## Uygular: design/game-brief.md, FAZ 5 mobil arayüz; şablon kuralı: ölçeklenebilir yazı ve renk körlüğü kipi zorunlu,
## animasyonlar hareket tercihine saygı gösterir.

## Bir ayar değişti.
signal changed

## Yazı boyutu basamakları (çarpan).
const TEXT_SCALES: Array[float] = [0.9, 1.0, 1.2, 1.4]

var sound_on: bool = true
var vibration_on: bool = true
## Salınım, parçacık ve iz efektlerini kapatır.
var reduce_motion: bool = false
## TEXT_SCALES dizinine indeks (1 = normal).
var text_scale_index: int = 1
## Renk körlüğü dostu palet (mavi-turuncu vurgu; yalnız renge dayanmayan ipuçları).
var colorblind: bool = false
## Başlangıç öğreticisi tamamlandı mı?
var tutorial_done: bool = false


func text_scale() -> float:
	return TEXT_SCALES[clampi(text_scale_index, 0, TEXT_SCALES.size() - 1)]


func set_sound(value: bool) -> void:
	sound_on = value
	changed.emit()


func set_vibration(value: bool) -> void:
	vibration_on = value
	changed.emit()


func set_reduce_motion(value: bool) -> void:
	reduce_motion = value
	changed.emit()


func set_text_scale_index(value: int) -> void:
	text_scale_index = clampi(value, 0, TEXT_SCALES.size() - 1)
	changed.emit()


func set_colorblind(value: bool) -> void:
	colorblind = value
	changed.emit()


func set_tutorial_done(value: bool) -> void:
	tutorial_done = value
	changed.emit()


## JSON uyumlu sözlük (kayıt dosyası).
func to_dict() -> Dictionary:
	return {
		"sound": sound_on,
		"vibration": vibration_on,
		"reduce_motion": reduce_motion,
		"text_scale": text_scale_index,
		"colorblind": colorblind,
		"tutorial_done": tutorial_done,
	}


func load_dict(data: Dictionary) -> void:
	sound_on = bool(data.get("sound", true))
	vibration_on = bool(data.get("vibration", true))
	reduce_motion = bool(data.get("reduce_motion", false))
	text_scale_index = clampi(int(data.get("text_scale", 1)), 0, TEXT_SCALES.size() - 1)
	colorblind = bool(data.get("colorblind", false))
	tutorial_done = bool(data.get("tutorial_done", false))
	changed.emit()
