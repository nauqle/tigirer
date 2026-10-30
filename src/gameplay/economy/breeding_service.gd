class_name BreedingService
extends RefCounted
## Laboratuvar çaprazlaması: iki tohum seçilir, kredi ödenir, `GeneticsEngine` çocukları üretir ve envantere girer.
## Ebeveyn tohumlar HARCANMAZ (genotip kopyası çoğaltılır); maliyet krediyle ödenir. Mutasyon bonusu (UV laboratuvarı,
## FAZ 4) dışarıdan verilir. Saf mantık: rastgelelik dışarıdan.
##
## Uygular: design/game-brief.md, "Core loop" son madde (çaprazla, %5 mutasyon, Seed-Dex'e kayıt).
##
## [codeblock]
## var outcome: BreedingService.Outcome = breeding.crossbreed(inventory, wallet, "seed_a", "seed_b", lab_bonus)
## if outcome.ok:
##     print(outcome.children.size(), " yeni tohum, mutasyon: ", outcome.new_mutations)
## [/codeblock]

## İki ebeveyn çaprazlandı ve bir çocuk doğdu.
signal bred(parent_a: PlantGene, parent_b: PlantGene, child: PlantGene)
## Çocukta YENİ bir mutasyon ortaya çıktı.
signal mutation_found(child: PlantGene, mutation_id: StringName)


## Bir çaprazlamanın sonucu.
class Outcome:
	extends RefCounted
	var ok: bool = false
	## Başarısızlık nedeni için çeviri anahtarı (başarılıysa boş).
	var error_key: String = ""
	var children: Array[PlantGene] = []
	## Çocuklarda yeni çıkan mutasyonlar (çocukla aynı sırada, çıkmayan için boş).
	var new_mutations: Array[StringName] = []
	var cost: int = 0


var config: EconomyConfig
var ruleset: GeneticsRuleset

var _rng: RandomNumberGenerator


## Ayarları, kural setini ve rastgele üreticiyi bağlar.
func setup(economy_config: EconomyConfig, genetics_ruleset: GeneticsRuleset, rng: RandomNumberGenerator) -> void:
	config = economy_config
	ruleset = genetics_ruleset
	_rng = rng


## `uid_a` ve `uid_b` tohumlarını çaprazlar. Tohumlardan biri envanterde yoksa ya da kredi yetmiyorsa hiçbir şey değişmez.
## `mutation_bonus`: yeni mutasyon olasılığına eklenen oran (UV laboratuvarı).
func crossbreed(inventory: InventoryService, wallet: WalletService, uid_a: String, uid_b: String, mutation_bonus: float = 0.0) -> Outcome:
	var outcome: Outcome = Outcome.new()
	var parent_a: PlantGene = inventory.peek_seed(uid_a)
	var parent_b: PlantGene = inventory.peek_seed(uid_b)
	if parent_a == null or parent_b == null:
		outcome.error_key = "ERR_SEED_MISSING"
		return outcome
	if not wallet.spend(config.cross_cost):
		outcome.error_key = "ERR_NOT_ENOUGH_CREDITS"
		return outcome
	outcome.cost = config.cross_cost
	for i: int in config.offspring_per_cross:
		var result: BreedResult = GeneticsEngine.crossbreed_detailed(parent_a, parent_b, ruleset, _rng, mutation_bonus)
		if result == null:
			continue
		inventory.add_seed(result.child, 1)
		outcome.children.append(result.child)
		outcome.new_mutations.append(result.new_mutation)
		bred.emit(parent_a, parent_b, result.child)
		if result.new_mutation != &"":
			mutation_found.emit(result.child, result.new_mutation)
	outcome.ok = not outcome.children.is_empty()
	return outcome
