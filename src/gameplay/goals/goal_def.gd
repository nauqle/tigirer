class_name GoalDef
extends Resource
## Hedef tanımı (veri): "şunu şu kadar yap, ödülü al". Hedefler sıralı bir zincirdir (`GameCatalog.goals`); oyuncuya her an tek hedef
## gösterilir. Başlık ve açıklama çeviri anahtarıdır: `GOAL_<KİMLİK>_TITLE`, `GOAL_<KİMLİK>_DESC` (açıklamadaki `%s` hedef sayısıdır).
## Yeni hedef eklemek bir .tres eklemektir.
##
## Uygular: design/game-brief.md, "Player goal" ve "Fail state" (oturumun tamamlanmış hissi: bir hedefe yaklaşmak); design/design-language.md.
##
## [codeblock]
## var goal: GoalDef = load("res://assets/data/goals/goal_first_harvest.tres")
## print(goal.kind, " ", goal.target, " -> ", goal.reward)
## [/codeblock]

## Hedefin ilerlemesini hangi olay besler.
enum Kind {
	HARVEST,  ## hasat edilen bitki sayısı
	SELL_CREDITS,  ## satıştan kazanılan toplam kredi
	DELIVER_ORDERS,  ## teslim edilen VIP sipariş sayısı
	DISCOVER_SPECIES,  ## Seed-Dex'te keşfedilen yeni tür sayısı
	CROSSBREED,  ## yapılan çaprazlama sayısı
	BUY_EQUIPMENT,  ## satın alınan donanım sayısı (sulama, UV, dron, lab UV)
	UNLOCK_FLOOR,  ## açılan kat sayısı
	REACH_CREDITS,  ## ulaşılan en yüksek kredi bakiyesi
}

@export var id: StringName = &""
@export var kind: Kind = Kind.HARVEST
## Hedef sayı (olay sayısı ya da kredi).
@export_range(1, 1000000) var target: int = 1
## Tamamlanınca verilen kredi.
@export_range(0, 100000) var reward: int = 0
