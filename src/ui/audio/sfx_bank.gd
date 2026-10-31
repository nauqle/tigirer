class_name SfxBank
extends RefCounted
## Prosedürel ses efektleri: dosya yok, her ses çalışma anında matematikle üretilir (küçük APK, telifsiz).
## 22,05 kHz, 16 bit, tek kanal. Üretim deterministiktir (aynı çağrı aynı ses).
##
## Uygular: design/game-brief.md, FAZ 2 "ASMR hasat sesleri" ve "Art & audio direction".
##
## [codeblock]
## var stream: AudioStreamWAV = SfxBank.make(SfxBank.Id.SNIP)
## player.stream = stream
## player.play()
## [/codeblock]

## Ses kimlikleri.
enum Id {
	SNIP,  ## hasat: kısa, parlak "çıt"
	PLANT,  ## ekim: yumuşak "tıp"
	WATER,  ## sulama: akış
	COIN,  ## satış: iki notalı "ding"
	MUTATION,  ## mutasyon: yükselen pırıltı
	TAP,  ## arayüz dokunuşu
	MATURE,  ## bitki olgunlaştı: sakin çan
	ERROR,  ## yapılamaz
	ORDER,  ## sipariş teslim: kutlama
	UPGRADE,  ## donanım/kat alındı
}

const SAMPLE_RATE: int = 22050
## Ortam sesi döngüsünün uzunluğu (saniye) ve uç uca bindirme süresi.
const AMBIENCE_SECONDS: float = 8.0
const AMBIENCE_FADE_SECONDS: float = 0.8


## Verilen kimliğin ses akışını üretir.
static func make(id: Id) -> AudioStreamWAV:
	match id:
		Id.SNIP:
			return _to_stream(_snip())
		Id.PLANT:
			return _to_stream(_plant())
		Id.WATER:
			return _to_stream(_water())
		Id.COIN:
			return _to_stream(_notes([988.0, 1319.0], 0.07, 0.3, 14.0))
		Id.MUTATION:
			return _to_stream(_notes([523.0, 659.0, 784.0, 1047.0, 1319.0], 0.09, 0.6, 5.0))
		Id.TAP:
			return _to_stream(_notes([1800.0], 0.0, 0.05, 90.0))
		Id.MATURE:
			return _to_stream(_notes([880.0, 1320.0], 0.0, 0.32, 8.0))
		Id.ERROR:
			return _to_stream(_notes([150.0], 0.0, 0.2, 9.0, 0.28, true))
		Id.ORDER:
			return _to_stream(_notes([523.0, 659.0, 784.0, 1047.0], 0.12, 0.7, 4.5))
		Id.UPGRADE:
			return _to_stream(_notes([392.0, 587.0, 784.0], 0.1, 0.55, 5.5))
	return _to_stream(PackedFloat32Array([0.0]))


## Sera ortam sesi: alçak uğultu (55 ve 82.5 Hz, yavaş nefes alan genlik) + hafif, süzülmüş hava gürültüsü. Döngü uçları eşit güçle
## birbirine bindirilir (dikişsiz). Alçak ve sürekli olduğundan oyuncuyu yormaz; deterministiktir.
static func make_ambience() -> AudioStreamWAV:
	var loop_count: int = int(SAMPLE_RATE * AMBIENCE_SECONDS)
	var fade_count: int = int(SAMPLE_RATE * AMBIENCE_FADE_SECONDS)
	var raw: PackedFloat32Array = PackedFloat32Array()
	raw.resize(loop_count + fade_count)
	var noise_state: int = 4242
	var smooth: float = 0.0
	for i: int in raw.size():
		var t: float = float(i) / float(SAMPLE_RATE)
		noise_state = (noise_state * 1103515245 + 12345) & 0x7FFFFFFF
		var noise: float = float(noise_state) / float(0x7FFFFFFF) * 2.0 - 1.0
		smooth += (noise - smooth) * 0.035
		var breathe: float = 0.75 + 0.25 * sin(TAU * t / AMBIENCE_SECONDS)
		var hum: float = sin(TAU * 55.0 * t) * 0.07 + sin(TAU * 82.5 * t) * 0.035 * (0.6 + 0.4 * sin(TAU * 2.0 * t / AMBIENCE_SECONDS))
		raw[i] = hum * breathe + smooth * 0.12
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(loop_count)
	for i: int in loop_count:
		samples[i] = raw[i]
	for i: int in fade_count:
		var blend: float = float(i) / float(fade_count)
		samples[i] = raw[i] * sin(blend * PI * 0.5) + raw[loop_count + i] * cos(blend * PI * 0.5)
	var stream: AudioStreamWAV = _to_stream(samples)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = loop_count
	return stream


## Gürültü patlaması + yükselen kısa sinüs: "çıt".
static func _snip() -> PackedFloat32Array:
	var count: int = int(SAMPLE_RATE * 0.14)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var noise_state: int = 12345
	for i: int in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		noise_state = (noise_state * 1103515245 + 12345) & 0x7FFFFFFF
		var noise: float = float(noise_state) / float(0x7FFFFFFF) * 2.0 - 1.0
		var chirp: float = sin(TAU * (1400.0 * t + 3200.0 * t * t))
		samples[i] = noise * exp(-t * 42.0) * 0.45 + chirp * exp(-t * 28.0) * 0.4
	return samples


## Düşen frekanslı yumuşak darbe: "tıp".
static func _plant() -> PackedFloat32Array:
	var count: int = int(SAMPLE_RATE * 0.16)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	for i: int in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		samples[i] = sin(TAU * (240.0 * t - 520.0 * t * t)) * exp(-t * 22.0) * 0.6
	return samples


## Alçak geçiren süzgeçten geçmiş gürültü, yumuşak zarf: akış.
static func _water() -> PackedFloat32Array:
	var count: int = int(SAMPLE_RATE * 0.32)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var noise_state: int = 777
	var smooth: float = 0.0
	for i: int in count:
		var t: float = float(i) / float(count)
		noise_state = (noise_state * 1103515245 + 12345) & 0x7FFFFFFF
		var noise: float = float(noise_state) / float(0x7FFFFFFF) * 2.0 - 1.0
		smooth += (noise - smooth) * lerpf(0.30, 0.08, t)
		samples[i] = smooth * pow(sin(PI * t), 1.4) * 0.9
	return samples


## Notalar dizisi: her nota `step` saniye arayla başlar, `exp(-decay x t)` ile söner. `square` doğruysa kare dalga (hata sesi).
static func _notes(frequencies: Array[float], step: float, duration: float, decay: float, gain: float = 0.35, square: bool = false) -> PackedFloat32Array:
	var count: int = int(SAMPLE_RATE * duration)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	for note_index: int in frequencies.size():
		var start: int = int(SAMPLE_RATE * step * float(note_index))
		for i: int in range(start, count):
			var t: float = float(i - start) / float(SAMPLE_RATE)
			var wave: float = sin(TAU * frequencies[note_index] * t)
			if square:
				wave = signf(wave) * 0.6
			samples[i] += wave * exp(-t * decay) * gain
	return samples


static func _to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i: int in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
