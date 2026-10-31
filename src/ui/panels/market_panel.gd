class_name MarketPanel
extends GamePanel
## Pazar sekmesi: fiyat tablosu (meyve başına mini grafik ve yüzde değişim), borsa haberleri ve süren olaylar, ürün yığınları (fiyat
## eğilimiyle, tek ya da toplu sat), VIP siparişler (müşteri, koşul, ilerleme çubuğu, ödül, kalan süre, teslim). Satış ve teslim
## `GameSession` komutlarıdır; fiyatlar ve süreler yalnızca okunur.
##
## Uygular: design/game-brief.md, FAZ 3 (dinamik borsa, haber olayları, envanter yönetimi, VIP müşteri kontratları); design/design-language.md.

var _board_row: HBoxContainer
var _news_box: VBoxContainer
var _stock_box: VBoxContainer
var _orders_box: VBoxContainer
var _sell_all: PriceButton
var _event_timers: Array[Label] = []
var _event_defs: Array[MarketEventDef] = []
var _order_timers: Dictionary = {}  # sipariş no -> Label
var _timer: Timer


func _build() -> void:
	var scroll: ScrollContainer = UiKit.scroll()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var column: VBoxContainer = UiKit.vbox(UiTokens.SPACE_2)
	scroll.add_child(column)

	column.add_child(UiKit.section_title(tr("MARKET_BOARD"), &"market"))
	var board_scroll: ScrollContainer = ScrollContainer.new()
	board_scroll.custom_minimum_size = Vector2(0.0, 232.0)
	board_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(board_scroll)
	_board_row = UiKit.hbox(UiTokens.SPACE_1)
	_board_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	board_scroll.add_child(_board_row)

	column.add_child(UiKit.section_title(tr("MARKET_NEWS"), &"news"))
	var news_card: PanelContainer = UiKit.card()
	_news_box = UiKit.vbox(UiTokens.SPACE_1)
	news_card.add_child(_news_box)
	column.add_child(news_card)

	var stock_header: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	column.add_child(stock_header)
	var stock_title: Control = UiKit.section_title(tr("MARKET_STOCK"), &"tag")
	stock_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stock_header.add_child(stock_title)
	_sell_all = PriceButton.new()
	_sell_all.setup(tr("MARKET_SELL_ALL"), 0, &"PrimaryButton", &"", 76.0)
	_sell_all.pressed.connect(func() -> void: UiKit.report(session.sell_everything()))
	stock_header.add_child(_sell_all)
	_stock_box = UiKit.vbox(UiTokens.SPACE_2)
	column.add_child(_stock_box)

	column.add_child(UiKit.section_title(tr("MARKET_ORDERS"), &"order"))
	_orders_box = UiKit.vbox(UiTokens.SPACE_2)
	column.add_child(_orders_box)

	SignalBus.inventory_changed.connect(_refresh_if_visible)
	SignalBus.prices_changed.connect(_refresh_if_visible)
	SignalBus.order_added.connect(_on_order_event)
	SignalBus.order_completed.connect(_on_order_event)
	SignalBus.order_expired.connect(_on_order_event)
	SignalBus.game_reloaded.connect(refresh)
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.autostart = true
	_timer.timeout.connect(_update_timers)
	add_child(_timer)


func refresh() -> void:
	if _news_box == null:
		return
	_rebuild_board()
	_rebuild_news()
	_rebuild_stock()
	_rebuild_orders()


func on_shown() -> void:
	refresh()
	var cards: Array[Control] = []
	for card: Node in _board_row.get_children():
		if card is Control:
			cards.append(card as Control)
	UiMotion.stagger_in(cards, 0.06)


func _refresh_if_visible() -> void:
	if is_visible_in_tree():
		refresh()


func _on_order_event(_order: Order) -> void:
	_refresh_if_visible()


# -------------------------------------------------------------- fiyat tablosu


