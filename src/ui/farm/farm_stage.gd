class_name FarmStage
extends Node3D
## Bir katın 2.5D sahnesi: gerçek 3D geometri (cam, raflar, saksılar, borular, UV lambaları, dronlar), perspektif kamera ve ışık;
## bitkiler ise ortak atlastan (`PlantAtlas`) basılan düz dörtgenlerdir. Oynanış düzlem üzerindedir (z = 0): ızgara birimi bir KARO,
## x sağa, y yukarı; kat bölmesi r için raf üstü y = -(2r + 2), saksı ağzı raf üstünden 0.355 yukarıdadır. Kamera hareketi (hafif süzülme)
## yalnızca derinlik algısı içindir; oyun mantığına dokunmaz.
##
## OYUN DURUMUNU DEĞİŞTİRMEZ: `FarmView` her karede `sync()` ile durumu okuyup verir. Ekran <-> düzlem dönüşümü kameradan ANALİTİK
## hesaplanır (`project`, `plane_point`): bir görünüm penceresinin çizilmiş olmasına bağlı değildir, başsız testte de aynı sonucu verir.
##
## Uygular: docs/architecture/floralab-architecture.md, "2.5D çiftlik sahnesi" kararı; design/design-language.md, "Derinlik ve ışık".
##
## [codeblock]
## var stage: FarmStage = FarmStage.new()
## viewport.add_child(stage)
## stage.setup(ruleset)
## stage.set_view_size(Vector2(1030.0, 1000.0))
## stage.build_floor(floor_state)
## stage.sync(floor_state, config, agents, show_dock)
## var screen: Vector2 = stage.project(stage.pot_base_world(0))
## [/codeblock]

## Izgaranın iki yanındaki hizmet boşluğu (karo).
const MARGIN_TILES: int = 1
## Bir kat bölmesinin yüksekliği (karo): üstte lamba, altta saksı rafı.
const BAY_HEIGHT: float = 2.0
const SLAB_THICKNESS: float = 0.16
const SLAB_DEPTH: float = 1.7
const WALL_Z: float = -0.9
const GLASS_Z: float = 0.95
const PIPE_Z: float = -0.22
## Saksı karosunun üstünden boruya olan uzaklık (karo). Eski 2D yerleşimiyle aynı (142 / 180).
const PIPE_BELOW_TILE_TOP: float = 0.79
const PIPE_RADIUS: float = 0.05
const LAMP_HEIGHT: float = 0.08
const LAMP_DEPTH: float = 0.30
const LAMP_Z: float = 0.10
## UV huzmesinin sıralama derinliği: bitkilerin ARKASINDA kalır (toplamalı huzme önce çizilir, bitki üstüne biner; aksi hâlde bitki solar).
const BEAM_Z: float = -0.30
## Dronun saksı tabanından uçuş yüksekliği ve üste kondukta inişi (karo).
const DRONE_HOVER: float = 0.19
const DRONE_IDLE_DROP: float = 0.155
const DRONE_Z: float = 0.20
## Bitki düz dörtgeninin dünya boyutu: atlas pikseli / (atlas pikseli başına karo).
const PLANT_UNITS_PER_TILE: float = 360.0
## Bitkinin düz dörtgeninin sahnedeki derinliği (saksının biraz önü) ve halonun derinliği (bitkinin arkası).
const PLANT_Z: float = 0.02
const HALO_Z: float = -0.04
const HALO_TILES: float = 1.2
const HALO_ALPHA: float = 0.55
const HALO_START_AT: float = 0.3

# Kamera.
const FOV_DEGREES: float = 26.0
const PITCH_DEGREES: float = 5.0
const MAX_PIXELS_PER_TILE: float = 225.0
const FIT_PADDING: float = 1.05
const DRIFT_YAW_DEGREES: float = 1.8
const DRIFT_PITCH_DEGREES: float = 0.8
const DRIFT_SECONDS: float = 12.0

## Gündüz ve gece ton çarpanları (bitkiler ve duvar).
const DAY_TONE: Color = Color(1.0, 0.99, 0.94)
const NIGHT_TONE: Color = Color(0.74, 0.82, 1.0)
const DAY_AMBIENT: Color = Color(0.56, 0.72, 0.70)
const NIGHT_AMBIENT: Color = Color(0.34, 0.44, 0.64)
const AMBIENT_DAY_ENERGY: float = 1.15
const AMBIENT_NIGHT_ENERGY: float = 1.0
const SUN_DAY_ENERGY: float = 1.15
const SUN_NIGHT_ENERGY: float = 0.55

