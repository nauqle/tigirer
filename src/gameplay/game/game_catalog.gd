class_name GameCatalog
extends Resource
## Oyunun tüm veri kökü: ayarlar, kural seti, katlar, donanım, haber olayları, sipariş şablonları ve başlangıç tohumları.
## `GameSession` yalnızca bunu alır (bağımlılık enjeksiyonu): testler küçük bir katalogla, oyun `assets/data/game_catalog.tres`
## ile çalışır. Yeni içerik (kat, donanım, olay, şablon) eklemek buradaki listeye bir .tres eklemektir.
##
## Uygular: design/game-brief.md, "Veri odaklı tasarım" (tüm içerik ve sayılar Resource olarak dışarıdadır).
##
## [codeblock]
## var catalog: GameCatalog = load("res://assets/data/game_catalog.tres")
## var problems: PackedStringArray = catalog.validate()   # boş = tutarlı
## session.setup(catalog)
## [/codeblock]

@export var farm_config: FarmConfig
@export var economy_config: EconomyConfig
@export var automation_config: AutomationConfig
@export var ruleset: GeneticsRuleset
@export var floors: Array[FloorDef] = []
@export var equipment: Array[EquipmentDef] = []
@export var market_events: Array[MarketEventDef] = []
@export var order_templates: Array[OrderTemplateDef] = []
## Yeni oyunda envantere konan tohumlar ve adetleri (aynı sırada, aynı uzunlukta).
@export var starter_seeds: Array[PlantGene] = []
@export var starter_seed_counts: PackedInt32Array = PackedInt32Array()


## Katalogun kendi tutarlılığını denetler. Boş dizi = sorun yok.
func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if farm_config == null or economy_config == null or automation_config == null or ruleset == null:
		problems.append("ayar kaynaklarından biri eksik")
		return problems
	if floors.is_empty():
		problems.append("en az bir kat gerekli")
	for i: int in floors.size():
		if floors[i] == null or floors[i].index != i:
			problems.append("kat sırası bozuk: %d" % i)
	if not floors.is_empty() and floors[0].unlock_cost != 0:
		problems.append("zemin kat baştan açık olmalı")
	if starter_seeds.size() != starter_seed_counts.size():
		problems.append("başlangıç tohumu sayısı ile adet listesi uyuşmuyor")
	if starter_seeds.is_empty():
		problems.append("başlangıç tohumu yok")
	for gene: PlantGene in starter_seeds:
		for issue: String in GeneticsEngine.validate(gene, ruleset):
			problems.append("başlangıç tohumu %s: %s" % [gene.uid, issue])
	for issue: String in ruleset.validate():
		problems.append("kural seti: " + issue)
	return problems
