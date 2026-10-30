class_name UiTheme
extends RefCounted
## Arayüz teması: koyu siber palet, dokunmatik dostu büyük düğmeler, yazı boyutu ölçeği ve renk körlüğü paleti.
## Tüm yazı boyutları tema tür varyasyonlarındandır (`HeadingLabel`, `BigLabel`, `SmallLabel` ...): yazı boyutu ayarı tek
## yerden (ölçek çarpanı) uygulanır, panel kodu boyut sabitlemez.
##
## Uygular: design/game-brief.md, "Art & audio direction"; şablon kuralı: ölçeklenebilir yazı ve renk körlüğü kipi zorunlu.
##
## [codeblock]
## root_control.theme = UiTheme.build(settings.text_scale(), settings.colorblind)
## label.theme_type_variation = &"HeadingLabel"
## [/codeblock]

const BASE_FONT_SIZE: int = 30
## Sekme/üst çubuk düğmeleri yazı ölçeğinin yalnızca bu payını izler: beş sekme en büyük yazıda bile ekran genişliğine sığmalı.
const TAB_TEXT_SCALE_SHARE: float = 0.3
const _PANEL: Color = Color(0.05, 0.10, 0.15, 0.92)
const _PANEL_EDGE: Color = Color(0.16, 0.33, 0.42, 1.0)
const _BUTTON: Color = Color(0.09, 0.19, 0.26, 1.0)
const _BUTTON_HOVER: Color = Color(0.13, 0.27, 0.36, 1.0)
const _BUTTON_PRESSED: Color = Color(0.06, 0.14, 0.2, 1.0)
const _TEXT: Color = Color(0.88, 0.96, 0.94)
const _MUTED: Color = Color(0.58, 0.72, 0.72)


## Palet: normalde yeşil-turkuaz vurgu; renk körlüğü kipinde mavi-turuncu (kırmızı/yeşil ayrımına dayanmaz).
static func palette(colorblind: bool) -> Dictionary:
	if colorblind:
		return {
			"accent": Color(0.38, 0.72, 1.0),
			"good": Color(0.38, 0.72, 1.0),
			"bad": Color(1.0, 0.66, 0.18),
			"gold": Color(1.0, 0.9, 0.45),
			"text": _TEXT,
			"muted": _MUTED,
		}
	return {
		"accent": Color(0.42, 1.0, 0.82),
		"good": Color(0.5, 0.95, 0.55),
		"bad": Color(1.0, 0.5, 0.42),
		"gold": Color(1.0, 0.86, 0.35),
		"text": _TEXT,
		"muted": _MUTED,
	}


