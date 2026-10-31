class_name HudBar
extends PanelContainer
## Üst çubuk (cam yüzey): kredi (sayarak yükselen), gün ve gün ilerlemesi, hız ve menü düğmeleri, itibar ve haber şeridi.
## Yalnızca gösterir; hız değişimi `GameSession.set_speed` komutuyla yapılır, değerler SignalBus olaylarıyla güncellenir.
## Kredi artınca küçük bir "+N" yükselip kaybolur; hareketi azalt açıkken yalnızca sayı değişir.
##
## Uygular: design/design-language.md, "Gezinme" (HUD); design/game-brief.md, FAZ 5 mobil arayüz (kredi, zaman, borsa haberi
## her ekranda görünür).

## Menü (ayarlar) düğmesine basıldı.
signal menu_requested
## Hedef çipine basıldı.
signal goal_requested

const _SPEEDS: Array[float] = [1.0, 2.0, 5.0]

var _session: GameSession
var _credits: CreditTag
var _day_icon: TextureRect
var _day_label: Label
var _day_bar: ProgressBar
var _speed: FxButton
var _reputation: Label
var _news: Label
var _news_icon: TextureRect
var _news_row: HBoxContainer
var _goal_chip: FxButton
var _goal_icon: TextureRect
var _goal_title: Label
var _goal_count: Label
var _goal_bar: ProgressBar
var _float_layer: Control
var _gain_label: Label
var _gain_tween: Tween
var _gain_total: int = 0
var _gain_origin: Vector2 = Vector2.ZERO
var _last_credits: int = -1
var _colorblind: bool = false


## Oturumu bağlar, arayüzü kurar ve olaylara abone olur.
func setup(session: GameSession) -> void:
	_session = session
	theme_type_variation = &"Glass"
	var rows: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	add_child(rows)

	var top: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	rows.add_child(top)
	_credits = CreditTag.new()
	_credits.setup(&"DisplayLabel", UiTokens.ICON_LG * 0.62)
	top.add_child(_credits)
	top.add_child(UiKit.spacer())
	var day_chip: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	day_chip.size_flags_horizontal = Control.SIZE_SHRINK_END
	_day_icon = UiKit.icon(&"day", UiTokens.ICON_SM, UiTokens.SAP)
	day_chip.add_child(_day_icon)
	_day_label = UiKit.label("", &"AccentLabel")
	_day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	day_chip.add_child(_day_label)
	top.add_child(day_chip)
	_speed = UiKit.button("", &"IconButton", 68.0)
	_speed.custom_minimum_size = Vector2(0.0, 68.0)
	_speed.tooltip_text = tr("HUD_SPEED_TIP")
	_speed.pressed.connect(_on_speed_pressed)
	top.add_child(_speed)
	var menu: FxButton = UiKit.icon_button(&"menu", 68.0, UiTokens.ICON_SM)
	menu.tooltip_text = tr("HUD_MENU_TIP")
	menu.pressed.connect(func() -> void: menu_requested.emit())
	top.add_child(menu)

	_day_bar = ProgressBar.new()
	_day_bar.theme_type_variation = &"AquaProgress"
	_day_bar.show_percentage = false
	_day_bar.max_value = 1.0
	_day_bar.step = 0.001
	_day_bar.custom_minimum_size = Vector2(0.0, 6.0)
	rows.add_child(_day_bar)

	var bottom: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	rows.add_child(bottom)
	var rep_row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	rep_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rep_row.add_child(UiKit.icon(&"star", UiTokens.ICON_SM * 0.85, UiTokens.SAP))
	_reputation = UiKit.label("", &"MutedLabel")
	_reputation.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rep_row.add_child(_reputation)
	bottom.add_child(rep_row)
	_goal_chip = _make_goal_chip()
	bottom.add_child(_goal_chip)

	_news_row = UiKit.hbox(UiTokens.SPACE_1)
	_news_icon = UiKit.icon(&"news", UiTokens.ICON_SM * 0.85, UiTokens.TEXT_MUTED)
	_news_row.add_child(_news_icon)
	_news = UiKit.label("", &"SmallLabel")
	_news.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_news.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_news.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_news.clip_text = true
	_news.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_news_row.add_child(_news)
	rows.add_child(_news_row)

	_float_layer = Control.new()
	_float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_float_layer.top_level = false
	add_child(_float_layer)

	SignalBus.credits_changed.connect(_on_credits_changed)
	SignalBus.reputation_changed.connect(_on_reputation_changed)
	SignalBus.day_changed.connect(_on_day_changed)
	SignalBus.speed_changed.connect(_on_speed_changed)
	SignalBus.market_event_started.connect(_on_market_event)
	SignalBus.market_event_ended.connect(_on_market_event)
	SignalBus.game_reloaded.connect(refresh)
	SignalBus.goals_changed.connect(_update_goal)
	SignalBus.goal_completed.connect(_on_goal_completed)
	refresh()


