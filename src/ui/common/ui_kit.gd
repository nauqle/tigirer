class_name UiKit
extends RefCounted
## Arayüz yapı taşları: etiket, düğme, kart, ikon, çip, kutu ve kısa yardımcılar. Stil tema varyasyonlarından gelir (`UiTheme`);
## burada renk/boyut/süre sabitlenmez, `UiTokens` kullanılır. Metinler çağıranın `tr()` ile verdiği çevrilmiş metinlerdir.
##
## Uygular: design/design-language.md, "Bileşenler".
##
## [codeblock]
## var title: Label = UiKit.label(tr("TAB_FARM"), &"TitleLabel")
## var buy: Button = UiKit.button(tr("BTN_BUY"), &"PrimaryButton", UiTokens.TOUCH_MIN, &"upgrades")
## var chip: PanelContainer = UiKit.chip(tr("HUD_DAY") % 3, &"day")
## UiKit.report(session.buy_irrigation(0, 0))   # sonucu bildirim olarak gösterir
## [/codeblock]

## Dokunmatik için en küçük düğme yüksekliği (piksel).
const MIN_BUTTON_HEIGHT: float = UiTokens.TOUCH_MIN
## Metin içinde kredi simgesinin geleceği yeri işaretler ("+{c}250"): sembol glifi yerine renkli ikon çizilir.
const CREDIT_MARK: String = "{c}"


