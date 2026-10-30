class_name GeneticsFixtures
extends RefCounted
## Genetik testleri için küçük, KODLA kurulan kural seti ve üreticiler. Gerçek veri dosyalarına
## (assets/data/genetics) bağlı değildir: testler hızlı, deterministik ve izoledir
## (.claude/rules/test-standards.md: test verisi testte ya da özel fixture'da tanımlanır).
##
## Kural seti: her katmanda baskın (a), orta (b) ve çekinik (r) bir parça; dört mutasyon.
## Varsayılan olarak sapma KAPALIDIR (quant_drift = hue_drift = 0): aleller olduğu gibi geçer.

const STEM_A: StringName = &"stem_a"
const STEM_B: StringName = &"stem_b"
const STEM_R: StringName = &"stem_r"
const LEAF_A: StringName = &"leaf_a"
const LEAF_B: StringName = &"leaf_b"
const LEAF_R: StringName = &"leaf_r"
const FRUIT_A: StringName = &"fruit_a"
const FRUIT_B: StringName = &"fruit_b"
const FRUIT_R: StringName = &"fruit_r"
const M_GLOW: StringName = &"m_glow"
const M_FAST: StringName = &"m_fast"
const M_GOLD: StringName = &"m_gold"
const M_CHIMERA: StringName = &"m_chimera"


static func make_part(id: StringName, layer: PlantPartDef.Layer, dominance: int, base_value: float = 0.0) -> PlantPartDef:
	var part: PlantPartDef = PlantPartDef.new()
	part.id = id
	part.layer = layer
	part.dominance = dominance
	part.base_value = base_value
	return part


static func make_mutation(id: StringName, weight: float) -> MutationDef:
	var mutation: MutationDef = MutationDef.new()
	mutation.id = id
	mutation.weight = weight
	return mutation


## Dört mutasyonlu standart kural seti.
static func make_ruleset() -> GeneticsRuleset:
	var ruleset: GeneticsRuleset = GeneticsRuleset.new()
	ruleset.mutation_chance = 0.05
	ruleset.mutation_inherit_chance = 0.5
	ruleset.max_mutations = 3
	ruleset.quant_dominance = 0.5
	ruleset.quant_drift = 0.0
	ruleset.hue_drift = 0.0
	ruleset.hue_buckets = 24
	ruleset.parts = [
		make_part(STEM_A, PlantPartDef.Layer.STEM, 2),
		make_part(STEM_B, PlantPartDef.Layer.STEM, 1),
		make_part(STEM_R, PlantPartDef.Layer.STEM, 0),
		make_part(LEAF_A, PlantPartDef.Layer.LEAF, 2),
		make_part(LEAF_B, PlantPartDef.Layer.LEAF, 1),
		make_part(LEAF_R, PlantPartDef.Layer.LEAF, 0),
		make_part(FRUIT_A, PlantPartDef.Layer.FRUIT, 2, 10.0),
		make_part(FRUIT_B, PlantPartDef.Layer.FRUIT, 1, 20.0),
		make_part(FRUIT_R, PlantPartDef.Layer.FRUIT, 0, 50.0),
	]

	var glow: MutationDef = make_mutation(M_GLOW, 30.0)
	glow.glow_strength = 1.0
	glow.glow_color = Color(0.0, 1.0, 0.5)
	glow.value_multiplier = 1.5

	var fast: MutationDef = make_mutation(M_FAST, 30.0)
	fast.growth_multiplier = 1.6

	var gold: MutationDef = make_mutation(M_GOLD, 10.0)
	gold.value_multiplier = 3.0
	gold.tint_override = Color(1.0, 0.8, 0.2, 1.0)
	gold.shimmer = 0.6

	var chimera: MutationDef = make_mutation(M_CHIMERA, 10.0)
	chimera.fruit_hue_shift = 0.5
	chimera.value_multiplier = 1.4
	chimera.excludes = [M_GOLD]

	ruleset.mutations = [glow, fast, gold, chimera]
	return ruleset


## Üç parçası da belirtilen, sayısal aleller nötr, ton 0.3 olan homozigot genotip.
static func make_gene(stem: StringName, leaf: StringName, fruit: StringName, uid: String = "") -> PlantGene:
	var gene: PlantGene = PlantGene.homozygous(stem, leaf, fruit, 0.3)
	gene.uid = uid
	return gene


## Tohumlu RNG: aynı tohum = aynı sonuç.
static func make_rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
