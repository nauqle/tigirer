class_name MarketEventDef
extends Resource
## Bir haber bülteni olayının tanımı (veri): belirli meyvelerin ya da mutasyonların fiyatını bir süre çarpar.
## Yeni olay eklemek bir .tres eklemektir, kod değişmez.
##
## Uygular: design/game-brief.md, FAZ 3 "haber bülteni etkinlikleri".
##
## [codeblock]
## var event: MarketEventDef = load("res://assets/data/economy/events/event_cyber_craze.tres")
## var factor: float = event.price_multiplier if event.affects(&"fruit_orb", []) else 1.0
## [/codeblock]

## Olayın etkilediği kapsam.
enum Scope {
	ALL,  ## her şey
	FRUIT,  ## `target_ids` içindeki meyve/çiçek türleri
	MUTATION,  ## `target_ids` içindeki mutasyonlardan birini taşıyan bitkiler
}

@export var id: StringName = &""
## Haber başlığı (oyuncuya gösterilir).
@export var headline: String = ""
## Ayrıntı satırı.
@export_multiline var body: String = ""
@export var scope: Scope = Scope.ALL
## Kapsam FRUIT ise meyve kimlikleri, MUTATION ise mutasyon kimlikleri.
@export var target_ids: Array[StringName] = []
## Fiyat çarpanı: 1.5 = %50 zam, 0.6 = %40 düşüş.
@export_range(0.1, 5.0, 0.05) var price_multiplier: float = 1.5
## Olayın süresi (oyun saniyesi).
@export_range(10.0, 1200.0, 1.0) var duration_seconds: float = 120.0
## Rastgele seçimde ağırlık.
@export_range(0.0, 100.0, 0.5) var weight: float = 10.0


## Bu olay verilen meyve türü ve mutasyonlara uygulanıyor mu?
func affects(fruit_id: StringName, mutations: Array[StringName]) -> bool:
	match scope:
		Scope.ALL:
			return true
		Scope.FRUIT:
			return target_ids.has(fruit_id)
		Scope.MUTATION:
			for mutation_id: StringName in mutations:
				if target_ids.has(mutation_id):
					return true
	return false


## Olay fiyatı artırıyor mu (arayüz rengi için)?
func is_positive() -> bool:
	return price_multiplier >= 1.0
