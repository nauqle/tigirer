class_name PlantPhenotype
extends RefCounted
## Bir genotipten İFADE EDİLEN görünüm ve özellikler (`GeneticsEngine.express()` üretir).
## Genotip değişmedikçe aynıdır; kaydedilmez, her seferinde hesaplanır.
##
## Uygular: design/game-brief.md, MVP maddesi "Katmanlı prosedürel bitki ... genetik renk ve parlama" (FAZ 1).
##
## [codeblock]
## var phenotype: PlantPhenotype = GeneticsEngine.express(gene, ruleset)
## print(phenotype.morph_id, " değer=", phenotype.market_value)
## [/codeblock]

## İfade edilen parça kimlikleri.
var stem_id: StringName = &""
var leaf_id: StringName = &""
var fruit_id: StringName = &""

## Büyüme hızı çarpanı (1.0 = nötr). Yüksek = daha hızlı. Mutasyon çarpanları dahildir.
var growth_speed: float = 1.0
## Su tüketimi çarpanı (1.0 = nötr). DÜŞÜK = daha verimli. Mutasyon çarpanları dahildir.
var water_use: float = 1.0
## Tek bir meyvenin pazar değeri (altın): meyve taban değeri x değer geni x mutasyon çarpanları.
var market_value: float = 0.0

## Temel ton, [0, 1). Yapraklar ve gövde buna göre boyanır.
var hue: float = 0.0
## Meyvenin tonu: `hue` + mutasyonların meyve ton kayması.
var fruit_hue: float = 0.0
## Alfa 0'dan büyükse meyvenin rengi bu renge zorlanır (örn. altın mutasyonu).
var tint_override: Color = Color(1.0, 1.0, 1.0, 0.0)

## Parlama gücü (0 = yok) ve rengi: mutasyonların en güçlüsünden.
var glow_strength: float = 0.0
var glow_color: Color = Color(1.0, 1.0, 1.0)
## Yüzeyde gezinen parlak bant yoğunluğu, 0..1.
var shimmer: float = 0.0

## Bilinen mutasyonların kimlikleri, alfabetik sıralı.
var mutations: Array[StringName] = []

## "gövde|yaprak|meyve": yalnızca şekil. Tohum kütüphanesinde türün kendisi.
var morph_id: StringName = &""
## Tam imza: şekil + ton dilimi + mutasyon kümesi. Tohum kütüphanesinde "yeni kombinasyon" anahtarı.
var signature: StringName = &""


## Parlayan ya da ışıldayan görünüm var mı (halo çizilsin mi)?
func is_luminous() -> bool:
	return glow_strength > 0.0
