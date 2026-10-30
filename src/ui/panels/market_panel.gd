class_name MarketPanel
extends GamePanel
## Pazar sekmesi: borsa haberleri ve süren olaylar, ürün yığınları (fiyat eğilimiyle, tek ya da toplu sat), VIP siparişler
## (koşul, ilerleme, ödül, kalan süre, teslim). Satış ve teslim `GameSession` komutlarıdır; fiyatlar ve süreler yalnızca okunur.
##
## Uygular: design/game-brief.md, FAZ 3 (dinamik borsa, haber olayları, envanter yönetimi, VIP müşteri kontratları).

var _news_box: VBoxContainer
var _stock_box: VBoxContainer
var _orders_box: VBoxContainer
var _sell_all: Button
var _event_timers: Array[Label] = []
var _event_defs: Array[MarketEventDef] = []
var _order_timers: Dictionary = {}  # sipariş no -> Label
var _timer: Timer


func _build() -> void:
	var scroll: ScrollContainer = UiKit.scroll()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var column: VBoxContainer = UiKit.vbox(14)
	scroll.add_child(column)

	column.add_child(UiKit.label(tr("MARKET_NEWS"), &"HeadingLabel"))
	var news_card: PanelContainer = UiKit.card()
	_news_box = UiKit.vbox(6)
	news_card.add_child(_news_box)
	column.add_child(news_card)

	var stock_header: HBoxContainer = UiKit.hbox(12)
	column.add_child(stock_header)
	stock_header.add_child(UiKit.label(tr("MARKET_STOCK"), &"HeadingLabel"))
	stock_header.add_child(UiKit.spacer())
	_sell_all = UiKit.button("", &"PrimaryButton", 76.0)
	_sell_all.pressed.connect(func() -> void: UiKit.report(session.sell_everything()))
	stock_header.add_child(_sell_all)
	_stock_box = UiKit.vbox(12)
	column.add_child(_stock_box)

	column.add_child(UiKit.label(tr("MARKET_ORDERS"), &"HeadingLabel"))
	_orders_box = UiKit.vbox(12)
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
	_rebuild_news()
	_rebuild_stock()
	_rebuild_orders()


func _refresh_if_visible() -> void:
	if is_visible_in_tree():
		refresh()


func _on_order_event(_order: Order) -> void:
	_refresh_if_visible()


# ------------------------------------------------------------------- haberler


func _rebuild_news() -> void:
	UiKit.clear(_news_box)
	_event_timers.clear()
	_event_defs.clear()
	var market: MarketService = session.market
	if market.active_events.is_empty() and market.news.is_empty():
		_news_box.add_child(UiKit.label(tr("HUD_NEWS_QUIET"), &"MutedLabel"))
		return
	for active: MarketService.ActiveEvent in market.active_events:
		var row: HBoxContainer = UiKit.hbox(10)
		var good: bool = active.def.is_positive()
		var headline: Label = UiKit.label("%s %s  ×%.2f" % ["▲" if good else "▼", active.def.headline, active.def.price_multiplier], &"GoodLabel" if good else &"BadLabel", true)
		headline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(headline)
		var remaining: Label = UiKit.label("", &"MutedLabel")
		row.add_child(remaining)
		_event_timers.append(remaining)
		_event_defs.append(active.def)
		_news_box.add_child(row)
		_news_box.add_child(UiKit.label(active.def.body, &"MutedLabel", true))
	var shown: int = 0
	for headline_text: String in market.news:
		if shown >= 3:
			break
		_news_box.add_child(UiKit.label("• " + headline_text, &"SmallLabel", true))
		shown += 1
	_update_timers()


# --------------------------------------------------------------------- ürünler


func _rebuild_stock() -> void:
	UiKit.clear(_stock_box)
	var stacks: Array[ProduceStack] = session.inventory.stacks()
	var total: int = 0
	for stack: ProduceStack in stacks:
		total += session.market.quote(stack, stack.count)
	_sell_all.text = tr("MARKET_SELL_ALL") % total
	_sell_all.disabled = stacks.is_empty()
	if stacks.is_empty():
		_stock_box.add_child(UiKit.label(tr("MARKET_EMPTY"), &"MutedLabel", true))
		return
	for stack: ProduceStack in stacks:
		_stock_box.add_child(_make_stack_row(stack))


