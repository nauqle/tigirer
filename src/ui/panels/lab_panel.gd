class_name LabPanel
extends GamePanel
## Laboratuvar sekmesi: iki ebeveyn tohum seç, çaprazla, çocukları gör. Çocuğa dokunmak onu sıradaki ebeveyn yapar. Çaprazlama anında
## DNA simgesi dönerek ebeveynler "birleşir", çocuklar sırayla belirir; mutasyonlu çocuk mor çerçeve ve ışıltıyla ayrışır.
## Mutasyon ve keşif bildirimleri SignalBus olaylarıdır (ToastLayer gösterir). Çaprazlama `GameSession.crossbreed` komutudur.
##
## Uygular: design/game-brief.md, "Core loop" son madde (çaprazla, %5 mutasyon, Seed-Dex'e kayıt); design/design-language.md.

var _slot_uids: Array[String] = ["", ""]
var _next_slot: int = 0
var _previews: Array[PlantPreview] = []
var _names: Array[Label] = []
var _details: Array[Label] = []
var _cards: Array[PanelContainer] = []
var _dna: TextureRect
var _cross_button: PriceButton
var _chance_chip: PanelContainer
var _chance_label: Label
var _children_box: VBoxContainer
var _children_row: HBoxContainer
var _children_title: Label
var _hint: FloraBubble


