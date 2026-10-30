class_name UpgradesPanel
extends GamePanel
## Geliştir sekmesi: laboratuvar UV odası, kat açma ve her açık katta satır başına sulama/UV, kat başına dron satın alma.
## Fiyatları ve seviyeleri `AutomationService`'ten okur; satın alma `GameSession` komutlarıdır. Yetmeyen krediyle düğme pasif kalır.
##
## Uygular: design/game-brief.md, FAZ 4 (otomatik sulama/ışıklandırma matrisi, hasat dronları, yeni gökdelen katları).

var _column: VBoxContainer


func _build() -> void:
	var scroll: ScrollContainer = UiKit.scroll()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	_column = UiKit.vbox(14)
	scroll.add_child(_column)
	SignalBus.credits_changed.connect(_on_state_changed)
	SignalBus.equipment_purchased.connect(_on_purchase)
	SignalBus.floor_unlocked.connect(_on_floor)
	SignalBus.game_reloaded.connect(refresh)


func refresh() -> void:
	if _column == null:
		return
	UiKit.clear(_column)
	_column.add_child(UiKit.label(tr("UPG_TITLE"), &"HeadingLabel"))
	_column.add_child(_make_lab_card())
	for def: FloorDef in session.catalog.floors:
		_column.add_child(_make_floor_card(def))


func _on_state_changed(_credits: int) -> void:
	if is_visible_in_tree():
		refresh()


func _on_purchase(_kind: EquipmentDef.Kind, _floor_index: int, _target: int, _level: int) -> void:
	refresh()


func _on_floor(_floor_index: int) -> void:
	refresh()


func _make_lab_card() -> Control:
	var card: PanelContainer = UiKit.card()
	var box: VBoxContainer = UiKit.vbox(8)
	card.add_child(box)
	var def: EquipmentDef = session.automation.equipment_for(EquipmentDef.Kind.LAB_UV)
	box.add_child(UiKit.label(def.display_name, &"AccentLabel", true))
	box.add_child(UiKit.label(def.description, &"MutedLabel", true))
	var level: int = session.automation.lab_uv_level
	box.add_child(UiKit.label(tr("UPG_LAB_STATUS") % [level, def.max_level, session.automation.lab_mutation_bonus() * 100.0], &"SmallLabel"))
	box.add_child(_buy_button(session.automation.next_cost(EquipmentDef.Kind.LAB_UV), tr("UPG_UPGRADE"), func() -> void: UiKit.report(session.buy_lab_uv())))
	return card


func _make_floor_card(def: FloorDef) -> Control:
	var card: PanelContainer = UiKit.card()
	var box: VBoxContainer = UiKit.vbox(10)
	card.add_child(box)
	var floor_state: FloorState = session.farm.get_floor(def.index)
	box.add_child(UiKit.label("%s  (%d×%d)" % [def.display_name, def.cols, def.rows], &"AccentLabel"))
	if not floor_state.unlocked:
		var previous_open: bool = def.index == 0 or session.farm.get_floor(def.index - 1).unlocked
		box.add_child(UiKit.label(tr("UPG_FLOOR_LOCKED") if previous_open else tr("UPG_FLOOR_NEED_PREVIOUS"), &"MutedLabel", true))
		var unlock: Button = _buy_button(def.unlock_cost, tr("UPG_UNLOCK"), func() -> void: UiKit.report(session.unlock_floor(def.index)))
		unlock.disabled = unlock.disabled or not previous_open
		box.add_child(unlock)
		return card
	for row: int in floor_state.rows:
		box.add_child(_make_row(def.index, row, floor_state))
	var drone_def: EquipmentDef = session.automation.equipment_for(EquipmentDef.Kind.DRONE)
	var drone_cost: int = session.automation.next_cost(EquipmentDef.Kind.DRONE, def.index)
	var drone_text: String = tr("UPG_DRONE") % [floor_state.drones, drone_def.max_level]
	box.add_child(_buy_button(drone_cost, drone_text, func() -> void: UiKit.report(session.buy_drone(def.index))))
	return card


## Bir satırın sulama ve UV düğmeleri.
func _make_row(floor_index: int, row: int, floor_state: FloorState) -> Control:
	var line: HBoxContainer = UiKit.hbox(10)
	var title: Label = UiKit.label(tr("UPG_ROW") % (row + 1), &"SmallLabel")
	title.custom_minimum_size.x = 120.0
	line.add_child(title)
	var irrigation_cost: int = session.automation.next_cost(EquipmentDef.Kind.IRRIGATION, floor_index, row)
	var irrigation: Button = _buy_button(irrigation_cost, tr("UPG_IRRIGATION") + (" ✓" if floor_state.irrigation_rows[row] else ""), func() -> void: UiKit.report(session.buy_irrigation(floor_index, row)))
	line.add_child(irrigation)
	var uv_def: EquipmentDef = session.automation.equipment_for(EquipmentDef.Kind.UV_LAMP)
	var uv_cost: int = session.automation.next_cost(EquipmentDef.Kind.UV_LAMP, floor_index, row)
	var uv_text: String = tr("UPG_UV") % [floor_state.uv_rows[row], uv_def.max_level]
	line.add_child(_buy_button(uv_cost, uv_text, func() -> void: UiKit.report(session.buy_uv_lamp(floor_index, row))))
	return line


## Fiyatlı satın alma düğmesi: maliyet < 0 = sınıra gelindi (pasif, "MAX"); kredi yetmiyorsa pasif.
func _buy_button(cost: int, text: String, action: Callable) -> Button:
	var maxed: bool = cost < 0
	var caption: String = text + (" · MAX" if maxed else "  ◆%d" % cost)
	var button: Button = UiKit.button(caption, &"" if maxed else &"PrimaryButton", 76.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = maxed or not session.wallet.can_afford(cost)
	button.pressed.connect(action)
	return button
