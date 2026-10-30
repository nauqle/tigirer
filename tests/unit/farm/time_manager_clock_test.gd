extends TestCase
## TimeManager: hız çarpanı, duraklatma, hız sınırı ve gün değişimi.

const EPSILON: float = 0.0001

var _time: TimeManager


func before_each() -> void:
	_time = TimeManager.new()
	_time.setup(100.0, 5.0)


func test_advance_scales_real_time_by_the_speed() -> void:
	_time.set_speed(2.0)

	var game_delta: float = _time.advance(1.5)

	assert_almost_eq(game_delta, 3.0, EPSILON, "dönen oyun saniyesi")
	assert_almost_eq(_time.game_seconds, 3.0, EPSILON, "saat ilerledi")


func test_a_paused_clock_does_not_advance() -> void:
	_time.paused = true

	var game_delta: float = _time.advance(10.0)

	assert_almost_eq(game_delta, 0.0, EPSILON)
	assert_almost_eq(_time.game_seconds, 0.0, EPSILON)


func test_speed_is_clamped_between_zero_and_the_maximum() -> void:
	_time.set_speed(99.0)
	assert_almost_eq(_time.speed, 5.0, EPSILON, "üst sınır")

	_time.set_speed(-1.0)
	assert_almost_eq(_time.speed, 0.0, EPSILON, "alt sınır")


func test_a_new_day_is_announced_exactly_once_when_the_day_length_is_crossed() -> void:
	var announced: Array[int] = []
	_time.day_changed.connect(func(day: int) -> void: announced.append(day))

	_time.advance(99.0)
	assert_eq(announced.size(), 0, "gün bitmeden olay yok")
	_time.advance(2.0)
	_time.advance(5.0)

	assert_eq(announced, [2] as Array[int], "yalnızca 2. gün bir kez")
	assert_eq(_time.day(), 2)


func test_restore_sets_the_clock_without_announcing_a_day() -> void:
	var announced: Array[int] = []
	_time.day_changed.connect(func(day: int) -> void: announced.append(day))

	_time.restore(250.0)

	assert_eq(_time.day(), 3, "250 sn / 100 sn = 3. gün")
	assert_eq(announced.size(), 0, "yükleme gün olayı tetiklemez")
	assert_almost_eq(_time.day_progress(), 0.5, EPSILON)
