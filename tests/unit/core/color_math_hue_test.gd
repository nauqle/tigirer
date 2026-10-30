extends TestCase
## ColorMath ton (hue) yardımcılarının testleri. Ton [0, 1) aralığında DAİRESELDİR: 0.95 ile 0.05
## birbirine 0.1 uzaklıktadır, 0.9 değil. Çaprazlanan çiçek renginin doğru çıkması buna bağlı.

const EPSILON: float = 0.000001


func test_wrap_hue_wraps_values_into_unit_range() -> void:
	# Arrange / Act
	var above: float = ColorMath.wrap_hue(1.25)
	var below: float = ColorMath.wrap_hue(-0.1)
	var inside: float = ColorMath.wrap_hue(0.4)

	# Assert
	assert_almost_eq(above, 0.25, EPSILON, "1.25 -> 0.25")
	assert_almost_eq(below, 0.9, EPSILON, "-0.1 -> 0.9")
	assert_almost_eq(inside, 0.4, EPSILON, "aralık içindeki değer değişmemeli")


func test_hue_distance_measures_the_short_way_around_the_circle() -> void:
	assert_almost_eq(ColorMath.hue_distance(0.95, 0.05), 0.1, EPSILON, "dikişin iki yanı 0.1 uzakta")
	assert_almost_eq(ColorMath.hue_distance(0.1, 0.4), 0.3, EPSILON, "dikişi geçmeyen çift")
	assert_almost_eq(ColorMath.hue_distance(0.0, 0.5), 0.5, EPSILON, "en uzak çift 0.5")


func test_mix_hues_across_the_seam_takes_the_short_arc() -> void:
	# Arrange: 0.95 ve 0.05 birbirine yakın kırmızılar; ortalamaları kırmızı (0.0) olmalı, camgöbeği (0.5) değil.
	# Act
	var mixed: float = ColorMath.mix_hues(0.95, 0.05)

	# Assert
	assert_almost_eq(ColorMath.hue_distance(mixed, 0.0), 0.0, EPSILON, "ortalama 0.0 civarında olmalı, 0.5 değil")


func test_mix_hues_without_crossing_the_seam_is_the_midpoint() -> void:
	assert_almost_eq(ColorMath.mix_hues(0.1, 0.3), 0.2, EPSILON)


func test_mix_hues_is_order_independent() -> void:
	# Tam karşıt tonlar (fark = 0.5) sıraya bağlı sonuç verirse aynı iki ebeveynden iki farklı çocuk çıkar.
	assert_almost_eq(ColorMath.mix_hues(0.0, 0.5), ColorMath.mix_hues(0.5, 0.0), EPSILON, "karşıt tonlar")
	assert_almost_eq(ColorMath.mix_hues(0.95, 0.05), ColorMath.mix_hues(0.05, 0.95), EPSILON, "dikiş")
	assert_almost_eq(ColorMath.mix_hues(0.2, 0.7), ColorMath.mix_hues(0.7, 0.2), EPSILON, "genel")


func test_mix_hues_of_identical_hues_returns_that_hue() -> void:
	assert_almost_eq(ColorMath.mix_hues(0.37, 0.37), 0.37, EPSILON)


func test_lerp_hue_moves_along_the_short_arc() -> void:
	# 0.9 -> 0.1 kısa yoldan 0.2 uzaklık (dikişi geçerek); yarısı 0.0 olmalı
	var halfway: float = ColorMath.lerp_hue(0.9, 0.1, 0.5)
	assert_almost_eq(ColorMath.hue_distance(halfway, 0.0), 0.0, EPSILON, "dikişi geçerek yarı yol")
	assert_almost_eq(ColorMath.lerp_hue(0.2, 0.6, 0.0), 0.2, EPSILON, "ağırlık 0: başlangıç")
	assert_almost_eq(ColorMath.lerp_hue(0.2, 0.6, 1.0), 0.6, EPSILON, "ağırlık 1: hedef")
