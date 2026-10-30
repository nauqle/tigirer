class_name FarmPanel
extends GamePanel
## Çiftlik sekmesi: kat seçici, toplu sulama/ekim düğmeleri, FarmView ızgarası (dokun = ekim/sulama/hasat, sürükle = toplu hasat),
## bağlamsal ipucu ve alttaki tohum şeridi. Kararı oyuncu verir (hangi tohum, hangi saksı); değişikliği `GameSession` komutları yapar.
##
## Uygular: design/game-brief.md, "Core loop" ve FAZ 2 (hidroponik ızgara, kaydırarak hasat).

var _floor_index: int = 0
var _selected_uid: String = ""
var _floor_label: Label
var _view: FarmView
var _lock_label: Label
var _hint: Label
var _hint_card: PanelContainer
var _seed_row: HBoxContainer
var _seed_group: ButtonGroup = ButtonGroup.new()
var _water_button: Button
var _plant_button: Button
var _refresh_timer: Timer


func _build() -> void:
	var column: VBoxContainer = UiKit.vbox(12)
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(column)

	var floors: HBoxContainer = UiKit.hbox(12)
	column.add_child(floors)
	var previous: Button = UiKit.button("◀", &"TabButton", 72.0)
	previous.custom_minimum_size.x = 100.0
	previous.pressed.connect(_change_floor.bind(-1))
	floors.add_child(previous)
	_floor_label = UiKit.label("", &"HeadingLabel", false, HORIZONTAL_ALIGNMENT_CENTER)
	_floor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_floor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	floors.add_child(_floor_label)
	var next: Button = UiKit.button("▶", &"TabButton", 72.0)
	next.custom_minimum_size.x = 100.0
	next.pressed.connect(_change_floor.bind(1))
	floors.add_child(next)

	var actions: HBoxContainer = UiKit.hbox(12)
	column.add_child(actions)
	_water_button = UiKit.button(tr("FARM_WATER_ALL"), &"", 76.0)
	_water_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_water_button.pressed.connect(_on_water_all)
	actions.add_child(_water_button)
	_plant_button = UiKit.button(tr("FARM_PLANT_ALL"), &"PrimaryButton", 76.0)
	_plant_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plant_button.pressed.connect(_on_plant_all)
	actions.add_child(_plant_button)

	_view = FarmView.new()
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.custom_minimum_size = Vector2(0.0, 600.0)
	column.add_child(_view)
	_view.setup(session.farm, session.catalog.ruleset)
	_view.setup_drones(session.drones)
	_view.pot_tapped.connect(_on_pot_tapped)
	_view.swipe_started.connect(session.begin_swipe)
	_view.harvest_requested.connect(_on_harvest_requested)
	_view.swipe_ended.connect(session.end_swipe)

	_lock_label = UiKit.label(tr("FARM_LOCKED"), &"HeadingLabel", true, HORIZONTAL_ALIGNMENT_CENTER)
	_lock_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_view.add_child(_lock_label)

	_hint_card = UiKit.card()
	column.add_child(_hint_card)
	_hint = UiKit.label("", &"SmallLabel", true, HORIZONTAL_ALIGNMENT_CENTER)
	_hint_card.add_child(_hint)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 190.0)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(scroll)
	_seed_row = UiKit.hbox(12)
	_seed_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	scroll.add_child(_seed_row)

	SignalBus.inventory_changed.connect(_rebuild_seeds)
	SignalBus.floor_unlocked.connect(_on_floor_unlocked)
	SignalBus.game_reloaded.connect(_on_game_reloaded)
	SignalBus.item_sold.connect(_on_item_sold)
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 0.5
	_refresh_timer.autostart = true
	_refresh_timer.timeout.connect(_update_hint)
	add_child(_refresh_timer)
	_show_floor(0)


func refresh() -> void:
	if _view == null:
		return
	_view.reduce_motion = session.settings.reduce_motion
	_rebuild_seeds()
	_update_hint()


func on_shown() -> void:
	refresh()


# ------------------------------------------------------------------ katlar


func _change_floor(step: int) -> void:
	var count: int = session.catalog.floors.size()
	_show_floor((_floor_index + step + count) % count)


func _show_floor(index: int) -> void:
	_floor_index = index
	_view.show_floor(index)
	var def: FloorDef = session.catalog.floors[index]
	var unlocked: bool = session.farm.get_floor(index).unlocked
	_floor_label.text = def.display_name if unlocked else "%s (%s)" % [def.display_name, tr("FARM_LOCKED_TAG")]
	_lock_label.visible = not unlocked
	_water_button.disabled = not unlocked
	_plant_button.disabled = not unlocked
	_update_hint()