func _rebuild_board() -> void:
	UiKit.clear(_board_row)
	var palette: Dictionary = UiTokens.palette(session.settings.colorblind)
	for part: PlantPartDef in session.catalog.ruleset.get_parts_for_layer(PlantPartDef.Layer.FRUIT):
		var history: PackedFloat32Array = session.market.history_of(part.id)
		var index: float = session.market.price_index(part.id)
		var change: float = index - 1.0
		var up: bool = change > 0.02
		var down: bool = change < -0.02
		var tint: Color = (palette["good"] as Color) if up else ((palette["bad"] as Color) if down else UiTokens.TEXT_MUTED)
		var card: PanelContainer = UiKit.card("Card")
		card.custom_minimum_size = Vector2(300.0, 0.0)
		card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
		card.add_child(box)
		box.add_child(UiKit.label(GeneSummary.part_name(part.id, session.catalog.ruleset), &"SmallLabel"))
		var change_row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
		change_row.add_child(UiKit.icon(&"trend_up" if up else (&"trend_down" if down else &"clock"), UiTokens.ICON_SM * 0.8, tint))
		var percent_label: Label = UiKit.label(UiFormat.signed_percent(change), &"HeadingLabel")
		percent_label.add_theme_color_override("font_color", tint)
		change_row.add_child(percent_label)
		box.add_child(change_row)
		var chart: PriceChart = PriceChart.new()
		chart.custom_minimum_size = Vector2(0.0, 78.0)
		chart.set_data(history, tint if (up or down) else UiTokens.AQUA)
		box.add_child(chart)
		_board_row.add_child(card)


# ------------------------------------------------------------------- haberler


func _rebuild_news() -> void:
	UiKit.clear(_news_box)
	_event_timers.clear()
	_event_defs.clear()
	var market: MarketService = session.market
	if market.active_events.is_empty() and market.news.is_empty():
		_news_box.add_child(UiKit.label(tr("HUD_NEWS_QUIET"), &"MutedLabel"))
		return
	var palette: Dictionary = UiTokens.palette(session.settings.colorblind)
	for active: MarketService.ActiveEvent in market.active_events:
		var good: bool = active.def.is_positive()
		var tint: Color = (palette["good"] as Color) if good else (palette["bad"] as Color)
		var row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
		row.add_child(UiKit.icon(&"trend_up" if good else &"trend_down", UiTokens.ICON_SM, tint))
		var headline: Label = UiKit.label("%s  ×%s" % [tr(active.def.headline), UiFormat.decimal(active.def.price_multiplier, 2)], &"GoodLabel" if good else &"BadLabel", true)
		headline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(headline)
		var remaining: Label = UiKit.label("", &"MutedLabel")
		row.add_child(remaining)
		_event_timers.append(remaining)
		_event_defs.append(active.def)
		_news_box.add_child(row)
		_news_box.add_child(UiKit.label(tr(active.def.body), &"MutedLabel", true))
	# Etkin olay yukarıda ayrıntısıyla durur; geçmiş listesi yalnızca bitmiş olayları anar (aynı başlık iki kez görünmez).
	var active_headlines: Array[String] = []
	for active: MarketService.ActiveEvent in market.active_events:
		active_headlines.append(active.def.headline)
	var shown: int = 0
	for headline_key: String in market.news:
		if shown >= 3:
			break
		if active_headlines.has(headline_key):
			continue
		_news_box.add_child(UiKit.icon_label(&"news", tr(headline_key), &"SmallLabel", UiTokens.TEXT_DIM, UiTokens.ICON_SM * 0.7))
		shown += 1
	_update_timers()


# --------------------------------------------------------------------- ürünler


func _rebuild_stock() -> void:
	UiKit.clear(_stock_box)
	var stacks: Array[ProduceStack] = session.inventory.stacks()
	var total: int = 0
	for stack: ProduceStack in stacks:
		total += session.market.quote(stack, stack.count)
	_sell_all.set_price(total)
	_sell_all.set_enabled(not stacks.is_empty())
	if stacks.is_empty():
		var empty: PanelContainer = UiKit.card()
		empty.add_child(UiKit.label(tr("MARKET_EMPTY"), &"MutedLabel", true))
		_stock_box.add_child(empty)
		return
	for stack: ProduceStack in stacks:
		_stock_box.add_child(_make_stack_row(stack))


