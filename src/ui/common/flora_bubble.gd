class_name FloraBubble
extends PanelContainer
## FLORA'nın konuşma balonu: kulenin bakım yapay zekâsı kısa, kuru esprili ipuçları verir. Daire içinde ışıltı ikonu + tek paragraf.
## Metin değişince balon hafifçe sıçrar; boşsa gizlenir. Yalnızca gösterir.
##
## Uygular: design/design-language.md, "Yazım sesi" (FLORA); design/game-brief.md, "Core loop" (öğretici).
##
## [codeblock]
## bubble.say(tr("HINT_PLANT"))
## [/codeblock]

var _label: Label
var _avatar: Panel
var _last_text: String = ""


func _init() -> void:
	theme_type_variation = &"FloraBubble"
	var row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	add_child(row)
	_avatar = Panel.new()
	_avatar.custom_minimum_size = Vector2(64.0, 64.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UiTokens.with_alpha(UiTokens.AQUA, 0.18)
	style.border_color = UiTokens.with_alpha(UiTokens.AQUA, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(UiTokens.RADIUS_PILL)
	_avatar.add_theme_stylebox_override("panel", style)
	_avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spark: TextureRect = UiKit.icon(&"sparkle", 36.0, UiTokens.AQUA)
	spark.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	spark.offset_left = -18.0
	spark.offset_top = -18.0
	spark.offset_right = 18.0
	spark.offset_bottom = 18.0
	_avatar.add_child(spark)
	row.add_child(_avatar)
	_label = UiKit.label("", &"SmallLabel", true)
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_label)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Mesajı gösterir; boş metin balonu gizler.
func say(text: String) -> void:
	visible = text != ""
	if text == _last_text:
		return
	_last_text = text
	_label.text = text
	if text != "":
		UiMotion.bump(self, 1.025)
