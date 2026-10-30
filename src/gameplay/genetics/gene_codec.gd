class_name GeneCodec
extends RefCounted
## PlantGene <-> Dictionary dönüşümü: kayıt dosyası ve testler için. Çıktı JSON uyumludur
## (yalnızca sayı, metin, dizi ve sözlük içerir). Bozuk ya da eksik veride null döner; çağıran karar verir.
##
## Uygular: design/game-brief.md, MVP "şifreli kayıt" (FAZ 5): genotipler kayıtta bu biçimde saklanır.
##
## [codeblock]
## var data: Dictionary = GeneCodec.to_dict(gene)
## var same: PlantGene = GeneCodec.from_dict(data)  # null: bozuk veri
## [/codeblock]


## Genotipi JSON uyumlu sözlüğe çevirir.
static func to_dict(gene: PlantGene) -> Dictionary:
	return {
		"uid": gene.uid,
		"name": gene.display_name,
		"generation": gene.generation,
		"parents": Array(gene.parent_uids),
		"stem": _ids_to_array(gene.stem_alleles),
		"leaf": _ids_to_array(gene.leaf_alleles),
		"fruit": _ids_to_array(gene.fruit_alleles),
		"growth": _floats_to_array(gene.growth_alleles),
		"water": _floats_to_array(gene.water_alleles),
		"value": _floats_to_array(gene.value_alleles),
		"hue": _floats_to_array(gene.hue_alleles),
		"mutations": _ids_to_array(gene.mutations),
	}


## Sözlükten genotip kurar. Yapı bozuksa (her lokusta tam iki alel yoksa) null döner.
static func from_dict(data: Dictionary) -> PlantGene:
	var gene: PlantGene = PlantGene.new()
	gene.uid = String(data.get("uid", ""))
	gene.display_name = String(data.get("name", ""))
	gene.generation = int(data.get("generation", 0))
	gene.parent_uids = _to_strings(data.get("parents", []))
	gene.stem_alleles = _to_ids(data.get("stem", []))
	gene.leaf_alleles = _to_ids(data.get("leaf", []))
	gene.fruit_alleles = _to_ids(data.get("fruit", []))
	gene.growth_alleles = _to_floats(data.get("growth", []))
	gene.water_alleles = _to_floats(data.get("water", []))
	gene.value_alleles = _to_floats(data.get("value", []))
	gene.hue_alleles = _to_floats(data.get("hue", []))
	gene.mutations = _to_ids(data.get("mutations", []))
	if not gene.is_well_formed():
		return null
	return gene


static func _ids_to_array(ids: Array[StringName]) -> Array:
	var result: Array = []
	for id: StringName in ids:
		result.append(String(id))
	return result


static func _floats_to_array(values: PackedFloat32Array) -> Array:
	var result: Array = []
	for value: float in values:
		result.append(value)
	return result


static func _to_ids(source: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if source is Array:
		for item: Variant in source as Array:
			result.append(StringName(String(item)))
	return result


static func _to_strings(source: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if source is Array:
		for item: Variant in source as Array:
			result.append(String(item))
	return result


static func _to_floats(source: Variant) -> PackedFloat32Array:
	var result: PackedFloat32Array = PackedFloat32Array()
	if source is Array:
		for item: Variant in source as Array:
			result.append(float(item))
	return result
