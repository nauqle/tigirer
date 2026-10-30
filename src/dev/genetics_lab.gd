extends Control
## FAZ 1 genetik laboratuvarı: GELİŞTİRİCİ aracı ve görsel doğrulama sahnesi (oyuncuya gösterilmez).
## İki ebeveyn seç, çaprazla, sekiz çocuğu gör; bir çocuğa dokunarak onu ebeveyn yap; mutasyon olasılığını
## artır; büyüme çubuğuyla filizden olgunluğa bak. Mantık `GeneticsEngine`'de, çizim `PlantInstance`'tadır;
## bu sahne yalnızca ikisini birbirine bağlar ve olayları SignalBus'a yayınlar.
##
## Uygular: design/game-brief.md, "Build order" 1. madde (FAZ 1: genetik çekirdeği ve bitki görseli).
##
## Komut satırı (godot ... -- seçenekler): --cross=N (açılışta N kez çaprazla), --seed=N (tohumlu RNG),
## --bonus (mutasyon +%20 açık), --growth=0.0..1.0, --adopt=İ (açılıştaki çaprazlamadan sonra İ. çocuğu
## ebeveyn yapar, dokunuşun karşılığı). Ekran görüntüsü için `--write-movie` ile birlikte kullanılır.
## Dev-only: kullanıcıya dönük metinler bilerek yerelleştirilmedi (src/ui kuralı bu klasörü kapsamaz).

const OFFSPRING_COUNT: int = 8
const OFFSPRING_COLUMNS: int = 4
const PLANT_SCENE: PackedScene = preload("res://src/gameplay/plants/plant_instance.tscn")
## Dev aracı için mutasyon bonusu (UV lambası etkisi benzetimi).
const MUTATION_BONUS: float = 0.20

const _BACKGROUND_TOP: Color = Color(0.03, 0.05, 0.11)
const _BACKGROUND_BOTTOM: Color = Color(0.04, 0.13, 0.15)
const _TEXT: Color = Color(0.86, 0.95, 0.93)
const _MUTED: Color = Color(0.58, 0.72, 0.70)
const _ACCENT: Color = Color(0.42, 1.0, 0.82)

@export var ruleset: GeneticsRuleset
## Başlangıç tohumları (ebeveyn seçimi bunlar arasında dolaşır). Dışa aktarmada izlendiği için sahnede atanır.
@export var starter_seeds: Array[PlantGene] = []

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _parents: Array[PlantGene] = [null, null]
## Varsayılan: iki taşıyıcı. Çocuklarda hem çekinik parçalar hem ton ayrışması hemen görünür.
var _seed_cursor: Array[int] = [3, 3]
var _next_slot: int = 0
var _bonus_on: bool = false
var _growth: float = 1.0

var _parent_plants: Array[PlantInstance] = []
var _parent_labels: Array[Label] = []
var _offspring: Array[PlantGene] = []
var _offspring_plants: Array[PlantInstance] = []
var _offspring_labels: Array[Label] = []
var _banner: Label
var _bonus_button: Button
var _growth_label: Label
var _status: Label


func _ready() -> void:
	var options: Dictionary = _read_options()
	if options.has("seed"):
		_rng.seed = int(options["seed"])
	else:
		_rng.randomize()
	_bonus_on = options.has("bonus")
	_growth = float(options.get("growth", 1.0))

	_build_interface()
	SignalBus.mutation_discovered.connect(_on_mutation_discovered)
	_parents[0] = starter_seeds[_seed_cursor[0] % starter_seeds.size()]
	_parents[1] = starter_seeds[_seed_cursor[1] % starter_seeds.size()]
	_refresh_parents()
	for i: int in int(options.get("cross", 1)):
		_cross()
	if options.has("adopt"):
		_on_offspring_tapped(int(options["adopt"]))


# ------------------------------------------------------------------ arayüz


