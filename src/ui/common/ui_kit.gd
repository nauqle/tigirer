class_name UiKit
extends RefCounted
## Arayüz yapı taşları: etiket, düğme, kart, kutu ve kısa yardımcılar. Stil tema varyasyonlarından gelir (UiTheme);
## burada renk/boyut sabitlenmez. Metinler çağıranın `tr()` ile verdiği çevrilmiş metinlerdir.
##
## [codeblock]
## var title: Label = UiKit.label(tr("TAB_FARM"), &"HeadingLabel")
## var buy: Button = UiKit.button(tr("BTN_BUY"), &"PrimaryButton")
## UiKit.report(session.buy_irrigation(0, 0))   # sonucu bildirim olarak gösterir
## [/codeblock]

## Dokunmatik için en küçük düğme yüksekliği (piksel).
const MIN_BUTTON_HEIGHT: float = 84.0


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


static func button(text: String, variation: StringName = &"", min_height: float = MIN_BUTTON_HEIGHT) -> Button:
	var item: Button = Button.new()
	item.text = text
	if variation != &"":
		item.theme_type_variation = variation
	item.custom_minimum_size = Vector2(0.0, min_height)
	item.focus_mode = Control.FOCUS_NONE
	return item


## Kenarlıklı kart; içine tek çocuk eklenir (genelde bir kutu).
static func card() -> PanelContainer:
	var item: PanelContainer = PanelContainer.new()
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
	var total: int = maxi(int(seconds), 0)
	if total >= 3600:
		return "%d:%02d:%02d" % [total / 3600, (total % 3600) / 60, total % 60]
	return "%d:%02d" % [total / 60, total % 60]
