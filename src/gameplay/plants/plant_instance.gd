class_name PlantInstance
extends Node2D
## Bir genotipi (PlantGene) KATMANLI sprite'larla çizen bitki düğümü: gövde + yapraklar + çiçek/meyve.
## Hangi parçanın çizileceğini genden `GeneticsEngine.express()` ile okur; genetik rengi `modulate` ile,
## mutasyon parlamasını/parıltısını `canvas_plant_tint.gdshader` ile uygular. Büyüme (0..1) filizden
## olgunluğa gövde boyunu, yaprak sayısını ve meyveyi ölçekler.
##
## Uygular: design/game-brief.md, MVP maddesi "Katmanlı prosedürel bitki: gövde + yaprak + çiçek/meyve parçaları,
## genetik renk ve parlama" (FAZ 1). Düğüm ağacı: docs/architecture/floralab-architecture.md.
##
## Sahne: res://src/gameplay/plants/plant_instance.tscn
## [codeblock]
## var plant: PlantInstance = preload("res://src/gameplay/plants/plant_instance.tscn").instantiate()
## add_child(plant)
## plant.gene = my_gene          # katmanlar yeniden kurulur
## plant.growth = 0.4            # filiz evresi
## [/codeblock]
## Davranış durumsuzdur: görünüm gen + kural seti + büyümenin işlevidir. Oyun durumu tutmaz, SignalBus'a dokunmaz.

## Katmanlar (yeniden) kurulduktan sonra yayınlanır.
signal visuals_rebuilt

const PLANT_SHADER: Shader = preload("res://assets/shaders/canvas_plant_tint.gdshader")
## Halo dokusunun kenar uzunluğu (piksel); ölçek `halo_size`'dan hesaplanır.
const _HALO_TEXTURE_SIZE: int = 256
## Faz değerinin aralığı [0, 2*PI) için, imza özetinden türetilen tamsayının bölen sabiti.
const _PHASE_STEPS: int = 6283

## Parçaların, mutasyonların ve ayarların kaynağı. Sahnede varsayılan kural seti atanmıştır.
@export var ruleset: GeneticsRuleset:
	set(value):
		ruleset = value
		rebuild()
## Çizilecek genotip. Değişince katmanlar yeniden kurulur. null = boş.
@export var gene: PlantGene:
	set(value):
		gene = value
		rebuild()
## Büyüme: 0 = tohum, ~0.3 = filiz, 1 = olgun. [0, 1]'e kırpılır.
@export_range(0.0, 1.0, 0.01) var growth: float = 1.0:
	set(value):
		growth = clampf(value, 0.0, 1.0)
		_apply_growth()

@export_group("Palet")
## Yaprakların çekildiği "yeşil" tonu (HSV hue).
@export_range(0.0, 1.0, 0.01) var leaf_green_hue: float = 0.36
## Yaprak tonunun, yeşilden genetik tona doğru ne kadar çekileceği (0 = hep yeşil, 1 = genetik ton).
@export_range(0.0, 1.0, 0.01) var leaf_hue_pull: float = 0.30
@export_range(0.0, 1.0, 0.01) var leaf_saturation: float = 0.65
@export_range(0.0, 1.0, 0.01) var leaf_value: float = 0.95
@export_range(0.0, 1.0, 0.01) var stem_saturation: float = 0.35
@export_range(0.0, 1.0, 0.01) var stem_value: float = 0.70
@export_range(0.0, 1.0, 0.01) var fruit_saturation: float = 0.80
@export_range(0.0, 1.0, 0.01) var fruit_value: float = 1.0

@export_group("Büyüme eğrisi")
## Tohumda gövdenin boyu (olgun boyun oranı).
@export_range(0.0, 1.0, 0.01) var stem_min_scale: float = 0.18
## Tohumda gövdenin eni (olgun enin oranı).
@export_range(0.0, 1.0, 0.01) var stem_min_width_scale: float = 0.55
## Gövdenin tam boya eriştiği büyüme değeri.
@export_range(0.05, 1.0, 0.01) var stem_full_at: float = 0.6
## İlk yaprağın belirmeye başladığı büyüme değeri.
@export_range(0.0, 1.0, 0.01) var leaf_start_at: float = 0.25
## Son yaprağın belirmeye başladığı büyüme değeri.
@export_range(0.0, 1.0, 0.01) var leaf_full_at: float = 0.8
## Bir yaprağın belirmeye başlamasından tam boyuna kadar geçen büyüme aralığı.
@export_range(0.01, 0.5, 0.01) var leaf_pop_span: float = 0.15
## Çiçek/meyvenin belirmeye başladığı büyüme değeri.
@export_range(0.0, 0.99, 0.01) var fruit_start_at: float = 0.85

@export_group("Yaprak yerleşimi")
@export_range(0.0, 80.0, 1.0) var leaf_base_angle_degrees: float = 28.0
## Her üst yaprakta açıya eklenen derece.
@export_range(0.0, 30.0, 1.0) var leaf_angle_step_degrees: float = 6.0
## Üst yapraklar bu oranda küçülür (her basamakta).
@export_range(0.0, 0.5, 0.01) var leaf_size_falloff: float = 0.12