static func label(text: String, variation: StringName = &"", wrap: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var item: Label = Label.new()
	item.text = text
	item.horizontal_alignment = align
	if variation != &"":
		item.theme_type_variation = variation
	if wrap:
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.custom_minimum_size = Vector2(10.0, 0.0)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item


## Metin içindeki `{c}` işaretlerini renkli kredi ikonuna çeviren etiket: işaret yoksa düz `Label`, varsa yan yana parça + ikon.
static func credit_text(text: String, variation: StringName = &"", wrap: bool = false) -> Control:
	if not text.contains(CREDIT_MARK):
		return label(text, variation, wrap)
	var row: HBoxContainer = hbox(2)
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var parts: PackedStringArray = text.split(CREDIT_MARK)
	for i: int in parts.size():
		if parts[i] != "":
			var piece: Label = label(parts[i], variation)
			piece.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(piece)
		if i < parts.size() - 1:
			row.add_child(icon(&"credit", UiTokens.ICON_SM * 0.8))
	return row


## Metinden kredi işaretini temizler (düz metin gereken yerler: testler, erişilebilirlik).
static func plain_text(text: String) -> String:
	return text.replace(CREDIT_MARK, "")


## Düğme (`FxButton`: basma geri bildirimi + ses). `icon_name` verilirse metnin soluna ikon konur.
static func button(text: String, variation: StringName = &"", min_height: float = MIN_BUTTON_HEIGHT, icon_name: StringName = &"") -> FxButton:
	var item: FxButton = FxButton.new()
	item.text = text
	if variation != &"":
		item.theme_type_variation = variation
	item.custom_minimum_size = Vector2(0.0, min_height)
	if icon_name != &"":
		set_button_icon(item, icon_name)
	return item


## Düğmenin ikonunu ayarlar (boyut belirteçten, renk tema ikon renginden).
static func set_button_icon(item: Button, icon_name: StringName, size: float = UiTokens.ICON_SM) -> void:
	item.icon = UiIcons.get_icon(icon_name)
	item.expand_icon = true
	# Metinli düğmede ikon metnin soluna oturur; yalnızca ikonlu düğmede ortalanır (aksi halde metinle üst üste biner).
	item.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT if item.text != "" else HORIZONTAL_ALIGNMENT_CENTER
	item.add_theme_constant_override("icon_max_width", int(size))


## Yalnızca ikonlu yuvarlak düğme (üst çubuk, ok düğmeleri).
static func icon_button(icon_name: StringName, size: float = 76.0, icon_size: float = UiTokens.ICON_SM) -> FxButton:
	var item: FxButton = button("", &"IconButton", size, icon_name)
	item.custom_minimum_size = Vector2(size, size)
	set_button_icon(item, icon_name, icon_size)
	return item


## Boyanabilir ikon.
static func icon(icon_name: StringName, size: float = UiTokens.ICON_MD, tint: Color = UiTokens.TEXT) -> TextureRect:
	var item: TextureRect = TextureRect.new()
	item.texture = UiIcons.get_icon(icon_name)
	item.custom_minimum_size = Vector2(size, size)
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.modulate = Color.WHITE if icon_name == &"credit" else tint
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item


## Yan yana ikon + etiket.
static func icon_label(icon_name: StringName, text: String, variation: StringName = &"", tint: Color = UiTokens.TEXT, icon_size: float = UiTokens.ICON_SM) -> HBoxContainer:
	var row: HBoxContainer = hbox(UiTokens.SPACE_1)
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(icon(icon_name, icon_size, tint))
	var text_label: Label = label(text, variation)
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(text_label)
	return row


## Küçük hap biçimli etiket (isteğe bağlı ikonlu). `variation`: `Chip`, `ChipGold`, `ChipAccent`.
static func chip(text: String, icon_name: StringName = &"", variation: StringName = &"Chip", tint: Color = UiTokens.TEXT) -> PanelContainer:
	var item: PanelContainer = PanelContainer.new()
	item.theme_type_variation = variation
	item.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = hbox(UiTokens.SPACE_1)
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if icon_name != &"":
		row.add_child(icon(icon_name, UiTokens.ICON_SM * 0.8, tint))
	var text_label: Label = label(text, &"SmallLabel")
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(text_label)
	item.add_child(row)
	return item


## Fiyat çipi: kredi ikonu + tutar (düğme içinde ya da yanında).
static func price_tag(amount: int, variation: StringName = &"SmallLabel") -> CreditTag:
	var tag: CreditTag = CreditTag.new()
	tag.setup(variation, UiTokens.ICON_SM * 0.8)
	tag.set_amount(amount, false)
	return tag


## Bölüm başlığı: ikon + başlık yazısı.
static func section_title(text: String, icon_name: StringName = &"") -> Control:
	if icon_name == &"":
		return label(text, &"HeadingLabel")
	return icon_label(icon_name, text, &"HeadingLabel", UiTokens.ACCENT, UiTokens.ICON_MD)


## Kart; içine tek çocuk eklenir (genelde bir kutu). `variation`: `Card`, `CardRaised`, `CardAccent`, `CardUv`, `CardWarn`.
static func card(variation: StringName = &"Card") -> PanelContainer:
	var item: PanelContainer = PanelContainer.new()
	item.theme_type_variation = variation
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item


static func vbox(separation: int = -1) -> VBoxContainer:
	var item: VBoxContainer = VBoxContainer.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if separation >= 0:
		item.add_theme_constant_override("separation", separation)
	return item


static func hbox(separation: int = -1) -> HBoxContainer:
	var item: HBoxContainer = HBoxContainer.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if separation >= 0:
		item.add_theme_constant_override("separation", separation)
	return item


## Boş, genişleyen aralık.
static func spacer() -> Control:
	var item: Control = Control.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item


## Dikey kaydırılan içerik alanı: dokunmatik sürükleme ile kayar, yatay kaydırma kapalı.
static func scroll() -> ScrollContainer:
	var item: ScrollContainer = ScrollContainer.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return item


## Bir düğümün tüm çocuklarını (hemen) kaldırır ve siler.
static func clear(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()


## Komut sonucunda mesaj anahtarı varsa oyuncuya bildirim gösterir (SignalBus üzerinden; arayüz bildirimi kendisi çizmez).
static func report(result: CommandResult) -> void:
	if result.message_key != "":
		SignalBus.toast_requested.emit(result.message_key, result.args)


## Saniyeyi "d:ss" ya da "s:dd:ss" metnine çevirir.
static func clock_text(seconds: float) -> String:
	return UiFormat.clock(seconds)
