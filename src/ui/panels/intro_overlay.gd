class_name IntroOverlay
extends Control
## Açılış kartı (ilk açılışta bir kez): FLORA, kulenin bakım yapay zekâsı, kendini ve kurguyu iki paragrafta tanıtır. Kapatınca
## `GameSettings.intro_seen` işaretlenir. Yalnızca gösterir.
##
## Uygular: design/game-brief.md, "One-sentence pitch" (terk edilmiş gökdelende sera); design/design-language.md, "Yazım sesi" (FLORA).

## Kart kapatıldı.
signal closed

var _settings: GameSettings
var _card: PanelContainer


func setup(settings: GameSettings) -> void:
	_settings = settings
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.01, 0.03, 0.02, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_card = UiKit.card("CardRaised")
	_card.custom_minimum_size = Vector2(900.0, 0.0)
	center.add_child(_card)
	var box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_2)
	_card.add_child(box)
	var avatar_row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	avatar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var avatar: Panel = Panel.new()
	avatar.custom_minimum_size = Vector2(120.0, 120.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UiTokens.with_alpha(UiTokens.AQUA, 0.16)
	style.border_color = UiTokens.with_alpha(UiTokens.AQUA, 0.75)
	style.set_border_width_all(3)
	style.set_corner_radius_all(UiTokens.RADIUS_PILL)
	style.shadow_color = UiTokens.with_alpha(UiTokens.AQUA, 0.35)
	style.shadow_size = 22
	avatar.add_theme_stylebox_override("panel", style)
	var spark: TextureRect = UiKit.icon(&"sparkle", 64.0, UiTokens.AQUA)
	spark.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	spark.offset_left = -32.0
	spark.offset_top = -32.0
	spark.offset_right = 32.0
	spark.offset_bottom = 32.0
	avatar.add_child(spark)
	avatar_row.add_child(avatar)
	box.add_child(avatar_row)
	box.add_child(UiKit.label(tr("INTRO_NAME"), &"OverlineLabel", false, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.label(tr("INTRO_TITLE"), &"TitleLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.label(tr("INTRO_BODY"), &"SmallLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	var start: FxButton = UiKit.button(tr("INTRO_BUTTON"), &"PrimaryButton", 96.0)
	start.pressed.connect(close)
	box.add_child(start)


## Kartı gösterir.
func show_intro() -> void:
	visible = true
	UiMotion.pop_in(_card)


func close() -> void:
	if _settings != null and not _settings.intro_seen:
		_settings.set_intro_seen(true)
	visible = false
	closed.emit()
