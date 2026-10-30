class_name SeedItem
extends RefCounted
## Envanterdeki bir tohum yığını: bir genotip ve kaç adet olduğu. Aynı `uid`'li tohumlar tek yığında birleşir.
##
## Uygular: design/game-brief.md, FAZ 3 "envanter yönetimi" (tohumlar).

var gene: PlantGene
var count: int = 0


func _init(seed_gene: PlantGene = null, seed_count: int = 0) -> void:
	gene = seed_gene
	count = seed_count


## JSON uyumlu sözlük (kayıt dosyası).
func to_dict() -> Dictionary:
	return {"gene": GeneCodec.to_dict(gene), "count": count}


## Sözlükten yığın kurar; gen bozuksa null.
static func from_dict(data: Dictionary) -> SeedItem:
	var gene_data: Variant = data.get("gene", null)
	if not gene_data is Dictionary:
		return null
	var gene: PlantGene = GeneCodec.from_dict(gene_data as Dictionary)
	if gene == null:
		return null
	return SeedItem.new(gene, maxi(int(data.get("count", 0)), 0))
