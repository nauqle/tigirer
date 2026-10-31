extends TestCase
## FarmStage kamerası ve ekran <-> düzlem dönüşümü: analitik hesaplanır, çizilmiş görünüm penceresine bağlı değildir.
## Oyun düzlemi z = 0, birim karo; her boyutta ve her kat boyutunda ızgara görünüm penceresine sığmalıdır.

const RULESET_PATH: String = "res://assets/data/genetics/default_ruleset.tres"
const EPSILON: float = 0.01

var _ruleset: GeneticsRuleset


func before_each() -> void:
	_ruleset = load(RULESET_PATH) as GeneticsRuleset


func _stage(cols: int, rows: int, view: Vector2) -> FarmStage:
	var stage: FarmStage = FarmStage.new()
	add_to_tree(stage)
	stage.setup(_ruleset)
	stage.set_view_size(view)
	stage.build_floor(FarmFixtures.make_floor(cols, rows, true, 0))
	return stage


func test_a_plane_point_survives_a_project_and_unproject_round_trip() -> void:
	var stage: FarmStage = _stage(3, 2, Vector2(1030.0, 1000.0))
	var points: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(1.5, -1.2), Vector2(3.0, -4.0), Vector2(-0.8, -2.5), Vector2(2.2, -3.3)]

	for point: Vector2 in points:
		var screen: Vector2 = stage.project(FarmStage.plane_world(point.x, point.y))
		var back: Vector2 = stage.plane_point(screen)
		assert_almost_eq(back.x, point.x, EPSILON, "x gidiş-dönüş %s" % str(point))
		assert_almost_eq(back.y, point.y, EPSILON, "y gidiş-dönüş %s" % str(point))


func test_the_round_trip_still_holds_after_the_camera_drifts_and_dollies() -> void:
	var stage: FarmStage = _stage(4, 3, Vector2(1030.0, 900.0))
	stage.advance(3.7)
	stage.set_dolly(0.9)
	var point: Vector2 = Vector2(2.0, -3.0)

	var back: Vector2 = stage.plane_point(stage.project(FarmStage.plane_world(point.x, point.y)))

	assert_almost_eq(back.x, point.x, EPSILON)
	assert_almost_eq(back.y, point.y, EPSILON)


func test_every_pot_base_fits_inside_the_view_for_each_floor_size_and_aspect() -> void:
	var sizes: Array[Vector2i] = [Vector2i(3, 2), Vector2i(3, 3), Vector2i(4, 3), Vector2i(4, 4)]
	var views: Array[Vector2] = [Vector2(1030.0, 1000.0), Vector2(1030.0, 560.0), Vector2(1030.0, 1700.0), Vector2(520.0, 1000.0)]
	for floor_size: Vector2i in sizes:
		for view: Vector2 in views:
			var stage: FarmStage = _stage(floor_size.x, floor_size.y, view)
			for pot_index: int in floor_size.x * floor_size.y:
				var at: Vector2 = stage.project(stage.pot_base_world(pot_index))
				var inside: bool = at.x > 0.0 and at.x < view.x and at.y > 0.0 and at.y < view.y
				assert_true(inside, "%dx%d pencere %s saksı %d: %s" % [floor_size.x, floor_size.y, str(view), pot_index, str(at)])


func test_the_tile_size_on_screen_is_capped_so_a_small_floor_does_not_balloon() -> void:
	var stage: FarmStage = _stage(3, 2, Vector2(1030.0, 3000.0))

	assert_true(stage.pixels_per_tile() <= FarmStage.MAX_PIXELS_PER_TILE + 0.5, "çok uzun pencerede de karo sınırı aşılmaz (%f)" % stage.pixels_per_tile())


func test_a_taller_floor_makes_each_tile_smaller_in_the_same_view() -> void:
	var small: FarmStage = _stage(3, 2, Vector2(1030.0, 1000.0))
	var tall: FarmStage = _stage(4, 4, Vector2(1030.0, 1000.0))

	assert_true(tall.pixels_per_tile() < small.pixels_per_tile(), "büyük kat aynı pencereye sığmak için küçülür")


func test_reduce_motion_freezes_the_camera_while_normal_motion_drifts_it() -> void:
	var calm: FarmStage = _stage(3, 2, Vector2(1030.0, 1000.0))
	calm.reduce_motion = true
	var before: Vector2 = calm.project(calm.pot_base_world(0))
	calm.advance(2.5)
	assert_eq(calm.project(calm.pot_base_world(0)), before, "hareketi azalt: kamera sabit")

	var drifting: FarmStage = _stage(3, 2, Vector2(1030.0, 1000.0))
	var start: Vector2 = drifting.project(drifting.pot_base_world(0))
	drifting.advance(2.5)
	var moved: float = drifting.project(drifting.pot_base_world(0)).distance_to(start)
	assert_true(moved > 0.5, "süzülme saksıyı birkaç piksel kaydırır (%f)" % moved)
	assert_true(moved < 40.0, "ama oyun düzlemini bozacak kadar değil (%f)" % moved)


func test_a_point_behind_the_camera_projects_far_outside_the_view() -> void:
	var stage: FarmStage = _stage(3, 2, Vector2(1030.0, 1000.0))

	var at: Vector2 = stage.project(Vector3(1.5, -2.0, 400.0))

	assert_true(at.x < -1000.0, "kameranın arkası görünüm dışı")


func test_night_dims_the_sun_and_day_restores_it() -> void:
	var stage: FarmStage = _stage(3, 2, Vector2(1030.0, 1000.0))
	var day: float = stage.sun_energy()

	stage.set_night(1.0)
	var night: float = stage.sun_energy()
	stage.set_night(0.0)

	assert_true(night < day, "gece güneş ışığı azalır")
	assert_almost_eq(stage.sun_energy(), day, 0.0001, "gündüz eski şiddete döner")


func test_a_pot_base_sits_on_the_rim_of_a_pot_standing_on_its_shelf() -> void:
	var stage: FarmStage = _stage(3, 2, Vector2(1030.0, 1000.0))

	for pot_index: int in 6:
		var col: int = pot_index % 3
		var row: int = pot_index / 3
		var base: Vector3 = stage.pot_base_world(pot_index)
		var shelf_top: float = -float(2 * row + 2)
		assert_almost_eq(base.x, float(col) + 0.5, 0.0001, "saksı %d sütun ortası" % pot_index)
		assert_almost_eq(base.y, shelf_top + FarmStageParts.POT_HEIGHT, 0.01, "saksı %d: kök, raf üstü + saksı yüksekliği" % pot_index)
		assert_almost_eq(base.z, 0.0, 0.0001, "oyun düzleminde")


func test_the_first_row_sits_above_the_second_on_screen_and_columns_run_left_to_right() -> void:
	var stage: FarmStage = _stage(3, 2, Vector2(1030.0, 1000.0))

	var top_left: Vector2 = stage.project(stage.pot_base_world(0))
	var top_right: Vector2 = stage.project(stage.pot_base_world(2))
	var bottom_left: Vector2 = stage.project(stage.pot_base_world(3))

	assert_true(top_right.x > top_left.x + 100.0, "sütunlar soldan sağa")
	assert_true(bottom_left.y > top_left.y + 100.0, "ikinci satır ilkinin altında")
