class_name GoalsOverlay
extends SheetOverlay
## Hedefler sayfası: tamamlanan hedefler (tik), etkin hedef (ilerleme çubuğu, vurgulu) ve sıradakiler (soluk, kilitli) ödülleriyle listelenir.
## Yalnızca okur ve çizer; ilerleme `GoalService`'te tutulur.
##
## Uygular: design/game-brief.md, "Player goal" (oturumun tamamlanmış hissi); design/design-language.md.

var _session: GameSession
var _box: VBoxContainer


func setup(session: GameSession) -> void:
	_session = session
	_box = begin(tr("GOALS_TITLE"))
	SignalBus.goals_changed.connect(_on_changed)
	refresh()


func on_open() -> void:
	refresh()


func _on_changed() -> void:
	if visible:
		refresh()


func refresh() -> void:
	if _box == null:
		return
	UiKit.clear(_box)
	var goals: GoalService = _session.goals
	var summary: PanelContainer = UiKit.card("CardRaised")
	var summary_box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	summary.add_child(summary_box)
	summary_box.add_child(UiKit.label(tr("GOALS_PROGRESS") % [goals.completed_count(), goals.defs.size()], &"HeadingLabel"))
	var overall: ProgressBar = ProgressBar.new()
	overall.show_percentage = false
	overall.max_value = float(maxi(goals.defs.size(), 1))
	overall.value = float(goals.completed_count())
	overall.custom_minimum_size = Vector2(0.0, 14.0)
	summary_box.add_child(overall)
	_box.add_child(summary)
	var current: GoalDef = goals.current()
	for def: GoalDef in goals.defs:
		_box.add_child(_make_card(def, goals.is_done(def), def == current))


func _make_card(def: GoalDef, done: bool, active: bool) -> Control:
	var goals: GoalService = _session.goals
	var card: PanelContainer = UiKit.card("CardAccent" if active else "Card")
	var row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	card.add_child(row)
	var icon_name: StringName = &"check" if done else (&"target" if active else &"lock")
	var tint: Color = UiTokens.ACCENT if (done or active) else UiTokens.TEXT_DIM
	var icon: TextureRect = UiKit.icon(icon_name, UiTokens.ICON_MD, tint)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var texts: VBoxContainer = UiKit.vbox(4)
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title: Label = UiKit.label(GoalText.title(def), &"HeadingLabel", true)
	if not (done or active):
		title.modulate = Color(1, 1, 1, 0.55)
	texts.add_child(title)
	texts.add_child(UiKit.label(GoalText.description(def), &"MutedLabel", true))
	if active:
		var bar: ProgressBar = ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = float(def.target)
		bar.value = float(goals.progress_of(def))
		bar.custom_minimum_size = Vector2(0.0, 12.0)
		texts.add_child(bar)
		texts.add_child(UiKit.label(GoalText.progress_text(goals.progress_of(def), def.target), &"SmallLabel"))
	row.add_child(texts)
	var reward: CreditTag = UiKit.price_tag(def.reward, &"AccentLabel" if not done else &"MutedLabel")
	reward.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(reward)
	card.modulate = Color(1, 1, 1, 0.7) if done else Color.WHITE
	return card
