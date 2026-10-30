class_name Order
extends RefCounted
## Açık bir VIP siparişi: müşteri, istenen ürün koşulu, adet, ödül ve son teslim zamanı. Saf veri.
##
## Uygular: design/game-brief.md, FAZ 3 "VIP müşteri kontratları".

## Benzersiz sıra numarası (arayüz ve teslim için).
var id: int = 0
var template_id: StringName = &""
var customer: String = ""
var title: String = ""
## İstenen meyve/çiçek türü.
var fruit_id: StringName = &""
## Boş değilse ürün bu mutasyonu taşımalı.
var mutation_id: StringName = &""
## Birim değeri en az bu olmalı (0 = koşul yok).
var min_unit_value: float = 0.0
var quantity: int = 1
## Teslimde ödenen kredi ve kazanılan itibar.
var reward: int = 0
var reputation_reward: int = 0
## Sipariş bu oyun saniyesinde sona erer.
var expires_at: float = 0.0


## JSON uyumlu sözlük (kayıt dosyası).
func to_dict() -> Dictionary:
	return {
		"id": id,
		"template": String(template_id),
		"customer": customer,
		"title": title,
		"fruit": String(fruit_id),
		"mutation": String(mutation_id),
		"min_value": min_unit_value,
		"quantity": quantity,
		"reward": reward,
		"reputation": reputation_reward,
		"expires_at": expires_at,
	}


## Sözlükten sipariş kurar.
static func from_dict(data: Dictionary) -> Order:
	var order: Order = Order.new()
	order.id = int(data.get("id", 0))
	order.template_id = StringName(String(data.get("template", "")))
	order.customer = String(data.get("customer", ""))
	order.title = String(data.get("title", ""))
	order.fruit_id = StringName(String(data.get("fruit", "")))
	order.mutation_id = StringName(String(data.get("mutation", "")))
	order.min_unit_value = float(data.get("min_value", 0.0))
	order.quantity = maxi(int(data.get("quantity", 1)), 1)
	order.reward = maxi(int(data.get("reward", 0)), 0)
	order.reputation_reward = maxi(int(data.get("reputation", 0)), 0)
	order.expires_at = float(data.get("expires_at", 0.0))
	return order
