class_name UiTheme
extends RefCounted
## Arayüz teması: `UiTokens` belirteçlerinden ve `UiFonts` yazı tiplerinden kurulur. Tüm yazı boyutu/renk/biçim TEMA TÜR
## VARYASYONLARIYLA gelir (`TitleLabel`, `PrimaryButton`, `Card` ...): panel kodu boyut ya da renk sabitlemez; yazı boyutu ayarı
## ve renk körlüğü paleti tek yerden uygulanır. Yüzeyler çizgiyle değil kademeyle ayrılır (bkz. design/design-language.md).
##
## Uygular: design/design-language.md; şablon kuralı: ölçeklenebilir yazı ve renk körlüğü kipi zorunlu.
##
## [codeblock]
## root_control.theme = UiTheme.build(settings.text_scale(), settings.colorblind)
## label.theme_type_variation = &"TitleLabel"
## panel.theme_type_variation = &"Card"
## [/codeblock]

const BASE_FONT_SIZE: int = UiTokens.FONT_BASE
## Alt gezinme çubuğu yazısı ölçeğin yalnızca bu payını izler: beş sekme en büyük yazıda bile ekran genişliğine sığmalı.
const TAB_TEXT_SCALE_SHARE: float = 0.3


## Palet: bkz. `UiTokens.palette`. (Eski çağrılar için burada da durur.)
static func palette(colorblind: bool) -> Dictionary:
	return UiTokens.palette(colorblind)


