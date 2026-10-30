class_name DexPanel
extends GamePanel
## Seed-Dex sekmesi: keşfedilen türlerin koleksiyonu (önizleme, ad, en yüksek değer), tamamlanma göstergesi ve ayrıntı penceresi.
## Keşfedilmemiş türler "?" kartıdır (en çok birkaç tanesi gösterilir, kalanı sayıyla özetlenir). Yalnızca okur ve çizer.
##
## Uygular: design/game-brief.md, "Player goal" (Seed-Dex'i doldurmak) ve FAZ 5 (keşfedilen tohumlar ansiklopedisi).

const _COLUMNS: int = 3
const _LOCKED_PLACEHOLDERS: int = 6

var _stats: Label
var _progress: ProgressBar
var _grid: GridContainer
var _more: Label
var _detail: Control


func _build() -> void:
	var scroll: ScrollContainer = UiKit.scroll()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var column: VBoxContainer = UiKit.vbox(14)
	scroll.add_child(column)
	column.add_child(UiKit.label(tr("DEX_TITLE"), &"HeadingLabel"))
	var card: PanelContainer = UiKit.card()
	column.add_child(card)
	var box: VBoxContainer = UiKit.vbox(8)
	card.add_child(box)
	_stats = UiKit.label("", &"AccentLabel", true)
	box.add_child(_stats)
	_progress = ProgressBar.new()
	_progress.custom_minimum_size = Vector2(0.0, 26.0)
	_progress.show_percentage = false
	_progress.max_value = 100.0
	box.add_child(_progress)
	_grid = GridContainer.new()
	_grid.columns = _COLUMNS
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_grid)
	_more = UiKit.label("", &"MutedLabel", true, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_more)
	SignalBus.dex_discovery.connect(_on_discovery)
	SignalBus.game_reloaded.connect(refresh)
	SignalBus.plant_harvested.connect(_on_harvested)


func refresh() -> void:
	if _grid == null:
		return
	var ruleset: GeneticsRuleset = session.catalog.ruleset
	var total: int = session.dex.total_species(ruleset)
	_stats.text = tr("DEX_STATS") % [session.dex.species_count(), total, int(round(session.dex.completion(ruleset) * 100.0)), session.dex.variant_count()]
	_progress.value = session.dex.completion(ruleset) * 100.0
	UiKit.clear(_grid)
	var entries: Array[SeedDex.Entry] = session.dex.entries()
	entries.sort_custom(func(a: SeedDex.Entry, b: SeedDex.Entry) -> bool: return a.best_value > b.best_value)
	for entry: SeedDex.Entry in entries:
		_grid.add_child(_make_card(entry))
	var locked: int = total - session.dex.species_count()
	for i: int in mini(locked, _LOCKED_PLACEHOLDERS):
		_grid.add_child(_make_locked_card())
	var hidden: int = locked - _LOCKED_PLACEHOLDERS
	_more.text = tr("DEX_MORE") % hidden if hidden > 0 else ""


func _on_discovery(_morph_id: StringName, _new_species: bool, _bonus: int) -> void:
	if is_visible_in_tree():
		refresh()


func _on_harvested(_result: HarvestResult) -> void:
	pass


func _make_card(entry: SeedDex.Entry) -> Control:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(0.0, 270.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_show_detail.bind(entry.morph_id))
	var preview: PlantPreview = PlantPreview.new()
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview.offset_top = 8.0
	preview.offset_bottom = -78.0
	button.add_child(preview)
	preview.show_gene(entry.sample, session.catalog.ruleset, 1.0)
	preview.set_sway(false)
	var fruit_id: StringName = GeneticsEngine.express(entry.sample, session.catalog.ruleset).fruit_id
	var caption: Label = UiKit.label("%s\n◆%.0f" % [GeneSummary.part_name(fruit_id, session.catalog.ruleset), entry.best_value], &"SmallLabel", false, HORIZONTAL_ALIGNMENT_CENTER)
	caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -74.0
	button.add_child(caption)
	return button


func _make_locked_card() -> Control:
	var panel: PanelContainer = UiKit.card()
	panel.custom_minimum_size = Vector2(0.0, 270.0)
	panel.modulate = Color(1, 1, 1, 0.55)
	var mark: Label = UiKit.label("?", &"BigLabel", false, HORIZONTAL_ALIGNMENT_CENTER)
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(mark)
	return panel


## Tür ayrıntısı: büyük önizleme, özellikler ve görülme sayıları.
func _show_detail(morph_id: StringName) -> void:
	var entry: SeedDex.Entry = session.dex.entry(morph_id)
	if entry == null:
		return
	if _detail != null:
		_detail.queue_free()
	_detail = Control.new()
	_detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.03, 0.06, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail.add_child(center)
	var card: PanelContainer = UiKit.card()
	card.custom_minimum_size = Vector2(900.0, 0.0)
	center.add_child(card)
	var box: VBoxContainer = UiKit.vbox(10)
	card.add_child(box)
	var preview: PlantPreview = PlantPreview.new()
	preview.custom_minimum_size = Vector2(0.0, 470.0)
	box.add_child(preview)
	preview.show_gene(entry.sample, session.catalog.ruleset, 1.0)
	preview.set_sway(not session.settings.reduce_motion)
	box.add_child(UiKit.label(GeneSummary.title(entry.sample, session.catalog.ruleset), &"HeadingLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.label("\n".join(GeneSummary.describe(entry.sample, session.catalog.ruleset)), &"SmallLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.label(tr("DEX_SEEN") % [entry.times_seen, entry.signatures.size(), entry.first_day], &"MutedLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	var close: Button = UiKit.button(tr("BTN_CLOSE"), &"PrimaryButton", 84.0)
	close.pressed.connect(func() -> void: _detail.queue_free())
	box.add_child(close)
	add_child(_detail)
