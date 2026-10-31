class_name PriceButton
extends FxButton
## Fiyatlı eylem düğmesi: [ikon] Metin [kredi ikonu tutar]. Satın alma, satış ve çaprazlama düğmelerinin ortak biçimi; fiyat metin
## sembolüyle değil renkli kredi simgesiyle çizilir. `set_enabled(false)` düğmeyi pasifleştirir ve içeriği soldurur.
## Fiyat -1 verilirse tutar gizlenir ("MAX" gibi bitmiş durumlar).
##
## Uygular: design/design-language.md, "Bileşenler" (fiyatlı düğme).
##
## [codeblock]
## var buy: PriceButton = PriceButton.new()
## buy.setup(tr("UPG_UPGRADE"), 400, &"", &"upgrades")
## buy.set_enabled(session.wallet.can_afford(400))
## [/codeblock]

var _row: HBoxContainer
var _icon: TextureRect
var _caption: Label
var _tag: CreditTag
var _enabled: bool = true


## Düğmeyi kurar: metin, tutar (-1 = gizli), tema türü, isteğe bağlı ikon, en az yükseklik.
func setup(text_value: String, amount: int, variation: StringName = &"", icon_name: StringName = &"", min_height: float = UiTokens.TOUCH_MIN) -> void:
	if variation != &"":
		theme_type_variation = variation
	custom_minimum_size = Vector2(0.0, min_height)
	text = ""
	_row = HBoxContainer.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", UiTokens.SPACE_1)
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row.offset_left = 10.0
	_row.offset_right = -10.0
	add_child(_row)
	_icon = UiKit.icon(icon_name if icon_name != &"" else &"info", UiTokens.ICON_SM)
	_icon.visible = icon_name != &""
	_row.add_child(_icon)
	_caption = UiKit.label(text_value, &"")
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_row.add_child(_caption)
	_tag = CreditTag.new()
	_tag.setup(&"", UiTokens.ICON_SM * 0.85)
	_row.add_child(_tag)
	set_price(amount)
	_recolor()


func set_caption(text_value: String) -> void:
	_caption.text = text_value


## Düğme yazısı (gösterilen metin; testler ve erişilebilirlik için).
func caption() -> String:
	return _caption.text


## Fiyatı ayarlar; -1 tutarı gizler.
func set_price(amount: int) -> void:
	_tag.visible = amount >= 0
	if amount >= 0:
		_tag.set_amount(amount, false)


## Etkin/pasif durumu: pasifken içerik solar.
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	disabled = not enabled
	_row.modulate = Color(1, 1, 1, 1.0 if enabled else 0.42)


func is_enabled() -> bool:
	return _enabled


## Düğmenin kendi metni boş olduğundan en az genişlik içerik satırından gelir (aksi halde SHRINK düzenlerde çöker).
func _get_minimum_size() -> Vector2:
	if _row == null:
		return Vector2.ZERO
	return Vector2(_row.get_combined_minimum_size().x + 44.0, 0.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and _caption != null:
		_recolor()


## İçerik yazı ve ikon renkleri düğmenin tema renginden gelir (birincil düğmede koyu, ikincilde açık).
func _recolor() -> void:
	var tint: Color = get_theme_color("font_color")
	_caption.add_theme_color_override("font_color", tint)
	_tag.label().add_theme_color_override("font_color", tint)
	_icon.modulate = tint
