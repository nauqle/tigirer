class_name UiFonts
extends RefCounted
## Paketlenmiş yazı tipleri: başlık/sayı için Bricolage Grotesque, gövde için Nunito Sans (ikisi de SIL OFL; lisanslar `assets/fonts/`).
## İkisi de DEĞİŞKEN yazı tipidir: ağırlık `wght` ekseninden seçilir. Türkçe (İ ı Ğ ğ Ş ş Ç ç Ö ö Ü ü) ve İngilizce karakterlerin
## tamamı bu dosyalarda vardır; oyuncuya görünen metinde cihazın yedek fontuna bağımlı glif (◆ ▲ ★ ✓ ×) KULLANILMAZ, ikon kullanılır.
##
## Uygular: design/design-language.md, "Tipografi".
##
## [codeblock]
## label.add_theme_font_override("font", UiFonts.display(UiTokens.WEIGHT_DISPLAY))
## [/codeblock]

const DISPLAY_PATH: String = "res://assets/fonts/BricolageGrotesque-Variable.ttf"
const BODY_PATH: String = "res://assets/fonts/NunitoSans-Variable.ttf"
## OpenType `wght` ekseninin etiketi ("wght" = 0x77676874).
const AXIS_WEIGHT: int = 0x77676874

static var _cache: Dictionary = {}


## Başlık ve sayı yazı tipi (karakterli, yoğun).
static func display(weight: int = UiTokens.WEIGHT_DISPLAY) -> Font:
	return _variation(DISPLAY_PATH, weight, 0)


## Gövde yazı tipi (yumuşak, okunaklı).
static func body(weight: int = UiTokens.WEIGHT_REGULAR) -> Font:
	return _variation(BODY_PATH, weight, 0)


## Küçük büyük harf etiketler için aralıklı gövde yazı tipi.
static func overline() -> Font:
	return _variation(BODY_PATH, UiTokens.WEIGHT_BOLD, 3)


static func _variation(path: String, weight: int, glyph_spacing: int) -> Font:
	var key: String = "%s|%d|%d" % [path, weight, glyph_spacing]
	if _cache.has(key):
		return _cache[key] as Font
	var variation: FontVariation = FontVariation.new()
	variation.base_font = load(path) as Font
	variation.variation_opentype = {AXIS_WEIGHT: weight}
	variation.spacing_glyph = glyph_spacing
	_cache[key] = variation
	return variation