func _on_floor_unlocked(floor_index: int) -> void:
	if floor_index == _floor_index:
		_show_floor(_floor_index)


func _on_game_reloaded() -> void:
	_selected_uid = ""
	_show_floor(0)
	_rebuild_seeds()


# --------------------------------------------------------------- eylemler


func _on_pot_tapped(floor_index: int, pot_index: int) -> void:
	var pot: PotState = session.farm.get_pot(floor_index, pot_index)
	if pot == null:
		return
	if pot.is_empty():
		if _selected_uid == "":
			SignalBus.toast_requested.emit("ERR_PICK_SEED", [])
			return
		UiKit.report(session.plant_seed(floor_index, pot_index, _selected_uid))
	elif pot.is_mature():
		UiKit.report(session.harvest_pot(floor_index, pot_index))
	else:
		UiKit.report(session.water_pot(floor_index, pot_index))


func _on_harvest_requested(floor_index: int, pot_index: int) -> void:
	session.swipe_harvest(floor_index, pot_index)


func _on_water_all() -> void:
	UiKit.report(session.water_floor(_floor_index))


func _on_plant_all() -> void:
	if _selected_uid == "":
		SignalBus.toast_requested.emit("ERR_PICK_SEED", [])
		return
	UiKit.report(session.plant_all(_floor_index, _selected_uid))


func _on_item_sold(_signature: StringName, _quantity: int, _credits: int) -> void:
	session.complete_tutorial()


# ------------------------------------------------------------------ tohumlar


func _rebuild_seeds() -> void:
	UiKit.clear(_seed_row)
	_seed_group = ButtonGroup.new()
	var items: Array[SeedItem] = session.inventory.seeds()
	var still_owned: bool = false
	for item: SeedItem in items:
		if item.gene.uid == _selected_uid:
			still_owned = true
	if not still_owned:
		_selected_uid = items[0].gene.uid if not items.is_empty() else ""
	for item: SeedItem in items:
		_seed_row.add_child(_make_seed_button(item))
	if items.is_empty():
		_seed_row.add_child(UiKit.label(tr("FARM_NO_SEEDS"), &"MutedLabel"))


func _make_seed_button(item: SeedItem) -> Button:
	var button: Button = Button.new()
	button.toggle_mode = true
	button.button_group = _seed_group
	button.button_pressed = item.gene.uid == _selected_uid
	button.custom_minimum_size = Vector2(210.0, 170.0)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: _selected_uid = item.gene.uid)
	var preview: PlantPreview = PlantPreview.new()
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview.offset_bottom = -48.0
	preview.offset_top = 6.0
	button.add_child(preview)
	preview.show_gene(item.gene, session.catalog.ruleset, 1.0)
	preview.set_sway(not session.settings.reduce_motion)
	var caption: Label = UiKit.label("%s ×%d" % [GeneSummary.title(item.gene, session.catalog.ruleset), item.count], &"SmallLabel", false, HORIZONTAL_ALIGNMENT_CENTER)
	caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -42.0
	caption.clip_text = true
	button.add_child(caption)
	return button


# -------------------------------------------------------------------- ipucu


## Öğretici: ilk satışa kadar durumun bir sonraki adımı; sonra yalnızca kısa bağlamsal ipuçları.
func _update_hint() -> void:
	if session == null or _hint == null:
		return
	var floor_state: FloorState = session.farm.get_floor(_floor_index)
	var planted: int = 0
	var mature: int = 0
	var thirsty: int = 0
	for pot: PotState in floor_state.pots:
		if pot.is_empty():
			continue
		planted += 1
		if pot.is_mature():
			mature += 1
		elif pot.water < session.catalog.farm_config.water_growth_threshold + session.catalog.farm_config.water_growth_ramp:
			thirsty += 1
	var key: String = ""
	if not floor_state.unlocked:
		key = ""
	elif mature > 0:
		key = "HINT_SWIPE"
	elif thirsty > 0:
		key = "HINT_WATER"
	elif planted == 0:
		key = "HINT_PLANT"
	elif session.inventory.produce_count() > 0 and not session.settings.tutorial_done:
		key = "HINT_SELL"
	elif not session.settings.tutorial_done:
		key = "HINT_WAIT"
	_hint.text = tr(key) if key != "" else ""
	_hint_card.visible = key != ""