func _make_stack_row(stack: ProduceStack) -> Control:
	var card: PanelContainer = UiKit.card()
	var row: HBoxContainer = UiKit.hbox(12)
	card.add_child(row)
	var preview: PlantPreview = PlantPreview.new()
	preview.custom_minimum_size = Vector2(120.0, 150.0)
	row.add_child(preview)
	preview.show_gene(stack.gene, session.catalog.ruleset, 1.0)
	preview.set_sway(false)
	var info: VBoxContainer = UiKit.vbox(4)
	row.add_child(info)
	info.add_child(UiKit.label(GeneSummary.stack_title(stack, session.catalog.ruleset), &"AccentLabel", true))
	var multiplier: float = session.market.multiplier(stack.fruit_id(), stack.phenotype.mutations)
	var arrow: String = "▲" if multiplier > 1.05 else ("▼" if multiplier < 0.95 else "▬")
	var variation: StringName = &"GoodLabel" if multiplier > 1.05 else (&"BadLabel" if multiplier < 0.95 else &"SmallLabel")
	info.add_child(UiKit.label("%s ◆%d  ×%d" % [arrow, session.market.unit_price(stack), stack.count], variation))
	info.add_child(UiKit.label(tr("MARKET_AVG") % stack.average_value(), &"MutedLabel"))
	var buttons: VBoxContainer = UiKit.vbox(8)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(buttons)
	var one: Button = UiKit.button(tr("MARKET_SELL_ONE"), &"", 70.0)
	one.custom_minimum_size.x = 190.0
	one.pressed.connect(func() -> void: UiKit.report(session.sell(stack.signature, 1)))
	buttons.add_child(one)
	var all: Button = UiKit.button(tr("MARKET_SELL_STACK") % session.market.quote(stack, stack.count), &"PrimaryButton", 70.0)
	all.custom_minimum_size.x = 190.0
	all.pressed.connect(func() -> void: UiKit.report(session.sell_all_of(stack.signature)))
	buttons.add_child(all)
	return card


# -------------------------------------------------------------------- siparişler


func _rebuild_orders() -> void:
	UiKit.clear(_orders_box)
	_order_timers.clear()
	if session.orders.orders.is_empty():
		_orders_box.add_child(UiKit.label(tr("MARKET_NO_ORDERS"), &"MutedLabel", true))
		return
	for order: Order in session.orders.orders:
		_orders_box.add_child(_make_order_card(order))
	_update_timers()


func _make_order_card(order: Order) -> Control:
	var card: PanelContainer = UiKit.card()
	var box: VBoxContainer = UiKit.vbox(6)
	card.add_child(box)
	var header: HBoxContainer = UiKit.hbox(10)
	box.add_child(header)
	var title: Label = UiKit.label(order.title, &"AccentLabel", true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var remaining: Label = UiKit.label("", &"MutedLabel")
	header.add_child(remaining)
	_order_timers[order.id] = remaining
	box.add_child(UiKit.label(order.customer, &"MutedLabel"))
	box.add_child(UiKit.label(GeneSummary.order_requirement(order, session.catalog.ruleset), &"SmallLabel", true))
	var have: int = session.orders.eligible_count(order, session.inventory)
	var footer: HBoxContainer = UiKit.hbox(10)
	box.add_child(footer)
	footer.add_child(UiKit.label(tr("ORDER_HAVE") % [mini(have, order.quantity), order.quantity], &"GoodLabel" if have >= order.quantity else &"SmallLabel"))
	footer.add_child(UiKit.spacer())
	footer.add_child(UiKit.label("+%d ◆" % order.reward, &"GoldLabel"))
	var deliver: Button = UiKit.button(tr("ORDER_DELIVER"), &"PrimaryButton", 76.0)
	deliver.disabled = have < order.quantity
	deliver.pressed.connect(func() -> void: UiKit.report(session.fulfil_order(order.id)))
	box.add_child(deliver)
	return card


## Her saniye: olay ve sipariş geri sayımlarını günceller (ağacı yeniden kurmadan).
func _update_timers() -> void:
	if session == null or not is_visible_in_tree():
		return
	for i: int in _event_timers.size():
		for active: MarketService.ActiveEvent in session.market.active_events:
			if active.def == _event_defs[i]:
				_event_timers[i].text = UiKit.clock_text(active.remaining)
	for order_id: int in _order_timers.keys():
		var order: Order = session.orders.get_order(order_id)
		if order != null:
			(_order_timers[order_id] as Label).text = UiKit.clock_text(order.expires_at - session.time.game_seconds)