var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		_apply_motion()

var _ruleset: GeneticsRuleset
var _atlas: PlantAtlas
var _camera: Camera3D
var _environment: Environment
var _sun: DirectionalLight3D
var _content: Node3D
var _cols: int = 0
var _rows: int = 0
var _view_size: Vector2 = Vector2(1080.0, 1000.0)
var _night: float = 0.0
var _time: float = 0.0
var _dolly: float = 0.0
var _distance: float = 10.0
var _tan_half: float = tan(deg_to_rad(FOV_DEGREES) * 0.5)
var _cam_xform: Transform3D = Transform3D.IDENTITY

var _plant_quads: Array[MeshInstance3D] = []
var _plant_materials: Array[ShaderMaterial] = []
var _halo_quads: Array[MeshInstance3D] = []
var _halo_materials: Array[ShaderMaterial] = []
var _water_materials: Array[StandardMaterial3D] = []
var _water_cache: PackedFloat32Array = PackedFloat32Array()
var _uv_cache: PackedInt32Array = PackedInt32Array()
var _pipe_nodes: Array[MeshInstance3D] = []
var _pipe_materials: Array[ShaderMaterial] = []
var _riser: MeshInstance3D
var _lamp_materials: Array[StandardMaterial3D] = []
var _lamp_lights: Array[OmniLight3D] = []
var _beams: Array[MeshInstance3D] = []
var _beam_materials: Array[ShaderMaterial] = []
var _wall_material: ShaderMaterial
var _glass_material: ShaderMaterial
var _drone_nodes: Array[Node3D] = []
var _dock_pad: MeshInstance3D
var _pot_mesh: ArrayMesh
var _shared: Dictionary = {}


func _ready() -> void:
	_atlas = PlantAtlas.new()
	add_child(_atlas)
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_CLEAR_COLOR
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_camera = Camera3D.new()
	_camera.fov = FOV_DEGREES
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.near = 0.5
	_camera.far = 80.0
	_camera.environment = _environment
	add_child(_camera)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-38.0, -24.0, 0.0)
	_sun.light_specular = 0.25
	add_child(_sun)
	_pot_mesh = FarmStageParts.make_pot_mesh()
	_apply_night()
	_apply_camera()


## Kural setini bağlar (atlastaki bitkiler için).
func setup(ruleset: GeneticsRuleset) -> void:
	_ruleset = ruleset
	if _atlas != null:
		_atlas.setup(ruleset, 0)


## Bitki atlası (test ve görünüm penceresi için).
func atlas() -> PlantAtlas:
	return _atlas


## Görünüm penceresinin piksel boyutu; kamera ızgarayı sığdıracak şekilde yeniden kurulur.
func set_view_size(size: Vector2) -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	_view_size = size
	_refit()


## Günün karanlık oranı (0 gündüz, 1 gece).
func set_night(night: float) -> void:
	_night = clampf(night, 0.0, 1.0)
	_apply_night()


## Kat değiştirirken kameranın yatay kayması (karo); `FarmView` bunu süreler.
func set_dolly(offset: float) -> void:
	_dolly = offset
	_apply_camera()


func dolly() -> float:
	return _dolly


# ---------------------------------------------------------------- kamera ve projeksiyon


## Düzlemde (z = 0) bir noktanın (karo birimi, y yukarı) dünya konumu.
static func plane_world(x: float, y: float) -> Vector3:
	return Vector3(x, y, 0.0)


## Saksı tabanının (bitkinin kök noktası) dünya konumu.
func pot_base_world(pot_index: int) -> Vector3:
	var col: int = pot_index % maxi(_cols, 1)
	var row: int = pot_index / maxi(_cols, 1)
	return Vector3(float(col) + 0.5, -(float(2 * row + 1) + FarmStageParts.POT_BASE_IN_TILE), 0.0)


## Dünya noktasını görünüm penceresi (piksel, sol üst başlangıçlı) koordinatına izdüşürür. Kameranın arkasındaysa büyük bir dış değer döner.
func project(world: Vector3) -> Vector2:
	var local: Vector3 = _cam_xform.affine_inverse() * world
	if local.z > -0.001:
		return Vector2(-100000.0, -100000.0)
	var aspect: float = _view_size.x / _view_size.y
	var ndc: Vector2 = Vector2(local.x / (-local.z) / (_tan_half * aspect), local.y / (-local.z) / _tan_half)
	return Vector2((ndc.x * 0.5 + 0.5) * _view_size.x, (0.5 - ndc.y * 0.5) * _view_size.y)


