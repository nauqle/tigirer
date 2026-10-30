extends TestCase
## SegmentMath: kaydırma doğrusunun bitki dikdörtgenine değip değmediği.

const BOX: Rect2 = Rect2(100.0, 100.0, 50.0, 80.0)


func test_a_segment_crossing_the_rect_hits_it() -> void:
	assert_true(SegmentMath.segment_hits_rect(Vector2(50, 140), Vector2(200, 140), BOX), "soldan sağa içinden geçer")
	assert_true(SegmentMath.segment_hits_rect(Vector2(125, 0), Vector2(125, 300), BOX), "yukarıdan aşağıya")
	assert_true(SegmentMath.segment_hits_rect(Vector2(90, 90), Vector2(160, 190), BOX), "çapraz, iki köşeyi keser")


func test_a_segment_entirely_inside_the_rect_hits_it() -> void:
	assert_true(SegmentMath.segment_hits_rect(Vector2(110, 110), Vector2(140, 170), BOX))


func test_a_segment_that_stops_short_or_passes_beside_misses() -> void:
	assert_false(SegmentMath.segment_hits_rect(Vector2(0, 140), Vector2(90, 140), BOX), "dikdörtgene varmadan biter")
	assert_false(SegmentMath.segment_hits_rect(Vector2(0, 50), Vector2(300, 50), BOX), "üstünden geçer")
	assert_false(SegmentMath.segment_hits_rect(Vector2(160, 0), Vector2(160, 300), BOX), "yanından geçer")
	assert_false(SegmentMath.segment_hits_rect(Vector2(0, 0), Vector2(80, 300), BOX), "uzak çapraz")


func test_touching_the_edge_counts_as_a_hit() -> void:
	assert_true(SegmentMath.segment_hits_rect(Vector2(100, 0), Vector2(100, 300), BOX), "sol kenar")
	assert_true(SegmentMath.segment_hits_rect(Vector2(0, 100), Vector2(300, 100), BOX), "üst kenar")


func test_a_zero_length_segment_is_tested_as_a_point() -> void:
	assert_true(SegmentMath.segment_hits_rect(Vector2(120, 120), Vector2(120, 120), BOX), "içeride nokta")
	assert_false(SegmentMath.segment_hits_rect(Vector2(10, 10), Vector2(10, 10), BOX), "dışarıda nokta")
