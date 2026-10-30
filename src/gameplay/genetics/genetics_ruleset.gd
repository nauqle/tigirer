class_name GeneticsRuleset
extends Resource
## Genetik kurallarının tek kaynağı: mutasyon olasılığı, kalıtım ayarları, değer aralıkları ve
## içerik listeleri (parçalar, mutasyonlar). Oyun kodunda genetikle ilgili HİÇBİR sayı sabit yazılmaz;
## hepsi bu kaynağın .tres dosyasından gelir (assets/data/genetics/default_ruleset.tres).
##
## Uygular: design/game-brief.md, "Core loop" ve MVP maddesi "Mendel çaprazlama + %5 mutasyon" (FAZ 1).
## Kurallar ve formüller: docs/architecture/floralab-architecture.md.
##
## [codeblock]
## var ruleset: GeneticsRuleset = load("res://assets/data/genetics/default_ruleset.tres")
## var part: PlantPartDef = ruleset.get_part(&"stem_vine")
## var parts_of_stems: Array[PlantPartDef] = ruleset.get_parts_for_layer(PlantPartDef.Layer.STEM)
## [/codeblock]
## Not: GDScript 4.3 ile uyumluluk için Dictionary tipsizdir (tipli Dictionary 4.4'te geldi).

@export_group("Mutasyon")
## Bir çaprazlamada YENİ bir mutasyonun ortaya çıkma olasılığı (0.05 = %5).
@export_range(0.0, 1.0, 0.001) var mutation_chance: float = 0.05
## Ebeveyndeki bir mutasyonun çocuğa geçme olasılığı (ebeveyn başına). İki ebeveynde de varsa
## olasılık 1 - (1 - p)^2 olur.
@export_range(0.0, 1.0, 0.01) var mutation_inherit_chance: float = 0.5
## Bir bitkinin taşıyabileceği en çok mutasyon sayısı.
@export_range(0, 8) var max_mutations: int = 3

@export_group("Kalıtım")
## Sayısal özelliklerde (büyüme, su, değer) iki alelden ifade edilen: 0.5 = ortalama (eklemeli),
## 1.0 = büyük alel tamamen baskın, 0.0 = küçük alel tamamen baskın.
@export_range(0.0, 1.0, 0.01) var quant_dominance: float = 0.5
## Her gamette sayısal alele eklenen küçük gauss sapmasının, değer aralığına oranı. 0 = sapma yok
## (alel olduğu gibi geçer). Seçilim ile ilerleme bu küçük sapmadan gelir.
@export_range(0.0, 0.5, 0.001) var quant_drift: float = 0.04
## Ton aleline eklenen gauss sapması (tam daire = 1.0).
@export_range(0.0, 0.2, 0.001) var hue_drift: float = 0.01

@export_group("Aralıklar")
## Büyüme hızı çarpanının alel aralığı (x = en az, y = en çok).
@export var growth_range: Vector2 = Vector2(0.5, 2.5)
## Su tüketimi çarpanının alel aralığı. Düşük olan daha verimlidir.
@export var water_range: Vector2 = Vector2(0.4, 2.0)
## Pazar değeri çarpanının alel aralığı.
@export var value_range: Vector2 = Vector2(0.5, 4.0)

@export_group("Seed-Dex")
## Tonun, tohum kütüphanesi imzasında kaç dilime bölüneceği (24 = 15 derecelik dilimler).
@export_range(1, 360) var hue_buckets: int = 24

@export_group("İçerik")
@export var parts: Array[PlantPartDef] = []
@export var mutations: Array[MutationDef] = []

# Kimlik -> tanım dizinleri. Tembel kurulur; liste boyutu değişirse yeniden kurulur.
var _part_index: Dictionary = {}  # StringName -> PlantPartDef
var _mutation_index: Dictionary = {}  # StringName -> MutationDef


## Kimliğe göre parça tanımı; yoksa null.
func get_part(id: StringName) -> PlantPartDef:
	_ensure_index()
	return _part_index.get(id, null) as PlantPartDef


## Kimliğe göre mutasyon tanımı; yoksa null.
func get_mutation(id: StringName) -> MutationDef:
	_ensure_index()
	return _mutation_index.get(id, null) as MutationDef


## Bir katmandaki tüm parçalar, kimliğe göre sıralı (deterministik).
func get_parts_for_layer(layer: PlantPartDef.Layer) -> Array[PlantPartDef]:
	var result: Array[PlantPartDef] = []
	for part: PlantPartDef in parts:
		if part != null and part.layer == layer:
			result.append(part)
	result.sort_custom(func(a: PlantPartDef, b: PlantPartDef) -> bool: return String(a.id) < String(b.id))
	return result


## Dizinleri sıfırlar. Liste kodla değiştirildiyse (testler) çağrılabilir; normalde gerekmez.
func rebuild_index() -> void:
	_part_index.clear()
	_mutation_index.clear()
	for part: PlantPartDef in parts:
		if part != null:
			_part_index[part.id] = part
	for mutation: MutationDef in mutations:
		if mutation != null:
			_mutation_index[mutation.id] = mutation


## Kural setinin kendi tutarlılığını denetler. Boş dizi = sorun yok.
## Yinelenen kimlik, boş kimlik, bilinmeyen `excludes` hedefi, anlamsız aralık.
func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var seen_parts: Dictionary = {}
	for part: PlantPartDef in parts:
		if part == null:
			problems.append("parts listesinde null öğe var")
			continue
		if part.id == &"":
			problems.append("kimliği boş bir parça var")
		if seen_parts.has(part.id):
			problems.append("yinelenen parça kimliği: %s" % part.id)
		seen_parts[part.id] = true
	var seen_mutations: Dictionary = {}
	for mutation: MutationDef in mutations:
		if mutation == null:
			problems.append("mutations listesinde null öğe var")
			continue
		if mutation.id == &"":
			problems.append("kimliği boş bir mutasyon var")
		if seen_mutations.has(mutation.id):
			problems.append("yinelenen mutasyon kimliği: %s" % mutation.id)
		seen_mutations[mutation.id] = true
	for mutation: MutationDef in mutations:
		if mutation == null:
			continue
		for excluded: StringName in mutation.excludes:
			if not seen_mutations.has(excluded):
				problems.append("%s bilinmeyen mutasyonu dışlıyor: %s" % [mutation.id, excluded])
	for range_value: Vector2 in [growth_range, water_range, value_range]:
		if range_value.x <= 0.0 or range_value.y < range_value.x:
			problems.append("geçersiz değer aralığı: %s" % str(range_value))
	for layer: int in PlantPartDef.Layer.values():
		if get_parts_for_layer(layer as PlantPartDef.Layer).is_empty():
			problems.append("hiç parçası olmayan katman: %s" % PlantPartDef.Layer.keys()[layer])
	return problems


func _ensure_index() -> void:
	# Boyut karşılaştırması ucuz bir bayatlık denetimidir: kodla öğe eklenirse dizin yeniden kurulur.
	if _part_index.size() != _count_non_null_parts() or _mutation_index.size() != _count_non_null_mutations():
		rebuild_index()


func _count_non_null_parts() -> int:
	var count: int = 0
	for part: PlantPartDef in parts:
		if part != null:
			count += 1
	return count


func _count_non_null_mutations() -> int:
	var count: int = 0
	for mutation: MutationDef in mutations:
		if mutation != null:
			count += 1
	return count
