class_name PlantAtlas
extends SubViewport
## Çiftlikteki tüm bitkileri TEK saydam 2D görünüm penceresinde (atlas) çizer; her bitki kendi hücresindedir. 3D sahne (`FarmStage`)
## bu dokunun hücrelerini düz dörtgenlere basar. Böylece bitkinin elle çizilmiş katmanlı parçaları, genetik rengi ve parlama
## gölgelendiricisi (`PlantInstance`) olduğu gibi kalır; bitki başına ayrı pencere değil, kare başına tek çizim geçişi yapılır.
## Oyun durumu tutmaz: `FarmStage` her karede gen ve büyümeyi `sync_pot` ile bildirir.
##
## Uygular: docs/architecture/floralab-architecture.md, "2.5D çiftlik sahnesi" kararı.
##
## [codeblock]
## var atlas: PlantAtlas = PlantAtlas.new()
## add_child(atlas)
## atlas.setup(ruleset, 6)                       # 6 saksılık kat
## atlas.sync_pot(0, gene, growth)               # bitki hücresini günceller
## var region: Rect2 = atlas.cell_region(0)       # dörtgenin doku uzayındaki hücresi (0..1)
## [/codeblock]

## Bir hücrenin boyutu (piksel). Bitki hücrede tabanından ortalanır.
const CELL_SIZE: Vector2i = Vector2i(288, 448)
## Hücrelerin dizildiği sütun sayısı.
const COLUMNS: int = 4
## Bitkinin hücre içindeki taban noktası (piksel; sol üste göre).
const BASE_IN_CELL: Vector2 = Vector2(144.0, 400.0)
## Bitki parçalarının atlastaki ölçeği: `PlantInstance` birimi başına piksel.
const PLANT_SCALE: float = 0.7

var _ruleset: GeneticsRuleset
var _plants: Array[PlantInstance] = []
var _sway: bool = true


func _init() -> void:
	transparent_bg = true
	disable_3d = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	gui_disable_input = true


## Kural setini bağlar ve en az `capacity` bitki hücresi hazırlar.
func setup(ruleset: GeneticsRuleset, capacity: int) -> void:
	_ruleset = ruleset
	ensure_capacity(capacity)


## Hücre sayısını gerektiği kadar büyütür (küçülmez); atlas dokusu buna göre yeniden boyutlanır.
func ensure_capacity(capacity: int) -> void:
	while _plants.size() < capacity:
		var plant: PlantInstance = preload("res://src/gameplay/plants/plant_instance.tscn").instantiate() as PlantInstance
		plant.ruleset = _ruleset
		plant.halo_enabled = false
		plant.sway_enabled = _sway
		plant.scale = Vector2.ONE * PLANT_SCALE
		plant.position = cell_origin(_plants.size()) + BASE_IN_CELL
		add_child(plant)
		_plants.append(plant)
	var rows: int = ceili(float(maxi(_plants.size(), 1)) / float(COLUMNS))
	size = Vector2i(COLUMNS * CELL_SIZE.x, rows * CELL_SIZE.y)


## Hücre sayısı.
func capacity() -> int:
	return _plants.size()


## Hücredeki bitki düğümü (test ve ince ayar için).
func plant_at(index: int) -> PlantInstance:
	return _plants[index]


## Hücrenin atlas içindeki sol üst köşesi (piksel).
func cell_origin(index: int) -> Vector2:
	return Vector2(float(index % COLUMNS) * float(CELL_SIZE.x), float(index / COLUMNS) * float(CELL_SIZE.y))


## Hücrenin doku uzayındaki dikdörtgeni (0..1): x, y, genişlik, yükseklik.
func cell_region(index: int) -> Rect2:
	var atlas_size: Vector2 = Vector2(size)
	return Rect2(cell_origin(index) / atlas_size, Vector2(CELL_SIZE) / atlas_size)


## Bitkinin hücresini günceller: gen değişince katmanlar yeniden kurulur, büyüme değişince ölçeklenir.
func sync_pot(index: int, gene: PlantGene, growth: float) -> void:
	var plant: PlantInstance = _plants[index]
	if plant.gene != gene:
		plant.gene = gene
	if absf(plant.growth - growth) > 0.002 or (gene == null and plant.growth != 0.0):
		plant.growth = growth


## Rüzgâr salınımını tüm bitkilerde açar/kapatır (hareketi azalt).
func set_sway(enabled: bool) -> void:
	_sway = enabled
	for plant: PlantInstance in _plants:
		plant.sway_enabled = enabled


## Atlas yalnızca görünürken çizilir (sekme gizliyken boşuna çizim geçişi yapılmaz).
func set_active(active: bool) -> void:
	render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
