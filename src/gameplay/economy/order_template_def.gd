class_name OrderTemplateDef
extends Resource
## VIP müşteri sözleşmesi şablonu (veri): hangi ürünü, kaç adet, hangi koşulla ister ve ne kadar prim öder.
## `OrderService` bu şablonlardan rastgele sipariş üretir. Yeni müşteri tipi eklemek bir .tres eklemektir.
##
## Uygular: design/game-brief.md, FAZ 3 "VIP müşteri kontratları".
##
## [codeblock]
## var template: OrderTemplateDef = load("res://assets/data/economy/orders/order_cyber_collector.tres")
## print(template.title, " ", template.min_quantity, "-", template.max_quantity)
## [/codeblock]

@export var id: StringName = &""
## Sözleşme başlığı (oyuncuya gösterilir).
@export var title: String = ""
## Müşteri adları havuzu; sipariş birini seçer.
@export var customers: PackedStringArray = PackedStringArray()
## İstenen meyve/çiçek türleri; boşsa kural setindeki herhangi biri.
@export var fruit_ids: Array[StringName] = []
## Boş değilse ürün bu mutasyonu taşımalı.
@export var mutation_id: StringName = &""
## Ürünün tek birim değeri en az bu olmalı (0 = koşul yok).
@export_range(0.0, 1000.0, 1.0) var min_unit_value: float = 0.0
@export_range(1, 30) var min_quantity: int = 2
@export_range(1, 30) var max_quantity: int = 4
## Ödül çarpanı (EconomyConfig.order_reward_multiplier üstüne).
@export_range(0.5, 5.0, 0.05) var reward_multiplier: float = 1.0
## Rastgele seçimde ağırlık.
@export_range(0.0, 100.0, 0.5) var weight: float = 10.0
## Bu şablon için gereken en düşük itibar seviyesi.
@export_range(0, 20) var min_reputation_level: int = 0
