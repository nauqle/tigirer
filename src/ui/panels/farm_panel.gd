class_name FarmPanel
extends GamePanel
## Çiftlik sekmesi: kat seçici, FarmView ızgarası (dokun = ekim/sulama/hasat, sürükle = toplu hasat), FLORA'nın bağlamsal ipucu balonu,
## toplu sulama/ekim eylemleri ve alttaki tohum tepsisi. Kararı oyuncu verir (hangi tohum, hangi saksı); değişikliği `GameSession`
## komutları yapar.
##
## Uygular: design/game-brief.md, "Core loop" ve FAZ 2 (hidroponik ızgara, kaydırarak hasat); design/design-language.md.

var _floor_index: int = 0
var _selected_uid: String = ""
var _floor_name: Label
var _floor_size: Label
var _floor_icon: TextureRect
var _view: FarmView
var _lock_card: PanelContainer
var _hint: FloraBubble
var _seed_row: HBoxContainer
var _seed_group: ButtonGroup = ButtonGroup.new()
var _water_button: FxButton
var _plant_button: FxButton
var _refresh_timer: Timer


func _build() -> void:
	var column: VBoxContainer = UiKit.vbox(UiTokens.SPACE_2)
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(column)

	var floors: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	column.add_child(floors)
	var previous: FxButton = UiKit.icon_button(&"chevron_left", 76.0)
	previous.pressed.connect(_change_floor.bind(-1))
	floors.add_child(previous)
	var chip: PanelContainer = UiKit.card("Chip")
	var chip_row: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_child(chip_row)
	_floor_icon = UiKit.icon(&"tower", UiTokens.ICON_SM, UiTokens.ACCENT)
	chip_row.add_child(_floor_icon)
	_floor_name = UiKit.label("", &"HeadingLabel")
	_floor_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_row.add_child(_floor_name)
	_floor_size = UiKit.label("", &"MutedLabel")
	_floor_size.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_row.add_child(_floor_size)
	floors.add_child(chip)
	var next: FxButton = UiKit.icon_button(&"chevron_right", 76.0)
	next.pressed.connect(_change_floor.bind(1))
	floors.add_child(next)

	_view = FarmView.new()
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.custom_minimum_size = Vector2(0.0, 560.0)
	column.add_child(_view)
	_view.setup(session.farm, session.catalog.ruleset)
	_view.setup_drones(session.drones)
	_view.pot_tapped.connect(_on_pot_tapped)
	_view.swipe_started.connect(session.begin_swipe)
	_view.harvest_requested.connect(_on_harvest_requested)
	_view.swipe_ended.connect(session.end_swipe)

	_lock_card = UiKit.card("CardRaised")
	_lock_card.set_anchors_preset(Control.PRESET_CENTER)
	_lock_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_lock_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	var lock_box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_2)
	_lock_card.add_child(lock_box)
	var lock_icon: TextureRect = UiKit.icon(&"lock", UiTokens.ICON_LG, UiTokens.TEXT_MUTED)
	lock_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lock_box.add_child(lock_icon)
	lock_box.add_child(UiKit.label(tr("FARM_LOCKED"), &"SmallLabel", true, HORIZONTAL_ALIGNMENT_CENTER))
	var go: FxButton = UiKit.button(tr("FARM_GO_UPGRADES"), &"PrimaryButton", UiTokens.TOUCH_MIN, &"upgrades")
	go.pressed.connect(func() -> void: tab_requested.emit(4))
	lock_box.add_child(go)
	_view.add_child(_lock_card)

	_hint = FloraBubble.new()
	column.add_child(_hint)

	var actions: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	column.add_child(actions)
	_water_button = UiKit.button(tr("FARM_WATER_ALL"), &"", 80.0, &"water")
	_water_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_water_button.pressed.connect(_on_water_all)
	actions.add_child(_water_button)
	_plant_button = UiKit.button(tr("FARM_PLANT_ALL"), &"PrimaryButton", 80.0, &"seed")
	_plant_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plant_button.pressed.connect(_on_plant_all)
	actions.add_child(_plant_button)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 226.0)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(scroll)
	_seed_row = UiKit.hbox(UiTokens.SPACE_1)
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
	_view.colorblind = session.settings.colorblind
	_rebuild_seeds()
	_update_hint()


func on_shown() -> void:
	refresh()
	var cards: Array[Control] = []
	for card: Node in _seed_row.get_children():
		if card is Control:
			cards.append(card as Control)
	UiMotion.stagger_in(cards, 0.05)


# ------------------------------------------------------------------ katlar


func _change_floor(step: int) -> void:
	var count: int = session.catalog.floors.size()
	_show_floor((_floor_index + step + count) % count, step)


## Günün karanlık oranı (Main her yarım saniyede verir): çiftlik görünümüne hafif ton.
func set_time_of_day(phase: float) -> void:
	if _view != null:
		_view.set_night(NightBackdrop.night_factor(phase))


func _show_floor(index: int, direction: int = 0) -> void:
	_floor_index = index
	_view.show_floor(index, direction)
	var def: FloorDef = session.catalog.floors[index]
	var unlocked: bool = session.farm.get_floor(index).unlocked
	_floor_name.text = tr(def.display_name)
	_floor_size.text = "%d×%d" % [def.cols, def.rows]
	_floor_icon.texture = UiIcons.get_icon(&"tower" if unlocked else &"lock")
	_floor_icon.modulate = UiTokens.ACCENT if unlocked else UiTokens.TEXT_DIM
	_lock_card.visible = not unlocked
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
		var card: SeedCard = SeedCard.new()
		card.button_group = _seed_group
		card.setup(item.gene, item.count, session.catalog.ruleset, not session.settings.reduce_motion)
		card.set_pressed_no_signal(item.gene.uid == _selected_uid)
		card.pressed.connect(func() -> void: _selected_uid = item.gene.uid)
		_seed_row.add_child(card)
	if items.is_empty():
		_seed_row.add_child(UiKit.label(tr("FARM_NO_SEEDS"), &"MutedLabel", true))


# -------------------------------------------------------------------- ipucu


## FLORA: ilk satışa kadar durumun bir sonraki adımı; sonra yalnızca kısa bağlamsal ipuçları.
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
	_hint.say(tr(key) if key != "" else "")
