class_name CreditTag
extends HBoxContainer
## Kredi göstergesi: renkli öz kristali ikonu + sayı (dile duyarlı binlik ayracı). `set_amount(değer, animasyonlu)` artışta sayarak
## yükselir ve kısa bir "tık" yapar. Metin sembolü (◆) KULLANMAZ: cihazın yedek fontuna bağımlı olmasın diye ikon çizilir.
##
## Uygular: design/design-language.md, "İkonografi" (kredi simgesi) ve "Hareket" (sayaç).
##
## [codeblock]
## var tag: CreditTag = CreditTag.new()
## tag.setup(&"DisplayLabel")
## tag.set_amount(1250, true)
## [/codeblock]

var amount: int = 0

var _icon: TextureRect
var _label: Label
var _first: bool = true


## Etiket türünü (tema varyasyonu) ve ikon boyutunu seçer.
func setup(label_variation: StringName = &"GoldLabel", icon_size: float = UiTokens.ICON_SM) -> void:
	add_theme_constant_override("separation", UiTokens.SPACE_1)
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon = UiKit.icon(&"credit", icon_size)
	add_child(_icon)
	_label = UiKit.label("0", label_variation)
	add_child(_label)
	set_amount(amount, false)


## Tutarı gösterir. `animated` doğruysa ve tutar arttıysa sayarak yükselir.
func set_amount(value: int, animated: bool = false) -> void:
	if _label == null:
		amount = value
		return
	var previous: int = amount
	amount = value
	if animated and not _first and value != previous:
		UiMotion.count_label(_label, previous, value, UiFormat.number)
		if value > previous:
			UiMotion.bump(_label)
	else:
		_label.text = UiFormat.number(value)
	_first = false


## Etiket düğümü (renk geçersiz kılma vb. için).
func label() -> Label:
	return _label
