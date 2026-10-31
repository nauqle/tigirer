extends TestCase
## UiFormat: sayı, ondalık, kısaltma, süre ve yüzde biçimleri dile duyarlıdır (Türkçe: 12.480 · 1,5 · %45; İngilizce: 12,480 · 1.5 · 45%).

var _previous_locale: String


func before_each() -> void:
	_previous_locale = TranslationServer.get_locale()


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)


func test_turkish_groups_thousands_with_dots_and_uses_a_decimal_comma() -> void:
	TranslationServer.set_locale("tr")

	assert_eq(UiFormat.number(12480), "12.480")
	assert_eq(UiFormat.number(999), "999")
	assert_eq(UiFormat.number(1000000), "1.000.000")
	assert_eq(UiFormat.number(-4500), "-4.500")
	assert_eq(UiFormat.decimal(1.6, 2), "1,60")
	assert_eq(UiFormat.percent(0.45), "%45")


func test_english_groups_thousands_with_commas_and_uses_a_decimal_point() -> void:
	TranslationServer.set_locale("en")

	assert_eq(UiFormat.number(12480), "12,480")
	assert_eq(UiFormat.number(0), "0")
	assert_eq(UiFormat.decimal(1.6, 2), "1.60")
	assert_eq(UiFormat.percent(0.45), "45%")


func test_large_numbers_are_abbreviated_from_one_million() -> void:
	TranslationServer.set_locale("en")
	assert_eq(UiFormat.compact(999999), "999,999")
	assert_eq(UiFormat.compact(1250000), "1.25M")

	TranslationServer.set_locale("tr")
	assert_eq(UiFormat.compact(1250000), "1,25 Mn")


func test_clock_shows_minutes_and_hours_and_never_goes_negative() -> void:
	assert_eq(UiFormat.clock(65.0), "1:05")
	assert_eq(UiFormat.clock(3725.0), "1:02:05")
	assert_eq(UiFormat.clock(-5.0), "0:00")


func test_signed_percent_carries_the_sign_and_zero_has_none() -> void:
	TranslationServer.set_locale("en")
	assert_eq(UiFormat.signed_percent(0.12), "+12%")
	assert_eq(UiFormat.signed_percent(-0.08), "-8%")
	assert_eq(UiFormat.signed_percent(0.001), "0%")

	TranslationServer.set_locale("tr")
	assert_eq(UiFormat.signed_percent(0.12), "+%12")
	assert_eq(UiFormat.signed_percent(-0.08), "-%8")