func _build() -> void:
	var scroll: ScrollContainer = UiKit.scroll()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var column: VBoxContainer = UiKit.vbox(UiTokens.SPACE_2)
	scroll.add_child(column)

	var header: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	column.add_child(header)
	var title: Label = UiKit.label(tr("LAB_TITLE"), &"TitleLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	_chance_chip = UiKit.chip("", &"sparkle", &"ChipGold", UiTokens.SAP)
	_chance_label = (_chance_chip.get_child(0).get_child(1)) as Label
	header.add_child(_chance_chip)

	var slots: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	column.add_child(slots)
	slots.add_child(_make_slot(0))
	_dna = UiKit.icon(&"dna", UiTokens.ICON_LG, UiTokens.UV)
	_dna.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slots.add_child(_dna)
	slots.add_child(_make_slot(1))

	_cross_button = PriceButton.new()
	_cross_button.setup(tr("LAB_CROSS"), session.catalog.economy_config.cross_cost, &"PrimaryButton", &"dna", 104.0)
	_cross_button.pressed.connect(_on_cross)
	column.add_child(_cross_button)

	_hint = FloraBubble.new()
	_hint.say(tr("LAB_HINT"))
	column.add_child(_hint)

	_children_box = UiKit.vbox(UiTokens.SPACE_1)
	_children_box.visible = false
	column.add_child(_children_box)
	_children_title = UiKit.label(tr("LAB_CHILDREN"), &"OverlineLabel")
	_children_box.add_child(_children_title)
	_children_row = UiKit.hbox(UiTokens.SPACE_1)
	_children_box.add_child(_children_row)
	SignalBus.inventory_changed.connect(_on_inventory_changed)
	SignalBus.equipment_purchased.connect(_on_equipment_changed)
	SignalBus.credits_changed.connect(_on_credits_changed)
	SignalBus.game_reloaded.connect(_on_reloaded)


func _make_slot(slot: int) -> Control:
	var card: PanelContainer = UiKit.card("CardRaised")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	card.add_child(box)
	box.add_child(UiKit.label(tr("LAB_PARENT_A") if slot == 0 else tr("LAB_PARENT_B"), &"OverlineLabel", false, HORIZONTAL_ALIGNMENT_CENTER))
	var preview: PlantPreview = PlantPreview.new()
	preview.custom_minimum_size = Vector2(0.0, 290.0)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(preview)
	_previews.append(preview)
	var name_label: Label = UiKit.label("", &"HeadingLabel", true, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(name_label)
	_names.append(name_label)
	var detail: Label = UiKit.label("", &"MutedLabel", true, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(detail)
	_details.append(detail)
	box.add_child(UiKit.spacer())
	var buttons: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	box.add_child(buttons)
	var back: FxButton = UiKit.icon_button(&"chevron_left", 68.0)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(_cycle.bind(slot, -1))
	buttons.add_child(back)
	var forward: FxButton = UiKit.icon_button(&"chevron_right", 68.0)
	forward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	forward.pressed.connect(_cycle.bind(slot, 1))
	buttons.add_child(forward)
	_cards.append(card)
	return card


func refresh() -> void:
	if _cross_button == null:
		return
	_keep_selection_valid()
	for slot: int in 2:
		_show_slot(slot)
	var economy: EconomyConfig = session.catalog.economy_config
	var chance: float = clampf(session.catalog.ruleset.mutation_chance + session.automation.lab_mutation_bonus(), 0.0, 1.0)
	_chance_label.text = tr("LAB_CHANCE") % UiFormat.percent(chance)
	_cross_button.set_price(economy.cross_cost)
	_cross_button.set_enabled(_slot_uids[0] != "" and _slot_uids[1] != "" and session.wallet.can_afford(economy.cross_cost))


func on_shown() -> void:
	refresh()
	var slots: Array[Control] = []
	for card: PanelContainer in _cards:
		slots.append(card)
	UiMotion.stagger_in(slots, 0.07)


func _keep_selection_valid() -> void:
	var items: Array[SeedItem] = session.inventory.seeds()
	for slot: int in 2:
		if _slot_uids[slot] != "" and session.inventory.seed_count(_slot_uids[slot]) <= 0:
			_slot_uids[slot] = ""
		if _slot_uids[slot] == "" and not items.is_empty():
			_slot_uids[slot] = items[mini(slot, items.size() - 1)].gene.uid


func _show_slot(slot: int) -> void:
	var gene: PlantGene = session.inventory.peek_seed(_slot_uids[slot]) if _slot_uids[slot] != "" else null
	if gene == null:
		_names[slot].text = tr("LAB_NO_SEED")
		_details[slot].text = ""
		return
	_previews[slot].show_gene(gene, session.catalog.ruleset, 1.0)
	_previews[slot].set_sway(not session.settings.reduce_motion)
	_names[slot].text = "%s ×%d" % [GeneSummary.title(gene, session.catalog.ruleset), session.inventory.seed_count(gene.uid)]
	_details[slot].text = "\n".join(GeneSummary.describe(gene, session.catalog.ruleset))


func _cycle(slot: int, step: int) -> void:
	var items: Array[SeedItem] = session.inventory.seeds()
	if items.is_empty():
		return
	var index: int = 0
	for i: int in items.size():
		if items[i].gene.uid == _slot_uids[slot]:
			index = i
	_slot_uids[slot] = items[(index + step + items.size()) % items.size()].gene.uid
	refresh()
	UiMotion.bump(_cards[slot], 1.025)


func _on_cross() -> void:
	var result: CommandResult = session.crossbreed(_slot_uids[0], _slot_uids[1])
	UiKit.report(result)
	if result.ok:
		_play_cross_fx()
		_show_children()
	else:
		UiMotion.shake(_cross_button)
	refresh()


## Ebeveynler "birleşir": DNA simgesi dönüp parlar, kartlar hafifçe öne eğilir.
func _play_cross_fx() -> void:
	if UiMotion.reduce_motion:
		return
	UiMotion.center_pivot(_dna)
	_dna.rotation = 0.0
	var tween: Tween = _dna.create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dna, "rotation", TAU, UiTokens.DUR_SLOW * 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_dna, "scale", Vector2.ONE * 1.5, UiTokens.DUR_BASE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(_dna, "scale", Vector2.ONE, UiTokens.DUR_BASE)
	for card: PanelContainer in _cards:
		UiMotion.bump(card, 1.03)


## Son çaprazlamanın çocukları: dokunan çocuk sıradaki ebeveyn yuvasına geçer. Mutasyonlu çocuk mor çerçeveli.
func _show_children() -> void:
	UiKit.clear(_children_row)
	_children_box.visible = true
	_hint.visible = false
	var outcome: BreedingService.Outcome = session.last_breed
	var cards: Array[Control] = []
	for i: int in outcome.children.size():
		var child: PlantGene = outcome.children[i]
		var mutated: bool = outcome.new_mutations[i] != &""
		var button: FxButton = FxButton.new()
		button.theme_type_variation = &"MutantButton" if mutated else &"CardButton"
		button.custom_minimum_size = Vector2(0.0, 340.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_adopt.bind(child.uid))
		var preview: PlantPreview = PlantPreview.new()
		preview.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview.offset_top = 10.0
		preview.offset_bottom = -92.0
		button.add_child(preview)
		preview.show_gene(child, session.catalog.ruleset, 1.0)
		preview.set_sway(not session.settings.reduce_motion)
		var caption: Label = UiKit.label(GeneSummary.title(child, session.catalog.ruleset), &"SmallLabel", true, HORIZONTAL_ALIGNMENT_CENTER)
		caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		caption.offset_top = -88.0
		caption.offset_bottom = -44.0
		button.add_child(caption)
		var hint: Label = UiKit.label(tr("LAB_TAP_ADOPT"), &"OverlineLabel", false, HORIZONTAL_ALIGNMENT_CENTER)
		hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		hint.offset_top = -44.0
		hint.offset_bottom = -8.0
		button.add_child(hint)
		if mutated:
			var badge: HBoxContainer = UiKit.icon_label(&"sparkle", GeneSummary.mutation_name(outcome.new_mutations[i], session.catalog.ruleset), &"UvLabel", UiTokens.UV, UiTokens.ICON_SM * 0.8)
			badge.set_anchors_preset(Control.PRESET_TOP_WIDE)
			badge.offset_top = 8.0
			badge.offset_bottom = 48.0
			badge.alignment = BoxContainer.ALIGNMENT_CENTER
			button.add_child(badge)
		_children_row.add_child(button)
		cards.append(button)
	UiMotion.stagger_in(cards, 0.12, 0.9)


## Çocuğu sıradaki ebeveyn yuvasına koyar (yuvalar sırayla dolar).
func _adopt(uid: String) -> void:
	_slot_uids[_next_slot] = uid
	UiMotion.bump(_cards[_next_slot], 1.04)
	_next_slot = 1 - _next_slot
	refresh()


func _on_inventory_changed() -> void:
	if is_visible_in_tree():
		refresh()


func _on_equipment_changed(_kind: EquipmentDef.Kind, _floor_index: int, _target: int, _level: int) -> void:
	refresh()


func _on_credits_changed(_credits: int) -> void:
	if _cross_button != null:
		refresh()


func _on_reloaded() -> void:
	_slot_uids = ["", ""]
	UiKit.clear(_children_row)
	_children_box.visible = false
	_hint.visible = true
	refresh()
