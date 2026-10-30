class_name OfflinePopup
extends Control
## "Hoş geldin" penceresi: oyuncu uzaktayken ne olduğunu (dron hasadı, bekleyen ve aşırı olgunlaşan bitkiler) özetler.
## Yalnızca gösterir; hesap `OfflineProgress`'te yapılmıştır.
##
## Uygular: design/game-brief.md, FAZ 5 "çevrimdışı kazanç [Idle/Overgrowth]".

## Pencere kapatıldı.
signal closed

var _body: VBoxContainer


func setup() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.03, 0.06, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card: PanelContainer = UiKit.card()
	card.custom_minimum_size = Vector2(900.0, 0.0)
	center.add_child(card)
	_body = UiKit.vbox(14)
	card.add_child(_body)


## Raporu gösterir.
func show_report(report: OfflineReport) -> void:
	UiKit.clear(_body)
	_body.add_child(UiKit.label(tr("OFFLINE_TITLE"), &"HeadingLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	var minutes: int = int(report.seconds_away / 60.0)
	_body.add_child(UiKit.label(tr("OFFLINE_AWAY") % [minutes / 60, minutes % 60], &"MutedLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	if report.capped:
		_body.add_child(UiKit.label(tr("OFFLINE_CAPPED") % int(report.seconds_simulated / 3600.0), &"MutedLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	if report.harvests > 0:
		_body.add_child(UiKit.label(tr("OFFLINE_HARVESTS") % [report.harvests, report.harvested_units, int(round(report.harvested_value))], &"GoodLabel", true))
	if report.waiting_mature > 0:
		_body.add_child(UiKit.label(tr("OFFLINE_WAITING") % report.waiting_mature, &"AccentLabel", true))
	if report.overgrown > 0:
		_body.add_child(UiKit.label(tr("OFFLINE_OVERGROWN") % [report.overgrown, int(round(report.value_lost))], &"BadLabel", true))
	var ok: Button = UiKit.button(tr("BTN_OK"), &"PrimaryButton", 90.0)
	ok.pressed.connect(close)
	_body.add_child(ok)
	visible = true


func close() -> void:
	visible = false
	closed.emit()