@export_group("Hareket")
## Rüzgârda hafif salınım. Testlerde ve ekran görüntülerinde kapatılır (deterministik).
@export var sway_enabled: bool = true:
	set(value):
		sway_enabled = value
		_restart_sway()
@export_range(0.0, 8.0, 0.1) var sway_degrees: float = 1.8
@export_range(0.5, 8.0, 0.1) var sway_seconds: float = 2.8

@export_group("Halo")
## Parlayan mutasyonun halosunun en yüksek saydamlığı.
@export_range(0.0, 1.0, 0.01) var halo_alpha: float = 0.55
## Halonun boyutu (piksel).
@export var halo_size: Vector2 = Vector2(420.0, 420.0)
## Halonun belirmeye başladığı büyüme değeri (tam boyuna olgunlukta erişir).
@export_range(0.0, 0.99, 0.01) var halo_start_at: float = 0.3

# Halo dokusu ve malzemesi tüm bitkilerce paylaşılır (bitkiye özel parametresi yok).
static var _halo_texture: GradientTexture2D
static var _halo_material: CanvasItemMaterial

var _phenotype: PlantPhenotype
var _material: ShaderMaterial
var _sway_tween: Tween
## Havuzlanmış yaprak sprite'ları; gövdenin bağlantı sayısı kadarı kullanılır, fazlası gizlenir.
var _leaf_sprites: Array[Sprite2D] = []
var _active_leaf_count: int = 0
var _leaf_mounts: PackedVector2Array = PackedVector2Array()
var _fruit_mount: Vector2 = Vector2.ZERO

@onready var _halo: Sprite2D = %Halo
@onready var _rig: Node2D = %Rig
@onready var _stem: Sprite2D = %Stem
@onready var _leaves: Node2D = %Leaves
@onready var _fruit: Sprite2D = %Fruit


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = PLANT_SHADER
	_halo.texture = _get_halo_texture()
	_halo.material = _get_halo_material()
	rebuild()
	_restart_sway()


## Fenotip: şu an çizilen bitkinin ifade edilen özellikleri. Gen/kural seti yoksa null.
## [codeblock]
## var value: float = plant.get_phenotype().market_value
## [/codeblock]
func get_phenotype() -> PlantPhenotype:
	return _phenotype


## Katmanları gen ve kural setinden yeniden kurar. Gen ya da kural seti değişince kendiliğinden çağrılır.
func rebuild() -> void:
	if not is_node_ready():
		return
	if gene == null or ruleset == null:
		_phenotype = null
		_clear_visuals()
		visuals_rebuilt.emit()
		return

	_phenotype = GeneticsEngine.express(gene, ruleset)
	var stem_part: PlantPartDef = ruleset.get_part(_phenotype.stem_id)
	var leaf_part: PlantPartDef = ruleset.get_part(_phenotype.leaf_id)
	var fruit_part: PlantPartDef = ruleset.get_part(_phenotype.fruit_id)

	_configure_material()
	_build_stem(stem_part)
	_build_leaves(stem_part, leaf_part)
	_build_fruit(fruit_part, stem_part)
	_build_halo()
	_apply_growth()
	visuals_rebuilt.emit()


