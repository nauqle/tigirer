class_name EquipmentDef
extends Resource
## Satın alınabilir donanımın tanımı (veri): maliyet, maliyet artışı, en yüksek seviye. Etkileri (büyüme bonusu,
## sulama hızı, dron hızı) `FarmConfig` ve `AutomationConfig`'te durur; burada yalnızca "ne, kaça, kaç kez" vardır.
## Yeni donanım eklemek bir .tres eklemektir.
##
## Uygular: design/game-brief.md, MVP "otomatik sulama/ışık, hasat dronu" (FAZ 4).
##
## [codeblock]
## var cost: int = equipment.cost_for_level(1)   # 2. seviyenin maliyeti
## [/codeblock]

## Donanım türü ve kapsamı.
enum Kind {
	IRRIGATION,  ## otomatik sulama: SATIR başına
	UV_LAMP,  ## UV büyüme lambası: SATIR başına, seviyeli
	DRONE,  ## hasat dronu: KAT başına, adetli
	LAB_UV,  ## laboratuvar UV odası: GLOBAL, mutasyon olasılığını artırır
}

@export var id: StringName = &""
@export var kind: Kind = Kind.IRRIGATION
@export var display_name: String = ""
@export_multiline var description: String = ""
## İlk seviyenin maliyeti (kredi).
@export_range(0, 1000000) var cost: int = 100
## Her ek seviyede maliyetin çarpıldığı oran (1.0 = hep aynı).
@export_range(1.0, 5.0, 0.05) var cost_growth: float = 1.0
## Hedef başına (satır, kat ya da genel) en çok seviye/adet.
@export_range(1, 20) var max_level: int = 1
## Yalnızca LAB_UV: her seviyenin yeni mutasyon olasılığına eklediği oran (0.03 = +%3 puan).
@export_range(0.0, 0.5, 0.005) var mutation_bonus_per_level: float = 0.0


## Mevcut seviyeden (0 = hiç yok) bir sonrakine geçmenin maliyeti: `cost` x `cost_growth`^seviye, yuvarlanmış.
func cost_for_level(current_level: int) -> int:
	return int(round(float(cost) * pow(cost_growth, float(maxi(current_level, 0)))))
