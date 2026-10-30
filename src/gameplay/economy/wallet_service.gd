class_name WalletService
extends RefCounted
## Oyuncunun parası (kredi) ve itibarı. Harcama yeterli bakiye olmadan başarısız olur; bakiye asla negatife inmez.
##
## Uygular: design/game-brief.md, "Core loop" (parayla saksı, boru, UV lambası, dron ve yeni kat al).
##
## [codeblock]
## if wallet.spend(150):
##     automation.install_irrigation(0, 1)
## wallet.add_credits(sale_value)
## [/codeblock]

## Kredi değişti (yeni bakiye).
signal credits_changed(credits: int)
## İtibar değişti (yeni toplam).
signal reputation_changed(reputation: int)

var credits: int = 0
var reputation: int = 0
## Oyun boyunca kazanılan toplam kredi (istatistik).
var total_earned: int = 0


## Kredi ekler (negatif değer yok sayılır).
func add_credits(amount: int) -> void:
	if amount <= 0:
		return
	credits += amount
	total_earned += amount
	credits_changed.emit(credits)


func can_afford(amount: int) -> bool:
	return amount <= credits


## `amount` kredi harcar; bakiye yetmezse hiçbir şey değişmez ve false döner.
func spend(amount: int) -> bool:
	if amount < 0 or amount > credits:
		return false
	if amount == 0:
		return true
	credits -= amount
	credits_changed.emit(credits)
	return true


func add_reputation(amount: int) -> void:
	if amount <= 0:
		return
	reputation += amount
	reputation_changed.emit(reputation)


## JSON uyumlu sözlük (kayıt dosyası).
func to_dict() -> Dictionary:
	return {"credits": credits, "reputation": reputation, "total_earned": total_earned}


func load_dict(data: Dictionary) -> void:
	credits = maxi(int(data.get("credits", 0)), 0)
	reputation = maxi(int(data.get("reputation", 0)), 0)
	total_earned = maxi(int(data.get("total_earned", 0)), 0)
	credits_changed.emit(credits)
	reputation_changed.emit(reputation)
