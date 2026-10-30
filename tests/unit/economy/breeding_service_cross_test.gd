extends TestCase
## BreedingService: ücret, ebeveynlerin korunması, çocuk tohumlar, hata durumları ve mutasyon bonusu.
## Ayar (EconomyFixtures): çaprazlama 40 kredi, 2 çocuk.

var _ruleset: GeneticsRuleset
var _inventory: InventoryService
var _wallet: WalletService
var _breeding: BreedingService


func before_each() -> void:
	_ruleset = GeneticsFixtures.make_ruleset()
	_inventory = EconomyFixtures.make_inventory(_ruleset)
	_wallet = WalletService.new()
	_wallet.add_credits(100)
	_breeding = _make_breeding(11)
	_inventory.add_seed(FarmFixtures.make_gene(GeneticsFixtures.FRUIT_A, "mom"), 1)
	_inventory.add_seed(FarmFixtures.make_gene(GeneticsFixtures.FRUIT_B, "dad"), 1)


func _make_breeding(rng_seed: int) -> BreedingService:
	var breeding: BreedingService = BreedingService.new()
	breeding.setup(EconomyFixtures.make_config(), _ruleset, GeneticsFixtures.make_rng(rng_seed))
	return breeding


func test_crossbreeding_charges_the_fee_and_adds_the_children_while_the_parents_stay() -> void:
	var outcome: BreedingService.Outcome = _breeding.crossbreed(_inventory, _wallet, "mom", "dad")

	assert_true(outcome.ok)
	assert_eq(outcome.cost, 40)
	assert_eq(_wallet.credits, 60)
	assert_eq(outcome.children.size(), 2, "offspring_per_cross")
	assert_eq(_inventory.seed_count("mom"), 1, "ebeveyn harcanmaz")
	assert_eq(_inventory.seed_count("dad"), 1)
	assert_eq(_inventory.seed_total(), 4, "2 ebeveyn + 2 çocuk")
	for child: PlantGene in outcome.children:
		assert_eq(child.generation, 1)
		assert_eq(child.parent_uids, PackedStringArray(["mom", "dad"]))
		assert_eq(_inventory.seed_count(child.uid), 1, "çocuk envanterde")


func test_children_get_distinct_uids() -> void:
	var outcome: BreedingService.Outcome = _breeding.crossbreed(_inventory, _wallet, "mom", "dad")

	assert_ne(outcome.children[0].uid, outcome.children[1].uid)


func test_a_seed_may_be_crossed_with_itself() -> void:
	var outcome: BreedingService.Outcome = _breeding.crossbreed(_inventory, _wallet, "mom", "mom")

	assert_true(outcome.ok)
	assert_eq(_inventory.seed_count("mom"), 1)


func test_without_enough_credits_nothing_happens() -> void:
	_wallet.spend(70)  # 30 kaldı

	var outcome: BreedingService.Outcome = _breeding.crossbreed(_inventory, _wallet, "mom", "dad")

	assert_false(outcome.ok)
	assert_eq(outcome.error_key, "ERR_NOT_ENOUGH_CREDITS")
	assert_eq(_wallet.credits, 30)
	assert_eq(_inventory.seed_total(), 2, "çocuk doğmadı")


func test_a_missing_parent_is_refused_before_any_charge() -> void:
	var outcome: BreedingService.Outcome = _breeding.crossbreed(_inventory, _wallet, "mom", "ghost")

	assert_false(outcome.ok)
	assert_eq(outcome.error_key, "ERR_SEED_MISSING")
	assert_eq(_wallet.credits, 100, "ücret alınmadı")


func test_a_full_mutation_bonus_gives_every_child_a_new_mutation_and_announces_them() -> void:
	var found: Array[StringName] = []
	_breeding.mutation_found.connect(func(_child: PlantGene, mutation_id: StringName) -> void: found.append(mutation_id))
	var bred_count: Dictionary = {"n": 0}
	_breeding.bred.connect(func(_a: PlantGene, _b: PlantGene, _child: PlantGene) -> void: bred_count["n"] += 1)

	var outcome: BreedingService.Outcome = _breeding.crossbreed(_inventory, _wallet, "mom", "dad", 1.0)

	assert_eq(outcome.new_mutations.size(), 2)
	for mutation_id: StringName in outcome.new_mutations:
		assert_ne(mutation_id, &"", "%100 olasılık: her çocukta yeni mutasyon")
	assert_eq(found.size(), 2)
	assert_eq(bred_count["n"], 2)


func test_with_no_bonus_new_mutations_are_rare() -> void:
	# %5 olasılık: 100 çaprazlama x 2 çocuk içinde beklenen ~10; kaba bir bant (testin kararlı olması için sabit tohum)
	_wallet.add_credits(100000)
	var mutated: int = 0
	var total: int = 0
	for i: int in 100:
		var outcome: BreedingService.Outcome = _breeding.crossbreed(_inventory, _wallet, "mom", "dad")
		for mutation_id: StringName in outcome.new_mutations:
			total += 1
			if mutation_id != &"":
				mutated += 1

	assert_eq(total, 200)
	assert_between(float(mutated), 3.0, 22.0, "yaklaşık %5")


func test_the_same_seed_breeds_the_same_children() -> void:
	var first: BreedingService.Outcome = _make_breeding(5).crossbreed(_inventory, _wallet, "mom", "dad")
	var inventory_two: InventoryService = EconomyFixtures.make_inventory(_ruleset)
	inventory_two.add_seed(FarmFixtures.make_gene(GeneticsFixtures.FRUIT_A, "mom"), 1)
	inventory_two.add_seed(FarmFixtures.make_gene(GeneticsFixtures.FRUIT_B, "dad"), 1)
	var wallet_two: WalletService = WalletService.new()
	wallet_two.add_credits(100)

	var second: BreedingService.Outcome = _make_breeding(5).crossbreed(inventory_two, wallet_two, "mom", "dad")

	assert_eq(first.children[0].uid, second.children[0].uid)
	assert_eq(first.children[1].uid, second.children[1].uid)
