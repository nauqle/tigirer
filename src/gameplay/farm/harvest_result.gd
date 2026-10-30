class_name HarvestResult
extends RefCounted
## Bir hasadın sonucu: ne kadar, hangi değerde ürün çıktı, kaç tohum döndü. `FarmService.harvested` bunu taşır;
## envanter, Seed-Dex, ses/efekt ve istatistik bu sonucu dinler.
##
## Uygular: design/game-brief.md, "Core loop" (hasat -> meyve ve tohum envantere girer).

var floor_index: int = 0
var pot_index: int = 0
## Hasat edilen bitkinin genotipi ve ifade edilen özellikleri.
var gene: PlantGene
var phenotype: PlantPhenotype
## Çıkan meyve adedi.
var quantity: int = 0
## Tek meyvenin değeri: taban pazar değeri x aşırı olgunluk çarpanı x (1 + kombo bonusu).
var unit_value: float = 0.0
## Tek kaydırmadaki sırası (0 = ilk bitki).
var combo_step: int = 0
## Aşırı olgunluk değer çarpanı (1.0 = kayıp yok).
var overgrowth_factor: float = 1.0
## Envantere dönen tohum adedi.
var seeds_returned: int = 0


## Toplam değer: adet x birim değer.
func total_value() -> float:
	return float(quantity) * unit_value