## Verilen yazı ölçeği ve palet için tema kurar.
static func build(text_scale: float, colorblind: bool) -> Theme:
	var colors: Dictionary = palette(colorblind)
	var accent: Color = colors["accent"] as Color
	var theme: Theme = Theme.new()
	theme.default_font_size = int(round(float(BASE_FONT_SIZE) * text_scale))

	theme.set_color("font_color", "Label", _TEXT)
	theme.set_stylebox("panel", "PanelContainer", _box(_PANEL, _PANEL_EDGE, 22, 2, 22))
	theme.set_stylebox("panel", "Panel", _box(_PANEL, _PANEL_EDGE, 22, 2, 0))

	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var fill: Color = _BUTTON
		var edge: Color = _PANEL_EDGE
		match state:
			"hover":
				fill = _BUTTON_HOVER
			"pressed":
				fill = _BUTTON_PRESSED
				edge = accent
			"disabled":
				fill = Color(0.07, 0.12, 0.16, 0.9)
				edge = Color(0.12, 0.2, 0.26)
		if state == "focus":
			theme.set_stylebox(state, "Button", StyleBoxEmpty.new())
		else:
			theme.set_stylebox(state, "Button", _box(fill, edge, 20, 2, 22))
	theme.set_color("font_color", "Button", _TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", accent)
	theme.set_color("font_disabled_color", "Button", Color(0.4, 0.5, 0.52))
	theme.set_color("font_hover_pressed_color", "Button", accent)

	_variation(theme, "PrimaryButton", "Button", accent.darkened(0.55), accent, accent.lightened(0.5))
	_variation(theme, "TabButton", "Button", Color(0.06, 0.12, 0.17), _PANEL_EDGE, _MUTED)
	_variation(theme, "TabButtonActive", "Button", accent.darkened(0.62), accent, accent)
	for tab_variation: StringName in [&"TabButton", &"TabButtonActive"]:
		theme.set_font_size("font_size", tab_variation, int(round(float(BASE_FONT_SIZE) * (1.0 + (text_scale - 1.0) * TAB_TEXT_SCALE_SHARE))))
	_variation(theme, "DangerButton", "Button", Color(0.35, 0.1, 0.1), Color(0.8, 0.3, 0.25), Color(1.0, 0.8, 0.75))

	_label_variation(theme, "HeadingLabel", 1.35, accent)
	_label_variation(theme, "BigLabel", 1.7, colors["gold"] as Color)
	_label_variation(theme, "SmallLabel", 0.8, _TEXT)
	_label_variation(theme, "MutedLabel", 0.82, _MUTED)
	_label_variation(theme, "AccentLabel", 1.0, accent)
	_label_variation(theme, "GoodLabel", 1.0, colors["good"] as Color)
	_label_variation(theme, "BadLabel", 1.0, colors["bad"] as Color)
	_label_variation(theme, "GoldLabel", 1.0, colors["gold"] as Color)

	theme.set_stylebox("background", "ProgressBar", _box(Color(0.04, 0.09, 0.13), Color(0.14, 0.3, 0.38), 13, 2, 0))
	theme.set_stylebox("fill", "ProgressBar", _box(accent.darkened(0.1), accent, 13, 0, 0))
	theme.set_constant("separation", "VBoxContainer", 14)
	theme.set_constant("separation", "HBoxContainer", 14)
	theme.set_constant("h_separation", "GridContainer", 14)
	theme.set_constant("v_separation", "GridContainer", 14)
	# Dokunmatik kaydırma çubukları: kalın ve belirgin
	theme.set_stylebox("scroll", "VScrollBar", _box(Color(0.05, 0.1, 0.14, 0.6), Color(0, 0, 0, 0), 8, 0, 0))
	theme.set_stylebox("grabber", "VScrollBar", _box(accent.darkened(0.3), Color(0, 0, 0, 0), 8, 0, 0))
	theme.set_stylebox("grabber_highlight", "VScrollBar", _box(accent, Color(0, 0, 0, 0), 8, 0, 0))
	theme.set_stylebox("grabber_pressed", "VScrollBar", _box(accent, Color(0, 0, 0, 0), 8, 0, 0))
	return theme


static func _box(fill: Color, edge: Color, radius: int, border: int, margin: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.content_margin_left = float(margin)
	box.content_margin_right = float(margin)
	box.content_margin_top = float(maxi(margin * 2 / 3, 0))
	box.content_margin_bottom = float(maxi(margin * 2 / 3, 0))
	return box


## Düğme türü varyasyonu: dolgu, kenar ve yazı rengi.
static func _variation(theme: Theme, name: StringName, base: StringName, fill: Color, edge: Color, text: Color) -> void:
	theme.set_type_variation(name, base)
	theme.set_stylebox("normal", name, _box(fill, edge, 20, 3, 22))
	theme.set_stylebox("hover", name, _box(fill.lightened(0.12), edge, 20, 3, 22))
	theme.set_stylebox("pressed", name, _box(fill.darkened(0.2), edge, 20, 3, 22))
	theme.set_stylebox("disabled", name, _box(fill.darkened(0.45), edge.darkened(0.5), 20, 2, 22))
	theme.set_color("font_color", name, text)
	theme.set_color("font_hover_color", name, Color.WHITE)
	theme.set_color("font_pressed_color", name, text)
	theme.set_color("font_disabled_color", name, Color(0.45, 0.52, 0.55))


static func _label_variation(theme: Theme, name: StringName, size_factor: float, color: Color) -> void:
	theme.set_type_variation(name, "Label")
	theme.set_font_size("font_size", name, int(round(float(theme.default_font_size) * size_factor)))
	theme.set_color("font_color", name, color)
