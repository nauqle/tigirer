class_name UiTokens
extends RefCounted
## FloraLab tasarım belirteçleri (design tokens): renk, boşluk, yarıçap, yazı boyutu ve hareket süreleri TEK yerde.
## Hiçbir panel renk, piksel ya da süre sabitlemez; buradan okur. Tasarım dili belgesi: design/design-language.md.
##
## Dil: "Gece Serası": kömür-yeşili zemin, tek bir canlı vurgu (klorofil), mor (UV/mutasyon), turkuaz (su), kehribar (kredi),
## mercan (olumsuz). Yüzeyler çizgiyle değil KADEMEYLE ayrılır: zemin < yüzey-1 < yüzey-2 < yüzey-3.
##
## [codeblock]
## label.add_theme_color_override("font_color", UiTokens.TEXT_MUTED)
## container.add_theme_constant_override("separation", UiTokens.SPACE_2)
## [/codeblock]

# ---------------------------------------------------------------------------- renk: zemin ve yüzeyler
const BG_DEEP: Color = Color("060b0a")
const BG: Color = Color("0a120f")
const SURFACE_1: Color = Color("101b17")
const SURFACE_2: Color = Color("172722")
const SURFACE_3: Color = Color("20352d")
const SURFACE_4: Color = Color("2b463b")
const HAIRLINE: Color = Color(1.0, 1.0, 1.0, 0.09)
const HAIRLINE_STRONG: Color = Color(1.0, 1.0, 1.0, 0.18)

# ---------------------------------------------------------------------------- renk: metin
const TEXT: Color = Color("eef4e6")
const TEXT_MUTED: Color = Color("9fb4a6")
const TEXT_DIM: Color = Color("68796f")

# ---------------------------------------------------------------------------- renk: anlam
## Klorofil: büyüme, ana eylem, seçili.
const ACCENT: Color = Color("a6f04a")
const ACCENT_DARK: Color = Color("12200a")
## Mor: UV ışığı, mutasyon, nadirlik.
const UV: Color = Color("a883ff")
## Turkuaz: su, bilgi.
const AQUA: Color = Color("4fcfff")
## Kehribar: kredi (öz kristali), ödül.
const SAP: Color = Color("ffc35a")
## Mercan: olumsuz, uyarı, düşüş.
const BLOOM: Color = Color("ff6f61")

# ---------------------------------------------------------------------------- boşluk (8 noktalı ızgara)
const SPACE_1: int = 8
const SPACE_2: int = 16
const SPACE_3: int = 24
const SPACE_4: int = 32
const SPACE_5: int = 48

# ---------------------------------------------------------------------------- yarıçap
const RADIUS_SM: int = 14
const RADIUS_MD: int = 22
const RADIUS_LG: int = 30
const RADIUS_XL: int = 40
const RADIUS_PILL: int = 999

# ---------------------------------------------------------------------------- tipografi
## Gövde yazısının taban boyutu (1080 genişlikte); kullanıcı ölçeği bununla çarpılır.
const FONT_BASE: int = 30
## Tür ölçeği: taban boyutla çarpan.
const SCALE_DISPLAY: float = 2.0
const SCALE_TITLE: float = 1.5
const SCALE_HEADING: float = 1.2
const SCALE_SMALL: float = 0.82
const SCALE_MICRO: float = 0.68
## Yazı ağırlıkları (değişken yazı tipinin `wght` ekseni).
const WEIGHT_REGULAR: int = 500
const WEIGHT_SEMIBOLD: int = 650
const WEIGHT_BOLD: int = 780
const WEIGHT_DISPLAY: int = 800

# ---------------------------------------------------------------------------- dokunma ve ölçü
## Dokunmatik için en küçük hedef yüksekliği (piksel).
const TOUCH_MIN: float = 84.0
const ICON_SM: float = 36.0
const ICON_MD: float = 48.0
const ICON_LG: float = 72.0

# ---------------------------------------------------------------------------- hareket (saniye)
## Düğmeye basma geri bildirimi.
const DUR_PRESS: float = 0.09
const DUR_QUICK: float = 0.16
const DUR_BASE: float = 0.26
const DUR_SLOW: float = 0.45
## Ortam döngüleri (nabız, salınım).
const DUR_AMBIENT: float = 2.4
## Basılı düğme ölçeği.
const PRESS_SCALE: float = 0.955
## Ödül/uyarı "pop" animasyonunda aşım.
const POP_OVERSHOOT: float = 1.12

# ---------------------------------------------------------------------------- nadirlik
## Tür/çeşit nadirlik katmanları (Seed-Dex çerçevesi, ürün etiketi).
enum Rarity { COMMON, UNCOMMON, RARE, MUTANT }
## Mutasyonsuz bir bitkinin pazar değerinden nadirlik katmanı eşikleri (yalnızca sunum; oyun kuralı değildir).
const UNCOMMON_VALUE: float = 12.0
const RARE_VALUE: float = 18.0


## Anlam renkleri: normalde klorofil/mercan; renk körlüğü kipinde mavi/turuncu (kırmızı-yeşil ayrımına dayanmaz).
## Olumlu/olumsuz her yerde AYRICA şekille (▲▼ ikonları, işaret) verilir; renk tek başına bilgi taşımaz.
static func palette(colorblind: bool) -> Dictionary:
	if colorblind:
		return {
			"accent": Color("5cc8ff"),
			"accent_dark": Color("041622"),
			"good": Color("5cc8ff"),
			"bad": Color("ffa31a"),
			"gold": Color("ffe27a"),
			"uv": Color("c3a6ff"),
			"aqua": Color("7fe0ff"),
			"text": TEXT,
			"muted": TEXT_MUTED,
		}
	return {
		"accent": ACCENT,
		"accent_dark": ACCENT_DARK,
		"good": ACCENT,
		"bad": BLOOM,
		"gold": SAP,
		"uv": UV,
		"aqua": AQUA,
		"text": TEXT,
		"muted": TEXT_MUTED,
	}


## Nadirlik rengi (çerçeve ve etiket).
static func rarity_color(rarity: Rarity, colorblind: bool = false) -> Color:
	var colors: Dictionary = palette(colorblind)
	match rarity:
		Rarity.UNCOMMON:
			return colors["good"] as Color
		Rarity.RARE:
			return colors["aqua"] as Color
		Rarity.MUTANT:
			return colors["uv"] as Color
	return TEXT_DIM


## Rengin verilen alfa ile kopyası (yarı saydam dolgu/halo için).
static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
