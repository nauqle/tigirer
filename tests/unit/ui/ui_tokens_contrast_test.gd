extends TestCase
## Tasarım dili kontrast kuralı (design/design-language.md, "Erişilebilirlik"): bilgi taşıyan her metin/vurgu rengi, üzerinde durduğu yüzeylerde
## WCAG AA'yı (4.5:1) geçer; yalnızca TEXT_DIM (pasif/dekoratif) geçmez ve bilgi taşımaz. Hem normal hem renk körlüğü paleti denetlenir.

const AA: float = 4.5
const SURFACES: Array[Color] = [UiTokens.BG, UiTokens.SURFACE_1, UiTokens.SURFACE_2, UiTokens.SURFACE_3]


static func _channel(value: float) -> float:
	return value / 12.92 if value <= 0.03928 else pow((value + 0.055) / 1.055, 2.4)


static func luminance(color: Color) -> float:
	return 0.2126 * _channel(color.r) + 0.7152 * _channel(color.g) + 0.0722 * _channel(color.b)


static func contrast(a: Color, b: Color) -> float:
	var light: float = maxf(luminance(a), luminance(b))
	var dark: float = minf(luminance(a), luminance(b))
	return (light + 0.05) / (dark + 0.05)


func _assert_readable(color: Color, label: String) -> void:
	for surface: Color in SURFACES:
		assert_true(contrast(color, surface) >= AA, "%s zeminde okunmuyor: %.2f:1 (%s üstünde)" % [label, contrast(color, surface), surface.to_html(false)])


func test_the_contrast_helper_matches_known_values() -> void:
	assert_almost_eq(contrast(Color.WHITE, Color.BLACK), 21.0, 0.01)
	assert_almost_eq(contrast(Color.WHITE, Color.WHITE), 1.0, 0.001)


func test_informational_text_colors_pass_aa_on_every_surface() -> void:
	_assert_readable(UiTokens.TEXT, "TEXT")
	_assert_readable(UiTokens.TEXT_MUTED, "TEXT_MUTED")


func test_every_semantic_accent_passes_aa_in_both_palettes() -> void:
	for colorblind: bool in [false, true]:
		var palette: Dictionary = UiTokens.palette(colorblind)
		for key: String in ["accent", "good", "bad", "gold", "uv", "aqua"]:
			_assert_readable(palette[key] as Color, "%s (renk körlüğü=%s)" % [key, colorblind])


func test_text_on_the_primary_button_passes_aa() -> void:
	for colorblind: bool in [false, true]:
		var palette: Dictionary = UiTokens.palette(colorblind)
		assert_true(contrast(palette["accent_dark"] as Color, palette["accent"] as Color) >= AA, "birincil düğme metni (renk körlüğü=%s)" % colorblind)


func test_only_the_dim_text_color_is_allowed_to_fall_below_aa() -> void:
	var worst: float = 99.0
	for surface: Color in SURFACES:
		worst = minf(worst, contrast(UiTokens.TEXT_DIM, surface))
	assert_true(worst < AA, "TEXT_DIM pasif/dekoratif olarak kalır; AA'yı geçecek hale gelirse belge güncellenmeli (%.2f)" % worst)
