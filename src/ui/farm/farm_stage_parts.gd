class_name FarmStageParts
extends RefCounted
## 2.5D çiftlik sahnesinin kodla üretilen parçaları: saksı (torna profili), malzemeler ve gölgelendirici örnekleri. Sanat dosyası yok;
## her şey profil noktalarından ve `UiTokens` paletinden türer. Durumsuzdur, yalnızca nesne üretir.
##
## Uygular: docs/architecture/floralab-architecture.md, "2.5D çiftlik sahnesi" kararı; design/design-language.md, "Derinlik ve ışık".

const WALL_SHADER: Shader = preload("res://assets/shaders/spatial_wall.gdshader")
const PIPE_SHADER: Shader = preload("res://assets/shaders/spatial_pipe_flow.gdshader")
const GLASS_SHADER: Shader = preload("res://assets/shaders/spatial_glass.gdshader")
const PLANT_SHADER: Shader = preload("res://assets/shaders/spatial_plant_billboard.gdshader")
const HALO_SHADER: Shader = preload("res://assets/shaders/spatial_plant_halo.gdshader")
const BEAM_SHADER: Shader = preload("res://assets/shaders/spatial_uv_beam.gdshader")
const BLOB_SHADER: Shader = preload("res://assets/shaders/spatial_blob_shadow.gdshader")

## Saksı gövdesinin torna profili (yarıçap, yükseklik), tabanın ortasından dışa, ağıza, sonra iç duvardan aşağı. Birim: karo.
const POT_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.23, 0.0), Vector2(0.27, 0.035), Vector2(0.335, 0.30), Vector2(0.365, 0.335),
	Vector2(0.365, 0.355), Vector2(0.30, 0.355), Vector2(0.29, 0.30), Vector2(0.28, 0.255), Vector2(0.0, 0.255),
]
## Ağız halkası (profilin üst yüzü) bu iki noktadır; ayrı yüzey olarak parlak çizilir.
const POT_RIM_FROM: int = 5
const POT_SEGMENTS: int = 28
## Bitkinin kök noktasının saksı karosunun üstünden uzaklığı (karo). Eski 2D yerleşimiyle aynı (116 / 180).
const POT_BASE_IN_TILE: float = 0.644
## Saksının toplam yüksekliği ve su penceresinin (içteki su yüzeyi) yüksekliği.
const POT_HEIGHT: float = 0.355
const POT_WATER_Y: float = 0.262
const POT_WATER_RADIUS: float = 0.275


## Torna profilinden saksı ağı: yüzey 0 = gövde, yüzey 1 = ağız halkası. Her profil parçası kendi normaline sahiptir
## (profilde sert kenar, çevrede yumuşak).
static func make_pot_mesh() -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	var rim: SurfaceTool = SurfaceTool.new()
	var body: SurfaceTool = SurfaceTool.new()
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	rim.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in POT_PROFILE.size() - 1:
		var a: Vector2 = POT_PROFILE[k]
		var b: Vector2 = POT_PROFILE[k + 1]
		var direction: Vector2 = b - a
		var normal2: Vector2 = Vector2(direction.y, -direction.x).normalized()
		var target: SurfaceTool = rim if k == POT_RIM_FROM else body
		for j: int in POT_SEGMENTS:
			var t0: float = TAU * float(j) / float(POT_SEGMENTS)
			var t1: float = TAU * float(j + 1) / float(POT_SEGMENTS)
			_add_quad(target, a, b, t0, t1, normal2)
	body.index()
	rim.index()
	body.commit(mesh)
	rim.commit(mesh)
	return mesh


## Profil parçasını (a -> b) iki açı arasında döndürüp dörtgen olarak ekler; sargı yönü normale göre seçilir.
static func _add_quad(target: SurfaceTool, a: Vector2, b: Vector2, t0: float, t1: float, normal2: Vector2) -> void:
	var p00: Vector3 = Vector3(a.x * cos(t0), a.y, a.x * sin(t0))
	var p10: Vector3 = Vector3(b.x * cos(t0), b.y, b.x * sin(t0))
	var p11: Vector3 = Vector3(b.x * cos(t1), b.y, b.x * sin(t1))
	var p01: Vector3 = Vector3(a.x * cos(t1), a.y, a.x * sin(t1))
	var n0: Vector3 = Vector3(normal2.x * cos(t0), normal2.y, normal2.x * sin(t0))
	var n1: Vector3 = Vector3(normal2.x * cos(t1), normal2.y, normal2.x * sin(t1))
	var corners: Array[Vector3] = [p00, p10, p11, p01]
	var normals: Array[Vector3] = [n0, n0, n1, n1]
	var order: Array[int] = [0, 1, 2, 0, 2, 3]
	var face_normal: Vector3 = (corners[1] - corners[0]).cross(corners[2] - corners[0])
	if face_normal.dot(n0 + n1) < 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for index: int in order:
		target.set_normal(normals[index])
		target.add_vertex(corners[index])


## Saksı gövdesi: koyu çelik, hafif metalik.
static func pot_body_material(tint: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = 0.12
	material.roughness = 0.42
	return material


## Parlayan ince şerit (saksı ağzı, raf ucu): yalnızca emisyon.
static func glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.6)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


## Düz, hafif metalik yüzey (raf, direk, çerçeve).
static func steel_material(tint: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = 0.10
	material.roughness = 0.55
	return material


## Su penceresi: emisyonu ıslaklığa göre ayarlanır (`FarmStage` günceller).
static func water_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.05, 0.12, 0.16)
	material.emission_enabled = true
	material.emission = UiTokens.AQUA
	material.emission_energy_multiplier = 0.0
	material.roughness = 0.15
	return material


static func shader_material(shader: Shader) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	return material
