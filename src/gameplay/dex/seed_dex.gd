class_name SeedDex
extends RefCounted
## Seed-Dex (Tohum Kütüphanesi): keşfedilen her tür (gövde+yaprak+meyve birleşimi) ve varyant (ton dilimi + mutasyon kümesi)
## burada kayıtlıdır. Bir tür, ilk görüldüğü genotiple ve en değerli örneğiyle saklanır.
## Saf mantık: ödül (kredi) vermez, yalnızca "yeni mi?" sorusunu yanıtlar; ödülü `GameSession` verir.
##
## Uygular: design/game-brief.md, "Player goal" (Seed-Dex'i doldurmak) ve FAZ 5 "keşfedilen tohumlar ansiklopedisi".
##
## [codeblock]
## var found: SeedDex.Discovery = dex.record(gene, phenotype, day)
## if found.new_species:
##     print("Yeni tür: ", found.morph_id)
## print(dex.species_count(), "/", dex.total_species(ruleset))
## [/codeblock]


## Bir türün kaydı.
class Entry:
	extends RefCounted
	var morph_id: StringName = &""
	## Türü temsil eden genotip (en değerli görülen örnek).
	var sample: PlantGene
	var best_value: float = 0.0
	## Bu türden kaç kez görüldü (çaprazlama ya da hasat).
	var times_seen: int = 0
	## İlk görüldüğü oyun günü.
	var first_day: int = 1
	## Görülen varyant imzaları (imza -> true).
	var signatures: Dictionary = {}


## `record` sonucu: yeni tür mü, yeni varyant mı?
class Discovery:
	extends RefCounted
	var morph_id: StringName = &""
	var new_species: bool = false
	var new_variant: bool = false


var _entries: Dictionary = {}  # morph_id (StringName) -> Entry
var _variant_count: int = 0


## Bir genotipin görüldüğünü kaydeder. Tür ya da varyant yeniyse sonuç bunu bildirir.
func record(gene: PlantGene, phenotype: PlantPhenotype, day: int) -> Discovery:
	var discovery: Discovery = Discovery.new()
	discovery.morph_id = phenotype.morph_id
	var entry: Entry = _entries.get(phenotype.morph_id, null) as Entry
	if entry == null:
		entry = Entry.new()
		entry.morph_id = phenotype.morph_id
		entry.first_day = day
		entry.sample = gene
		entry.best_value = phenotype.market_value
		_entries[phenotype.morph_id] = entry
		discovery.new_species = true
	if not entry.signatures.has(phenotype.signature):
		entry.signatures[phenotype.signature] = true
		_variant_count += 1
		discovery.new_variant = true
	entry.times_seen += 1
	if phenotype.market_value > entry.best_value:
		entry.best_value = phenotype.market_value
		entry.sample = gene
	return discovery


## Tür kaydı; keşfedilmemişse null.
func entry(morph_id: StringName) -> Entry:
	return _entries.get(morph_id, null) as Entry


func has_species(morph_id: StringName) -> bool:
	return _entries.has(morph_id)


## Keşfedilen tür sayısı.
func species_count() -> int:
	return _entries.size()


## Keşfedilen varyant sayısı (tüm türlerde).
func variant_count() -> int:
	return _variant_count


## Tüm kayıtlar, tür kimliğine göre sıralı (kararlı sıra).
func entries() -> Array[Entry]:
	var result: Array[Entry] = []
	for entry_item: Entry in _entries.values():
		result.append(entry_item)
	result.sort_custom(func(a: Entry, b: Entry) -> bool: return String(a.morph_id) < String(b.morph_id))
	return result


## Kural setinin üretebileceği tüm tür sayısı: gövde x yaprak x meyve parça sayıları.
func total_species(ruleset: GeneticsRuleset) -> int:
	return (
		ruleset.get_parts_for_layer(PlantPartDef.Layer.STEM).size()
		* ruleset.get_parts_for_layer(PlantPartDef.Layer.LEAF).size()
		* ruleset.get_parts_for_layer(PlantPartDef.Layer.FRUIT).size()
	)


## Tamamlanma oranı, 0..1 (keşfedilen tür / tüm türler).
func completion(ruleset: GeneticsRuleset) -> float:
	var total: int = total_species(ruleset)
	return float(species_count()) / float(total) if total > 0 else 0.0


func clear() -> void:
	_entries.clear()
	_variant_count = 0


## JSON uyumlu sözlük (kayıt dosyası).
func to_dict() -> Dictionary:
	var items: Array = []
	for entry_item: Entry in entries():
		var signatures: Array = []
		for signature: StringName in entry_item.signatures.keys():
			signatures.append(String(signature))
		items.append(
			{
				"morph": String(entry_item.morph_id),
				"sample": GeneCodec.to_dict(entry_item.sample),
				"best": entry_item.best_value,
				"seen": entry_item.times_seen,
				"day": entry_item.first_day,
				"signatures": signatures,
			}
		)
	return {"entries": items}


## Kayıttan yükler (mevcut içeriğin yerine); bozuk girdiler atlanır.
func load_dict(data: Dictionary) -> void:
	clear()
	for raw: Variant in data.get("entries", []) as Array:
		if not raw is Dictionary:
			continue
		var item: Dictionary = raw as Dictionary
		var sample_data: Variant = item.get("sample", null)
		if not sample_data is Dictionary:
			continue
		var sample: PlantGene = GeneCodec.from_dict(sample_data as Dictionary)
		var morph_id: StringName = StringName(String(item.get("morph", "")))
		if sample == null or morph_id == &"":
			continue
		var entry_item: Entry = Entry.new()
		entry_item.morph_id = morph_id
		entry_item.sample = sample
		entry_item.best_value = float(item.get("best", 0.0))
		entry_item.times_seen = maxi(int(item.get("seen", 1)), 1)
		entry_item.first_day = maxi(int(item.get("day", 1)), 1)
		for signature: Variant in item.get("signatures", []) as Array:
			entry_item.signatures[StringName(String(signature))] = true
		_variant_count += entry_item.signatures.size()
		_entries[morph_id] = entry_item
