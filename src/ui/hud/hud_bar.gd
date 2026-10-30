class_name HudBar
extends PanelContainer
## Üst çubuk: kredi, oyun günü, hız düğmesi, menü düğmesi, itibar ve haber şeridi. Yalnızca gösterir; hız değişimi
## `GameSession.set_speed` komutuyla yapılır, değerler SignalBus olaylarıyla güncellenir.
##
## Uygular: design/game-brief.md, FAZ 5 mobil arayüz (kredi, zaman, borsa haberi her ekranda görünür).

## Menü (ayarlar) düğmesine basıldı.
signal menu_requested

const _SPEEDS: Array[float] = [1.0, 2.0, 5.0]

var _session: GameSession
var _credits: Label
var _day: Label
var _speed: Button
var _reputation: Label
var _news: Label
var _reduce_motion: bool = false
var _last_credits: int = -1


## Oturumu bağlar, arayüzü kurar ve olaylara abone olur.
func setup(session: GameSession) -> void:
	_session = session
	var rows: VBoxContainer = UiKit.vbox(8)
	add_child(rows)
	var top: HBoxContainer = UiKit.hbox(14)
	rows.add_child(top)
	_credits = UiKit.label("", &"BigLabel")
	top.add_child(_credits)
	top.add_child(UiKit.spacer())
	_day = UiKit.label("", &"AccentLabel")
	top.add_child(_day)
	_speed = UiKit.button("", &"TabButton", 64.0)
	_speed.custom_minimum_size.x = 110.0
	_speed.pressed.connect(_on_speed_pressed)
	top.add_child(_speed)
	var menu: Button = UiKit.button(tr("HUD_MENU"), &"TabButton", 64.0)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	top.add_child(menu)
	var bottom: HBoxContainer = UiKit.hbox(14)
	rows.add_child(bottom)
	_reputation = UiKit.label("", &"MutedLabel")
	bottom.add_child(_reputation)
	_news = UiKit.label("", &"SmallLabel")
	_news.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_news.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_news.clip_text = true
	bottom.add_child(_news)

	SignalBus.credits_changed.connect(_on_credits_changed)
	SignalBus.reputation_changed.connect(_on_reputation_changed)
	SignalBus.day_changed.connect(_on_day_changed)
	SignalBus.speed_changed.connect(_on_speed_changed)
	SignalBus.market_event_started.connect(_on_market_event)
	SignalBus.market_event_ended.connect(_on_market_event)
	SignalBus.game_reloaded.connect(refresh)
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


func set_reduce_motion(value: bool) -> void:
	_reduce_motion = value


func _on_credits_changed(credits: int) -> void:
	_credits.text = "◆ %d" % credits
	if _last_credits >= 0 and credits > _last_credits and not _reduce_motion:
		_credits.pivot_offset = Vector2(0.0, _credits.size.y * 0.5)
		var tween: Tween = create_tween()
		tween.tween_property(_credits, "scale", Vector2(1.12, 1.12), 0.08)
		tween.tween_property(_credits, "scale", Vector2.ONE, 0.18)
	_last_credits = credits


func _on_reputation_changed(reputation: int) -> void:
	_reputation.text = tr("HUD_REP") % reputation


func _on_day_changed(day: int) -> void:
	_day.text = tr("HUD_DAY") % day


func _on_speed_changed(speed: float) -> void:
	_speed.text = "×%d" % int(round(speed)) if speed > 0.0 else "II"


func _on_speed_pressed() -> void:
	var current: int = _SPEEDS.find(_session.time.speed)
	_session.set_speed(_SPEEDS[(current + 1) % _SPEEDS.size()])


func _on_market_event(_event_def: MarketEventDef) -> void:
	_update_news()


## Haber şeridi: süren ilk olay (▲ zam / ▼ düşüş), yoksa son başlık, yoksa "borsa sakin".
func _update_news() -> void:
	if not _session.market.active_events.is_empty():
		var event_def: MarketEventDef = _session.market.active_events[0].def
		_news.text = "%s %s" % ["▲" if event_def.is_positive() else "▼", event_def.headline]
		_news.theme_type_variation = &"GoodLabel" if event_def.is_positive() else &"BadLabel"
	elif not _session.market.news.is_empty():
		_news.text = _session.market.news[0]
		_news.theme_type_variation = &"SmallLabel"
	else:
		_news.text = tr("HUD_NEWS_QUIET")
		_news.theme_type_variation = &"MutedLabel"
