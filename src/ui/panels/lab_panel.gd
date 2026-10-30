class_name LabPanel
extends GamePanel
## Laboratuvar sekmesi: iki ebeveyn tohum seç, çaprazla, çocukları gör. Çocuğa dokunmak onu sıradaki ebeveyn yapar.
## Mutasyon ve keşif bildirimleri SignalBus olaylarıdır (ToastLayer gösterir). Çaprazlama `GameSession.crossbreed` komutudur.
##
## Uygular: design/game-brief.md, "Core loop" son madde (çaprazla, %5 mutasyon, Seed-Dex'e kayıt).

var _slot_uids: Array[String] = ["", ""]
var _next_slot: int = 0
var _previews: Array[PlantPreview] = []
var _names: Array[Label] = []
var _details: Array[Label] = []
var _cross_button: Button
var _chance_label: Label
var _children_row: HBoxContainer
var _children_title: Label


func _build() -> void:
	var scroll: ScrollContainer = UiKit.scroll()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var column: VBoxContainer = UiKit.vbox(14)
	scroll.add_child(column)
	column.add_child(UiKit.label(tr("LAB_TITLE"), &"HeadingLabel"))
	_chance_label = UiKit.label("", &"MutedLabel", true)
	column.add_child(_chance_label)

	var slots: HBoxContainer = UiKit.hbox(14)
	column.add_child(slots)
	for slot: int in 2:
		slots.add_child(_make_slot(slot))

	_cross_button = UiKit.button("", &"PrimaryButton", 100.0)
	_cross_button.pressed.connect(_on_cross)
	column.add_child(_cross_button)

	_children_title = UiKit.label(tr("LAB_CHILDREN"), &"AccentLabel")
	_children_title.visible = false
	column.add_child(_children_title)
	_children_row = UiKit.hbox(12)
	column.add_child(_children_row)
	SignalBus.inventory_changed.connect(_on_inventory_changed)
	SignalBus.equipment_purchased.connect(_on_equipment_changed)
	SignalBus.credits_changed.connect(_on_credits_changed)
	SignalBus.game_reloaded.connect(_on_reloaded)


func _make_slot(slot: int) -> Control:
	var card: PanelContainer = UiKit.card()
	var box: VBoxContainer = UiKit.vbox(8)
	card.add_child(box)
	box.add_child(UiKit.label(tr("LAB_PARENT_A") if slot == 0 else tr("LAB_PARENT_B"), &"AccentLabel", false, HORIZONTAL_ALIGNMENT_CENTER))
	var preview: PlantPreview = PlantPreview.new()
	preview.custom_minimum_size = Vector2(0.0, 300.0)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(preview)
	_previews.append(preview)
	var name_label: Label = UiKit.label("", &"GoldLabel", true, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(name_label)
	_names.append(name_label)
	var detail: Label = UiKit.label("", &"MutedLabel", true, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(detail)
	_details.append(detail)
	var buttons: HBoxContainer = UiKit.hbox(10)
	box.add_child(buttons)
	var back: Button = UiKit.button("◀", &"TabButton", 72.0)
	back.pressed.connect(_cycle.bind(slot, -1))
	buttons.add_child(back)
	var forward: Button = UiKit.button("▶", &"TabButton", 72.0)
	forward.pressed.connect(_cycle.bind(slot, 1))
	buttons.add_child(forward)
	return card


func refresh() -> void:
	if _cross_button == null:
		return
	_keep_selection_valid()
	for slot: int in 2:
		_show_slot(slot)
	var economy: EconomyConfig = session.catalog.economy_config
	var chance: float = clampf(session.catalog.ruleset.mutation_chance + session.automation.lab_mutation_bonus(), 0.0, 1.0)
	_chance_label.text = tr("LAB_CHANCE") % [chance * 100.0, economy.offspring_per_cross]
	_cross_button.text = tr("LAB_CROSS") % economy.cross_cost
	_cross_button.disabled = _slot_uids[0] == "" or _slot_uids[1] == "" or not session.wallet.can_afford(economy.cross_cost)


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


func _on_cross() -> void:
	var result: CommandResult = session.crossbreed(_slot_uids[0], _slot_uids[1])
	UiKit.report(result)
	if result.ok:
		_show_children()
	refresh()


## Son çaprazlamanın çocukları: dokunan çocuk sıradaki ebeveyn yuvasına geçer.
func _show_children() -> void:
	UiKit.clear(_children_row)
	_children_title.visible = true
	var outcome: BreedingService.Outcome = session.last_breed
	for i: int in outcome.children.size():
		var child: PlantGene = outcome.children[i]
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(250.0, 330.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_adopt.bind(child.uid))
		var preview: PlantPreview = PlantPreview.new()
		preview.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview.offset_top = 8.0
		preview.offset_bottom = -90.0
		button.add_child(preview)
		preview.show_gene(child, session.catalog.ruleset, 1.0)
		preview.set_sway(not session.settings.reduce_motion)
		var caption: String = GeneSummary.title(child, session.catalog.ruleset)
		if outcome.new_mutations[i] != &"":
			caption += "\n★ " + GeneSummary.mutation_name(outcome.new_mutations[i], session.catalog.ruleset)
		var label: Label = UiKit.label(caption, &"SmallLabel", true, HORIZONTAL_ALIGNMENT_CENTER)
		label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		label.offset_top = -86.0
		button.add_child(label)
		_children_row.add_child(button)


## Çocuğu sıradaki ebeveyn yuvasına koyar (yuvalar sırayla dolar).
func _adopt(uid: String) -> void:
	_slot_uids[_next_slot] = uid
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
	_children_title.visible = false
	refresh()