## Tüm göstergeleri oturumdan yeniden okur.
func refresh() -> void:
	if _session == null:
		return
	_on_credits_changed(_session.wallet.credits)
	_on_reputation_changed(_session.wallet.reputation)
	_on_day_changed(_session.time.day())
	_on_speed_changed(_session.time.speed)
	_update_news()
	_update_goal()


## Renk körlüğü paleti (haber ikon/yazı renkleri).
func set_colorblind(value: bool) -> void:
	_colorblind = value
	_update_news()


## Günün evresi (0..1): gün/gece ikonu ve ilerleme çizgisi.
func set_time_of_day(phase: float) -> void:
	_day_bar.value = phase
	var daytime: bool = NightBackdrop.is_daytime(phase)
	_day_icon.texture = UiIcons.get_icon(&"day" if daytime else &"night")
	_day_icon.modulate = UiTokens.SAP if daytime else UiTokens.UV


func _on_credits_changed(credits: int) -> void:
	var gained: int = credits - _last_credits if _last_credits >= 0 else 0
	_credits.set_amount(credits, true)
	if gained > 0:
		_spawn_gain(gained)
	_last_credits = credits


## Yüzen "+N" etiketlerini hemen kaldırır.
func clear_floats() -> void:
	if _gain_tween != null and _gain_tween.is_valid():
		_gain_tween.kill()
	_gain_label = null
	UiKit.clear(_float_layer)


