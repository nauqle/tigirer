extends TestCase
## SfxBank: her ses kimliği için kısa, sessiz olmayan ve deterministik bir akış üretir.


func test_every_sound_id_produces_a_short_audible_stream() -> void:
	for id: SfxBank.Id in SfxBank.Id.values():
		var stream: AudioStreamWAV = SfxBank.make(id)

		assert_not_null(stream, "akış var: %s" % SfxBank.Id.keys()[id])
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
		assert_eq(stream.mix_rate, SfxBank.SAMPLE_RATE)
		var seconds: float = float(stream.data.size()) / 2.0 / float(SfxBank.SAMPLE_RATE)
		assert_between(seconds, 0.03, 1.0, "süre makul: %s" % SfxBank.Id.keys()[id])
		var peak: int = 0
		for i: int in stream.data.size() / 2:
			peak = maxi(peak, absi(stream.data.decode_s16(i * 2)))
		assert_true(peak > 2000, "sessiz değil: %s (tepe %d)" % [SfxBank.Id.keys()[id], peak])


func test_generation_is_deterministic() -> void:
	for id: SfxBank.Id in SfxBank.Id.values():
		assert_eq(SfxBank.make(id).data, SfxBank.make(id).data, "aynı kimlik, aynı bayt: %s" % SfxBank.Id.keys()[id])


func test_different_sounds_are_actually_different() -> void:
	assert_ne(SfxBank.make(SfxBank.Id.SNIP).data, SfxBank.make(SfxBank.Id.PLANT).data)
	assert_ne(SfxBank.make(SfxBank.Id.COIN).data, SfxBank.make(SfxBank.Id.ERROR).data)
