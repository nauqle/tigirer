extends TestCase
## CreditTag: sayma animasyonu sürerken bile "tutar tamamen yazılınca" kaplanacak genişlik bilinir (HUD'daki "+N" buna göre konur).


func _make(start: int) -> CreditTag:
	var tag: CreditTag = CreditTag.new()
	add_to_tree(tag)
	tag.setup(&"GoldLabel")
	tag.set_amount(start, false)
	return tag


func test_the_final_width_grows_with_the_number_of_digits() -> void:
	var small: CreditTag = _make(5)
	var large: CreditTag = _make(5_000_000)

	assert_true(large.final_width() > small.final_width() + 20.0, "yedi hane bir haneden belirgin geniştir")


func test_the_final_width_does_not_depend_on_a_running_count_up() -> void:
	var settled: CreditTag = _make(1_250_000)
	var counting: CreditTag = _make(0)

	counting.set_amount(1_250_000, true)

	assert_almost_eq(counting.final_width(), settled.final_width(), 0.01, "sayma sürerken de son genişlik")
