class_name GeneticsEngine
extends RefCounted
## Genetik motoru: iki tohumu çaprazlar, bir genotipin görünümünü (fenotip) hesaplar.
## Saf mantıktır: durum tutmaz, sahne ağacına ve SignalBus'a dokunmaz. Rastgelelik ve kurallar
## DIŞARIDAN verilir (tohumlu RNG + GeneticsRuleset), bu yüzden testlerde tamamen deterministiktir.
## Olay yayınlama (SignalBus) çağıranın işidir.
##
## Uygular: design/game-brief.md, MVP maddesi "Mendel çaprazlama, baskın/çekinik parçalar, %5 mutasyon,
## kalıtım" (FAZ 1). Kurallar ve formüller: docs/architecture/floralab-architecture.md.
##
## Çaprazlama (Mendel):
##   1. Her diploid lokusta çocuk, her ebeveynin iki aleinden RASTGELE BİRİNİ alır (ayrışma yasası).
##   2. Lokuslar birbirinden bağımsız dağılır (bağımsız dağılım yasası).
##   3. Sayısal alellere ve ton alellerine küçük gauss sapması eklenir, aralığa kırpılır.
##   4. Ebeveyndeki mutasyonlar olasılıkla geçer; ardından %5 (ayarlanabilir) olasılıkla yeni mutasyon.
##
## İfade (fenotip):
##   Parça: baskınlığı büyük olan alel görünür (çekinik yalnızca homozigotta çıkar).
##   Sayısal: lerp(küçük alel, büyük alel, quant_dominance), sonra mutasyon çarpanları.
##   Ton: iki ton aleinin dairesel ortalaması.
##
## [codeblock]
## var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## rng.randomize()
## var child: PlantGene = GeneticsEngine.crossbreed(seed_a, seed_b, ruleset, rng)
## var look: PlantPhenotype = GeneticsEngine.express(child, ruleset)
## print(look.signature, " değer=", look.market_value)
## [/codeblock]

## Ayrışma: bir alel çiftinden rastgele biri.
const _PAIR_SIZE: int = 2


## İki ebeveynden bir çocuk genotipi üretir. Girdi geçersizse (boş, bozuk) `push_error` ile bildirir ve null döner.
## `rng` verilmezse rastgele tohumlu yeni bir üretici kullanılır. `mutation_chance_bonus`, kural setindeki
## mutasyon olasılığına eklenir (örn. UV lambası, FAZ 4); toplam [0, 1]'e kırpılır.
## [codeblock]
## var child: PlantGene = GeneticsEngine.crossbreed(a, b, ruleset, rng)
## [/codeblock]
static func crossbreed(
	parent_a: PlantGene,
	parent_b: PlantGene,
	ruleset: GeneticsRuleset,
	rng: RandomNumberGenerator = null,
	mutation_chance_bonus: float = 0.0
) -> PlantGene:
	var result: BreedResult = crossbreed_detailed(parent_a, parent_b, ruleset, rng, mutation_chance_bonus)
	if result == null:
		return null
	return result.child


## `crossbreed` ile aynıdır ama sonucun nasıl oluştuğunu da döndürür (yeni / miras mutasyon).
## [codeblock]
## var result: BreedResult = GeneticsEngine.crossbreed_detailed(a, b, ruleset, rng)
## if result.new_mutation != &"":
##     print("MUTASYON: ", result.new_mutation)
## [/codeblock]
static func crossbreed_detailed(
	parent_a: PlantGene,
	parent_b: PlantGene,
	ruleset: GeneticsRuleset,
	rng: RandomNumberGenerator = null,
	mutation_chance_bonus: float = 0.0
) -> BreedResult:
	if parent_a == null or parent_b == null or ruleset == null:
		push_error("GeneticsEngine.crossbreed: ebeveynler ve kural seti boş olamaz.")
		return null
	if not parent_a.is_well_formed() or not parent_b.is_well_formed():
		push_error("GeneticsEngine.crossbreed: ebeveyn genotipi bozuk (her lokusta tam iki alel olmalı).")
		return null

	var random: RandomNumberGenerator = rng
	if random == null:
		random = RandomNumberGenerator.new()
		random.randomize()

	var child: PlantGene = PlantGene.new()
	child.generation = maxi(parent_a.generation, parent_b.generation) + 1
	child.parent_uids = PackedStringArray([parent_a.uid, parent_b.uid])

	# Parça lokusları: ayrık aleller, sapma yok.
	child.stem_alleles = _inherit_ids(parent_a.stem_alleles, parent_b.stem_alleles, random)
	child.leaf_alleles = _inherit_ids(parent_a.leaf_alleles, parent_b.leaf_alleles, random)
	child.fruit_alleles = _inherit_ids(parent_a.fruit_alleles, parent_b.fruit_alleles, random)

	# Sayısal lokuslar: gamet + küçük gauss sapması, aralığa kırpılır.
	child.growth_alleles = _inherit_quantitative(
		parent_a.growth_alleles, parent_b.growth_alleles, ruleset.growth_range, ruleset.quant_drift, random
	)
	child.water_alleles = _inherit_quantitative(
		parent_a.water_alleles, parent_b.water_alleles, ruleset.water_range, ruleset.quant_drift, random
	)
	child.value_alleles = _inherit_quantitative(
		parent_a.value_alleles, parent_b.value_alleles, ruleset.value_range, ruleset.quant_drift, random
	)

	# Renk lokusu: dairesel; sapma sonrası [0, 1)'e sarılır.
	child.hue_alleles = _inherit_hue(parent_a.hue_alleles, parent_b.hue_alleles, ruleset.hue_drift, random)

	var result: BreedResult = BreedResult.new()
	result.child = child
	_inherit_mutations(parent_a, parent_b, ruleset, random, result)
	_roll_new_mutation(ruleset, mutation_chance_bonus, random, result)

	child.uid = _make_uid(random)
	return result