## Verilen yazı ölçeği ve palet için tema kurar.
static func build(text_scale: float, colorblind: bool) -> Theme:
	var colors: Dictionary = UiTokens.palette(colorblind)
	var accent: Color = colors["accent"] as Color
	var accent_dark: Color = colors["accent_dark"] as Color
	var good: Color = colors["good"] as Color
	var bad: Color = colors["bad"] as Color
	var gold: Color = colors["gold"] as Color
	var uv: Color = colors["uv"] as Color
	var aqua: Color = colors["aqua"] as Color
	var theme: Theme = Theme.new()
	theme.default_font = UiFonts.body(UiTokens.WEIGHT_REGULAR)
	theme.default_font_size = int(round(float(BASE_FONT_SIZE) * text_scale))

	# --- Etiketler
	theme.set_color("font_color", "Label", UiTokens.TEXT)
	_label(theme, "DisplayLabel", UiFonts.display(UiTokens.WEIGHT_DISPLAY), UiTokens.SCALE_DISPLAY, gold)
	_label(theme, "TitleLabel", UiFonts.display(UiTokens.WEIGHT_BOLD), UiTokens.SCALE_TITLE, UiTokens.TEXT)
	_label(theme, "HeadingLabel", UiFonts.display(UiTokens.WEIGHT_BOLD), UiTokens.SCALE_HEADING, UiTokens.TEXT)
	_label(theme, "BigLabel", UiFonts.display(UiTokens.WEIGHT_DISPLAY), UiTokens.SCALE_DISPLAY * 0.85, gold)
	_label(theme, "SmallLabel", UiFonts.body(UiTokens.WEIGHT_REGULAR), UiTokens.SCALE_SMALL, UiTokens.TEXT)
	_label(theme, "MutedLabel", UiFonts.body(UiTokens.WEIGHT_REGULAR), UiTokens.SCALE_SMALL, UiTokens.TEXT_MUTED)
	_label(theme, "OverlineLabel", UiFonts.overline(), UiTokens.SCALE_MICRO, UiTokens.TEXT_MUTED)
	_label(theme, "AccentLabel", UiFonts.body(UiTokens.WEIGHT_BOLD), 1.0, accent)
	_label(theme, "GoodLabel", UiFonts.body(UiTokens.WEIGHT_BOLD), 1.0, good)
	_label(theme, "BadLabel", UiFonts.body(UiTokens.WEIGHT_BOLD), 1.0, bad)
	_label(theme, "GoldLabel", UiFonts.display(UiTokens.WEIGHT_BOLD), 1.0, gold)
	_label(theme, "UvLabel", UiFonts.body(UiTokens.WEIGHT_BOLD), 1.0, uv)
	_label(theme, "AquaLabel", UiFonts.body(UiTokens.WEIGHT_BOLD), 1.0, aqua)
	_label(theme, "NavLabel", UiFonts.body(UiTokens.WEIGHT_BOLD), UiTokens.SCALE_SMALL * (1.0 + (text_scale - 1.0) * TAB_TEXT_SCALE_SHARE) / maxf(text_scale, 0.01), UiTokens.TEXT_MUTED)

	# --- Düğmeler: ikincil (varsayılan), birincil, hayalet, tehlike, ikon, kart, gezinme
	theme.set_font("font", "Button", UiFonts.body(UiTokens.WEIGHT_BOLD))
	_button(theme, "Button", UiTokens.SURFACE_3, UiTokens.HAIRLINE, UiTokens.TEXT, UiTokens.TEXT, accent, 0.0)
	_button(theme, "PrimaryButton", accent, Color(0, 0, 0, 0), accent_dark, accent_dark, accent_dark, 0.22, accent)
	_button(theme, "GhostButton", Color(0, 0, 0, 0), Color(0, 0, 0, 0), UiTokens.TEXT_MUTED, UiTokens.TEXT, accent, 0.0)
	_button(theme, "DangerButton", UiTokens.with_alpha(bad, 0.16), UiTokens.with_alpha(bad, 0.55), bad, UiTokens.TEXT, bad, 0.0)
	_button(theme, "IconButton", UiTokens.SURFACE_2, UiTokens.HAIRLINE, UiTokens.TEXT, UiTokens.TEXT, accent, 0.0, Color(0, 0, 0, 0), UiTokens.RADIUS_PILL, 18, 12)
	_button(theme, "CardButton", UiTokens.SURFACE_2, UiTokens.HAIRLINE, UiTokens.TEXT, UiTokens.TEXT, accent, 0.0, Color(0, 0, 0, 0), UiTokens.RADIUS_MD, 12, 12)
	_button(theme, "BuyButton", UiTokens.with_alpha(accent, 0.10), UiTokens.with_alpha(accent, 0.6), accent, accent, accent, 0.0, Color(0, 0, 0, 0), UiTokens.RADIUS_MD, 18, 12)
	_button(theme, "MutantButton", UiTokens.with_alpha(uv, 0.14), UiTokens.with_alpha(uv, 0.6), UiTokens.TEXT, UiTokens.TEXT, uv, 0.0, Color(0, 0, 0, 0), UiTokens.RADIUS_MD, 12, 12)
	_button(theme, "SegmentButton", Color(0, 0, 0, 0), Color(0, 0, 0, 0), UiTokens.TEXT_MUTED, UiTokens.TEXT, accent, 0.0, Color(0, 0, 0, 0), UiTokens.RADIUS_MD, 14, 12)
	_button(theme, "NavButton", Color(0, 0, 0, 0), Color(0, 0, 0, 0), UiTokens.TEXT_MUTED, UiTokens.TEXT, accent, 0.0, Color(0, 0, 0, 0), UiTokens.RADIUS_LG, 6, 10)
	# Seçili (basılı) durumlar: kart düğmesi ve gezinme ayrı bakar
	_selected_style(theme, "CardButton", UiTokens.with_alpha(accent, 0.12), accent)
	_selected_style(theme, "MutantButton", UiTokens.with_alpha(uv, 0.28), uv)
	_selected_style(theme, "SegmentButton", UiTokens.with_alpha(accent, 0.18), accent)
	_selected_style(theme, "NavButton", UiTokens.with_alpha(accent, 0.14), UiTokens.with_alpha(accent, 0.0))
	# Eski adlar (geriye uyum): sekme düğmeleri
	theme.set_type_variation("TabButton", "Button")
	theme.set_type_variation("TabButtonActive", "PrimaryButton")

	# --- Yüzeyler
	theme.set_stylebox("panel", "PanelContainer", _box(UiTokens.SURFACE_1, UiTokens.HAIRLINE, 1, UiTokens.RADIUS_LG, 24, 20))
	theme.set_stylebox("panel", "Panel", _box(UiTokens.SURFACE_1, UiTokens.HAIRLINE, 1, UiTokens.RADIUS_LG, 0, 0))
	_panel(theme, "Card", _box(UiTokens.SURFACE_1, UiTokens.HAIRLINE, 1, UiTokens.RADIUS_LG, 24, 20))
	_panel(theme, "CardRaised", _box(UiTokens.SURFACE_2, UiTokens.HAIRLINE_STRONG, 1, UiTokens.RADIUS_LG, 24, 20, Color(0, 0, 0, 0.45), 18, Vector2(0, 8)))
	_panel(theme, "CardAccent", _box(UiTokens.with_alpha(accent, 0.1), UiTokens.with_alpha(accent, 0.5), 2, UiTokens.RADIUS_LG, 24, 20))
	_panel(theme, "CardUv", _box(UiTokens.with_alpha(uv, 0.12), UiTokens.with_alpha(uv, 0.5), 2, UiTokens.RADIUS_LG, 24, 20))
	_panel(theme, "CardWarn", _box(UiTokens.with_alpha(bad, 0.1), UiTokens.with_alpha(bad, 0.5), 2, UiTokens.RADIUS_LG, 24, 20))
	_panel(theme, "Chip", _box(UiTokens.SURFACE_3, UiTokens.HAIRLINE, 1, UiTokens.RADIUS_PILL, 18, 8))
	_panel(theme, "ChipGold", _box(UiTokens.with_alpha(gold, 0.14), UiTokens.with_alpha(gold, 0.45), 1, UiTokens.RADIUS_PILL, 18, 8))
	_panel(theme, "ChipAccent", _box(UiTokens.with_alpha(accent, 0.14), UiTokens.with_alpha(accent, 0.45), 1, UiTokens.RADIUS_PILL, 18, 8))
	_panel(theme, "Glass", _box(Color(0.04, 0.08, 0.07, 0.8), UiTokens.HAIRLINE_STRONG, 1, UiTokens.RADIUS_LG, 22, 14, Color(0, 0, 0, 0.4), 16, Vector2(0, 6)))
	_panel(theme, "Toast", _box(UiTokens.SURFACE_3, UiTokens.HAIRLINE_STRONG, 1, UiTokens.RADIUS_PILL, 26, 14, Color(0, 0, 0, 0.5), 20, Vector2(0, 8)))
	_panel(theme, "Sheet", _sheet_box(UiTokens.SURFACE_1, UiTokens.HAIRLINE_STRONG))
	_panel(theme, "FloraBubble", _box(UiTokens.with_alpha(aqua, 0.1), UiTokens.with_alpha(aqua, 0.4), 1, UiTokens.RADIUS_LG, 20, 16))

	# --- İlerleme çubukları
	_progress(theme, "ProgressBar", accent)
	_progress(theme, "UvProgress", uv)
	_progress(theme, "SapProgress", gold)
	_progress(theme, "AquaProgress", aqua)

	# --- Düzen sabitleri ve dokunmatik kaydırma çubukları
	theme.set_constant("separation", "VBoxContainer", UiTokens.SPACE_2)
	theme.set_constant("separation", "HBoxContainer", UiTokens.SPACE_2)
	theme.set_constant("h_separation", "GridContainer", UiTokens.SPACE_2)
	theme.set_constant("v_separation", "GridContainer", UiTokens.SPACE_2)
	var thin: StyleBoxFlat = _box(UiTokens.with_alpha(accent, 0.45), Color(0, 0, 0, 0), 0, UiTokens.RADIUS_PILL, 0, 0)
	theme.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	theme.set_stylebox("grabber", "VScrollBar", thin)
	theme.set_stylebox("grabber_highlight", "VScrollBar", thin)
	theme.set_stylebox("grabber_pressed", "VScrollBar", thin)
	theme.set_stylebox("scroll", "HScrollBar", StyleBoxEmpty.new())
	theme.set_stylebox("grabber", "HScrollBar", thin)
	theme.set_stylebox("grabber_highlight", "HScrollBar", thin)
	theme.set_stylebox("grabber_pressed", "HScrollBar", thin)
	return theme


