class_name SeedCard
extends FxButton
## Tohum kartı (çiftlik tohum tepsisi, laboratuvar seçimi): bitki önizlemesi, ad ve adet rozeti. Seçili kart klorofil çerçeveyle
## belirir (tema `CardButton`); seçilince hafifçe yükselir. Oyun durumuna dokunmaz; gen ve adet verilir, çizer.
##
## Uygular: design/design-language.md, "Bileşenler" (tohum kartı).

const _CARD_SIZE: Vector2 = Vector2(196.0, 214.0)

## Kartın temsil ettiği tohumun kimliği.
var uid: String = ""

var _preview: PlantPreview
var _name: Label
var _count: PanelContainer
var _count_label: Label


## Kartı kurar.
func setup(gene: PlantGene, count: int, ruleset: GeneticsRuleset, sway: bool) -> void:
	uid = gene.uid
	theme_type_variation = &"CardButton"
	toggle_mode = true
	custom_minimum_size = _CARD_SIZE
	_preview = PlantPreview.new()
	_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview.offset_top = 10.0
	_preview.offset_bottom = -52.0
	_preview.offset_left = 8.0
	_preview.offset_right = -8.0
	add_child(_preview)
	_preview.show_gene(gene, ruleset, 1.0)
	_preview.set_sway(sway)
	_name = UiKit.label(GeneSummary.title(gene, ruleset), &"SmallLabel", false, HORIZONTAL_ALIGNMENT_CENTER)
	_name.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_name.offset_top = -46.0
	_name.offset_bottom = -8.0
	_name.clip_text = true
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_name)
	_count = PanelContainer.new()
	_count.theme_type_variation = &"ChipAccent"
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_label = UiKit.label("×%d" % count, &"SmallLabel")
	_count.add_child(_count_label)
	_count.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_count.offset_left = -92.0
	_count.offset_top = 8.0
	_count.offset_right = -8.0
	_count.offset_bottom = 52.0
	add_child(_count)
	toggled.connect(_on_toggled)


func _on_toggled(pressed_now: bool) -> void:
	if pressed_now:
		UiMotion.bump(self, 1.05)
