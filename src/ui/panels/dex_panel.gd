class_name DexPanel
extends GamePanel
## Seed-Dex sekmesi: tamamlanma halkası ve sayaçlar, keşfedilen türlerin koleksiyonu (önizleme, ad, en yüksek değer, nadirlik çerçevesi)
## ve ayrıntı penceresi. Keşfedilmemiş türler kilitli karttır (en çok birkaç tanesi gösterilir, kalanı sayıyla özetlenir). Yalnızca
## okur ve çizer.
##
## Uygular: design/game-brief.md, "Player goal" (Seed-Dex'i doldurmak) ve FAZ 5 (keşfedilen tohumlar ansiklopedisi);
## design/design-language.md, "Nadirlik".

const _COLUMNS: int = 3
const _LOCKED_PLACEHOLDERS: int = 6

var _ring: ProgressRing
var _species_chip: PanelContainer
var _species_label: Label
var _variant_chip: PanelContainer
var _variant_label: Label
var _grid: GridContainer
var _more: Label
var _detail: Control


func _build() -> void:
	var scroll: ScrollContainer = UiKit.scroll()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var column: VBoxContainer = UiKit.vbox(UiTokens.SPACE_2)
	scroll.add_child(column)

	var header: PanelContainer = UiKit.card("CardRaised")
	var header_row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_3)
	header.add_child(header_row)
	_ring = ProgressRing.new()
	header_row.add_child(_ring)
	var stats: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	stats.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_row.add_child(stats)
	stats.add_child(UiKit.label(tr("DEX_TITLE"), &"TitleLabel"))
	_species_chip = UiKit.chip("", &"dex", &"ChipAccent", UiTokens.ACCENT)
	_species_label = (_species_chip.get_child(0).get_child(1)) as Label
	stats.add_child(_species_chip)
	_variant_chip = UiKit.chip("", &"sparkle", &"Chip", UiTokens.UV)
	_variant_label = (_variant_chip.get_child(0).get_child(1)) as Label
	stats.add_child(_variant_chip)
	column.add_child(header)

	_grid = GridContainer.new()
	_grid.columns = _COLUMNS
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_grid)
	_more = UiKit.label("", &"MutedLabel", true, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_more)
	SignalBus.dex_discovery.connect(_on_discovery)
	SignalBus.game_reloaded.connect(refresh)


func refresh() -> void:
	if _grid == null:
		return
	var ruleset: GeneticsRuleset = session.catalog.ruleset
	var total: int = session.dex.total_species(ruleset)
	_ring.ring_color = UiTokens.palette(session.settings.colorblind)["accent"] as Color
	_ring.set_ratio(session.dex.completion(ruleset), true)
	_species_label.text = tr("DEX_SPECIES") % [session.dex.species_count(), total]
	_variant_label.text = tr("DEX_VARIANTS") % session.dex.variant_count()
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


func on_shown() -> void:
	refresh()
	var cards: Array[Control] = []
	for card: Node in _grid.get_children():
		if card is Control:
			cards.append(card as Control)
	UiMotion.stagger_in(cards, 0.03, 0.45)


func _on_discovery(_morph_id: StringName, _new_species: bool, _bonus: int) -> void:
	if is_visible_in_tree():
		refresh()


## Nadirlik çerçevesi: kartın üstüne binen, fareyi yakalamayan renkli kenarlık.
func _rarity_frame(rarity: UiTokens.Rarity) -> Panel:
	var frame: Panel = Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	var color: Color = UiTokens.rarity_color(rarity, session.settings.colorblind)
	style.border_color = UiTokens.with_alpha(color, 0.9 if rarity != UiTokens.Rarity.COMMON else 0.25)
	style.set_border_width_all(3 if rarity != UiTokens.Rarity.COMMON else 1)
	style.set_corner_radius_all(UiTokens.RADIUS_MD)
	if rarity == UiTokens.Rarity.MUTANT:
		style.shadow_color = UiTokens.with_alpha(color, 0.35)
		style.shadow_size = 14
	frame.add_theme_stylebox_override("panel", style)
	return frame


