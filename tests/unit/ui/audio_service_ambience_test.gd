extends TestCase
## AudioService: sera uğultusu ses ayarına bağlıdır (açıkken döner, kapalıyken susar).


func _make(sound_on: bool = true) -> AudioService:
	var audio: AudioService = AudioService.new()
	audio.enabled = sound_on
	add_to_tree(audio)
	return audio


func test_the_greenhouse_hum_starts_when_sound_is_on() -> void:
	var audio: AudioService = _make()

	assert_true(audio.is_ambience_playing())


func test_turning_sound_off_silences_the_hum_and_turning_it_on_restarts_it() -> void:
	var audio: AudioService = _make()

	audio.enabled = false
	assert_false(audio.is_ambience_playing(), "kapalıyken susar")

	audio.enabled = true
	assert_true(audio.is_ambience_playing(), "açılınca yeniden başlar")


func test_the_hum_sits_far_below_the_effects() -> void:
	var audio: AudioService = _make()

	assert_true(AudioService.AMBIENCE_VOLUME_DB <= audio.volume_db - 15.0)


func test_an_audio_service_created_with_sound_off_never_starts_the_hum() -> void:
	var audio: AudioService = _make(false)

	assert_false(audio.is_ambience_playing())
