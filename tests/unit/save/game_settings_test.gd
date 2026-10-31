extends TestCase
## GameSettings: varsayılanlar, yazı boyutu basamakları, `changed` olayı ve kayıt.


func test_defaults_are_sound_on_normal_text_and_no_special_modes() -> void:
	var settings: GameSettings = GameSettings.new()

	assert_true(settings.sound_on)
	assert_true(settings.vibration_on)
	assert_false(settings.reduce_motion)
	assert_false(settings.colorblind)
	assert_false(settings.tutorial_done)
	assert_almost_eq(settings.text_scale(), 1.0, 0.0001)


func test_text_scale_follows_the_index_and_the_index_is_clamped() -> void:
	var settings: GameSettings = GameSettings.new()

	settings.set_text_scale_index(3)
	assert_almost_eq(settings.text_scale(), 1.4, 0.0001)

	settings.set_text_scale_index(99)
	assert_eq(settings.text_scale_index, GameSettings.TEXT_SCALES.size() - 1)

	settings.set_text_scale_index(-5)
	assert_eq(settings.text_scale_index, 0)
	assert_almost_eq(settings.text_scale(), 0.9, 0.0001)


func test_text_scale_stays_inside_the_table_even_when_the_index_field_is_out_of_range() -> void:
	var settings: GameSettings = GameSettings.new()

	settings.text_scale_index = 9
	assert_almost_eq(settings.text_scale(), 1.4, 0.0001, "çok büyük indeks son ölçeğe sıkıştırılır")

	settings.text_scale_index = -3
	assert_almost_eq(settings.text_scale(), 0.9, 0.0001, "negatif indeks ilk ölçeğe sıkıştırılır")


func test_loading_settings_announces_a_change_so_the_interface_restyles() -> void:
	var settings: GameSettings = GameSettings.new()
	var count: Dictionary = {"n": 0}
	settings.changed.connect(func() -> void: count["n"] += 1)

	settings.load_dict({"colorblind": true})

	assert_eq(count["n"], 1)
	assert_true(settings.colorblind)


func test_every_setter_announces_a_change() -> void:
	var settings: GameSettings = GameSettings.new()
	var count: Dictionary = {"n": 0}
	settings.changed.connect(func() -> void: count["n"] += 1)

	settings.set_sound(false)
	settings.set_vibration(false)
	settings.set_reduce_motion(true)
	settings.set_text_scale_index(2)
	settings.set_colorblind(true)
	settings.set_tutorial_done(true)

	assert_eq(count["n"], 6)
	assert_false(settings.sound_on)
	assert_true(settings.reduce_motion and settings.colorblind and settings.tutorial_done)


func test_settings_survive_a_json_round_trip_and_missing_keys_fall_back_to_defaults() -> void:
	var settings: GameSettings = GameSettings.new()
	settings.set_sound(false)
	settings.set_text_scale_index(2)
	settings.set_colorblind(true)
	var restored: GameSettings = GameSettings.new()

	restored.load_dict(JSON.parse_string(JSON.stringify(settings.to_dict())) as Dictionary)

	assert_false(restored.sound_on)
	assert_eq(restored.text_scale_index, 2)
	assert_true(restored.colorblind)

	restored.load_dict({})
	assert_true(restored.sound_on, "eksik anahtar varsayılana döner")
	assert_eq(restored.text_scale_index, 1)


func test_language_starts_unset_and_only_supported_codes_are_accepted() -> void:
	var settings: GameSettings = GameSettings.new()
	var count: Dictionary = {"n": 0}
	settings.changed.connect(func() -> void: count["n"] += 1)

	assert_eq(settings.language, "", "ilk açılışta seçilmemiş")
	settings.set_language("fr")
	assert_eq(settings.language, "", "desteklenmeyen dil yok sayılır")
	assert_eq(count["n"], 0)

	settings.set_language("en")
	assert_eq(settings.language, "en")
	assert_eq(count["n"], 1)


func test_the_default_language_follows_the_system_language_and_falls_back_to_english() -> void:
	assert_eq(GameSettings.default_language("tr"), "tr")
	assert_eq(GameSettings.default_language("tr_TR"), "tr")
	assert_eq(GameSettings.default_language("TR"), "tr")
	assert_eq(GameSettings.default_language("en_US"), "en")
	assert_eq(GameSettings.default_language("de"), "en", "bilinmeyen sistem dili İngilizceye düşer")
	assert_eq(GameSettings.default_language(""), "en")


func test_the_language_survives_a_round_trip_and_garbage_is_dropped() -> void:
	var settings: GameSettings = GameSettings.new()
	settings.set_language("tr")
	var restored: GameSettings = GameSettings.new()

	restored.load_dict(JSON.parse_string(JSON.stringify(settings.to_dict())) as Dictionary)
	assert_eq(restored.language, "tr")

	restored.load_dict({"language": "klingon"})
	assert_eq(restored.language, "", "bozuk dil seçimi temizlenir")