func _make_card(entry: SeedDex.Entry) -> Control:
	var phenotype: PlantPhenotype = GeneticsEngine.express(entry.sample, session.catalog.ruleset)
	var rarity: UiTokens.Rarity = GeneSummary.rarity(phenotype)
	var button: FxButton = FxButton.new()
	button.theme_type_variation = &"MutantButton" if rarity == UiTokens.Rarity.MUTANT else &"CardButton"
	button.custom_minimum_size = Vector2(0.0, 290.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_show_detail.bind(entry.morph_id))
	var preview: PlantPreview = PlantPreview.new()
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview.offset_top = 10.0
	preview.offset_bottom = -92.0
	button.add_child(preview)
	preview.show_gene(entry.sample, session.catalog.ruleset, 1.0)
	preview.set_sway(false)
	var caption: Label = UiKit.label(GeneSummary.part_name(phenotype.fruit_id, session.catalog.ruleset), &"SmallLabel", false, HORIZONTAL_ALIGNMENT_CENTER)
	caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -88.0
	caption.offset_bottom = -52.0
	caption.clip_text = true
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_child(caption)
	var tag: CreditTag = UiKit.price_tag(int(round(entry.best_value)), &"AccentLabel")
	tag.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tag.offset_top = -50.0
	tag.offset_bottom = -8.0
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(tag)
	button.add_child(_rarity_frame(rarity))
	return button


func _make_locked_card() -> Control:
	var panel: PanelContainer = UiKit.card()
	panel.custom_minimum_size = Vector2(0.0, 290.0)
	panel.modulate = Color(1, 1, 1, 0.6)
	var box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon: TextureRect = UiKit.icon(&"lock", UiTokens.ICON_LG, UiTokens.TEXT_DIM)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	box.add_child(UiKit.label(tr("DEX_UNKNOWN"), &"OverlineLabel", false, HORIZONTAL_ALIGNMENT_CENTER))
	panel.add_child(box)
	return panel


## Tür ayrıntısı: büyük önizleme, nadirlik, özellikler ve görülme sayıları.
func _show_detail(morph_id: StringName) -> void:
	var entry: SeedDex.Entry = session.dex.entry(morph_id)
	if entry == null:
		return
	if _detail != null:
		_detail.queue_free()
	var phenotype: PlantPhenotype = GeneticsEngine.express(entry.sample, session.catalog.ruleset)
	var rarity: UiTokens.Rarity = GeneSummary.rarity(phenotype)
	_detail = Control.new()
	_detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.01, 0.03, 0.02, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			_close_detail()
	)
	_detail.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(center)
	var card: PanelContainer = UiKit.card("CardUv" if rarity == UiTokens.Rarity.MUTANT else "CardRaised")
	card.custom_minimum_size = Vector2(900.0, 0.0)
	center.add_child(card)
	var box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	card.add_child(box)
	var preview: PlantPreview = PlantPreview.new()
	preview.custom_minimum_size = Vector2(0.0, 470.0)
	box.add_child(preview)
	preview.show_gene(entry.sample, session.catalog.ruleset, 1.0)
	preview.set_sway(not session.settings.reduce_motion)
	var rarity_chip: PanelContainer = UiKit.chip(tr("RARITY_%d" % int(rarity)), &"sparkle", &"Chip", UiTokens.rarity_color(rarity, session.settings.colorblind))
	rarity_chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(rarity_chip)
	box.add_child(UiKit.label(GeneSummary.title(entry.sample, session.catalog.ruleset), &"TitleLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.label("\n".join(GeneSummary.describe(entry.sample, session.catalog.ruleset)), &"SmallLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.label(tr("DEX_SEEN") % [entry.times_seen, entry.signatures.size(), entry.first_day], &"MutedLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	var close: FxButton = UiKit.button(tr("BTN_CLOSE"), &"PrimaryButton", 88.0)
	close.pressed.connect(_close_detail)
	box.add_child(close)
	add_child(_detail)
	UiMotion.fade_in(dim, UiTokens.DUR_QUICK)
	UiMotion.pop_in(card)


func _close_detail() -> void:
	if _detail != null:
		_detail.queue_free()
		_detail = null
