class_name UpgradesPanel
extends GamePanel
## Geliştir sekmesi: laboratuvar UV odası, kat açma ve her açık katta satır başına sulama/UV, kat başına dron satın alma.
## Fiyatları ve seviyeleri `AutomationService`'ten okur; satın alma `GameSession` komutlarıdır. Alınabilir olan düğmeler klorofil
## çerçeveli, yetmeyenler soluktur; biten donanım düğme yerine "tamam" rozetidir (bir ekranda tek bağırıp duran birincil düğme yok).
##
## Uygular: design/game-brief.md, FAZ 4 (otomatik sulama/ışıklandırma matrisi, hasat dronları, yeni gökdelen katları);
## design/design-language.md, "Hiyerarşi".

var _column: VBoxContainer


func _build() -> void:
	var scroll: ScrollContainer = UiKit.scroll()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	_column = UiKit.vbox(UiTokens.SPACE_2)
	scroll.add_child(_column)
	SignalBus.credits_changed.connect(_on_state_changed)
	SignalBus.equipment_purchased.connect(_on_purchase)
	SignalBus.floor_unlocked.connect(_on_floor)
	SignalBus.game_reloaded.connect(refresh)


func refresh() -> void:
	if _column == null:
		return
	UiKit.clear(_column)
	_column.add_child(UiKit.label(tr("UPG_TITLE"), &"TitleLabel"))
	_column.add_child(_make_lab_card())
	for def: FloorDef in session.catalog.floors:
		_column.add_child(_make_floor_card(def))


func on_shown() -> void:
	refresh()
	var cards: Array[Control] = []
	for card: Node in _column.get_children():
		if card is PanelContainer:
			cards.append(card as Control)
	UiMotion.stagger_in(cards, 0.06)


func _on_state_changed(_credits: int) -> void:
	if is_visible_in_tree():
		refresh()


func _on_purchase(_kind: EquipmentDef.Kind, _floor_index: int, _target: int, _level: int) -> void:
	refresh()


func _on_floor(_floor_index: int) -> void:
	refresh()


func _make_lab_card() -> Control:
	var card: PanelContainer = UiKit.card("CardUv")
	var box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	card.add_child(box)
	var def: EquipmentDef = session.automation.equipment_for(EquipmentDef.Kind.LAB_UV)
	var head: HBoxContainer = UiKit.hbox(UiTokens.SPACE_2)
	head.add_child(UiKit.icon(&"uv", UiTokens.ICON_LG, UiTokens.UV))
	var texts: VBoxContainer = UiKit.vbox(2)
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.add_child(UiKit.label(tr(def.display_name), &"HeadingLabel", true))
	texts.add_child(UiKit.label(tr(def.description), &"MutedLabel", true))
	head.add_child(texts)
	box.add_child(head)
	var level: int = session.automation.lab_uv_level
	var status: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	var pips: LevelPips = LevelPips.new()
	pips.set_levels(level, def.max_level, UiTokens.UV)
	status.add_child(pips)
	status.add_child(UiKit.label(tr("UPG_LAB_BONUS") % UiFormat.percent(session.automation.lab_mutation_bonus()), &"SmallLabel"))
	box.add_child(status)
	box.add_child(_buy_button(session.automation.next_cost(EquipmentDef.Kind.LAB_UV), tr("UPG_UPGRADE"), &"upgrades", func() -> void: UiKit.report(session.buy_lab_uv())))
	return card


