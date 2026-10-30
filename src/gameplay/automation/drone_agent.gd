class_name DroneAgent
extends RefCounted
## Hasat dronunun durum makinesi: durumlar ve AÇIK geçiş tablosu. Yalnızca tablodaki geçişlere izin verilir;
## başka bir geçiş reddedilir. Hareketi/mantığı `DroneService` yürütür, burası yalnızca "hangi durumdan nereye" bilgisini tutar.
##
## Uygular: design/game-brief.md, FAZ 4 "hasat dronları için basit durum makinesi [State Machine]".
##
## Durumlar ve geçişler:
##   IDLE       -> SEEKING                       (bekleme bitti)
##   SEEKING    -> FLYING_TO | IDLE              (hedef bulundu | olgun bitki yok)
##   FLYING_TO  -> HARVESTING | SEEKING          (vardı | hedef kayboldu, oyuncu biçti)
##   HARVESTING -> RETURNING                     (biçti)
##   RETURNING  -> IDLE                          (üsse döndü)
##
## [codeblock]
## var agent: DroneAgent = DroneAgent.new()
## if agent.transition(DroneAgent.State.SEEKING):
##     print(DroneAgent.State.keys()[agent.state])
## [/codeblock]

enum State {
	IDLE,  ## üste bekliyor
	SEEKING,  ## olgun bir bitki arıyor
	FLYING_TO,  ## hedefe uçuyor
	HARVESTING,  ## biçiyor
	RETURNING,  ## üsse dönüyor
}

## Geçiş tablosu: durum -> izin verilen sonraki durumlar.
const TRANSITIONS: Dictionary = {
	State.IDLE: [State.SEEKING],
	State.SEEKING: [State.FLYING_TO, State.IDLE],
	State.FLYING_TO: [State.HARVESTING, State.SEEKING],
	State.HARVESTING: [State.RETURNING],
	State.RETURNING: [State.IDLE],
}

var state: State = State.IDLE
## Saksı hücresi biriminde konum (sütun, satır); saksı merkezi (sütun + 0.5, satır + 0.5).
var position: Vector2 = Vector2.ZERO
## Üs konumu (aynı birim).
var dock: Vector2 = Vector2.ZERO
## Hedef saksının indeksi (-1 = yok).
var target_pot: int = -1
## Duruma özgü geri sayım (bekleme, biçme).
var timer: float = 0.0


## `to` durumuna geçiş tabloda var mı?
func can_transition(to: State) -> bool:
	return (TRANSITIONS[state] as Array).has(to)


## Geçiş izinliyse durumu değiştirir ve true döner; değilse hiçbir şey değişmez ve false döner.
func transition(to: State) -> bool:
	if not can_transition(to):
		return false
	state = to
	return true