func _build_interface() -> void:
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([_BACKGROUND_TOP, _BACKGROUND_BOTTOM])
	var gradient_texture: GradientTexture2D = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0.5, 0.0)
	gradient_texture.fill_to = Vector2(0.5, 1.0)
	var background: TextureRect = TextureRect.new()
	background.texture = gradient_texture
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_add_label("FLORALAB · GENETİK LABORATUVARI", Vector2(0.0, 36.0), 1080.0, 42, _ACCENT)
	_add_label("FAZ 1 · iki tohumu çaprazla, çocuğa dokunarak onu ebeveyn yap", Vector2(0.0, 92.0), 1080.0, 24, _MUTED)
	_banner = _add_label("", Vector2(0.0, 132.0), 1080.0, 46, Color(1.0, 0.85, 0.3))
	_banner.modulate.a = 0.0

	for slot: int in 2:
		var center_x: float = 270.0 + 540.0 * float(slot)
		var plant: PlantInstance = _make_plant(Vector2(center_x, 720.0), 0.78)
		_parent_plants.append(plant)
		# Bilgi kutusu en çok 6 satır (satır ~32 px) sığacak kadar yer bırakır; düğme onun altındadır.
		var label: Label = _add_label("", Vector2(center_x - 255.0, 738.0), 510.0, 22, _TEXT, true)
		_parent_labels.append(label)
		_add_label("EBEVEYN %s" % ("A" if slot == 0 else "B"), Vector2(center_x - 250.0, 214.0), 500.0, 30, _ACCENT)
		var cycle: Button = _add_button("TOHUMU DEĞİŞTİR", Vector2(center_x - 170.0, 940.0), Vector2(340.0, 60.0), 24)
		cycle.pressed.connect(_on_cycle_seed.bind(slot))

	var cross: Button = _add_button("ÇAPRAZLA  ×%d" % OFFSPRING_COUNT, Vector2(300.0, 1018.0), Vector2(480.0, 96.0), 40)
	cross.pressed.connect(_cross)
	_bonus_button = _add_button("", Vector2(30.0, 1032.0), Vector2(250.0, 68.0), 22)
	_bonus_button.pressed.connect(_on_toggle_bonus)
	_update_bonus_button()

	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = _growth
	slider.position = Vector2(800.0, 1062.0)
	slider.size = Vector2(240.0, 32.0)
	slider.value_changed.connect(_on_growth_changed)
	add_child(slider)
	_growth_label = _add_label("", Vector2(800.0, 1026.0), 240.0, 24, _MUTED)
	_update_growth_label()

	_status = _add_label("", Vector2(0.0, 1134.0), 1080.0, 24, _MUTED)

	for i: int in OFFSPRING_COUNT:
		var column: int = i % OFFSPRING_COLUMNS
		var row: int = i / OFFSPRING_COLUMNS
		var cell_x: float = 135.0 + 270.0 * float(column)
		var base_y: float = 1420.0 + 340.0 * float(row)
		var plant: PlantInstance = _make_plant(Vector2(cell_x, base_y), 0.42)
		_offspring_plants.append(plant)
		var label: Label = _add_label("", Vector2(cell_x - 130.0, base_y + 12.0), 260.0, 20, _TEXT)
		_offspring_labels.append(label)
		var tap: Button = Button.new()
		tap.flat = true
		tap.position = Vector2(cell_x - 130.0, base_y - 230.0)
		tap.size = Vector2(260.0, 330.0)
		tap.pressed.connect(_on_offspring_tapped.bind(i))
		add_child(tap)


func _make_plant(base_position: Vector2, plant_scale: float) -> PlantInstance:
	var plant: PlantInstance = PLANT_SCENE.instantiate() as PlantInstance
	plant.ruleset = ruleset
	plant.position = base_position
	plant.scale = Vector2.ONE * plant_scale
	plant.growth = _growth
	add_child(plant)
	return plant