## Bir genotipin görünümünü ve özelliklerini hesaplar (fenotip). Genotip değişmedikçe sonuç aynıdır.
## Kural setinde olmayan parça ve mutasyon kimlikleri (eski kayıtlar) hata vermeden yok sayılır/yenilir.
## [codeblock]
## var look: PlantPhenotype = GeneticsEngine.express(gene, ruleset)
## [/codeblock]
static func express(gene: PlantGene, ruleset: GeneticsRuleset) -> PlantPhenotype:
	var phenotype: PlantPhenotype = PlantPhenotype.new()
	phenotype.stem_id = _express_part(gene.stem_alleles, ruleset)
	phenotype.leaf_id = _express_part(gene.leaf_alleles, ruleset)
	phenotype.fruit_id = _express_part(gene.fruit_alleles, ruleset)

	var growth: float = _express_quantitative(gene.growth_alleles, ruleset.quant_dominance)
	var water: float = _express_quantitative(gene.water_alleles, ruleset.quant_dominance)
	var value: float = _express_quantitative(gene.value_alleles, ruleset.quant_dominance)
	phenotype.hue = ColorMath.mix_hues(gene.hue_alleles[0], gene.hue_alleles[1])
	var fruit_hue_shift: float = 0.0

	# Mutasyonlar: kimliğe göre sıralı, yalnızca bilinenler. Çarpanlar çarpılır; görsel etkiler en güçlüden.
	var known_ids: Array[StringName] = []
	for id: StringName in gene.mutations:
		if ruleset.get_mutation(id) != null and not known_ids.has(id):
			known_ids.append(id)
	known_ids.sort()
	for id: StringName in known_ids:
		var mutation: MutationDef = ruleset.get_mutation(id)
		growth *= mutation.growth_multiplier
		water *= mutation.water_multiplier
		value *= mutation.value_multiplier
		fruit_hue_shift += mutation.fruit_hue_shift
		if mutation.glow_strength > phenotype.glow_strength:
			phenotype.glow_strength = mutation.glow_strength
			phenotype.glow_color = mutation.glow_color
		phenotype.shimmer = maxf(phenotype.shimmer, mutation.shimmer)
		if mutation.tint_override.a > 0.0 and phenotype.tint_override.a <= 0.0:
			phenotype.tint_override = mutation.tint_override
	phenotype.mutations = known_ids

	phenotype.growth_speed = growth
	phenotype.water_use = water
	phenotype.fruit_hue = ColorMath.wrap_hue(phenotype.hue + fruit_hue_shift)
	var fruit_part: PlantPartDef = ruleset.get_part(phenotype.fruit_id)
	phenotype.market_value = (fruit_part.base_value if fruit_part != null else 0.0) * value

	phenotype.morph_id = StringName("%s|%s|%s" % [phenotype.stem_id, phenotype.leaf_id, phenotype.fruit_id])
	var hue_bucket: int = mini(int(phenotype.hue * ruleset.hue_buckets), ruleset.hue_buckets - 1)
	var mutation_key: String = ",".join(PackedStringArray(known_ids))
	phenotype.signature = StringName("%s|h%02d|%s" % [phenotype.morph_id, hue_bucket, mutation_key])
	return phenotype


