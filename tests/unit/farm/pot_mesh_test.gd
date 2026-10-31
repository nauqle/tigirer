extends TestCase
## FarmStageParts: torna profilinden saksı ağı. Yüzey 0 gövde, yüzey 1 ağız halkası; ölçüler profilden gelir, normaller dışa bakar.

func test_the_pot_mesh_has_a_body_and_a_rim_surface() -> void:
	var mesh: ArrayMesh = FarmStageParts.make_pot_mesh()

	assert_eq(mesh.get_surface_count(), 2, "gövde + ağız halkası")


func test_the_pot_has_the_profile_height_and_radius() -> void:
	var box: AABB = FarmStageParts.make_pot_mesh().get_aabb()

	assert_almost_eq(box.size.y, FarmStageParts.POT_HEIGHT, 0.001, "yükseklik")
	assert_almost_eq(box.size.x, 2.0 * 0.365, 0.01, "çap (ağız en geniş yer)")
	assert_almost_eq(box.position.y, 0.0, 0.001, "taban rafa oturur")


func test_the_outer_wall_normals_point_away_from_the_axis() -> void:
	var arrays: Array = FarmStageParts.make_pot_mesh().surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	var checked: int = 0
	for i: int in vertices.size():
		# Dış duvar: yarıçap 0.3'ten büyük ve yükseklik ağız halkasının altında.
		var radial: Vector3 = Vector3(vertices[i].x, 0.0, vertices[i].z)
		if radial.length() > 0.3 and vertices[i].y < FarmStageParts.POT_HEIGHT - 0.04 and vertices[i].y > 0.1:
			checked += 1
			assert_true(normals[i].dot(radial.normalized()) > 0.5, "dış duvar normali dışa bakar: %s" % str(normals[i]))
	assert_true(checked > 50, "yeterince dış duvar köşesi denetlendi (%d)" % checked)


func test_every_triangle_winds_to_face_its_normal() -> void:
	var mesh: ArrayMesh = FarmStageParts.make_pot_mesh()
	for surface: int in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
		var wrong: int = 0
		for t: int in indices.size() / 3:
			var a: int = indices[t * 3]
			var b: int = indices[t * 3 + 1]
			var c: int = indices[t * 3 + 2]
			var face: Vector3 = (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a])
			if face.length() > 0.000001 and face.dot(normals[a] + normals[b] + normals[c]) < 0.0:
				wrong += 1
		assert_eq(wrong, 0, "yüzey %d: ters sarılmış üçgen yok" % surface)
