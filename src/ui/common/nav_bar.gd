class_name NavBar
extends PanelContainer
## Alt gezinme çubuğu: ikon + kısa etiket, seçili sekme klorofil renkli yumuşak hap ve yaylanan ikonla belli olur; dikkat gerektiren
## sekmede küçük nabız atan rozet görünür (teslim edilebilir sipariş, alınabilir yükseltme, yeni keşif).
## Gezinme KOMUT değil görünüm seçimidir; oyun durumuna dokunmaz.
##
## Uygular: design/design-language.md, "Gezinme".
##
## [codeblock]
## var nav: NavBar = NavBar.new()
## nav.setup()
## nav.add_tab(&"farm", tr("TAB_FARM"))
## nav.tab_selected.connect(_on_tab)
## nav.select(0, false)
## [/codeblock]

## Bir sekme seçildi (kullanıcı dokunuşuyla ya da `select`).
signal tab_selected(index: int)

const _TAB_HEIGHT: float = 116.0

var _row: HBoxContainer
var _group: ButtonGroup = ButtonGroup.new()
var _tabs: Array[Button] = []
var _icons: Array[TextureRect] = []
var _labels: Array[Label] = []
var _badges: Array[Control] = []
var _selected: int = -1
var _accent: Color = UiTokens.ACCENT


func setup(accent: Color = UiTokens.ACCENT) -> void:
	theme_type_variation = &"Glass"
	_accent = accent
	_row = UiKit.hbox(UiTokens.SPACE_1)
	_row.add_theme_constant_override("separation", 6)
	add_child(_row)


## Yeni sekme ekler; dizinini döndürür.
func add_tab(icon_name: StringName, text: String) -> int:
	var index: int = _tabs.size()
	var tab: FxButton = FxButton.new()
	tab.theme_type_variation = &"NavButton"
	tab.toggle_mode = true
	tab.button_group = _group
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.custom_minimum_size = Vector2(0.0, _TAB_HEIGHT)
	tab.clip_contents = false
	tab.tap_sound = false  # sesi seçim olayı çalar
	tab.pressed.connect(func() -> void: select(index, true))
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tab.add_child(column)
	var icon: TextureRect = UiKit.icon(icon_name, UiTokens.ICON_MD, UiTokens.TEXT_MUTED)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	var label: Label = UiKit.label(text, &"NavLabel", false, HORIZONTAL_ALIGNMENT_CENTER)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(label)
	var badge: Panel = _make_badge()
	badge.visible = false
	tab.add_child(badge)
	_row.add_child(tab)
	_tabs.append(tab)
	_icons.append(icon)
	_labels.append(label)
	_badges.append(badge)
	return index


## Sekmeyi seçer; `emit` doğruysa `tab_selected` yayınlanır.
func select(index: int, emit: bool = true) -> void:
	if index < 0 or index >= _tabs.size():
		return
	var changed: bool = index != _selected
	_selected = index
	for i: int in _tabs.size():
		var active: bool = i == index
		_tabs[i].set_pressed_no_signal(active)
		UiMotion.tint(_icons[i], _accent if active else UiTokens.TEXT_MUTED)
		_labels[i].add_theme_color_override("font_color", _accent if active else UiTokens.TEXT_MUTED)
	if changed:
		UiMotion.bump(_icons[index], 1.18)
	if emit:
		tab_selected.emit(index)


## Dikkat rozetini açar/kapatır.
func set_badge(index: int, visible_badge: bool) -> void:
	if index < 0 or index >= _badges.size():
		return
	var badge: Control = _badges[index]
	if badge.visible == visible_badge:
		return
	badge.visible = visible_badge
	if visible_badge:
		UiMotion.pulse(badge, 0.5, 1.25)


func selected() -> int:
	return _selected


func tab_count() -> int:
	return _tabs.size()


## Sekme düğmesi (test ve dış düzen için).
func tab(index: int) -> Button:
	return _tabs[index]


func badge_visible(index: int) -> bool:
	return _badges[index].visible


## Sağ üst köşede küçük mercan nokta.
func _make_badge() -> Panel:
	var dot: Panel = Panel.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UiTokens.BLOOM
	style.set_corner_radius_all(UiTokens.RADIUS_PILL)
	style.border_color = UiTokens.SURFACE_1
	style.set_border_width_all(3)
	dot.add_theme_stylebox_override("panel", style)
	dot.custom_minimum_size = Vector2(24.0, 24.0)
	dot.size = Vector2(24.0, 24.0)
	dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dot.offset_left = -46.0
	dot.offset_right = -22.0
	dot.offset_top = 12.0
	dot.offset_bottom = 36.0
	return dot