func _add_label(text: String, label_position: Vector2, width: float, font_size: int, color: Color, wrap: bool = false) -> Label:
	var label: Label = Label.new()
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	label.position = label_position
	label.size = Vector2(width, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _add_button(text: String, button_position: Vector2, button_size: Vector2, font_size: int) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.position = button_position
	button.size = button_size
	button.add_theme_font_size_override("font_size", font_size)
	add_child(button)
	return button


# ---------------------------------------------------------------- davranış


func _cross() -> void:
	if _parents[0] == null or _parents[1] == null:
		return
	var bonus: float = MUTATION_BONUS if _bonus_on else 0.0
	_offspring.clear()
	var mutations_seen: int = 0
	for i: int in OFFSPRING_COUNT:
		var result: BreedResult = GeneticsEngine.crossbreed_detailed(_parents[0], _parents[1], ruleset, _rng, bonus)
		_offspring.append(result.child)
		SignalBus.seed_crossbred.emit(_parents[0], _parents[1], result.child)
		if result.new_mutation != &"":
			mutations_seen += 1
			SignalBus.mutation_discovered.emit(result.child, result.new_mutation)
	_status.text = "%d çocuk · %d yeni mutasyon · olasılık %%%d" % [
		OFFSPRING_COUNT, mutations_seen, int(round((ruleset.mutation_chance + bonus) * 100.0))
	]
	_refresh_offspring()
	for plant: PlantInstance in _offspring_plants:
		plant.play_pop()


func _refresh_parents() -> void:
	for slot: int in 2:
		_parent_plants[slot].gene = _parents[slot]
		_parent_labels[slot].text = _describe(_parents[slot])


func _refresh_offspring() -> void:
	for i: int in OFFSPRING_COUNT:
		_offspring_plants[i].gene = _offspring[i]
		_offspring_labels[i].text = _describe_short(_offspring[i])


## Alt yazı için kısa özet: parçalar ve mutasyonlar.
func _describe_short(gene: PlantGene) -> String:
	var phenotype: PlantPhenotype = GeneticsEngine.express(gene, ruleset)
	var text: String = "%s\n%s" % [_part_name(phenotype.stem_id), _part_name(phenotype.fruit_id)]
	for id: StringName in phenotype.mutations:
		text += "\n★ " + ruleset.get_mutation(id).display_name
	return text


## Ebeveyn bilgi kutusu için ayrıntılı özet.
func _describe(gene: PlantGene) -> String:
	var phenotype: PlantPhenotype = GeneticsEngine.express(gene, ruleset)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s, %s, %s" % [_part_name(phenotype.stem_id), _part_name(phenotype.leaf_id), _part_name(phenotype.fruit_id)])
	lines.append("Büyüme ×%.2f · Su ×%.2f · Değer %.1f" % [phenotype.growth_speed, phenotype.water_use, phenotype.market_value])
	var carried: Array[StringName] = _hidden_alleles(gene, phenotype)
	if not carried.is_empty():
		lines.append("Gizli taşıyor: " + ", ".join(PackedStringArray(carried.map(_part_name))))
	if phenotype.mutations.is_empty():
		lines.append("Mutasyon yok · nesil %d" % gene.generation)
	else:
		var names: PackedStringArray = PackedStringArray()
		for id: StringName in phenotype.mutations:
			names.append(ruleset.get_mutation(id).display_name)
		lines.append("★ %s · nesil %d" % [", ".join(names), gene.generation])
	return "\n".join(lines)


## Görünmeyen (çekinik) aleller: genotipte olup fenotipte görünmeyen parça kimlikleri.
func _hidden_alleles(gene: PlantGene, phenotype: PlantPhenotype) -> Array[StringName]:
	var hidden: Array[StringName] = []
	var shown: Array[StringName] = [phenotype.stem_id, phenotype.leaf_id, phenotype.fruit_id]
	for alleles: Array[StringName] in [gene.stem_alleles, gene.leaf_alleles, gene.fruit_alleles]:
		for id: StringName in alleles:
			if not shown.has(id) and not hidden.has(id):
				hidden.append(id)
	return hidden


func _part_name(id: StringName) -> String:
	var part: PlantPartDef = ruleset.get_part(id)
	return part.display_name if part != null else String(id)


func _on_cycle_seed(slot: int) -> void:
	_seed_cursor[slot] = (_seed_cursor[slot] + 1) % starter_seeds.size()
	_parents[slot] = starter_seeds[_seed_cursor[slot]]
	_refresh_parents()


func _on_offspring_tapped(index: int) -> void:
	if index < 0 or index >= _offspring.size():
		return
	_parents[_next_slot] = _offspring[index]
	_next_slot = 1 - _next_slot
	_refresh_parents()


func _on_toggle_bonus() -> void:
	_bonus_on = not _bonus_on
	_update_bonus_button()


func _update_bonus_button() -> void:
	_bonus_button.text = "UV BONUS: %s" % ("AÇIK +%%%d" % int(MUTATION_BONUS * 100.0) if _bonus_on else "KAPALI")


func _on_growth_changed(value: float) -> void:
	_growth = value
	for plant: PlantInstance in _parent_plants:
		plant.growth = value
	for plant: PlantInstance in _offspring_plants:
		plant.growth = value
	_update_growth_label()


func _update_growth_label() -> void:
	_growth_label.text = "Büyüme %%%d" % int(round(_growth * 100.0))


## SignalBus üzerinden gelen olay: sahne, çaprazlamayı yapan koddan habersizdir, yalnızca olayı dinler.
func _on_mutation_discovered(_child: PlantGene, mutation_id: StringName) -> void:
	var mutation: MutationDef = ruleset.get_mutation(mutation_id)
	_banner.text = "★ MUTASYON: %s ★" % (mutation.display_name if mutation != null else String(mutation_id))
	var tween: Tween = create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.08)
	tween.tween_interval(1.6)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.5)


func _read_options() -> Dictionary:
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			continue
		var body: String = argument.substr(2)
		var split: int = body.find("=")
		if split < 0:
			options[body] = true
		else:
			options[body.substr(0, split)] = body.substr(split + 1)
	return options
