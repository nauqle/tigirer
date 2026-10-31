class_name SegmentedControl
extends PanelContainer
## Parçalı seçici (dil, yazı boyutu): tek seçim; seçili parça klorofil yumuşak dolgu ve çerçeveyle belirir. Seçenek metni yerelleştirilmiş
## olarak verilir. Seçim kullanıcı dokunuşuyla `selected` sinyalini yayınlar.
##
## Uygular: design/design-language.md, "Bileşenler" (parçalı seçici).

## Kullanıcı bir parça seçti.
signal selected(index: int)

var _row: HBoxContainer
var _group: ButtonGroup = ButtonGroup.new()
var _buttons: Array[FxButton] = []


## Seçenek metinlerini kurar.
func setup(options: Array[String]) -> void:
	theme_type_variation = &"Chip"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row = UiKit.hbox(6)
	add_child(_row)
	for i: int in options.size():
		var button: FxButton = UiKit.button(options[i], &"SegmentButton", 64.0)
		button.toggle_mode = true
		button.button_group = _group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.pressed.connect(func() -> void: selected.emit(i))
		_row.add_child(button)
		_buttons.append(button)


## Seçili parçayı ayarlar (olay yayınlamaz).
func set_selected(index: int) -> void:
	for i: int in _buttons.size():
		_buttons[i].set_pressed_no_signal(i == index)


func button(index: int) -> FxButton:
	return _buttons[index]
