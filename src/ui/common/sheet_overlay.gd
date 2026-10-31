class_name SheetOverlay
extends Control
## Alttan açılan sayfa tabanı (ayarlar, hedefler): karartma + üst köşeleri yuvarlak sayfa, başlık satırı ve kapatma düğmesi, kaydırılabilir
## içerik. Aşağıdan kayarak açılır (hareketi azalt: anında); karartmaya dokununca, kapat düğmesiyle ya da geri tuşuyla kapanır.
##
## Uygular: design/design-language.md, "Bileşenler" (alt sayfa).
##
## [codeblock]
## class_name GoalsOverlay extends SheetOverlay
## func setup(session: GameSession) -> void:
##     var box: VBoxContainer = begin(tr("GOALS_TITLE"))
##     box.add_child(...)
## [/codeblock]

## Sayfa kapandı.
signal closed

## Sayfanın üst kenarı ekran yüksekliğinin bu oranındadır.
const TOP_RATIO: float = 0.12

var _dim: ColorRect
var _sheet: PanelContainer
var _title: Label
var _tween: Tween


## Karartmayı, sayfayı ve başlık satırını kurar; içerik kutusunu döndürür (kaydırılabilir).
func begin(title_text: String) -> VBoxContainer:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.03, 0.02, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)
	_sheet = PanelContainer.new()
	_sheet.theme_type_variation = &"Sheet"
	_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sheet.anchor_top = TOP_RATIO
	_sheet.offset_top = 0.0
	add_child(_sheet)
	var outer: VBoxContainer = UiKit.vbox(UiTokens.SPACE_2)
	_sheet.add_child(outer)
	var header: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	outer.add_child(header)
	_title = UiKit.label(title_text, &"TitleLabel")
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_title)
	var close_button: FxButton = UiKit.icon_button(&"close", 72.0, UiTokens.ICON_SM)
	close_button.pressed.connect(close)
	header.add_child(close_button)
	var scroll: ScrollContainer = UiKit.scroll()
	outer.add_child(scroll)
	var box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_2)
	scroll.add_child(box)
	return box


## Sayfayı açar (aşağıdan kayarak).
func open() -> void:
	on_open()
	visible = true
	if _tween != null:
		_tween.kill()
	_dim.modulate.a = 1.0
	_slide(0.0)
	if UiMotion.reduce_motion:
		return
	_dim.modulate.a = 0.0
	_slide(size.y * 0.5)
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_dim, "modulate:a", 1.0, UiTokens.DUR_BASE)
	_tween.tween_method(_slide, size.y * 0.5, 0.0, UiTokens.DUR_SLOW).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Sayfayı kapatır.
func close() -> void:
	visible = false
	closed.emit()


## Alt sınıf: açılmadan hemen önce içeriği tazeler.
func on_open() -> void:
	pass


## Sayfayı dikeyde kaydırır (çıpaları bozmadan: üst ve alt ofset birlikte).
func _slide(amount: float) -> void:
	_sheet.offset_top = amount
	_sheet.offset_bottom = amount


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()
