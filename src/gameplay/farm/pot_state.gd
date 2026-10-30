class_name PotState
extends RefCounted
## Tek bir hidroponik saksının durumu: içindeki bitkinin genotipi, büyümesi, suyu ve aşırı olgunluk süresi.
## Saf veridir (sahne düğümü değil); `FarmService` günceller, `FarmView` yalnızca okuyup çizer.
##
## Uygular: design/game-brief.md, "Core loop" (saksıya tohum dik; su ve UV ışıkla Tohum -> Filiz -> Olgun).

## Saksıdaki bitkinin genotipi; null = boş saksı.
var gene: PlantGene
## `gene`'in ifade edilmiş hali (önbellek: her karede yeniden hesaplanmasın). Kayda yazılmaz, yüklemede yeniden kurulur.
var phenotype: PlantPhenotype
## 0 = tohum, 1 = olgun.
var growth: float = 0.0
## 0..1; sıfıra inerse büyüme durur.
var water: float = 1.0
## Olgunlaştıktan sonra hasat edilmeden beklenen oyun saniyesi.
var overgrowth_seconds: float = 0.0


func is_empty() -> bool:
	return gene == null


func is_mature() -> bool:
	return gene != null and growth >= 1.0


## Bitkiyi kaldırır, suyu korur.
func clear() -> void:
	gene = null
	phenotype = null
	growth = 0.0
	overgrowth_seconds = 0.0


## JSON uyumlu sözlük (kayıt dosyası).
func to_dict() -> Dictionary:
	var data: Dictionary = {"growth": growth, "water": water, "overgrowth": overgrowth_seconds}
	if gene != null:
		data["gene"] = GeneCodec.to_dict(gene)
	return data


## Sözlükten saksı kurar; `ruleset` ile fenotip önbelleği yeniden hesaplanır. Bozuk gen varsa saksı boş kalır.
static func from_dict(data: Dictionary, ruleset: GeneticsRuleset) -> PotState:
	var pot: PotState = PotState.new()
	pot.water = clampf(float(data.get("water", 1.0)), 0.0, 1.0)
	var gene_data: Variant = data.get("gene", null)
	if gene_data is Dictionary:
		var gene: PlantGene = GeneCodec.from_dict(gene_data as Dictionary)
		if gene != null:
			pot.gene = gene
			pot.phenotype = GeneticsEngine.express(gene, ruleset)
			pot.growth = clampf(float(data.get("growth", 0.0)), 0.0, 1.0)
			pot.overgrowth_seconds = maxf(float(data.get("overgrowth", 0.0)), 0.0)
	return pot