## "+N" yükselip kaybolur. Etiket hâlâ görünürken yeni kazanç gelirse yeni etiket açılmaz: tutar mevcut etikete eklenir ve
## etiket yeniden başlar (üst üste binen iki etiket okunmaz olurdu).
func _spawn_gain(amount: int) -> void:
	if UiMotion.reduce_motion or not is_inside_tree() or amount < 1:
		return
	if _gain_label != null and is_instance_valid(_gain_label) and _gain_label.is_inside_tree():
		_gain_total += amount
		_gain_label.text = "+%s" % UiFormat.number(_gain_total)
		_gain_label.position = _gain_origin
		_gain_label.modulate.a = 1.0
		_gain_tween.kill()
		UiMotion.bump(_gain_label)
	else:
		_gain_total = amount
		_gain_label = UiKit.label("+%s" % UiFormat.number(amount), &"GoldLabel")
		_float_layer.add_child(_gain_label)
		_gain_label.global_position = _credits.global_position + Vector2(_credits.final_width() + 14.0, 4.0)
		_gain_origin = _gain_label.position
	var gain: Label = _gain_label
	_gain_tween = gain.create_tween()
	_gain_tween.set_parallel(true)
	_gain_tween.tween_property(gain, "position:y", _gain_origin.y - 26.0, UiTokens.DUR_SLOW * 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_gain_tween.tween_property(gain, "modulate:a", 0.0, UiTokens.DUR_SLOW * 2.0).set_delay(UiTokens.DUR_SLOW)
	_gain_tween.chain().tween_callback(_finish_gain.bind(gain))


func _finish_gain(gain: Label) -> void:
	if gain == _gain_label:
		_gain_label = null
	gain.queue_free()


func _on_reputation_changed(reputation: int) -> void:
	_reputation.text = tr("HUD_REP") % reputation


func _on_day_changed(day: int) -> void:
	_day_label.text = tr("HUD_DAY") % day


func _on_speed_changed(speed: float) -> void:
	if speed > 0.0:
		_speed.text = "×%d" % int(round(speed))
		_speed.icon = null
		_speed.custom_minimum_size.x = 92.0
	else:
		_speed.text = ""
		UiKit.set_button_icon(_speed, &"pause")
		_speed.custom_minimum_size.x = 68.0


func _on_speed_pressed() -> void:
	var current: int = _SPEEDS.find(_session.time.speed)
	_session.set_speed(_SPEEDS[(current + 1) % _SPEEDS.size()])


func _on_market_event(_event_def: MarketEventDef) -> void:
	_update_news()


## Haber şeridi: süren ilk olay (▲ zam / ▼ düşüş ikon ve renkle), yoksa son başlık, yoksa "borsa sakin".
func _update_news() -> void:
	if _session == null or _news == null:
		return
	var colors: Dictionary = UiTokens.palette(_colorblind)
	if not _session.market.active_events.is_empty():
		var event_def: MarketEventDef = _session.market.active_events[0].def
		var positive: bool = event_def.is_positive()
		var tint: Color = (colors["good"] as Color) if positive else (colors["bad"] as Color)
		_news.text = tr(event_def.headline)
		_news.add_theme_color_override("font_color", tint)
		_news_icon.texture = UiIcons.get_icon(&"trend_up" if positive else &"trend_down")
		_news_icon.modulate = tint
	elif not _session.market.news.is_empty():
		_news.text = tr(_session.market.news[0])
		_news.add_theme_color_override("font_color", UiTokens.TEXT)
		_news_icon.texture = UiIcons.get_icon(&"news")
		_news_icon.modulate = UiTokens.TEXT_MUTED
	else:
		_news.text = tr("HUD_NEWS_QUIET")
		_news.add_theme_color_override("font_color", UiTokens.TEXT_MUTED)
		_news_icon.texture = UiIcons.get_icon(&"news")
		_news_icon.modulate = UiTokens.TEXT_MUTED
		_news_row.visible = false
		return
	_news_row.visible = true


## Etkin hedef çipi: bayrak + başlık + ilerleme sayısı, altında ince ilerleme çizgisi. Basınca hedef sayfası açılır.
func _make_goal_chip() -> FxButton:
	var chip: FxButton = UiKit.button("", &"ChipButton", 60.0)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16.0
	row.offset_right = -16.0
	row.offset_bottom = -6.0
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	_goal_icon = UiKit.icon(&"flag", UiTokens.ICON_SM * 0.9, UiTokens.ACCENT)
	_goal_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_goal_icon)
	_goal_title = UiKit.label("", &"SmallLabel")
	_goal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_goal_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_goal_title.clip_text = true
	_goal_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_goal_title)
	_goal_count = UiKit.label("", &"MutedLabel")
	_goal_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_goal_count)
	_goal_bar = ProgressBar.new()
	_goal_bar.show_percentage = false
	_goal_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goal_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_goal_bar.offset_left = 18.0
	_goal_bar.offset_right = -18.0
	_goal_bar.offset_top = -9.0
	_goal_bar.offset_bottom = -4.0
	chip.add_child(_goal_bar)
	chip.pressed.connect(func() -> void: goal_requested.emit())
	return chip


func _update_goal() -> void:
	if _session == null or _goal_chip == null:
		return
	var goal: GoalDef = _session.goals.current()
	if goal == null:
		_goal_icon.texture = UiIcons.get_icon(&"check")
		_goal_title.text = tr("HUD_GOALS_DONE")
		_goal_count.text = ""
		_goal_bar.max_value = 1.0
		_goal_bar.value = 1.0
		return
	_goal_icon.texture = UiIcons.get_icon(&"flag")
	_goal_title.text = GoalText.title(goal)
	_goal_count.text = "%s/%s" % [UiFormat.number(_session.goals.progress_of(goal)), UiFormat.number(goal.target)]
	_goal_bar.max_value = float(goal.target)
	_goal_bar.value = float(_session.goals.progress_of(goal))


func _on_goal_completed(_goal_id: StringName, _reward: int) -> void:
	UiMotion.bump(_goal_chip, 1.06)
