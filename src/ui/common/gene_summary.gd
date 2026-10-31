class_name GeneSummary
extends RefCounted
## Bir genotipin oyuncuya gösterilecek özetleri: tür adı, parçalar, sayısal özellikler, gizli (çekinik) aleller, mutasyonlar ve nadirlik.
## Yalnızca okur. Veri dosyalarındaki adlar çeviri ANAHTARIDIR (`PART_*`, `MUT_*`, `SEED_*`); burada `tr()` ile çözülür, böylece
## tüm metinler seçili dilde görünür. Sayılar dile duyarlı biçimlenir (`UiFormat`).
##
## Uygular: design/game-brief.md, "Player fantasy" (genetik çeşitliliği görünür kılmak); design/design-language.md.
##
## [codeblock]
## label.text = "\n".join(GeneSummary.describe(gene, ruleset))
## var name: String = GeneSummary.title(gene, ruleset)
## var rarity: UiTokens.Rarity = GeneSummary.rarity(GeneticsEngine.express(gene, ruleset))
## [/codeblock]


## Kısa başlık: tohumun kendi adı (başlangıç tohumlarında) ya da "meyve türü · nesil N".
static func title(gene: PlantGene, ruleset: GeneticsRuleset) -> String:
	if gene.display_name != "":
		return translate(gene.display_name)
	var phenotype: PlantPhenotype = GeneticsEngine.express(gene, ruleset)
	return translate("GENE_TITLE") % [part_name(phenotype.fruit_id, ruleset), gene.generation]


## Ayrıntılı satırlar: parçalar, sayısal özellikler, gizli aleller, mutasyonlar, nesil.
static func describe(gene: PlantGene, ruleset: GeneticsRuleset) -> PackedStringArray:
	var phenotype: PlantPhenotype = GeneticsEngine.express(gene, ruleset)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s, %s, %s" % [part_name(phenotype.stem_id, ruleset), part_name(phenotype.leaf_id, ruleset), part_name(phenotype.fruit_id, ruleset)])
	lines.append(translate("GENE_STATS") % [UiFormat.decimal(phenotype.growth_speed, 2), UiFormat.decimal(phenotype.water_use, 2), UiFormat.decimal(phenotype.market_value, 1)])
	var carried: Array[StringName] = hidden_alleles(gene, phenotype)
	if not carried.is_empty():
		var names: PackedStringArray = PackedStringArray()
		for id: StringName in carried:
			names.append(part_name(id, ruleset))
		lines.append(translate("GENE_CARRIES") % ", ".join(names))
	if phenotype.mutations.is_empty():
		lines.append(translate("GENE_NO_MUTATION") % gene.generation)
	else:
		lines.append(translate("GENE_MUTATIONS") % [", ".join(mutation_names(phenotype, ruleset)), gene.generation])
	return lines


## Genotipte olup fenotipte görünmeyen (çekinik) parça kimlikleri.
static func hidden_alleles(gene: PlantGene, phenotype: PlantPhenotype) -> Array[StringName]:
	var hidden: Array[StringName] = []
	var shown: Array[StringName] = [phenotype.stem_id, phenotype.leaf_id, phenotype.fruit_id]
	for alleles: Array[StringName] in [gene.stem_alleles, gene.leaf_alleles, gene.fruit_alleles]:
		for id: StringName in alleles:
			if not shown.has(id) and not hidden.has(id):
				hidden.append(id)
	return hidden


## Parçanın çevrilmiş adı.
static func part_name(id: StringName, ruleset: GeneticsRuleset) -> String:
	var part: PlantPartDef = ruleset.get_part(id)
	return translate(part.display_name) if part != null else String(id)


## Mutasyonun çevrilmiş adı.
static func mutation_name(id: StringName, ruleset: GeneticsRuleset) -> String:
	var mutation: MutationDef = ruleset.get_mutation(id)
	return translate(mutation.display_name) if mutation != null else String(id)


## Fenotipin mutasyon adları.
static func mutation_names(phenotype: PlantPhenotype, ruleset: GeneticsRuleset) -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for id: StringName in phenotype.mutations:
		names.append(mutation_name(id, ruleset))
	return names


## Ürün yığını için ad: "Meyve türü" ya da "Meyve türü · Mutasyon".
static func stack_title(stack: ProduceStack, ruleset: GeneticsRuleset) -> String:
	var text: String = part_name(stack.fruit_id(), ruleset)
	for id: StringName in stack.phenotype.mutations:
		text += " · " + mutation_name(id, ruleset)
	return text


## Siparişin koşul metni: "3× Meyve Salkımı", "2× Altın (herhangi bir ürün)"; asgari birim değeri eklenir.
static func order_requirement(order: Order, ruleset: GeneticsRuleset) -> String:
	var what: String = part_name(order.fruit_id, ruleset) if order.fruit_id != &"" else translate("ORDER_ANY_FRUIT")
	if order.mutation_id != &"":
		what += " · " + mutation_name(order.mutation_id, ruleset)
	var text: String = "%d× %s" % [order.quantity, what]
	if order.min_unit_value > 0.0:
		text += " · " + translate("ORDER_MIN_VALUE") % UiFormat.number(int(order.min_unit_value))
	return text


## Nadirlik: mutasyonlu = mutant; değere göre sıradan/seyrek/nadir (eşikler `UiTokens`).
static func rarity(phenotype: PlantPhenotype) -> UiTokens.Rarity:
	if not phenotype.mutations.is_empty():
		return UiTokens.Rarity.MUTANT
	if phenotype.market_value >= UiTokens.RARE_VALUE:
		return UiTokens.Rarity.RARE
	if phenotype.market_value >= UiTokens.UNCOMMON_VALUE:
		return UiTokens.Rarity.UNCOMMON
	return UiTokens.Rarity.COMMON


## Çeviri: anahtarsa çevrilir; çeviri tablosunda olmayan düz metin (eski kayıt, test verisi) olduğu gibi döner.
static func translate(key: String) -> String:
	return TranslationServer.translate(key)


## Eski ad (geriye uyum).
static func tr_fallback(key: String) -> String:
	return translate(key)