## Ekran noktasından geçen ışının z = 0 düzlemini kestiği nokta (karo birimi, y yukarı).
func plane_point(screen: Vector2) -> Vector2:
	var aspect: float = _view_size.x / _view_size.y
	var ndc: Vector2 = Vector2(screen.x / _view_size.x * 2.0 - 1.0, 1.0 - screen.y / _view_size.y * 2.0)
	var direction: Vector3 = (_cam_xform.basis * Vector3(ndc.x * _tan_half * aspect, ndc.y * _tan_half, -1.0)).normalized()
	var origin: Vector3 = _cam_xform.origin
	if absf(direction.z) < 0.00001:
		return Vector2.ZERO
	var s: float = -origin.z / direction.z
	var hit: Vector3 = origin + direction * s
	return Vector2(hit.x, hit.y)


## Düzlemde bir karonun ekranda kaç piksel olduğu (kamera yatay süzülmesinde bile ortalama).
func pixels_per_tile() -> float:
	return project(Vector3(0.0, 0.0, 0.0)).distance_to(project(Vector3(1.0, 0.0, 0.0)))


## Izgaranın toplam genişliği ve yüksekliği (karo): yan boşluklar dahil.
func grid_size() -> Vector2:
	return Vector2(float(_cols + 2 * MARGIN_TILES), float(_rows) * BAY_HEIGHT)


func _refit() -> void:
	var grid: Vector2 = grid_size()
	if grid.x <= 0.0 or grid.y <= 0.0:
		_apply_camera()
		return
	var aspect: float = _view_size.x / _view_size.y
	var by_height: float = grid.y * FIT_PADDING / (2.0 * _tan_half)
	var by_width: float = grid.x * FIT_PADDING / (2.0 * _tan_half * aspect)
	var closest: float = _view_size.y / (2.0 * _tan_half * MAX_PIXELS_PER_TILE)
	_distance = maxf(maxf(by_height, by_width), closest)
	_apply_camera()


func _apply_camera() -> void:
	if _camera == null:
		return
	var grid: Vector2 = grid_size()
	var target: Vector3 = Vector3(float(_cols) * 0.5 + _dolly, -grid.y * 0.5, 0.0)
	var yaw: float = 0.0
	var pitch: float = deg_to_rad(PITCH_DEGREES)
	if not reduce_motion:
		yaw = sin(_time * TAU / DRIFT_SECONDS) * deg_to_rad(DRIFT_YAW_DEGREES)
		pitch += sin(_time * TAU / (DRIFT_SECONDS * 1.37) + 1.0) * deg_to_rad(DRIFT_PITCH_DEGREES)
	var direction: Vector3 = Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var position_: Vector3 = target + direction * _distance
	_cam_xform = Transform3D(Basis.looking_at(-direction, Vector3.UP), position_)
	_camera.transform = _cam_xform
	if _glass_material != null:
		_glass_material.set_shader_parameter("shift", yaw * 6.0 + _dolly * 0.1)


## Kamerayı ve hareketli parçaları (rotorlar) `delta` saniye ilerletir.
func advance(delta: float) -> void:
	_time += delta
	if not reduce_motion:
		_apply_camera()
		for node: Node3D in _drone_nodes:
			var rotors: Node3D = node.get_node_or_null("Rotors") as Node3D
			if rotors != null:
				rotors.rotation.y += delta * 38.0


func _apply_motion() -> void:
	if _atlas != null:
		_atlas.set_sway(not reduce_motion)
	for material: ShaderMaterial in _pipe_materials:
		material.set_shader_parameter("flow_speed", 0.0 if reduce_motion else 0.32)
	for material: ShaderMaterial in _halo_materials:
		material.set_shader_parameter("pulse_speed", 0.0 if reduce_motion else 2.4)
	_apply_camera()


func _apply_night() -> void:
	if _environment == null:
		return
	_environment.ambient_light_color = DAY_AMBIENT.lerp(NIGHT_AMBIENT, _night)
	_environment.ambient_light_energy = lerpf(AMBIENT_DAY_ENERGY, AMBIENT_NIGHT_ENERGY, _night)
	_sun.light_color = DAY_TONE.lerp(NIGHT_TONE, _night)
	_sun.light_energy = lerpf(SUN_DAY_ENERGY, SUN_NIGHT_ENERGY, _night)
	var tone: Color = DAY_TONE.lerp(NIGHT_TONE, _night)
	for material: ShaderMaterial in _plant_materials:
		material.set_shader_parameter("tone", tone)
	if _wall_material != null:
		_wall_material.set_shader_parameter("tone", tone)


