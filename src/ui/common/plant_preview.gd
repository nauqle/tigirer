class_name PlantPreview
extends Control
## Düzen içinde küçük bir bitki önizlemesi: bir `PlantInstance`'ı kapsayıcının alt ortasına yerleştirir ve boyuta göre ölçekler.
## Tohum, çocuk, ürün ve Seed-Dex kartlarında kullanılır. Durum tutmaz; gen verilir, çizer.
##
## Uygular: design/game-brief.md, "Prosedürel görselleştirme" (her ekranda aynı bitki çizimi).
##
## [codeblock]
## var preview: PlantPreview = PlantPreview.new()
## preview.custom_minimum_size = Vector2(160, 190)
## preview.show_gene(gene, ruleset)
## [/codeblock]

const PLANT_SCENE: PackedScene = preload("res://src/gameplay/plants/plant_instance.tscn")
## Tam büyümüş bitkinin tasarım yüksekliği (yaklaşık, ölçekleme için).
const _DESIGN_HEIGHT: float = 420.0

var _plant: PlantInstance
var _ruleset: GeneticsRuleset
var _dim: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(_layout)
	_layout()


## Verilen genotipi çizer; `growth` 0..1 (varsayılan olgun). `dim` doğruysa solgun/gölge görünür.
func show_gene(gene: PlantGene, ruleset: GeneticsRuleset, growth: float = 1.0, dim: bool = false) -> void:
	_ruleset = ruleset
	_dim = dim
	if _plant == null:
		_plant = PLANT_SCENE.instantiate() as PlantInstance
		_plant.sway_enabled = false
		_plant.ruleset = ruleset
		add_child(_plant)
	_plant.growth = growth
	_plant.gene = gene
	_plant.modulate = Color(0.25, 0.3, 0.35, 0.85) if dim else Color.WHITE
	_layout()


## Salınımı açar/kapatır (hareketi azalt ayarı).
func set_sway(enabled: bool) -> void:
	if _plant != null:
		_plant.sway_enabled = enabled


func _layout() -> void:
	if _plant == null:
		return
	var fit: float = minf(size.y / _DESIGN_HEIGHT, size.x / 280.0)
	_plant.scale = Vector2.ONE * maxf(fit, 0.05)
	_plant.position = Vector2(size.x * 0.5, size.y - 6.0)