## Genotipi kural setine karşı denetler. Boş dizi = sorun yok. Bozuk yapı, bilinmeyen parça kimliği,
## yanlış katmandaki parça, bilinmeyen mutasyon, aralık dışı sayısal alel, [0, 1) dışı ton.
## [codeblock]
## var problems: PackedStringArray = GeneticsEngine.validate(gene, ruleset)
## [/codeblock]
static func validate(gene: PlantGene, ruleset: GeneticsRuleset) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if not gene.is_well_formed():
		problems.append("genotip bozuk: her lokusta tam iki alel olmalı")
		return problems
	_validate_part_alleles(gene.stem_alleles, PlantPartDef.Layer.STEM, "gövde", ruleset, problems)
	_validate_part_alleles(gene.leaf_alleles, PlantPartDef.Layer.LEAF, "yaprak", ruleset, problems)
	_validate_part_alleles(gene.fruit_alleles, PlantPartDef.Layer.FRUIT, "meyve", ruleset, problems)
	_validate_range(gene.growth_alleles, ruleset.growth_range, "büyüme", problems)
	_validate_range(gene.water_alleles, ruleset.water_range, "su", problems)
	_validate_range(gene.value_alleles, ruleset.value_range, "değer", problems)
	for hue: float in gene.hue_alleles:
		if hue < 0.0 or hue >= 1.0:
			problems.append("ton aleli [0, 1) dışında: %s" % str(hue))
	for id: StringName in gene.mutations:
		if ruleset.get_mutation(id) == null:
			problems.append("bilinmeyen mutasyon: %s" % id)
	if gene.mutations.size() > ruleset.max_mutations:
		problems.append("mutasyon sayısı sınırı aşıyor: %d > %d" % [gene.mutations.size(), ruleset.max_mutations])
	return problems


# ------------------------------------------------------------------ kalıtım


## Ayrık alel çifti: her ebeveynden rastgele biri. [anneden, babadan].
static func _inherit_ids(pair_a: Array[StringName], pair_b: Array[StringName], random: RandomNumberGenerator) -> Array[StringName]:
	var inherited: Array[StringName] = []
	inherited.append(pair_a[random.randi_range(0, _PAIR_SIZE - 1)])
	inherited.append(pair_b[random.randi_range(0, _PAIR_SIZE - 1)])
	return inherited


## Sayısal alel çifti: her ebeveynden rastgele biri + gauss sapması (sigma = drift x aralık genişliği), aralığa kırpılır.
static func _inherit_quantitative(
	pair_a: PackedFloat32Array,
	pair_b: PackedFloat32Array,
	value_range: Vector2,
	drift: float,
	random: RandomNumberGenerator
) -> PackedFloat32Array:
	var first: float = pair_a[random.randi_range(0, _PAIR_SIZE - 1)]
	var second: float = pair_b[random.randi_range(0, _PAIR_SIZE - 1)]
	var sigma: float = drift * (value_range.y - value_range.x)
	if sigma > 0.0:
		first += random.randfn(0.0, sigma)
		second += random.randfn(0.0, sigma)
	return PackedFloat32Array([clampf(first, value_range.x, value_range.y), clampf(second, value_range.x, value_range.y)])


## Ton alel çifti: her ebeveynden rastgele biri + gauss sapması, [0, 1)'e sarılır.
static func _inherit_hue(
	pair_a: PackedFloat32Array, pair_b: PackedFloat32Array, drift: float, random: RandomNumberGenerator
) -> PackedFloat32Array:
	var first: float = pair_a[random.randi_range(0, _PAIR_SIZE - 1)]
	var second: float = pair_b[random.randi_range(0, _PAIR_SIZE - 1)]
	if drift > 0.0:
		first += random.randfn(0.0, drift)
		second += random.randfn(0.0, drift)
	return PackedFloat32Array([ColorMath.wrap_hue(first), ColorMath.wrap_hue(second)])


## Ebeveyndeki mutasyonlar: ebeveyn başına `mutation_inherit_chance`; ikisinde de varsa 1 - (1 - p)^2.
## Sıra deterministik olsun diye kimliğe göre sıralanır. Sınır dolunca durur.
static func _inherit_mutations(
	parent_a: PlantGene, parent_b: PlantGene, ruleset: GeneticsRuleset, random: RandomNumberGenerator, result: BreedResult
) -> void:
	var carried: Array[StringName] = []
	for id: StringName in parent_a.mutations:
		if not carried.has(id):
			carried.append(id)
	for id: StringName in parent_b.mutations:
		if not carried.has(id):
			carried.append(id)
	carried.sort()

	for id: StringName in carried:
		if result.child.mutations.size() >= ruleset.max_mutations:
			break
		if ruleset.get_mutation(id) == null:
			continue  # Kural setinde olmayan (eski kayıt) mutasyon aktarılmaz.
		var carriers: int = 0
		if parent_a.mutations.has(id):
			carriers += 1
		if parent_b.mutations.has(id):
			carriers += 1
		var chance: float = 1.0 - pow(1.0 - ruleset.mutation_inherit_chance, carriers)
		if random.randf() < chance:
			result.child.mutations.append(id)
			result.inherited_mutations.append(id)


