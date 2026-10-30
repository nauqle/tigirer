class_name PlantGene
extends Resource
## Bir tohumun / bitkinin GENOTİPİ: her özellik için iki alel (anneden biri, babadan biri).
## Saf veridir: mantığı yoktur, yalnızca saklar, kopyalar ve yapısını denetler. İfade edilen görünüm
## (fenotip) `GeneticsEngine.express()` ile hesaplanır; çaprazlama `GeneticsEngine.crossbreed()` ile yapılır.
##
## Uygular: design/game-brief.md, MVP maddesi "Katmanlı prosedürel bitki" ve "Mendel çaprazlama" (FAZ 1).
##
## Lokuslar (hepsi diploid: tam iki alel, sıra önemsiz):
##   Parça lokusları (ayrık): gövde, yaprak, çiçek/meyve. Alel = parça kimliği. Baskınlık parça tanımındadır.
##   Sayısal lokuslar: büyüme hızı, su tüketimi, pazar değeri. Alel = çarpan (1.0 = nötr).
##   Renk lokusu: ton (hue), [0, 1) dairesel.
##   Mutasyonlar: nadir özellik kimlikleri (alel çifti değil, liste).
##
## [codeblock]
## var seed_a: PlantGene = PlantGene.homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry", 0.98)
## var seed_b: PlantGene = PlantGene.homozygous(&"stem_vine", &"leaf_fern", &"flower_tulip", 0.80)
## var child: PlantGene = GeneticsEngine.crossbreed(seed_a, seed_b, ruleset)
## [/codeblock]

## Bu bireyin benzersiz kimliği (kayıt ve soy ağacı için). Başlangıç tohumlarında elle verilir.
@export var uid: String = ""
## Oyuncuya gösterilecek ad (başlangıç tohumlarında dolu, melezlerde boş olabilir).
@export var display_name: String = ""
## Nesil: başlangıç tohumu 0, her çaprazlama ebeveynlerin en büyüğünden bir fazla.
@export var generation: int = 0
## Çaprazlamada ebeveynlerin `uid` değerleri (başlangıç tohumunda boş).
@export var parent_uids: PackedStringArray = PackedStringArray()

@export_group("Parça alelleri")
@export var stem_alleles: Array[StringName] = [&"", &""]
@export var leaf_alleles: Array[StringName] = [&"", &""]
@export var fruit_alleles: Array[StringName] = [&"", &""]

@export_group("Sayısal alelleri")
@export var growth_alleles: PackedFloat32Array = PackedFloat32Array([1.0, 1.0])
@export var water_alleles: PackedFloat32Array = PackedFloat32Array([1.0, 1.0])
@export var value_alleles: PackedFloat32Array = PackedFloat32Array([1.0, 1.0])

@export_group("Renk")
@export var hue_alleles: PackedFloat32Array = PackedFloat32Array([0.33, 0.33])

@export_group("Mutasyonlar")
@export var mutations: Array[StringName] = []


## Üç parça ve ton için homozigot (iki alel aynı) bir tohum üretir; sayısal alleller nötr (1.0) kalır.
## [codeblock]
## var seed: PlantGene = PlantGene.homozygous(&"stem_vine", &"leaf_fern", &"flower_tulip", 0.8)
## [/codeblock]
static func homozygous(stem: StringName, leaf: StringName, fruit: StringName, hue: float = 0.33) -> PlantGene:
	var gene: PlantGene = PlantGene.new()
	gene.stem_alleles = [stem, stem]
	gene.leaf_alleles = [leaf, leaf]
	gene.fruit_alleles = [fruit, fruit]
	gene.hue_alleles = PackedFloat32Array([hue, hue])
	return gene


## Tam (derin) kopya. Dizileri paylaşmaz: kopyayı değiştirmek asıl genotipi etkilemez.
## Kaynakları dolaylı kopyalayan `duplicate()` yerine bunu kullan (Godot 4.3'te `duplicate_deep` yok).
func copy() -> PlantGene:
	var clone: PlantGene = PlantGene.new()
	clone.uid = uid
	clone.display_name = display_name
	clone.generation = generation
	clone.parent_uids = parent_uids.duplicate()
	clone.stem_alleles.assign(stem_alleles)
	clone.leaf_alleles.assign(leaf_alleles)
	clone.fruit_alleles.assign(fruit_alleles)
	clone.growth_alleles = growth_alleles.duplicate()
	clone.water_alleles = water_alleles.duplicate()
	clone.value_alleles = value_alleles.duplicate()
	clone.hue_alleles = hue_alleles.duplicate()
	clone.mutations.assign(mutations)
	return clone


## Yapısal sağlamlık: her lokusta tam iki alel var mı? Değerlerin anlamlı olup olmadığına bakmaz
## (bunun için `GeneticsEngine.validate()`).
func is_well_formed() -> bool:
	return (
		stem_alleles.size() == 2
		and leaf_alleles.size() == 2
		and fruit_alleles.size() == 2
		and growth_alleles.size() == 2
		and water_alleles.size() == 2
		and value_alleles.size() == 2
		and hue_alleles.size() == 2
	)