func _make_floor_card(def: FloorDef) -> Control:
	var floor_state: FloorState = session.farm.get_floor(def.index)
	var card: PanelContainer = UiKit.card("Card")
	var box: VBoxContainer = UiKit.vbox(UiTokens.SPACE_1)
	card.add_child(box)
	var head: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	head.add_child(UiKit.icon(&"tower" if floor_state.unlocked else &"lock", UiTokens.ICON_MD, UiTokens.ACCENT if floor_state.unlocked else UiTokens.TEXT_DIM))
	var name_label: Label = UiKit.label(tr(def.display_name), &"HeadingLabel")
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	head.add_child(UiKit.chip("%d×%d" % [def.cols, def.rows], &"", &"Chip"))
	box.add_child(head)
	if not floor_state.unlocked:
		var previous_open: bool = def.index == 0 or session.farm.get_floor(def.index - 1).unlocked
		box.add_child(UiKit.label(tr("UPG_FLOOR_LOCKED") if previous_open else tr("UPG_FLOOR_NEED_PREVIOUS"), &"MutedLabel", true))
		var unlock: PriceButton = _buy_button(def.unlock_cost, tr("UPG_UNLOCK"), &"lock", func() -> void: UiKit.report(session.unlock_floor(def.index)))
		if not previous_open:
			unlock.set_enabled(false)
		elif session.wallet.can_afford(def.unlock_cost):
			unlock.theme_type_variation = &"PrimaryButton"
		box.add_child(unlock)
		return card
	for row: int in floor_state.rows:
		box.add_child(_make_row(def.index, row, floor_state))
	var drone_def: EquipmentDef = session.automation.equipment_for(EquipmentDef.Kind.DRONE)
	var drone_line: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	var drone_pips: LevelPips = LevelPips.new()
	drone_pips.set_levels(floor_state.drones, drone_def.max_level, UiTokens.ACCENT)
	drone_line.add_child(drone_pips)
	drone_line.add_child(_buy_or_done(session.automation.next_cost(EquipmentDef.Kind.DRONE, def.index), tr("UPG_DRONE") % [floor_state.drones, drone_def.max_level], &"drone", func() -> void: UiKit.report(session.buy_drone(def.index))))
	box.add_child(drone_line)
	return card


## Bir satırın sulama ve UV düğmeleri (bitenler "tamam" rozeti).
func _make_row(floor_index: int, row: int, floor_state: FloorState) -> Control:
	var line: HBoxContainer = UiKit.hbox(UiTokens.SPACE_1)
	var title: Label = UiKit.label(tr("UPG_ROW") % (row + 1), &"OverlineLabel")
	title.custom_minimum_size.x = 96.0
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(title)
	var irrigation_cost: int = session.automation.next_cost(EquipmentDef.Kind.IRRIGATION, floor_index, row)
	line.add_child(_buy_or_done(irrigation_cost, tr("UPG_IRRIGATION"), &"water", func() -> void: UiKit.report(session.buy_irrigation(floor_index, row))))
	var uv_def: EquipmentDef = session.automation.equipment_for(EquipmentDef.Kind.UV_LAMP)
	var uv_cost: int = session.automation.next_cost(EquipmentDef.Kind.UV_LAMP, floor_index, row)
	var uv_text: String = tr("UPG_UV") % [floor_state.uv_rows[row], uv_def.max_level]
	line.add_child(_buy_or_done(uv_cost, uv_text, &"uv", func() -> void: UiKit.report(session.buy_uv_lamp(floor_index, row))))
	return line


## Maliyet < 0 = sınıra gelindi: düğme yerine "tamam" rozeti; aksi halde fiyatlı düğme.
func _buy_or_done(cost: int, text: String, icon_name: StringName, action: Callable) -> Control:
	if cost < 0:
		var done: PanelContainer = UiKit.chip(text, &"check", &"ChipAccent", UiTokens.ACCENT)
		done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return done
	var button: PriceButton = _buy_button(cost, text, icon_name, action)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


## Fiyatlı satın alma düğmesi: kredi yetiyorsa klorofil çerçeveli, yetmiyorsa soluk ve pasif.
func _buy_button(cost: int, text: String, icon_name: StringName, action: Callable) -> PriceButton:
	var affordable: bool = cost >= 0 and session.wallet.can_afford(cost)
	var button: PriceButton = PriceButton.new()
	button.setup(text, cost, &"BuyButton" if affordable else &"", icon_name, 76.0)
	button.set_enabled(affordable)
	button.pressed.connect(action)
	return button