## Yeni mutasyon: `mutation_chance` (+ bonus) olasılıkla, uygun adaylar arasından ağırlıklı seçim.
## Zar HER ZAMAN atılır; böylece rastgele akışı, sınırın dolu olup olmamasına bağlı kaymaz.
static func _roll_new_mutation(
	ruleset: GeneticsRuleset, chance_bonus: float, random: RandomNumberGenerator, result: BreedResult
) -> void:
	var chance: float = clampf(ruleset.mutation_chance + chance_bonus, 0.0, 1.0)
	var roll: float = random.randf()
	if roll >= chance:
		return
	if result.child.mutations.size() >= ruleset.max_mutations:
		return
	var candidates: Array[MutationDef] = _eligible_mutations(result.child, ruleset)
	if candidates.is_empty():
		return
	var picked: MutationDef = _weighted_pick(candidates, random)
	result.child.mutations.append(picked.id)
	result.new_mutation = picked.id


## Çocukta olmayan ve çocuktakilerle uyumsuz olmayan mutasyonlar, kimliğe göre sıralı.
static func _eligible_mutations(child: PlantGene, ruleset: GeneticsRuleset) -> Array[MutationDef]:
	var eligible: Array[MutationDef] = []
	for mutation: MutationDef in ruleset.mutations:
		if mutation == null or child.mutations.has(mutation.id):
			continue
		var clashes: bool = false
		for existing_id: StringName in child.mutations:
			var existing: MutationDef = ruleset.get_mutation(existing_id)
			# Uyumsuzluk iki yönlüdür: biri diğerini dışlıyorsa yeterli.
			if mutation.excludes.has(existing_id) or (existing != null and existing.excludes.has(mutation.id)):
				clashes = true
				break
		if not clashes:
			eligible.append(mutation)
	eligible.sort_custom(func(a: MutationDef, b: MutationDef) -> bool: return String(a.id) < String(b.id))
	return eligible


static func _weighted_pick(candidates: Array[MutationDef], random: RandomNumberGenerator) -> MutationDef:
	var total: float = 0.0
	for candidate: MutationDef in candidates:
		total += maxf(candidate.weight, 0.0)
	if total <= 0.0:
		return candidates[random.randi_range(0, candidates.size() - 1)]
	var target: float = random.randf() * total
	var running: float = 0.0
	for candidate: MutationDef in candidates:
		running += maxf(candidate.weight, 0.0)
		if target < running:
			return candidate
	return candidates[candidates.size() - 1]


## 12 onaltılık haneli (48 bit) benzersiz kimlik; aynı RNG tohumu aynı kimliği üretir.
static func _make_uid(random: RandomNumberGenerator) -> String:
	return "%06x%06x" % [random.randi() & 0xFFFFFF, random.randi() & 0xFFFFFF]


# ---------------------------------------------------------------------- ifade


## Baskınlığı büyük alel görünür; eşitse kimliği alfabetik küçük olan. Bilinmeyen kimlik en zayıf sayılır.
static func _express_part(alleles: Array[StringName], ruleset: GeneticsRuleset) -> StringName:
	var first: StringName = alleles[0]
	var second: StringName = alleles[1]
	if first == second:
		return first
	var first_part: PlantPartDef = ruleset.get_part(first)
	var second_part: PlantPartDef = ruleset.get_part(second)
	var first_dominance: int = first_part.dominance if first_part != null else -1
	var second_dominance: int = second_part.dominance if second_part != null else -1
	if first_dominance != second_dominance:
		return first if first_dominance > second_dominance else second
	return first if String(first) < String(second) else second


## lerp(küçük alel, büyük alel, dominance): 0.5 ortalama, 1.0 büyük alel baskın, 0.0 küçük alel baskın.
static func _express_quantitative(alleles: PackedFloat32Array, dominance: float) -> float:
	var low: float = minf(alleles[0], alleles[1])
	var high: float = maxf(alleles[0], alleles[1])
	return lerpf(low, high, dominance)


# ------------------------------------------------------------------ denetim


static func _validate_part_alleles(
	alleles: Array[StringName], layer: PlantPartDef.Layer, label: String, ruleset: GeneticsRuleset, problems: PackedStringArray
) -> void:
	for id: StringName in alleles:
		var part: PlantPartDef = ruleset.get_part(id)
		if part == null:
			problems.append("%s aleli kural setinde yok: %s" % [label, id])
		elif part.layer != layer:
			problems.append("%s aleli yanlış katmanda: %s" % [label, id])


static func _validate_range(alleles: PackedFloat32Array, value_range: Vector2, label: String, problems: PackedStringArray) -> void:
	for allele: float in alleles:
		if allele < value_range.x or allele > value_range.y:
			problems.append("%s aleli aralık dışında: %s" % [label, str(allele)])
