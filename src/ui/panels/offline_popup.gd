class_name OfflinePopup
extends Control
## "Hoş geldin" penceresi: oyuncu uzaktayken ne olduğunu (dron hasadı ve kazanç, bekleyen ve aşırı olgunlaşan bitkiler) özetler.
## Kazanç sayarak yükselir. Yalnızca gösterir; hesap `OfflineProgress`'te yapılmıştır.
##
## Uygular: design/game-brief.md, FAZ 5 "çevrimdışı kazanç [Idle/Overgrowth]"; design/design-language.md, "Geri bildirim".

## Pencere kapatıldı.
signal closed

var _body: VBoxContainer
var _card: PanelContainer


func setup() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.01, 0.03, 0.02, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_card = UiKit.card("CardRaised")
	_card.custom_minimum_size = Vector2(900.0, 0.0)
	center.add_child(_card)
	_body = UiKit.vbox(UiTokens.SPACE_2)
	_card.add_child(_body)


## Raporu gösterir.
func show_report(report: OfflineReport) -> void:
	UiKit.clear(_body)
	var hero: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.add_child(UiKit.icon(&"night", UiTokens.ICON_LG, UiTokens.UV))
	_body.add_child(hero)
	_body.add_child(UiKit.label(tr("OFFLINE_TITLE"), &"TitleLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	var minutes: int = int(report.seconds_away / 60.0)
	_body.add_child(UiKit.label(tr("OFFLINE_AWAY") % [minutes / 60, minutes % 60], &"MutedLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	if report.capped:
		_body.add_child(UiKit.label(tr("OFFLINE_CAPPED") % int(report.seconds_simulated / 3600.0), &"MutedLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	var rows: Array[Control] = []
	if report.harvests > 0:
		var earned: PanelContainer = UiKit.card("CardAccent")
		var earned_box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
		earned.add_child(earned_box)
		earned_box.add_child(UiKit.icon_label(&"drone", tr("OFFLINE_HARVESTS") % [report.harvests, report.harvested_units], &"SmallLabel", UiTokens.ACCENT))
		var tag: CreditTag = CreditTag.new()
		tag.setup(&"DisplayLabel", UiTokens.ICON_LG * 0.7)
		tag.alignment = BoxContainer.ALIGNMENT_BEGIN
		earned_box.add_child(tag)
		tag.set_amount(0, false)
		tag.set_amount(int(round(report.harvested_value)), true)
		rows.append(earned)
	if report.waiting_mature > 0:
		var waiting: PanelContainer = UiKit.card()
		waiting.add_child(UiKit.icon_label(&"plant", tr("OFFLINE_WAITING") % report.waiting_mature, &"AccentLabel", UiTokens.ACCENT))
		rows.append(waiting)
	if report.overgrown > 0:
		var lost: PanelContainer = UiKit.card("CardWarn")
		var lost_row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
		lost_row.add_child(UiKit.icon(&"trend_down", UiTokens.ICON_SM, UiTokens.BLOOM))
		lost_row.add_child(UiKit.credit_text(tr("OFFLINE_OVERGROWN") % [report.overgrown, UiFormat.number(int(round(report.value_lost)))], &"BadLabel"))
		lost.add_child(lost_row)
		rows.append(lost)
	for row: Control in rows:
		_body.add_child(row)
	var ok: FxButton = UiKit.button(tr("BTN_OK"), &"PrimaryButton", 96.0)
	ok.pressed.connect(close)
	_body.add_child(ok)
	visible = true
	UiMotion.pop_in(_card)
	UiMotion.stagger_in(rows, 0.08)


func close() -> void:
	visible = false
	closed.emit()