# ------------------------------------------------------------------------- kurulum


## Kat için sahneyi baştan kurar (kabuk, raflar, saksılar, borular, lambalar).
func build_floor(floor_state: FloorState) -> void:
	if _content != null:
		remove_child(_content)
		_content.free()
	_content = Node3D.new()
	_content.name = "Floor"
	add_child(_content)
	_cols = floor_state.cols
	_rows = floor_state.rows
	_plant_quads.clear()
	_plant_materials.clear()
	_halo_quads.clear()
	_halo_materials.clear()
	_water_materials.clear()
	_pipe_nodes.clear()
	_pipe_materials.clear()
	_lamp_materials.clear()
	_lamp_lights.clear()
	_beams.clear()
	_beam_materials.clear()
	_drone_nodes.clear()
	_dock_pad = null
	_riser = null
	_water_cache = PackedFloat32Array()
	_water_cache.resize(floor_state.pots.size())
	_water_cache.fill(-1.0)
	_uv_cache = PackedInt32Array()
	_uv_cache.resize(floor_state.rows)
	_uv_cache.fill(-1)
	_shared = {
		"steel": FarmStageParts.steel_material(Color(0.20, 0.33, 0.34)),
		"steel_dark": FarmStageParts.steel_material(Color(0.12, 0.2, 0.22)),
		"pot": FarmStageParts.pot_body_material(Color(0.30, 0.46, 0.47)),
		"rim": FarmStageParts.glow_material(UiTokens.AQUA, 1.5),
		"edge": FarmStageParts.glow_material(UiTokens.ACCENT, 0.55),
	}
	_build_shell()
	for row: int in _rows:
		_build_bay(row, floor_state)
	for pot_index: int in floor_state.pots.size():
		_build_pot(pot_index, floor_state)
	_atlas.setup(_ruleset, floor_state.pots.size())
	_atlas.ensure_capacity(floor_state.pots.size())
	for pot_index: int in floor_state.pots.size():
		var region: Rect2 = _atlas.cell_region(pot_index)
		_plant_materials[pot_index].set_shader_parameter("atlas", _atlas.get_texture())
		_plant_materials[pot_index].set_shader_parameter("region", Vector4(region.position.x, region.position.y, region.size.x, region.size.y))
	_refit()
	_apply_night()
	_apply_motion()


