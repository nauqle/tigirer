class_name GeneSummary
extends RefCounted
## Bir genotipin oyuncuya gösterilecek özetleri: tür adı, parçalar, sayısal özellikler, gizli (çekinik) aleller, mutasyonlar.
## Yalnızca okur; metinler `tr()` anahtarlarıyla çevrilir, içerik adları (parça, mutasyon) veri dosyasından gelir.
##
## Uygular: design/game-brief.md, "Player fantasy" (genetik çeşitliliği görünür kılmak).
##
## [codeblock]
## label.text = "\n".join(GeneSummary.describe(gene, ruleset))
## var name: String = GeneSummary.title(gene, ruleset)
## [/codeblock]


## Kısa başlık: tohumun kendi adı (başlangıç tohumlarında) ya da "meyve türü · nesil N".
static func title(gene: PlantGene, ruleset: GeneticsRuleset) -> String:
	if gene.display_name != "":
		return gene.display_name
	var phenotype: PlantPhenotype = GeneticsEngine.express(gene, ruleset)
	return tr_fallback("GENE_TITLE") % [part_name(phenotype.fruit_id, ruleset), gene.generation]


## Ayrıntılı satırlar: parçalar, sayısal özellikler, gizli aleller, mutasyonlar, nesil.
static func describe(gene: PlantGene, ruleset: GeneticsRuleset) -> PackedStringArray:
	var phenotype: PlantPhenotype = GeneticsEngine.express(gene, ruleset)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s, %s, %s" % [part_name(phenotype.stem_id, ruleset), part_name(phenotype.leaf_id, ruleset), part_name(phenotype.fruit_id, ruleset)])
	lines.append(tr_fallback("GENE_STATS") % [phenotype.growth_speed, phenotype.water_use, phenotype.market_value])
	var carried: Array[StringName] = hidden_alleles(gene, phenotype)
	if not carried.is_empty():
		var names: PackedStringArray = PackedStringArray()
		for id: StringName in carried:
			names.append(part_name(id, ruleset))
		lines.append(tr_fallback("GENE_CARRIES") % ", ".join(names))
	if phenotype.mutations.is_empty():
		lines.append(tr_fallback("GENE_NO_MUTATION") % gene.generation)
	else:
		var mutation_names: PackedStringArray = PackedStringArray()
		for id: StringName in phenotype.mutations:
			mutation_names.append(mutation_name(id, ruleset))
		lines.append(tr_fallback("GENE_MUTATIONS") % [", ".join(mutation_names), gene.generation])
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


static func part_name(id: StringName, ruleset: GeneticsRuleset) -> String:
	var part: PlantPartDef = ruleset.get_part(id)
	return part.display_name if part != null else String(id)


static func mutation_name(id: StringName, ruleset: GeneticsRuleset) -> String:
	var mutation: MutationDef = ruleset.get_mutation(id)
	return mutation.display_name if mutation != null else String(id)


## Ürün yığını için ad: "Meyve türü" ya da "Meyve türü ★ Mutasyon".
static func stack_title(stack: ProduceStack, ruleset: GeneticsRuleset) -> String:
	var text: String = part_name(stack.fruit_id(), ruleset)
	for id: StringName in stack.phenotype.mutations:
		text += " ★ " + mutation_name(id, ruleset)
	return text


## Siparişin koşul metni: "3× Meyve Salkımı", "2× ★ Altın (herhangi meyve)", "birim ≥ 24" eklenir.
static func order_requirement(order: Order, ruleset: GeneticsRuleset) -> String:
	var what: String = part_name(order.fruit_id, ruleset) if order.fruit_id != &"" else tr_fallback("ORDER_ANY_FRUIT")
	if order.mutation_id != &"":
		what += " ★ " + mutation_name(order.mutation_id, ruleset)
	var text: String = "%d× %s" % [order.quantity, what]
	if order.min_unit_value > 0.0:
		text += " · " + tr_fallback("ORDER_MIN_VALUE") % int(order.min_unit_value)
	return text


## Çeviri tablosu yüklü değilken (örn. çok erken testler) anahtarı döndürür; normalde `TranslationServer` çevirir.
static func tr_fallback(key: String) -> String:
	return TranslationServer.translate(key)