func _make_stack_row(stack: ProduceStack) -> Control:
	var rarity: UiTokens.Rarity = GeneSummary.rarity(stack.phenotype)
	var card: PanelContainer = UiKit.card("CardUv" if rarity == UiTokens.Rarity.MUTANT else "Card")
	var row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	card.add_child(row)
	var preview: PlantPreview = PlantPreview.new()
	preview.custom_minimum_size = Vector2(120.0, 150.0)
	row.add_child(preview)
	preview.show_gene(stack.gene, session.catalog.ruleset, 1.0)
	preview.set_sway(false)
	var info: VBoxContainer = UiKit.vbox(4)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	info.add_child(UiKit.label(GeneSummary.stack_title(stack, session.catalog.ruleset), &"HeadingLabel", true))
	var multiplier: float = session.market.multiplier(stack.fruit_id(), stack.phenotype.mutations)
	var palette: Dictionary = UiTokens.palette(session.settings.colorblind)
	var price_row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	price_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if multiplier > 1.05:
		price_row.add_child(UiKit.icon(&"trend_up", UiTokens.ICON_SM * 0.8, palette["good"] as Color))
	elif multiplier < 0.95:
		price_row.add_child(UiKit.icon(&"trend_down", UiTokens.ICON_SM * 0.8, palette["bad"] as Color))
	price_row.add_child(UiKit.price_tag(session.market.unit_price(stack), &"AccentLabel"))
	price_row.add_child(UiKit.label("×%d" % stack.count, &"MutedLabel"))
	info.add_child(price_row)
	info.add_child(UiKit.credit_text(tr("MARKET_AVG") % UiFormat.decimal(stack.average_value(), 1), &"MutedLabel"))
	var buttons: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(buttons)
	var one: PriceButton = PriceButton.new()
	one.setup(tr("MARKET_SELL_ONE"), session.market.quote(stack, 1), &"", &"", 68.0)
	one.pressed.connect(func() -> void: UiKit.report(session.sell(stack.signature, 1)))
	buttons.add_child(one)
	var all: PriceButton = PriceButton.new()
	all.setup(tr("MARKET_SELL_STACK"), session.market.quote(stack, stack.count), &"BuyButton", &"", 68.0)
	all.pressed.connect(func() -> void: UiKit.report(session.sell_all_of(stack.signature)))
	buttons.add_child(all)
	return card


# -------------------------------------------------------------------- siparişler


func _rebuild_orders() -> void:
	UiKit.clear(_orders_box)
	_order_timers.clear()
	if session.orders.orders.is_empty():
		var empty: PanelContainer = UiKit.card()
		empty.add_child(UiKit.label(tr("MARKET_NO_ORDERS"), &"MutedLabel", true))
		_orders_box.add_child(empty)
		return
	for order: Order in session.orders.orders:
		_orders_box.add_child(_make_order_card(order))
	_update_timers()


func _make_order_card(order: Order) -> Control:
	var have: int = session.orders.eligible_count(order, session.inventory)
	var ready: bool = have >= order.quantity
	var card: PanelContainer = UiKit.card("CardAccent" if ready else "Card")
	var box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	card.add_child(box)
	var header: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	box.add_child(header)
	var who: VBoxContainer = UiKit.vbox(2)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.add_child(UiKit.label(tr(order.customer).to_upper(), &"OverlineLabel"))
	who.add_child(UiKit.label(tr(order.title), &"HeadingLabel", true))
	header.add_child(who)
	var remaining_chip: PanelContainer = UiKit.chip("", &"clock", &"Chip", UiTokens.TEXT_MUTED)
	var remaining: Label = (remaining_chip.get_child(0).get_child(1)) as Label
	header.add_child(remaining_chip)
	_order_timers[order.id] = remaining
	box.add_child(UiKit.credit_text(GeneSummary.order_requirement(order, session.catalog.ruleset), &"SmallLabel", true))
	var progress: ProgressBar = ProgressBar.new()
	progress.theme_type_variation = &"ProgressBar" if ready else &"AquaProgress"
	progress.show_percentage = false
	progress.max_value = float(order.quantity)
	progress.value = float(mini(have, order.quantity))
	progress.custom_minimum_size = Vector2(0.0, 14.0)
	box.add_child(progress)
	var footer: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	box.add_child(footer)
	var have_label: Label = UiKit.label(tr("ORDER_HAVE") % [mini(have, order.quantity), order.quantity], &"GoodLabel" if ready else &"MutedLabel")
	have_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(have_label)
	footer.add_child(UiKit.spacer())
	var deliver: PriceButton = PriceButton.new()
	deliver.setup(tr("ORDER_DELIVER"), order.reward, &"BuyButton" if ready else &"", &"check", 76.0)
	deliver.set_enabled(ready)
	deliver.pressed.connect(func() -> void: UiKit.report(session.fulfil_order(order.id)))
	footer.add_child(deliver)
	return card


## Her saniye: olay ve sipariş geri sayımlarını günceller (ağacı yeniden kurmadan).
func _update_timers() -> void:
	if session == null or not is_visible_in_tree():
		return
	for i: int in _event_timers.size():
		for active: MarketService.ActiveEvent in session.market.active_events:
			if active.def == _event_defs[i]:
				_event_timers[i].text = UiFormat.clock(active.remaining)
	for order_id: int in _order_timers.keys():
		var order: Order = session.orders.get_order(order_id)
		if order != null:
			(_order_timers[order_id] as Label).text = UiFormat.clock(order.expires_at - session.time.game_seconds)
