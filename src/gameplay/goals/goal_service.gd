class_name GoalService
extends RefCounted
## Sıralı hedef zinciri: etkin hedef, tamamlanmamış ilkidir. Olaylar (`note`, `note_credits`) TÜM hedefler için ilerleme biriktirir
## (sırası gelmemiş hedefin ilerlemesi de sayılır); etkin hedef bitince ödül cüzdana yazılır ve bir sonrakine geçilir. Sıradaki hedef
## zaten tamamsa art arda tamamlanır. Saf mantık: sahneye bağlı değildir; oyun olayları `GameSession`'dan buraya akar.
##
## Uygular: design/game-brief.md, "Player goal" (oturumun tamamlanmış hissi).
##
## [codeblock]
## goals.setup(catalog.goals, wallet)
## goals.note(GoalDef.Kind.HARVEST, 1)
## goals.note_credits(wallet.credits)
## var current: GoalDef = goals.current()
## [/codeblock]

## Bir hedef tamamlandı (kimlik, ödül).
signal completed(goal_id: StringName, reward: int)
## İlerleme ya da etkin hedef değişti.
signal changed

var defs: Array[GoalDef] = []
var wallet: WalletService

var _progress: Dictionary = {}  # kimlik (StringName) -> int
var _done: Array[StringName] = []
var _resolving: bool = false


## Hedef listesini ve ödülün yazılacağı cüzdanı bağlar; ilerlemeyi sıfırlar.
func setup(goal_defs: Array[GoalDef], wallet_service: WalletService) -> void:
	defs = goal_defs
	wallet = wallet_service
	_progress.clear()
	_done.clear()
	for def: GoalDef in defs:
		_progress[def.id] = 0


## Etkin hedef (tamamlanmamış ilki); hepsi bittiyse null.
func current() -> GoalDef:
	for def: GoalDef in defs:
		if not _done.has(def.id):
			return def
	return null


## Hedefin birikmiş ilerlemesi (hedefi aşmaz).
func progress_of(def: GoalDef) -> int:
	return mini(int(_progress.get(def.id, 0)), def.target)


func is_done(def: GoalDef) -> bool:
	return _done.has(def.id)


func completed_count() -> int:
	return _done.size()


func all_done() -> bool:
	return current() == null


## Sayılan olay: `amount` kadar ilerleme, bu türdeki TÜM tamamlanmamış hedeflere eklenir.
func note(kind: GoalDef.Kind, amount: int = 1) -> void:
	if amount <= 0:
		return
	for def: GoalDef in defs:
		if def.kind == kind and not _done.has(def.id):
			_progress[def.id] = mini(int(_progress.get(def.id, 0)) + amount, def.target)
	_resolve()
	changed.emit()


## Kredi bakiyesi bildirimi: `REACH_CREDITS` hedefleri görülen en yüksek bakiyeyi tutar (düşüş ilerlemeyi geri almaz).
func note_credits(credits: int) -> void:
	for def: GoalDef in defs:
		if def.kind == GoalDef.Kind.REACH_CREDITS and not _done.has(def.id):
			_progress[def.id] = mini(maxi(int(_progress.get(def.id, 0)), credits), def.target)
	_resolve()
	changed.emit()


## Etkin hedef bittiyse tamamlar ve sıradakine geçer; sıradaki de bittiyse devam eder. Ödül cüzdana yazılırken tekrar girilmez.
func _resolve() -> void:
	if _resolving:
		return
	_resolving = true
	var goal: GoalDef = current()
	while goal != null and int(_progress.get(goal.id, 0)) >= goal.target:
		_done.append(goal.id)
		if wallet != null and goal.reward > 0:
			wallet.add_credits(goal.reward)
		completed.emit(goal.id, goal.reward)
		goal = current()
	_resolving = false


# ----------------------------------------------------------------------- kayıt


func to_dict() -> Dictionary:
	var progress: Dictionary = {}
	for def: GoalDef in defs:
		progress[String(def.id)] = int(_progress.get(def.id, 0))
	var done: Array = []
	for id: StringName in _done:
		done.append(String(id))
	return {"done": done, "progress": progress}


## Kayıttan yükler. Bilinmeyen kimlikler ve bozuk sayılar yok sayılır.
func load_dict(data: Dictionary) -> void:
	for def: GoalDef in defs:
		_progress[def.id] = 0
	_done.clear()
	var progress: Dictionary = data.get("progress", {}) as Dictionary
	for def: GoalDef in defs:
		var raw: Variant = progress.get(String(def.id), 0)
		_progress[def.id] = clampi(int(raw) if (raw is int or raw is float) else 0, 0, def.target)
	for raw_id: Variant in data.get("done", []) as Array:
		if raw_id is String:
			var id: StringName = StringName(raw_id as String)
			for def: GoalDef in defs:
				if def.id == id and not _done.has(id):
					_done.append(id)
					_progress[id] = def.target
	changed.emit()
