extends TestCase
## PriceChart.points_for: örnekleri çizim noktalarına çevirir; nötr çizgiyi her zaman kapsar ve değerin büyüklüğünü korur.

const EPSILON: float = 0.01
const BOX: Vector2 = Vector2(200.0, 100.0)


func test_no_samples_make_no_points() -> void:
	assert_true(PriceChart.points_for(PackedFloat32Array(), BOX).is_empty())


func test_points_spread_evenly_left_to_right_inside_the_padding() -> void:
	var points: PackedVector2Array = PriceChart.points_for(PackedFloat32Array([1.0, 1.0, 1.0]), BOX, 10.0)

	assert_eq(points.size(), 3)
	assert_almost_eq(points[0].x, 10.0, EPSILON)
	assert_almost_eq(points[1].x, 100.0, EPSILON)
	assert_almost_eq(points[2].x, 190.0, EPSILON)


func test_a_higher_price_is_drawn_higher_on_the_screen() -> void:
	var points: PackedVector2Array = PriceChart.points_for(PackedFloat32Array([1.0, 1.4]), BOX, 0.0)

	assert_true(points[1].y < points[0].y, "yükselen fiyat yukarı çıkar (y küçülür)")


func test_the_axis_always_contains_the_neutral_line_even_for_flat_data() -> void:
	var flat: PackedFloat32Array = PackedFloat32Array([1.0, 1.0])
	var neutral: float = PriceChart.neutral_y(flat, BOX, 0.0)

	assert_true(neutral > 0.0 and neutral < BOX.y, "nötr çizgi kutunun içinde")
	var points: PackedVector2Array = PriceChart.points_for(flat, BOX, 0.0)
	assert_almost_eq(points[0].y, neutral, EPSILON, "düz veri nötr çizgi üzerinde")


func test_a_big_spike_does_not_collapse_the_neutral_line_and_keeps_its_size() -> void:
	var spiky: PackedFloat32Array = PackedFloat32Array([1.0, 2.0, 1.0])
	var points: PackedVector2Array = PriceChart.points_for(spiky, BOX, 0.0)

	assert_almost_eq(points[1].y, 0.0, EPSILON, "en yüksek değer en üstte")
	assert_true(points[0].y > 40.0, "nötr değer tepe noktasından belirgin biçimde aşağıda")
