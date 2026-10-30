class_name ProduceStack
extends RefCounted
## Envanterdeki bir ürün yığını: aynı `signature`'lı (şekil + ton dilimi + mutasyon kümesi) meyveler birleşir.
## Toplam değer tutulur; birim değer ortalamadır (farklı zamanlarda farklı değerle hasat edilmiş olabilir).
##
## Uygular: design/game-brief.md, FAZ 3 "envanter yönetimi" (ürünler).

var signature: StringName = &""
## Yığını temsil eden genotip (arayüz önizlemesi ve fiyat için meyve türü/mutasyonlar buradan okunur).
var gene: PlantGene
var phenotype: PlantPhenotype
var count: int = 0
## Yığındaki tüm birimlerin değer toplamı (kredi, küsuratlı).
var total_value: float = 0.0


## Ortalama birim değer; boş yığında 0.
func average_value() -> float:
	return total_value / float(count) if count > 0 else 0.0


## Meyve/çiçek türünün kimliği.
func fruit_id() -> StringName:
	return phenotype.fruit_id


## JSON uyumlu sözlük (kayıt dosyası).
func to_dict() -> Dictionary:
	return {"gene": GeneCodec.to_dict(gene), "count": count, "total_value": total_value}


## Sözlükten yığın kurar; fenotip ve imza yeniden hesaplanır. Gen bozuksa null.
static func from_dict(data: Dictionary, ruleset: GeneticsRuleset) -> ProduceStack:
	var gene_data: Variant = data.get("gene", null)
	if not gene_data is Dictionary:
		return null
	var gene: PlantGene = GeneCodec.from_dict(gene_data as Dictionary)
	if gene == null:
		return null
	var stack: ProduceStack = ProduceStack.new()
	stack.gene = gene
	stack.phenotype = GeneticsEngine.express(gene, ruleset)
	stack.signature = stack.phenotype.signature
	stack.count = maxi(int(data.get("count", 0)), 0)
	stack.total_value = maxf(float(data.get("total_value", 0.0)), 0.0)
	return stack