## Kısa bir "pop" animasyonu (ölçek vurgusu): çaprazlama sonucu ya da hasat anında. Yalnızca görsel katmanı ölçekler.
## [codeblock]
## plant.play_pop()
## [/codeblock]
func play_pop() -> void:
	if not is_node_ready():
		return
	var tween: Tween = create_tween()
	tween.tween_property(_rig, "scale", Vector2.ONE * 1.12, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_rig, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------------ kurulum


func _clear_visuals() -> void:
	_stem.texture = null
	_fruit.texture = null
	_fruit.visible = false
	_halo.visible = false
	for sprite: Sprite2D in _leaf_sprites:
		sprite.visible = false
	_active_leaf_count = 0


## Bitkiye özel malzemenin parametrelerini fenotipten ayarlar.
func _configure_material() -> void:
	_material.set_shader_parameter("glow_color", _phenotype.glow_color)
	_material.set_shader_parameter("glow_strength", _phenotype.glow_strength)
	_material.set_shader_parameter("shimmer", _phenotype.shimmer)
	_material.set_shader_parameter("phase", float(absi(hash(String(_phenotype.signature))) % _PHASE_STEPS) / 1000.0)


func _build_stem(stem_part: PlantPartDef) -> void:
	_leaf_mounts = PackedVector2Array()
	_fruit_mount = Vector2.ZERO
	if stem_part == null:
		_stem.texture = null
		return
	_leaf_mounts = stem_part.leaf_mounts
	_fruit_mount = stem_part.fruit_mount
	_stem.texture = stem_part.texture
	_stem.centered = false
	_stem.offset = -stem_part.anchor
	_stem.material = _material
	_stem.modulate = Color.from_hsv(_leaf_hue(), stem_saturation, stem_value)


func _build_leaves(_stem_part: PlantPartDef, leaf_part: PlantPartDef) -> void:
	_active_leaf_count = _leaf_mounts.size() if leaf_part != null else 0
	while _leaf_sprites.size() < _active_leaf_count:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.centered = false
		_leaves.add_child(sprite)
		_leaf_sprites.append(sprite)
	var leaf_color: Color = Color.from_hsv(_leaf_hue(), leaf_saturation, leaf_value)
	for i: int in _leaf_sprites.size():
		var sprite: Sprite2D = _leaf_sprites[i]
		sprite.visible = i < _active_leaf_count
		if i < _active_leaf_count:
			sprite.texture = leaf_part.texture
			sprite.offset = -leaf_part.anchor
			sprite.material = _material
			sprite.modulate = leaf_color


func _build_fruit(fruit_part: PlantPartDef, _stem_part: PlantPartDef) -> void:
	if fruit_part == null:
		_fruit.texture = null
		_fruit.visible = false
		return
	_fruit.texture = fruit_part.texture
	_fruit.centered = false
	_fruit.offset = -fruit_part.anchor
	_fruit.material = _material
	if _phenotype.tint_override.a > 0.0:
		_fruit.modulate = _phenotype.tint_override
	else:
		_fruit.modulate = Color.from_hsv(_phenotype.fruit_hue, fruit_saturation, fruit_value)


func _build_halo() -> void:
	_halo.visible = _phenotype.is_luminous()
	var tint: Color = _phenotype.glow_color
	tint.a = halo_alpha * clampf(_phenotype.glow_strength, 0.0, 1.0)
	_halo.modulate = tint


## Yaprak tonu: yeşilden genetik tona doğru kısmen çekilmiş.
func _leaf_hue() -> float:
	return ColorMath.lerp_hue(leaf_green_hue, _phenotype.hue, leaf_hue_pull)


# ------------------------------------------------------------------- büyüme


## Büyüme değerinden gövde boyunu, yaprakları, meyveyi ve halonun yerini/ölçeğini hesaplar.
func _apply_growth() -> void:
	if not is_node_ready() or _phenotype == null:
		return
	var stem_progress: float = clampf(growth / stem_full_at, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - stem_progress, 2.0)
	var stem_scale: Vector2 = Vector2(lerpf(stem_min_width_scale, 1.0, eased), lerpf(stem_min_scale, 1.0, eased))
	_stem.scale = stem_scale

	for i: int in _active_leaf_count:
		var sprite: Sprite2D = _leaf_sprites[i]
		var threshold: float = leaf_start_at
		if _active_leaf_count > 1:
			threshold = lerpf(leaf_start_at, leaf_full_at, float(i) / float(_active_leaf_count - 1))
		var progress: float = smoothstep(0.0, 1.0, clampf((growth - threshold) / leaf_pop_span, 0.0, 1.0))
		var size: float = progress * (1.0 - leaf_size_falloff * float(i))
		var side: float = 1.0 if i % 2 == 0 else -1.0
		sprite.position = _leaf_mounts[i] * stem_scale
		sprite.rotation = -side * deg_to_rad(leaf_base_angle_degrees + leaf_angle_step_degrees * float(i))
		sprite.scale = Vector2(side * size, size)
		sprite.visible = size > 0.001

	var fruit_progress: float = clampf((growth - fruit_start_at) / maxf(1.0 - fruit_start_at, 0.001), 0.0, 1.0)
	var fruit_size: float = smoothstep(0.0, 1.0, fruit_progress)
	_fruit.position = _fruit_mount * stem_scale
	_fruit.scale = Vector2.ONE * fruit_size
	_fruit.visible = _fruit.texture != null and fruit_size > 0.001

	_halo.position = _fruit.position
	_halo.scale = (halo_size / float(_HALO_TEXTURE_SIZE)) * smoothstep(halo_start_at, 1.0, growth)


# -------------------------------------------------------------------- hareket


## Rüzgâr salınımını (yeniden) başlatır. Kapalıysa gövde dik kalır.
func _restart_sway() -> void:
	if _sway_tween != null:
		_sway_tween.kill()
		_sway_tween = null
	if not is_node_ready():
		return
	_rig.rotation = 0.0
	if not sway_enabled or sway_degrees <= 0.0:
		return
	var amplitude: float = deg_to_rad(sway_degrees)
	var half_period: float = sway_seconds * 0.5
	_rig.rotation = -amplitude
	_sway_tween = create_tween().set_loops()
	_sway_tween.tween_property(_rig, "rotation", amplitude, half_period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sway_tween.tween_property(_rig, "rotation", -amplitude, half_period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---------------------------------------------------------------------- halo


static func _get_halo_texture() -> GradientTexture2D:
	if _halo_texture == null:
		var gradient: Gradient = Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		gradient.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 0.85), Color(1.0, 1.0, 1.0, 0.28), Color(1.0, 1.0, 1.0, 0.0)])
		var texture: GradientTexture2D = GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = _HALO_TEXTURE_SIZE
		texture.height = _HALO_TEXTURE_SIZE
		_halo_texture = texture
	return _halo_texture


static func _get_halo_material() -> CanvasItemMaterial:
	if _halo_material == null:
		var material: CanvasItemMaterial = CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_halo_material = material
	return _halo_material
