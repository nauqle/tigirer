extends TestCase
## Ana arayüz (Main): gerçek sahne, gerçek katalog, gerçek panel düğmeleri. Dokunuşlar fare olaylarıyla, düğmeler `pressed`
## sinyaliyle verilir; sonuç oyun durumundan (GameSession) okunur. Her ekranın temel akışı + ayarlar, geri tuşu ve uzun ekran.

const SAVE_PATH: String = "user://test_main_ui.dat"
const MAIN_SCENE: String = "res://src/ui/main.tscn"

var _main: Main
var _session: GameSession


func before_each() -> void:
	SaveManager.new(SAVE_PATH).delete_save()
	_main = (load(MAIN_SCENE) as PackedScene).instantiate() as Main
	_main.production_mode = false
	_main.save_path = SAVE_PATH
	_main.rng_seed = 3
	# Sabit boyutlu sınama için çapaları sol üste al (zıt çapalı denetimde `size` atamak uyarı verir)
	_main.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_to_tree(_main)
	_main.size = Vector2(1080.0, 1920.0)
	_session = _main.session
	_session.simulate_enabled = false  # zaman yalnızca testin çağırdığı tick() ile ilerler


func after_each() -> void:
	SaveManager.new(SAVE_PATH).delete_save()


## Alt ağaçta metni `prefix` ile başlayan (görünür) ilk düğme.
func _button(prefix: String, root: Node = null) -> Button:
	var base: Node = root if root != null else _main
	for node: Node in base.find_children("*", "Button", true, false):
		var button: Button = node as Button
		if button.text.begins_with(prefix) and button.is_visible_in_tree():
			return button
	return null


func _farm_view() -> FarmView:
	return _main.find_children("*", "FarmView", true, false)[0] as FarmView


func _frames(count: int = 2) -> void:
	for i: int in count:
		await tree.process_frame


