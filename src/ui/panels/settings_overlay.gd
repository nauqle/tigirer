class_name SettingsOverlay
extends SheetOverlay
## Ayarlar sayfası (alttan açılan sayfa): dil, ses, titreşim, hareketi azalt, renk körlüğü, yazı boyutu, nasıl oynanır, şimdi kaydet ve
## sıfırlama (iki adımlı onay). Değişiklikler `GameSettings` kurallarıyla yapılır (oyun durumunu etkilemez); sıfırlama ve kayıt
## `GameSession` komutlarıdır. Karartmaya dokununca ya da geri tuşuyla kapanır.
##
## Uygular: design/game-brief.md, FAZ 5 mobil arayüz; şablon kuralı: ölçeklenebilir yazı ve renk körlüğü kipi zorunlu,
## hareket tercihine saygı; kullanıcı isteği: İngilizce dil seçeneği.

var _session: GameSession
var _toggles: Dictionary = {}  # ad -> ToggleSwitch
var _language: SegmentedControl
var _sizes: SegmentedControl
var _confirm_row: HBoxContainer
var _reset_button: Button


func setup(session: GameSession) -> void:
	_session = session
	var box: VBoxContainer = begin(tr("SET_TITLE"))

	box.add_child(_make_language_row())
	_add_toggle(box, "sound", &"sound_on", "SET_SOUND", "", func() -> bool: return _session.settings.sound_on, func(v: bool) -> void: _session.settings.set_sound(v))
	_add_toggle(box, "vibration", &"vibration", "SET_VIBRATION", "", func() -> bool: return _session.settings.vibration_on, func(v: bool) -> void: _session.settings.set_vibration(v))
	_add_toggle(box, "motion", &"motion", "SET_MOTION", "SET_MOTION_HINT", func() -> bool: return _session.settings.reduce_motion, func(v: bool) -> void: _session.settings.set_reduce_motion(v))
	_add_toggle(box, "colorblind", &"eye", "SET_COLORBLIND", "SET_COLORBLIND_HINT", func() -> bool: return _session.settings.colorblind, func(v: bool) -> void: _session.settings.set_colorblind(v))
	box.add_child(_make_size_row())

	var help: PanelContainer = UiKit.card("CardRaised")
	var help_box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	help.add_child(help_box)
	help_box.add_child(UiKit.icon_label(&"info", tr("SET_HELP_TITLE"), &"HeadingLabel", UiTokens.AQUA))
	help_box.add_child(UiKit.label(tr("HELP_TEXT"), &"SmallLabel", true))
	box.add_child(help)

	var save: FxButton = UiKit.button(tr("SET_SAVE_NOW"), &"", UiTokens.TOUCH_MIN, &"check")
	save.pressed.connect(_on_save)
	box.add_child(save)
	_reset_button = UiKit.button(tr("SET_RESET"), &"DangerButton", UiTokens.TOUCH_MIN, &"trash")
	_reset_button.pressed.connect(_on_reset_pressed)
	box.add_child(_reset_button)
	_confirm_row = UiKit.hbox(UiTokens.SPACE_1)
	_confirm_row.visible = false
	box.add_child(_confirm_row)
	var yes: FxButton = UiKit.button(tr("SET_RESET_YES"), &"DangerButton", UiTokens.TOUCH_MIN)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(_on_reset_confirmed)
	_confirm_row.add_child(yes)
	var no: FxButton = UiKit.button(tr("BTN_CANCEL"), &"", UiTokens.TOUCH_MIN)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(func() -> void: _confirm_row.visible = false)
	_confirm_row.add_child(no)
	box.add_child(UiKit.label(tr("SET_VERSION") % ProjectSettings.get_setting("application/config/version", "1.0"), &"OverlineLabel", false, HORIZONTAL_ALIGNMENT_CENTER))
	_session.settings.changed.connect(refresh)
	refresh()


## Açılırken onay satırını kapatır ve değerleri tazeler.
func on_open() -> void:
	refresh()
	_confirm_row.visible = false


## Ad (`sound`, `vibration`, `motion`, `colorblind`) ile anahtar.
func toggle(toggle_name: String) -> ToggleSwitch:
	return _toggles[toggle_name] as ToggleSwitch


func language_control() -> SegmentedControl:
	return _language


func size_control() -> SegmentedControl:
	return _sizes


func refresh() -> void:
	if _language == null:
		return
	for toggle_name: String in _toggles.keys():
		var toggle: ToggleSwitch = _toggles[toggle_name] as ToggleSwitch
		var getter: Callable = toggle.get_meta("getter") as Callable
		toggle.set_value(getter.call() as bool, true)
	_language.set_selected(maxi(GameSettings.LANGUAGES.find(_session.settings.language), 0))
	_sizes.set_selected(_session.settings.text_scale_index)


func _make_language_row() -> Control:
	var card: PanelContainer = UiKit.card()
	var box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	card.add_child(box)
	box.add_child(UiKit.icon_label(&"globe", tr("SET_LANGUAGE"), &"AccentLabel", UiTokens.ACCENT))
	_language = SegmentedControl.new()
	var names: Array[String] = []
	for code: String in GameSettings.LANGUAGES:
		names.append(Localization.name_of(code))
	_language.setup(names)
	_language.selected.connect(func(index: int) -> void: _session.settings.set_language(GameSettings.LANGUAGES[index]))
	box.add_child(_language)
	return card


func _make_size_row() -> Control:
	var card: PanelContainer = UiKit.card()
	var box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	card.add_child(box)
	box.add_child(UiKit.icon_label(&"text_size", tr("SET_TEXT_SIZE"), &"AccentLabel", UiTokens.ACCENT))
	_sizes = SegmentedControl.new()
	var names: Array[String] = []
	for i: int in GameSettings.TEXT_SCALES.size():
		names.append(tr("SET_SIZE_%d" % i))
	_sizes.setup(names)
	_sizes.selected.connect(func(index: int) -> void: _session.settings.set_text_scale_index(index))
	box.add_child(_sizes)
	return card


## Bir ayar satırı: ikon + ad (+ açıklama) + anahtar. Satırın tamamına dokunmak anahtarı çevirir.
func _add_toggle(box: VBoxContainer, key: String, icon_name: StringName, title_key: String, hint_key: String, getter: Callable, setter: Callable) -> void:
	var card: PanelContainer = UiKit.card()
	var row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	card.add_child(row)
	row.add_child(UiKit.icon(icon_name, UiTokens.ICON_MD, UiTokens.ACCENT))
	var texts: VBoxContainer = UiKit.vbox(2)
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title: Label = UiKit.label(tr(title_key), &"HeadingLabel", true)
	title.add_theme_font_size_override("font_size", int(float(UiTokens.FONT_BASE) * 1.0))
	texts.add_child(title)
	if hint_key != "":
		texts.add_child(UiKit.label(tr(hint_key), &"MutedLabel", true))
	row.add_child(texts)
	var toggle: ToggleSwitch = ToggleSwitch.new()
	toggle.set_meta("getter", getter)
	toggle.toggled.connect(func(v: bool) -> void: setter.call(v))
	row.add_child(toggle)
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			toggle.flip()
	)
	box.add_child(card)
	_toggles[key] = toggle


func _on_save() -> void:
	var ok: bool = _session.save_game()
	SignalBus.toast_requested.emit("MSG_SAVED" if ok else "ERR_SAVE_FAILED", [])


func _on_reset_pressed() -> void:
	_confirm_row.visible = true


func _on_reset_confirmed() -> void:
	_confirm_row.visible = false
	_session.reset_game()
	SignalBus.toast_requested.emit("MSG_RESET_DONE", [])
	close()
