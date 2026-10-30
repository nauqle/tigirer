class_name TimeManager
extends RefCounted
## Oyun saati: gerçek zamanı oyun zamanına çevirir (hız çarpanı, duraklatma) ve "gün" sayar.
## Durum tutar ama sahneye/Autoload'a bağlı değildir: `GameSession` her karede `advance()` çağırır, dönen oyun
## saniyesini sistemlere dağıtır (dependency injection; testler saati elle ilerletir).
##
## Uygular: design/game-brief.md, FAZ 2 "TimeManager ile büyüme evreleri".
##
## [codeblock]
## var time: TimeManager = TimeManager.new()
## time.setup(config.day_length_seconds, config.max_speed)
## var game_delta: float = time.advance(delta)   # hız ve duraklatma uygulanmış
## farm.tick(game_delta)
## [/codeblock]

## Yeni bir oyun günü başladı (1'den başlar).
signal day_changed(day: int)

## Oyun başladığından beri geçen oyun saniyesi.
var game_seconds: float = 0.0
## Hız çarpanı [0, max_speed]; 0 duraklatmadır.
var speed: float = 1.0
var paused: bool = false

var _day_length: float = 300.0
var _max_speed: float = 5.0
var _last_day: int = 1


## Gün uzunluğunu ve en yüksek hızı ayarlar (genellikle `FarmConfig`'ten).
func setup(day_length_seconds: float, max_speed: float) -> void:
	_day_length = maxf(day_length_seconds, 1.0)
	_max_speed = maxf(max_speed, 1.0)
	speed = clampf(speed, 0.0, _max_speed)
	_last_day = day()


## Gerçek `delta` saniyeyi oyun zamanına çevirip saati ilerletir; eklenen oyun saniyesini döndürür.
func advance(real_delta: float) -> float:
	if paused or real_delta <= 0.0:
		return 0.0
	var game_delta: float = real_delta * speed
	game_seconds += game_delta
	var today: int = day()
	if today != _last_day:
		_last_day = today
		day_changed.emit(today)
	return game_delta


## Geçerli oyun günü (1'den başlar).
func day() -> int:
	return int(game_seconds / _day_length) + 1


## Günün ne kadarının geçtiği, 0..1 (arayüz göstergesi için).
func day_progress() -> float:
	return fmod(game_seconds, _day_length) / _day_length


## Hızı [0, max_speed] aralığına kırparak ayarlar.
func set_speed(value: float) -> void:
	speed = clampf(value, 0.0, _max_speed)


## Saati, kayıttan yüklenen değere ayarlar (gün olayı tetiklemez).
func restore(seconds: float) -> void:
	game_seconds = maxf(seconds, 0.0)
	_last_day = day()
