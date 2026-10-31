class_name UiIcons
extends RefCounted
## İkon kayıt defteri: `assets/art/icons/ic_<ad>.svg` (üretici: tools/art/make_icons.py). İkonlar tek renk beyazdır ve
## `modulate` ile tema renginden boyanır; yalnızca `credit` kendi renkli simgesidir. Metin içinde Unicode sembol yerine bunlar kullanılır.
##
## Uygular: design/design-language.md, "İkonografi".
##
## [codeblock]
## var texture: Texture2D = UiIcons.get_icon(&"water")
## [/codeblock]

const _DIR: String = "res://assets/art/icons/ic_%s.svg"

## Bilinen ikon adları (test bu listeyi dosyalarla karşılaştırır).
const NAMES: Array[StringName] = [
	&"farm", &"lab", &"market", &"dex", &"upgrades", &"menu", &"close", &"check", &"lock", &"chevron_left", &"chevron_right",
	&"speed", &"pause", &"day", &"night", &"clock", &"news", &"star", &"sparkle", &"trend_up", &"trend_down", &"flag", &"target",
	&"water", &"uv", &"drone", &"tower", &"seed", &"dna", &"tag", &"order", &"plant", &"sound_on", &"sound_off", &"vibration",
	&"motion", &"eye", &"text_size", &"globe", &"trash", &"info", &"credit",
]

static var _cache: Dictionary = {}


## İkon dokusu; bilinmeyen ad için `info` ikonu (görünür bir hata işareti, çökme yok).
static func get_icon(icon_name: StringName) -> Texture2D:
	var key: StringName = icon_name if NAMES.has(icon_name) else &"info"
	if not _cache.has(key):
		_cache[key] = load(_DIR % String(key)) as Texture2D
	return _cache[key] as Texture2D
