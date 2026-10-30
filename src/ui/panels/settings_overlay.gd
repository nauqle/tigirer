class_name SettingsOverlay
extends Control
## Ayarlar penceresi: ses, titreşim, hareketi azalt, yazı boyutu, renk körlüğü kipi, nasıl oynanır, şimdi kaydet ve
## sıfırlama (iki adımlı onay). Değişiklikler `GameSettings` kurallarıyla yapılır (oyun durumunu etkilemez); sıfırlama ve kayıt
## `GameSession` komutlarıdır.
##
## Uygular: design/game-brief.md, FAZ 5 mobil arayüz; şablon kuralı: ölçeklenebilir yazı ve renk körlüğü kipi zorunlu,
## hareket tercihine saygı.

## Pencere kapatıldı.
signal closed

var _session: GameSession
var _toggles: Dictionary = {}  # ad -> Button
var _size_buttons: Array[Button] = []
var _confirm_row: HBoxContainer
var _reset_button: Button


func setup(session: GameSession) -> void:
	_session = session
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.03, 0.06, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var scroll: ScrollContainer = UiKit.scroll()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 40.0
	scroll.offset_right = -40.0
	scroll.offset_top = 120.0
	scroll.offset_bottom = -120.0
	add_child(scroll)
	var card: PanelContainer = UiKit.card()
	scroll.add_child(card)
	var box: VBoxContainer = UiKit.vbox(14)
	card.add_child(box)
	box.add_child(UiKit.label(tr("SET_TITLE"), &"HeadingLabel"))

	_add_toggle(box, "sound", "SET_SOUND_ON", "SET_SOUND_OFF", func() -> bool: return _session.settings.sound_on, func(v: bool) -> void: _session.settings.set_sound(v))
	_add_toggle(box, "vibration", "SET_VIBRATION_ON", "SET_VIBRATION_OFF", func() -> bool: return _session.settings.vibration_on, func(v: bool) -> void: _session.settings.set_vibration(v))
	_add_toggle(box, "motion", "SET_MOTION_REDUCED", "SET_MOTION_FULL", func() -> bool: return _session.settings.reduce_motion, func(v: bool) -> void: _session.settings.set_reduce_motion(v))
	_add_toggle(box, "colorblind", "SET_COLORBLIND_ON", "SET_COLORBLIND_OFF", func() -> bool: return _session.settings.colorblind, func(v: bool) -> void: _session.settings.set_colorblind(v))

	box.add_child(UiKit.label(tr("SET_TEXT_SIZE"), &"AccentLabel"))
	var sizes: HBoxContainer = UiKit.hbox(10)
	box.add_child(sizes)
	for i: int in GameSettings.TEXT_SCALES.size():
		var button: Button = UiKit.button(tr("SET_SIZE_%d" % i), &"TabButton", 80.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: _session.settings.set_text_scale_index(i))
		sizes.add_child(button)
		_size_buttons.append(button)

	box.add_child(UiKit.label(tr("SET_HELP_TITLE"), &"AccentLabel"))
	box.add_child(UiKit.label(tr("HELP_TEXT"), &"SmallLabel", true))
	var save: Button = UiKit.button(tr("SET_SAVE_NOW"), &"", 80.0)
	save.pressed.connect(_on_save)
	box.add_child(save)
	_reset_button = UiKit.button(tr("SET_RESET"), &"DangerButton", 80.0)
	_reset_button.pressed.connect(_on_reset_pressed)
	box.add_child(_reset_button)
	_confirm_row = UiKit.hbox(10)
	_confirm_row.visible = false
	box.add_child(_confirm_row)
	var yes: Button = UiKit.button(tr("SET_RESET_YES"), &"DangerButton", 80.0)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(_on_reset_confirmed)
	_confirm_row.add_child(yes)
	var no: Button = UiKit.button(tr("BTN_CANCEL"), &"", 80.0)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(func() -> void: _confirm_row.visible = false)
	_confirm_row.add_child(no)
	var close: Button = UiKit.button(tr("BTN_CLOSE"), &"PrimaryButton", 90.0)
	close.pressed.connect(func() -> void: closed.emit())
	box.add_child(close)
	_session.settings.changed.connect(refresh)
	refresh()


func refresh() -> void:
	for button_name: String in _toggles.keys():
		var toggle: Button = _toggles[button_name] as Button
		var getter: Callable = toggle.get_meta("getter") as Callable
		var value: bool = getter.call() as bool
		toggle.theme_type_variation = &"TabButtonActive" if value else &"TabButton"
		toggle.text = tr(String(toggle.get_meta("key_on")) if value else String(toggle.get_meta("key_off")))
	for i: int in _size_buttons.size():
		_size_buttons[i].theme_type_variation = &"TabButtonActive" if i == _session.settings.text_scale_index else &"TabButton"


func _add_toggle(box: VBoxContainer, key: String, key_on: String, key_off: String, getter: Callable, setter: Callable) -> void:
	var button: Button = UiKit.button("", &"TabButton", 80.0)
	button.set_meta("getter", getter)
	button.set_meta("key_on", key_on)
	button.set_meta("key_off", key_off)
	button.pressed.connect(func() -> void: setter.call(not (getter.call() as bool)))
	box.add_child(button)
	_toggles[key] = button


func _on_save() -> void:
	var ok: bool = _session.save_game()
	SignalBus.toast_requested.emit("MSG_SAVED" if ok else "ERR_SAVE_FAILED", [])


func _on_reset_pressed() -> void:
	_confirm_row.visible = true


func _on_reset_confirmed() -> void:
	_confirm_row.visible = false
	_session.reset_game()
	SignalBus.toast_requested.emit("MSG_RESET_DONE", [])
	closed.emit()
