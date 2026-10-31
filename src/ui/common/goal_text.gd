class_name GoalText
extends RefCounted
## Hedef metinleri: başlık ve açıklama çeviri anahtarlarından (`GOAL_<KİMLİK>_TITLE` / `_DESC`) çözülür. Açıklamada `%s` varsa hedef
## sayısı (dile duyarlı biçimde) yerine konur; yoksa metin olduğu gibi kullanılır.
##
## Uygular: design/design-language.md, "Yazım sesi ve biçim"; design/game-brief.md, "Player goal".


static func title_key(def: GoalDef) -> String:
	return "GOAL_%s_TITLE" % String(def.id).to_upper()


static func description_key(def: GoalDef) -> String:
	return "GOAL_%s_DESC" % String(def.id).to_upper()


static func title(def: GoalDef) -> String:
	return TranslationServer.translate(title_key(def))


static func description(def: GoalDef) -> String:
	var text: String = TranslationServer.translate(description_key(def))
	return text % UiFormat.number(def.target) if text.contains("%s") else text


## "12 / 25" ya da kredi hedeflerinde "3.200 / 5.000".
static func progress_text(progress: int, target: int) -> String:
	return "%s / %s" % [UiFormat.number(progress), UiFormat.number(target)]