## Yuvarlak köşeli düz kutu; kenar, gölge ve iç boşluk isteğe bağlı.
static func _box(fill: Color, edge: Color, border: int, radius: int, margin_x: int, margin_y: int, shadow: Color = Color(0, 0, 0, 0), shadow_size: int = 0, shadow_offset: Vector2 = Vector2.ZERO) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.content_margin_left = float(margin_x)
	box.content_margin_right = float(margin_x)
	box.content_margin_top = float(margin_y)
	box.content_margin_bottom = float(margin_y)
	box.shadow_color = shadow
	box.shadow_size = shadow_size
	box.shadow_offset = shadow_offset
	return box


## Üst köşeleri yuvarlak alt sayfa (ayarlar, ayrıntı) kutusu.
static func _sheet_box(fill: Color, edge: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = _box(fill, edge, 1, UiTokens.RADIUS_XL, 32, 28, Color(0, 0, 0, 0.6), 30, Vector2(0, -6))
	box.corner_radius_bottom_left = 0
	box.corner_radius_bottom_right = 0
	return box


static func _panel(theme: Theme, variation: StringName, box: StyleBoxFlat) -> void:
	theme.set_type_variation(variation, "PanelContainer")
	theme.set_stylebox("panel", variation, box)


static func _label(theme: Theme, variation: StringName, font: Font, size_factor: float, color: Color) -> void:
	theme.set_type_variation(variation, "Label")
	theme.set_font("font", variation, font)
	theme.set_font_size("font_size", variation, int(round(float(theme.default_font_size) * size_factor)))
	theme.set_color("font_color", variation, color)


## Düğme türü: dolgu, kenar, yazı ve vurgu renkleri; `glow` > 0 ise vurgu rengiyle parıltı.
static func _button(theme: Theme, variation: StringName, fill: Color, edge: Color, text: Color, text_hover: Color, accent: Color, glow: float, glow_color: Color = Color(0, 0, 0, 0), radius: int = UiTokens.RADIUS_MD, margin_x: int = 28, margin_y: int = 16) -> void:
	if variation != "Button":
		theme.set_type_variation(variation, "Button")
	var glow_size: int = 16 if glow > 0.0 else 0
	var glow_tint: Color = UiTokens.with_alpha(glow_color, glow)
	theme.set_stylebox("normal", variation, _box(fill, edge, 1, radius, margin_x, margin_y, glow_tint, glow_size, Vector2(0, 4)))
	theme.set_stylebox("hover", variation, _box(fill.lightened(0.08), edge, 1, radius, margin_x, margin_y, glow_tint, glow_size, Vector2(0, 4)))
	theme.set_stylebox("pressed", variation, _box(fill.darkened(0.14), edge, 1, radius, margin_x, margin_y))
	theme.set_stylebox("hover_pressed", variation, _box(fill.darkened(0.14), edge, 1, radius, margin_x, margin_y))
	theme.set_stylebox("disabled", variation, _box(UiTokens.with_alpha(fill, fill.a * 0.35), UiTokens.with_alpha(edge, edge.a * 0.5), 1, radius, margin_x, margin_y))
	theme.set_stylebox("focus", variation, StyleBoxEmpty.new())
	theme.set_color("font_color", variation, text)
	theme.set_color("font_hover_color", variation, text_hover)
	theme.set_color("font_pressed_color", variation, text_hover)
	theme.set_color("font_hover_pressed_color", variation, text_hover)
	theme.set_color("font_disabled_color", variation, UiTokens.TEXT_DIM)
	theme.set_color("icon_normal_color", variation, text)
	theme.set_color("icon_hover_color", variation, text_hover)
	theme.set_color("icon_pressed_color", variation, text_hover)
	theme.set_color("icon_disabled_color", variation, UiTokens.TEXT_DIM)
	theme.set_constant("h_separation", variation, UiTokens.SPACE_1)


## Seçili (açık) durum: toggle düğmelerinin `pressed` stilleri vurgu renginde.
static func _selected_style(theme: Theme, variation: StringName, fill: Color, edge: Color) -> void:
	var normal: StyleBoxFlat = theme.get_stylebox("normal", variation) as StyleBoxFlat
	var selected: StyleBoxFlat = _box(fill, edge, 2, normal.corner_radius_top_left, int(normal.content_margin_left), int(normal.content_margin_top))
	theme.set_stylebox("pressed", variation, selected)
	theme.set_stylebox("hover_pressed", variation, selected)
	theme.set_color("font_pressed_color", variation, edge if edge.a > 0.5 else UiTokens.TEXT)
	theme.set_color("font_hover_pressed_color", variation, edge if edge.a > 0.5 else UiTokens.TEXT)


static func _progress(theme: Theme, variation: StringName, color: Color) -> void:
	if variation != "ProgressBar":
		theme.set_type_variation(variation, "ProgressBar")
	theme.set_stylebox("background", variation, _box(UiTokens.SURFACE_3, Color(0, 0, 0, 0), 0, UiTokens.RADIUS_PILL, 0, 0))
	theme.set_stylebox("fill", variation, _box(color, Color(0, 0, 0, 0), 0, UiTokens.RADIUS_PILL, 0, 0, UiTokens.with_alpha(color, 0.4), 8))