func _press_at(view: Control, position_: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = position_
	view._gui_input(event)


func _release_at(view: Control, position_: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = position_
	view._gui_input(event)


func _move_to(view: Control, position_: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = position_
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	view._gui_input(event)


# ------------------------------------------------------------------ yapı


func test_the_app_starts_on_the_farm_tab_with_five_tabs_and_a_fresh_game() -> void:
	await _frames()

	assert_true(_main.panel(0).visible, "çiftlik açık")
	for i: int in range(1, 5):
		assert_false(_main.panel(i).visible, "diğer sekmeler gizli: %d" % i)
	assert_eq(_session.wallet.credits, _session.catalog.economy_config.starting_credits)
	assert_not_null(_button(tr("TAB_LAB")), "sekme düğmeleri var")
	assert_not_null(_button(tr("TAB_UPGRADES")))


func test_tab_buttons_switch_the_visible_panel() -> void:
	await _frames()

	_button(tr("TAB_MARKET")).pressed.emit()
	assert_true(_main.panel(2).visible)
	assert_false(_main.panel(0).visible)

	_button(tr("TAB_DEX")).pressed.emit()
	assert_true(_main.panel(3).visible)
	assert_false(_main.panel(2).visible)


# ------------------------------------------------------------------ çiftlik


func test_tapping_an_empty_pot_plants_the_selected_seed() -> void:
	await _frames()
	var view: FarmView = _farm_view()
	var seeds_before: int = _session.inventory.seed_total()
	var point: Vector2 = view.pot_local_position(1)

	_press_at(view, point)
	_release_at(view, point)

	assert_false(_session.farm.get_pot(0, 1).is_empty(), "saksı doldu")
	assert_eq(_session.inventory.seed_total(), seeds_before - 1, "bir tohum harcandı")


func test_tapping_a_thirsty_growing_plant_waters_it_and_a_mature_one_harvests_it() -> void:
	await _frames()
	var view: FarmView = _farm_view()
	_session.plant_seed(0, 0, "starter_reed_berry")
	_session.plant_seed(0, 1, "starter_reed_berry")
	_session.farm.get_pot(0, 0).water = 0.05
	_session.farm.get_pot(0, 1).growth = 1.0

	_press_at(view, view.pot_local_position(0))
	_release_at(view, view.pot_local_position(0))
	_press_at(view, view.pot_local_position(1))
	_release_at(view, view.pot_local_position(1))

	assert_almost_eq(_session.farm.get_pot(0, 0).water, 1.0, 0.001, "susuz bitki sulandı")
	assert_true(_session.farm.get_pot(0, 1).is_empty(), "olgun bitki biçildi")
	assert_true(_session.inventory.produce_count() > 0)


func test_a_swipe_through_the_farm_harvests_mature_plants_with_a_combo() -> void:
	await _frames()
	var view: FarmView = _farm_view()
	for pot_index: int in 3:
		_session.plant_seed(0, pot_index, "starter_reed_berry")
		_session.farm.get_pot(0, pot_index).growth = 1.0
	var left: Vector2 = view.pot_local_position(0) + Vector2(-110.0, -60.0)
	var right: Vector2 = view.pot_local_position(2) + Vector2(110.0, -60.0)

	_press_at(view, left)
	_move_to(view, left.lerp(right, 0.5))
	_move_to(view, right)
	_release_at(view, right)

	for pot_index: int in 3:
		assert_true(_session.farm.get_pot(0, pot_index).is_empty(), "saksı %d biçildi" % pot_index)
	assert_eq(_session.inventory.produce_count(), 3 * _session.catalog.farm_config.base_yield_units)


func test_the_water_all_and_plant_all_buttons_work() -> void:
	await _frames()
	_session.plant_seed(0, 0, "starter_reed_berry")
	_session.farm.get_pot(0, 0).water = 0.1

	_button(tr("FARM_WATER_ALL")).pressed.emit()
	assert_almost_eq(_session.farm.get_pot(0, 0).water, 1.0, 0.001)

	_button(tr("FARM_PLANT_ALL")).pressed.emit()
	assert_eq(_session.farm.empty_pot_indices(0).size(), 6 - 1 - 3, "seçili tohumdan 3 tane daha dikildi (6 saksı, 1 dolu)")


func test_the_floor_arrows_cycle_through_floors_and_show_the_lock_notice() -> void:
	await _frames()

	_button("▶").pressed.emit()  # kat 1: kilitli

	assert_true(_button(tr("FARM_PLANT_ALL")).disabled, "kilitli katta toplu ekim pasif")
	_button("◀").pressed.emit()
	assert_false(_button(tr("FARM_PLANT_ALL")).disabled, "zemin kat açık")


# ------------------------------------------------------------------- pazar


func test_the_market_panel_sells_the_stock_and_pays_credits() -> void:
	await _frames()
	_session.plant_all(0, "starter_reed_berry")
	for pot_index: int in 3:
		_session.farm.get_pot(0, pot_index).growth = 1.0
		_session.harvest_pot(0, pot_index)
	_main.open_tab(2)
	await _frames()
	var credits: int = _session.wallet.credits

	_button(tr("MARKET_SELL_ALL").split("%")[0]).pressed.emit()

	assert_eq(_session.inventory.produce_count(), 0, "her şey satıldı")
	assert_true(_session.wallet.credits > credits, "para geldi")


func test_an_order_can_only_be_delivered_when_the_goods_are_there() -> void:
	_session.tick(0.5)  # ilk sipariş
	_main.open_tab(2)
	await _frames()
	var order: Order = _session.orders.orders[0]
	var deliver: Button = _button(tr("ORDER_DELIVER"))
	assert_not_null(deliver)
	assert_true(deliver.disabled, "ürün yokken pasif")

	var gene: PlantGene = PlantGene.homozygous(&"stem_reed", &"leaf_oval", order.fruit_id, 0.3)
	gene.uid = "order-goods"
	var result: HarvestResult = HarvestResult.new()
	result.gene = gene
	result.phenotype = GeneticsEngine.express(gene, _session.catalog.ruleset)
	result.quantity = order.quantity
	result.unit_value = 50.0
	_session.inventory.add_produce(result)
	await _frames()
	deliver = _button(tr("ORDER_DELIVER"))
	assert_false(deliver.disabled, "ürün varken açık")
	var credits: int = _session.wallet.credits

	deliver.pressed.emit()

	assert_eq(_session.wallet.credits, credits + order.reward)
	assert_eq(_session.wallet.reputation, 1)


# ---------------------------------------------------------------- laboratuvar


func test_the_lab_panel_crosses_the_selected_parents_and_shows_the_children() -> void:
	_main.open_tab(1)
	await _frames()
	var seeds: int = _session.inventory.seed_total()

	var cross: Button = _button("ÇAPRAZLA")
	assert_not_null(cross)
	assert_false(cross.disabled)
	cross.pressed.emit()
	await _frames()

	assert_eq(_session.inventory.seed_total(), seeds + _session.catalog.economy_config.offspring_per_cross)
	assert_not_null(_session.last_breed)
	assert_eq(_session.last_breed.children.size(), 2)


func test_the_cross_button_is_disabled_when_credits_run_out() -> void:
	_session.wallet.spend(_session.wallet.credits)
	_main.open_tab(1)
	await _frames()

	assert_true(_button("ÇAPRAZLA").disabled)


# ------------------------------------------------------------------- geliştir


func test_the_upgrades_panel_disables_what_the_credits_cannot_buy_and_buys_what_they_can() -> void:
	_main.open_tab(4)
	await _frames()
	var irrigation: Button = _button(tr("UPG_IRRIGATION"))
	assert_not_null(irrigation)
	assert_true(irrigation.disabled, "başlangıç parası 150'ye yetmez")

	_session.wallet.add_credits(1000)
	await _frames()
	irrigation = _button(tr("UPG_IRRIGATION"))
	assert_false(irrigation.disabled, "kredi gelince açıldı")
	irrigation.pressed.emit()

	assert_true(_session.farm.get_floor(0).irrigation_rows[0], "sulama kuruldu")


# ------------------------------------------------------------------ seed-dex


func _dex_stats_text() -> String:
	for node: Node in _main.panel(3).find_children("*", "Label", true, false):
		if (node as Label).text.contains("/ 120"):
			return (node as Label).text
	return ""


func test_the_dex_panel_counts_species_and_updates_on_a_discovery() -> void:
	_main.open_tab(3)
	await _frames()
	assert_true(_dex_stats_text().begins_with("4 / 120"), "başlangıç türleri: " + _dex_stats_text())

	_session.wallet.add_credits(500)
	_session.crossbreed("starter_reed_berry", "starter_vine_tulip")
	await _frames()

	assert_true(_dex_stats_text().begins_with("5 / 120"), "yeni tür eklendi: " + _dex_stats_text())


# -------------------------------------------------------------------- ayarlar


func test_the_settings_overlay_changes_settings_and_restyles_the_theme() -> void:
	await _frames()
	_button(tr("HUD_MENU")).pressed.emit()
	var overlay: SettingsOverlay = _main.settings_overlay()
	assert_true(overlay.visible)

	_button(tr("SET_SOUND_ON"), overlay).pressed.emit()
	assert_false(_session.settings.sound_on)
	assert_not_null(_button(tr("SET_SOUND_OFF"), overlay), "düğme metni değişti")

	_button(tr("SET_SIZE_3"), overlay).pressed.emit()
	assert_eq(_main.theme.default_font_size, int(round(float(UiTheme.BASE_FONT_SIZE) * 1.4)), "yazı boyutu ölçeği temaya yansıdı")

	_button(tr("SET_COLORBLIND_OFF"), overlay).pressed.emit()
	assert_true(_session.settings.colorblind)
	var accent: Color = _main.theme.get_color("font_color", "AccentLabel")
	assert_true(accent.is_equal_approx(UiTheme.palette(true)["accent"] as Color), "renk körlüğü paleti uygulandı")

	_button(tr("SET_MOTION_FULL"), overlay).pressed.emit()
	assert_true(_session.settings.reduce_motion)
	assert_true(_farm_view().reduce_motion, "hareketi azalt çiftlik görünümüne ulaştı")


func test_the_reset_button_needs_a_second_confirming_press() -> void:
	_session.wallet.add_credits(999)
	var credits: int = _session.wallet.credits
	_main.settings_overlay().visible = true
	var overlay: SettingsOverlay = _main.settings_overlay()

	_button(tr("SET_RESET"), overlay).pressed.emit()
	assert_eq(_session.wallet.credits, credits, "tek basış sıfırlamaz")

	_button(tr("SET_RESET_YES"), overlay).pressed.emit()
	assert_eq(_session.wallet.credits, _session.catalog.economy_config.starting_credits, "onaydan sonra sıfırlandı")
	assert_false(overlay.visible, "pencere kapandı")


func test_the_back_button_closes_windows_then_returns_to_the_farm_and_asks_twice_to_quit() -> void:
	var quits: Dictionary = {"n": 0}
	_main.quit_requested.connect(func() -> void: quits["n"] += 1)
	var overlay: SettingsOverlay = _main.settings_overlay()
	overlay.visible = true

	_main._on_back_pressed()
	assert_false(overlay.visible, "önce pencere kapanır")

	_main.open_tab(3)
	_main._on_back_pressed()
	assert_true(_main.panel(0).visible, "sonra çiftliğe döner")

	_main._on_back_pressed()
	assert_eq(quits["n"], 0, "ilk basış yalnızca uyarır")
	_main._on_back_pressed()
	assert_eq(quits["n"], 1, "ikinci basış çıkış ister")


# ----------------------------------------------------- çevrimdışı, bildirim, boyut


func test_the_offline_popup_summarizes_the_return_and_closes() -> void:
	_session.wallet.add_credits(5000)
	_session.buy_irrigation(0, 0)
	_session.buy_irrigation(0, 1)
	_session.buy_drone(0)
	_session.plant_all(0, "starter_reed_berry")
	_session.plant_all(0, "starter_vine_tulip")

	_session.apply_offline(3600.0)

	var popup: OfflinePopup = _main.find_children("*", "OfflinePopup", true, false)[0] as OfflinePopup
	assert_true(popup.visible, "rapor penceresi açıldı")
	_button(tr("BTN_OK"), popup).pressed.emit()
	assert_false(popup.visible)


func test_command_errors_appear_as_toasts() -> void:
	await _frames()
	var toasts: ToastLayer = _main.find_children("*", "ToastLayer", true, false)[0] as ToastLayer

	UiKit.report(_session.plant_seed(0, 0, "yok"))

	var texts: Array[String] = []
	for node: Node in toasts.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	assert_true(texts.has(tr("ERR_SEED_MISSING")), "hata bildirimi göründü: %s" % str(texts))


func test_a_taller_screen_gives_the_farm_more_room_and_keeps_the_tab_bar_inside() -> void:
	await _frames()
	var normal_height: float = _farm_view().size.y

	_main.size = Vector2(1080.0, 2400.0)
	await _frames()

	assert_true(_farm_view().size.y > normal_height + 300.0, "uzun ekranda çiftlik büyür")
	assert_true(_button(tr("TAB_FARM")).get_global_rect().end.y <= 2401.0, "sekme çubuğu ekranın içinde")


func test_the_largest_text_size_keeps_every_tab_button_inside_the_screen_width() -> void:
	_session.settings.set_text_scale_index(3)  # en büyük yazı
	await _frames()

	var last_tab: Button = _button(tr("TAB_UPGRADES"))
	assert_true(last_tab.get_global_rect().end.x <= 1080.0, "son sekme düğmesi sağ kenarı aşmıyor (%f)" % last_tab.get_global_rect().end.x)
	assert_true(_button(tr("TAB_FARM")).get_global_rect().position.x >= 0.0, "ilk sekme düğmesi sol kenarı aşmıyor")
	var market_tab: Button = _button(tr("TAB_MARKET"))
	_main.open_tab(2)
	await _frames()
	assert_true(_main.panel(2).get_global_rect().end.x <= 1080.0, "pazar paneli ekran genişliğini aşmıyor")
	assert_true(market_tab.get_global_rect().end.x <= 1080.0)