func _box(size: Vector3, position_: Vector3, material: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var node: MeshInstance3D = MeshInstance3D.new()
	node.mesh = mesh
	node.position = position_
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_content.add_child(node)
	return node


func _build_shell() -> void:
	var grid: Vector2 = grid_size()
	var width: float = grid.x
	var center_x: float = float(_cols) * 0.5
	var bottom: float = -grid.y - SLAB_THICKNESS
	# Arka duvar.
	var wall: MeshInstance3D = MeshInstance3D.new()
	var wall_mesh: QuadMesh = QuadMesh.new()
	wall_mesh.size = Vector2(width, -bottom)
	wall.mesh = wall_mesh
	wall.position = Vector3(center_x, bottom * 0.5, WALL_Z)
	_wall_material = FarmStageParts.shader_material(FarmStageParts.WALL_SHADER)
	_wall_material.set_shader_parameter("tiles", Vector2(width, -bottom * 0.5))
	wall.material_override = _wall_material
	_content.add_child(wall)
	# Tavan levhası (en üst bölmenin tavanı).
	_box(Vector3(width, SLAB_THICKNESS, SLAB_DEPTH), Vector3(center_x, -SLAB_THICKNESS * 0.5, -0.05), _shared["steel"] as Material)
	# Dört köşe direği (ön ve arka).
	var post_height: float = -bottom
	for x: float in [center_x - width * 0.5 + 0.06, center_x + width * 0.5 - 0.06]:
		for z: float in [WALL_Z + 0.06, GLASS_Z - 0.06]:
			_box(Vector3(0.12, post_height, 0.12), Vector3(x, bottom * 0.5, z), _shared["steel_dark"] as Material)
	# Ön cam.
	var glass: MeshInstance3D = MeshInstance3D.new()
	var glass_mesh: QuadMesh = QuadMesh.new()
	glass_mesh.size = Vector2(width - 0.1, post_height - 0.1)
	glass.mesh = glass_mesh
	glass.position = Vector3(center_x, bottom * 0.5, GLASS_Z)
	_glass_material = FarmStageParts.shader_material(FarmStageParts.GLASS_SHADER)
	glass.material_override = _glass_material
	glass.sorting_offset = 5.0
	_content.add_child(glass)


func _build_bay(row: int, floor_state: FloorState) -> void:
	var center_x: float = float(_cols) * 0.5
	var width: float = grid_size().x
	var slab_top: float = -float(2 * row + 2)
	# Raf levhası ve ön ucundaki parlak şerit.
	_box(Vector3(width, SLAB_THICKNESS, SLAB_DEPTH), Vector3(center_x, slab_top - SLAB_THICKNESS * 0.5, -0.05), _shared["steel"] as Material)
	_box(Vector3(width - 0.1, 0.02, 0.02), Vector3(center_x, slab_top - SLAB_THICKNESS * 0.5, GLASS_Z - 0.18), _shared["edge"] as Material)
	# Sulama borusu (görünürlüğü `sync` belirler).
	var pipe_mesh: CylinderMesh = CylinderMesh.new()
	pipe_mesh.top_radius = PIPE_RADIUS
	pipe_mesh.bottom_radius = PIPE_RADIUS
	pipe_mesh.height = float(_cols) + 1.0
	pipe_mesh.radial_segments = 12
	pipe_mesh.rings = 1
	var pipe: MeshInstance3D = MeshInstance3D.new()
	pipe.mesh = pipe_mesh
	pipe.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	pipe.position = Vector3(float(_cols) * 0.5 - 0.05, -float(2 * row + 1) - PIPE_BELOW_TILE_TOP, PIPE_Z)
	var pipe_material: ShaderMaterial = FarmStageParts.shader_material(FarmStageParts.PIPE_SHADER)
	pipe.material_override = pipe_material
	pipe.visible = false
	_content.add_child(pipe)
	_pipe_nodes.append(pipe)
	_pipe_materials.append(pipe_material)
	# UV lambası: çubuk, ışık ve saksı başına huzme (görünürlüğü `sync` belirler).
	var lamp_y: float = -float(2 * row) - SLAB_THICKNESS - LAMP_HEIGHT * 0.5
	var lamp_material: StandardMaterial3D = FarmStageParts.glow_material(UiTokens.UV, 0.0)
	_lamp_materials.append(lamp_material)
	_box(Vector3(float(_cols), LAMP_HEIGHT, LAMP_DEPTH), Vector3(center_x, lamp_y, LAMP_Z), lamp_material)
	var light: OmniLight3D = OmniLight3D.new()
	light.position = Vector3(center_x, lamp_y - 0.35, 0.55)
	light.omni_range = float(_cols) + 1.5
	light.light_color = UiTokens.UV
	light.light_energy = 0.0
	light.shadow_enabled = false
	_content.add_child(light)
	_lamp_lights.append(light)
	for col: int in _cols:
		var beam_mesh: CylinderMesh = CylinderMesh.new()
		beam_mesh.top_radius = 0.10
		beam_mesh.bottom_radius = 0.55
		var beam_top: float = lamp_y - LAMP_HEIGHT * 0.5
		var beam_bottom: float = slab_top + FarmStageParts.POT_HEIGHT
		beam_mesh.height = beam_top - beam_bottom
		beam_mesh.cap_top = false
		beam_mesh.cap_bottom = false
		beam_mesh.radial_segments = 16
		beam_mesh.rings = 1
		var beam: MeshInstance3D = MeshInstance3D.new()
		beam.mesh = beam_mesh
		beam.position = Vector3(float(col) + 0.5, (beam_top + beam_bottom) * 0.5, BEAM_Z)
		var beam_material: ShaderMaterial = FarmStageParts.shader_material(FarmStageParts.BEAM_SHADER)
		beam.material_override = beam_material
		beam.visible = false
		_content.add_child(beam)
		_beams.append(beam)
		_beam_materials.append(beam_material)
	# Sol kenarda dikey su yükselticisi (bir kez, ilk bölmede).
	if row == 0:
		var riser_mesh: CylinderMesh = CylinderMesh.new()
		riser_mesh.top_radius = PIPE_RADIUS * 1.2
		riser_mesh.bottom_radius = PIPE_RADIUS * 1.2
		riser_mesh.height = grid_size().y
		riser_mesh.radial_segments = 12
		riser_mesh.rings = 1
		_riser = MeshInstance3D.new()
		_riser.mesh = riser_mesh
		_riser.position = Vector3(-0.55, -grid_size().y * 0.5, PIPE_Z)
		var riser_material: ShaderMaterial = FarmStageParts.shader_material(FarmStageParts.PIPE_SHADER)
		riser_material.set_shader_parameter("axis", 1)
		_riser.material_override = riser_material
		_riser.visible = false
		_content.add_child(_riser)
		_pipe_materials.append(riser_material)


func _build_pot(pot_index: int, floor_state: FloorState) -> void:
	var col: int = floor_state.col_of(pot_index)
	var row: int = floor_state.row_of(pot_index)
	var slab_top: float = -float(2 * row + 2)
	var holder: Node3D = Node3D.new()
	holder.position = Vector3(float(col) + 0.5, slab_top, 0.0)
	_content.add_child(holder)
	# Yumuşak temas gölgesi.
	var shadow: MeshInstance3D = MeshInstance3D.new()
	var shadow_mesh: QuadMesh = QuadMesh.new()
	shadow_mesh.size = Vector2(1.0, 0.62)
	shadow.mesh = shadow_mesh
	shadow.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	shadow.position = Vector3(0.0, 0.004, 0.02)
	shadow.material_override = _blob_material()
	holder.add_child(shadow)
	# Saksı gövdesi ve ağız halkası.
	var body: MeshInstance3D = MeshInstance3D.new()
	body.mesh = _pot_mesh
	body.set_surface_override_material(0, _shared["pot"] as Material)
	body.set_surface_override_material(1, _shared["rim"] as Material)
	holder.add_child(body)
	# Su penceresi.
	var water_mesh: CylinderMesh = CylinderMesh.new()
	water_mesh.top_radius = FarmStageParts.POT_WATER_RADIUS
	water_mesh.bottom_radius = FarmStageParts.POT_WATER_RADIUS
	water_mesh.height = 0.006
	water_mesh.radial_segments = 20
	water_mesh.rings = 1
	var water_material: StandardMaterial3D = FarmStageParts.water_material()
	var water: MeshInstance3D = MeshInstance3D.new()
	water.mesh = water_mesh
	water.position = Vector3(0.0, FarmStageParts.POT_WATER_Y, 0.0)
	water.material_override = water_material
	holder.add_child(water)
	_water_materials.append(water_material)
	# Halo (bitkinin arkası) ve bitki dörtgeni (saksının hemen önü).
	var base: Vector3 = pot_base_world(pot_index)
	var halo_material: ShaderMaterial = FarmStageParts.shader_material(FarmStageParts.HALO_SHADER)
	var halo_mesh: QuadMesh = QuadMesh.new()
	halo_mesh.size = Vector2.ONE * HALO_TILES
	var halo: MeshInstance3D = MeshInstance3D.new()
	halo.mesh = halo_mesh
	halo.position = Vector3(base.x, base.y + 0.9, HALO_Z)
	halo.material_override = halo_material
	halo.visible = false
	_content.add_child(halo)
	_halo_quads.append(halo)
	_halo_materials.append(halo_material)
	var tiles_per_pixel: float = 1.0 / (PlantAtlas.PLANT_SCALE * PLANT_UNITS_PER_TILE)
	var quad_size: Vector2 = Vector2(PlantAtlas.CELL_SIZE) * tiles_per_pixel
	var plant_mesh: QuadMesh = QuadMesh.new()
	plant_mesh.size = quad_size
	var below_base: float = (float(PlantAtlas.CELL_SIZE.y) - PlantAtlas.BASE_IN_CELL.y) * tiles_per_pixel
	plant_mesh.center_offset = Vector3(0.0, quad_size.y * 0.5 - below_base, 0.0)
	var plant_material: ShaderMaterial = FarmStageParts.shader_material(FarmStageParts.PLANT_SHADER)
	var plant: MeshInstance3D = MeshInstance3D.new()
	plant.mesh = plant_mesh
	plant.position = Vector3(base.x, base.y, PLANT_Z)
	plant.material_override = plant_material
	plant.visible = false
	_content.add_child(plant)
	_plant_quads.append(plant)
	_plant_materials.append(plant_material)


func _blob_material() -> ShaderMaterial:
	if not _shared.has("blob"):
		_shared["blob"] = FarmStageParts.shader_material(FarmStageParts.BLOB_SHADER)
	return _shared["blob"] as ShaderMaterial


# ------------------------------------------------------------------ sorgular (salt okunur; test ve göstergeler için)


## Saksıdaki bitki dörtgeni şu an çiziliyor mu?
func plant_visible(pot_index: int) -> bool:
	return pot_index >= 0 and pot_index < _plant_quads.size() and _plant_quads[pot_index].visible


## Parlayan bitkinin halosu çiziliyor mu?
func halo_visible(pot_index: int) -> bool:
	return pot_index >= 0 and pot_index < _halo_quads.size() and _halo_quads[pot_index].visible


## Satırın sulama borusu çiziliyor mu?
func pipe_visible(row: int) -> bool:
	return row >= 0 and row < _pipe_nodes.size() and _pipe_nodes[row].visible


## Satırın UV lambası yanıyor mu (ışığı ve huzmeleri açık)?
func lamp_powered(row: int) -> bool:
	return row >= 0 and row < _lamp_lights.size() and _lamp_lights[row].light_energy > 0.0


## Sahnede şu an görünen dron sayısı.
func visible_drone_count() -> int:
	var count: int = 0
	for node: Node3D in _drone_nodes:
		if node.visible:
			count += 1
	return count


## Sahnedeki i. dronun dünya konumu (yoksa sıfır).
func drone_position(index: int) -> Vector3:
	return _drone_nodes[index].position if index >= 0 and index < _drone_nodes.size() else Vector3.ZERO


## Güneş ışığının şiddeti (gece/gündüz testi için).
func sun_energy() -> float:
	return _sun.light_energy


# ------------------------------------------------------------------ eşzamanlama


## Oyun durumunu sahneye yansıtır: bitkiler, su, borular, lambalar, halolar, dronlar. Durumu DEĞİŞTİRMEZ.
func sync(floor_state: FloorState, config: FarmConfig, agents: Array[DroneAgent], show_dock: bool, dock: Vector2) -> void:
	if _content == null:
		return
	var wet_level: float = config.water_growth_threshold + config.water_growth_ramp
	var any_pipe: bool = false
	for row: int in _rows:
		var piped: bool = floor_state.irrigation_rows[row]
		any_pipe = any_pipe or piped
		_pipe_nodes[row].visible = piped
		var uv_level: int = floor_state.uv_rows[row]
		if _uv_cache[row] != uv_level:
			_uv_cache[row] = uv_level
			_apply_lamp(row, uv_level)
	if _riser != null:
		_riser.visible = any_pipe
	for pot_index: int in floor_state.pots.size():
		_sync_pot(pot_index, floor_state, wet_level, config)
	_sync_drones(agents, show_dock, dock)


func _apply_lamp(row: int, level: int) -> void:
	var powered: bool = level > 0
	var energy: float = 0.0 if not powered else 1.0 + 0.8 * float(level)
	_lamp_materials[row].emission_energy_multiplier = energy * 0.45
	_lamp_lights[row].light_energy = 0.0 if not powered else 0.55 + 0.25 * float(level)
	for col: int in _cols:
		var index: int = row * _cols + col
		_beams[index].visible = powered
		_beam_materials[index].set_shader_parameter("strength", 0.28 + 0.12 * float(level))


func _sync_pot(pot_index: int, floor_state: FloorState, wet_level: float, config: FarmConfig) -> void:
	var pot: PotState = floor_state.pots[pot_index]
	_atlas.sync_pot(pot_index, pot.gene, pot.growth)
	var occupied: bool = not pot.is_empty()
	var quad: MeshInstance3D = _plant_quads[pot_index]
	quad.visible = occupied
	if occupied:
		var uv_level: int = floor_state.uv_rows[floor_state.row_of(pot_index)]
		_plant_materials[pot_index].set_shader_parameter("uv_amount", 0.0 if uv_level <= 0 else minf(0.4 + 0.25 * float(uv_level), 0.9))
	var water_fill: float = clampf((pot.water - config.water_growth_threshold) / maxf(wet_level - config.water_growth_threshold, 0.001), 0.0, 1.0)
	if absf(_water_cache[pot_index] - water_fill) > 0.04:
		_water_cache[pot_index] = water_fill
		_water_materials[pot_index].emission_energy_multiplier = 0.25 + 1.9 * water_fill
	_sync_halo(pot_index, pot, occupied)


func _sync_halo(pot_index: int, pot: PotState, occupied: bool) -> void:
	var halo: MeshInstance3D = _halo_quads[pot_index]
	var phenotype: PlantPhenotype = _atlas.plant_at(pot_index).get_phenotype() if occupied else null
	if phenotype == null or not phenotype.is_luminous():
		halo.visible = false
		return
	var material: ShaderMaterial = _halo_materials[pot_index]
	var strength: float = HALO_ALPHA * clampf(phenotype.glow_strength, 0.0, 1.0) * smoothstep(HALO_START_AT, 1.0, pot.growth)
	halo.visible = strength > 0.01
	material.set_shader_parameter("glow_color", phenotype.glow_color)
	material.set_shader_parameter("strength", strength * 2.0)
	material.set_shader_parameter("phase", float(absi(hash(String(phenotype.signature))) % 6283) / 1000.0)
	var fruit_y: float = _atlas.plant_at(pot_index).fruit_offset().y / PLANT_UNITS_PER_TILE * -1.0
	var base: Vector3 = pot_base_world(pot_index)
	halo.position = Vector3(base.x, base.y + maxf(fruit_y, 0.3), HALO_Z)


## Kattaki dronları ve üs padini çizer (salt okunur: konum ve durum `DroneAgent`'ta).
func _sync_drones(agents: Array[DroneAgent], show_dock: bool, dock: Vector2) -> void:
	while _drone_nodes.size() < agents.size():
		_drone_nodes.append(_make_drone())
	for i: int in _drone_nodes.size():
		_drone_nodes[i].visible = i < agents.size()
	for i: int in agents.size():
		var agent: DroneAgent = agents[i]
		var node: Node3D = _drone_nodes[i]
		var at: Vector3 = _drone_world(agent.position)
		if agent.state == DroneAgent.State.IDLE:
			at.y -= DRONE_IDLE_DROP
		elif not reduce_motion:
			at.y += sin(_time * 6.0 + float(i)) * 0.018
		node.position = at
		var glow: Node3D = node.get_node_or_null("Glow") as Node3D
		if glow != null:
			glow.visible = agent.state == DroneAgent.State.HARVESTING
	if show_dock or not agents.is_empty():
		if _dock_pad == null:
			_dock_pad = _box(Vector3(0.5, 0.05, 0.4), Vector3.ZERO, _shared["steel_dark"] as Material)
		_dock_pad.visible = true
		var pad: Vector3 = _drone_world(dock)
		_dock_pad.position = Vector3(pad.x, pad.y - DRONE_HOVER - 0.02, DRONE_Z)
	elif _dock_pad != null:
		_dock_pad.visible = false


## Hücre birimini (sütun + 0.5, satır + 0.5 = saksı merkezi) dünyaya çevirir: dron saksının biraz üstünde uçar.
func _drone_world(cell: Vector2) -> Vector3:
	return Vector3(cell.x, -cell.y * BAY_HEIGHT + DRONE_HOVER, DRONE_Z)


func _make_drone() -> Node3D:
	var drone: Node3D = Node3D.new()
	var body_mesh: SphereMesh = SphereMesh.new()
	body_mesh.radius = 0.085
	body_mesh.height = 0.11
	body_mesh.radial_segments = 14
	body_mesh.rings = 7
	var body: MeshInstance3D = MeshInstance3D.new()
	body.mesh = body_mesh
	body.material_override = FarmStageParts.glow_material(UiTokens.AQUA, 1.4)
	drone.add_child(body)
	var rotors: Node3D = Node3D.new()
	rotors.name = "Rotors"
	drone.add_child(rotors)
	for side: float in [-1.0, 1.0]:
		var arm: MeshInstance3D = MeshInstance3D.new()
		var arm_mesh: BoxMesh = BoxMesh.new()
		arm_mesh.size = Vector3(0.12, 0.012, 0.012)
		arm.mesh = arm_mesh
		arm.position = Vector3(side * 0.12, 0.02, 0.0)
		arm.material_override = _shared["steel_dark"] as Material
		rotors.add_child(arm)
		var blade: MeshInstance3D = MeshInstance3D.new()
		var blade_mesh: BoxMesh = BoxMesh.new()
		blade_mesh.size = Vector3(0.16, 0.004, 0.022)
		blade.mesh = blade_mesh
		blade.position = Vector3(side * 0.18, 0.034, 0.0)
		blade.material_override = FarmStageParts.glow_material(Color(0.85, 1.0, 0.95), 0.8)
		rotors.add_child(blade)
	var glow: MeshInstance3D = MeshInstance3D.new()
	glow.name = "Glow"
	var glow_mesh: QuadMesh = QuadMesh.new()
	glow_mesh.size = Vector2.ONE * 0.6
	glow.mesh = glow_mesh
	var glow_material: ShaderMaterial = FarmStageParts.shader_material(FarmStageParts.HALO_SHADER)
	glow_material.set_shader_parameter("glow_color", UiTokens.SAP)
	glow_material.set_shader_parameter("strength", 0.9)
	glow.material_override = glow_material
	glow.visible = false
	drone.add_child(glow)
	_content.add_child(drone)
	return drone
