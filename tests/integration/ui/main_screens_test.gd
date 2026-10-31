extends TestCase
## Ana arayüz (Main): gerçek sahne, gerçek katalog, gerçek panel düğmeleri. Dokunuşlar fare olaylarıyla, düğmeler `pressed`
## sinyaliyle verilir; sonuç oyun durumundan (GameSession) okunur. Her ekranın temel akışı + ayarlar, dil değişimi, rozetler,
## bildirim birleştirme, geri tuşu ve uzun ekran.

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
	_main.language_override = "tr"
	_main.show_intro_card = false
	# Sabit boyutlu sınama için çapaları sol üste al (zıt çapalı denetimde `size` atamak uyarı verir)
	_main.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_to_tree(_main)
	_main.size = Vector2(1080.0, 1920.0)
	_session = _main.session
	_session.simulate_enabled = false  # zaman yalnızca testin çağırdığı tick() ile ilerler


func after_each() -> void:
	SaveManager.new(SAVE_PATH).delete_save()
	TranslationServer.set_locale("tr")  # dil testleri İngilizceye geçmiş olabilir
	UiMotion.reduce_motion = false


## Düğmenin gösterilen yazısı: kendi metni, fiyatlı düğmenin başlığı ya da (sekme düğmesinde) içindeki etiket.
func _caption_of(button: Button) -> String:
	if button.text != "":
		return button.text
	if button is PriceButton:
		return (button as PriceButton).caption()
	for node: Node in button.find_children("*", "Label", true, false):
		return (node as Label).text
	return ""


## Alt ağaçta yazısı `prefix` ile başlayan (görünür) ilk düğme.
func _button(prefix: String, root: Node = null) -> Button:
	var base: Node = root if root != null else _main
	for node: Node in base.find_children("*", "Button", true, false):
		var button: Button = node as Button
		if _caption_of(button).begins_with(prefix) and button.is_visible_in_tree():
			return button
	return null


## Alt ağaçta verilen ikonlu (metinsiz) ilk görünür düğme.
func _icon_button(icon_name: StringName, root: Node = null) -> Button:
	var base: Node = root if root != null else _main
	var wanted: Texture2D = UiIcons.get_icon(icon_name)
	for node: Node in base.find_children("*", "Button", true, false):
		var button: Button = node as Button
		if button.icon == wanted and button.is_visible_in_tree():
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
	assert_eq(_main.nav_bar().tab_count(), 5)
	assert_not_null(_button(tr("TAB_LAB")), "sekme düğmeleri var")
	assert_not_null(_button(tr("TAB_UPGRADES")))
	assert_eq(_main.nav_bar().selected(), 0)


func test_tab_buttons_switch_the_visible_panel() -> void:
	await _frames()

	_button(tr("TAB_MARKET")).pressed.emit()
	assert_true(_main.panel(2).visible)
	assert_false(_main.panel(0).visible)
	assert_eq(_main.nav_bar().selected(), 2, "gezinme çubuğu seçimi izler")

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

	_icon_button(&"chevron_right").pressed.emit()  # kat 1: kilitli

	assert_true(_button(tr("FARM_PLANT_ALL")).disabled, "kilitli katta toplu ekim pasif")
	assert_not_null(_button(tr("FARM_GO_UPGRADES")), "kilit kartında Geliştir'e git düğmesi görünür")
	_icon_button(&"chevron_left").pressed.emit()
	assert_false(_button(tr("FARM_PLANT_ALL")).disabled, "zemin kat açık")


func test_the_locked_floor_shortcut_opens_the_upgrades_tab() -> void:
	await _frames()
	_icon_button(&"chevron_right").pressed.emit()

	_button(tr("FARM_GO_UPGRADES")).pressed.emit()

	assert_true(_main.panel(4).visible, "kısayol Geliştir sekmesini açtı")
	assert_eq(_main.nav_bar().selected(), 4)


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

	_button(tr("MARKET_SELL_ALL")).pressed.emit()

	assert_eq(_session.inventory.produce_count(), 0, "her şey satıldı")
	assert_true(_session.wallet.credits > credits, "para geldi")


func test_the_price_board_lists_every_fruit_with_a_chart() -> void:
	_main.open_tab(2)
	await _frames()

	var charts: Array[Node] = _main.panel(2).find_children("*", "PriceChart", true, false)

	var fruit_count: int = _session.catalog.ruleset.get_parts_for_layer(PlantPartDef.Layer.FRUIT).size()
	assert_eq(charts.size(), fruit_count, "her meyve için bir mini grafik")


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

	var cross: Button = _button(tr("LAB_CROSS"))
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

	assert_true(_button(tr("LAB_CROSS")).disabled)


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
	_icon_button(&"menu").pressed.emit()
	var overlay: SettingsOverlay = _main.settings_overlay()
	assert_true(overlay.visible)

	overlay.toggle("sound").flip()
	assert_false(_session.settings.sound_on)

	overlay.size_control().button(3).pressed.emit()
	assert_eq(_main.theme.default_font_size, int(round(float(UiTheme.BASE_FONT_SIZE) * 1.4)), "yazı boyutu ölçeği temaya yansıdı")

	overlay.toggle("colorblind").flip()
	assert_true(_session.settings.colorblind)
	var accent: Color = _main.theme.get_color("font_color", "AccentLabel")
	assert_true(accent.is_equal_approx(UiTheme.palette(true)["accent"] as Color), "renk körlüğü paleti uygulandı")

	overlay.toggle("motion").flip()
	assert_true(_session.settings.reduce_motion)
	assert_true(_farm_view().reduce_motion, "hareketi azalt çiftlik görünümüne ulaştı")
	assert_true(UiMotion.reduce_motion, "hareket yardımcısına da ulaştı")


func test_switching_the_language_rebuilds_every_text_in_english_and_back() -> void:
	await _frames()
	_main.open_settings()

	_main.settings_overlay().language_control().button(1).pressed.emit()
	await _frames(3)

	assert_eq(_session.settings.language, "en")
	assert_eq(Localization.current(), "en")
	assert_eq(tr("TAB_FARM"), "Farm")
	assert_not_null(_button("Farm"), "gezinme çubuğu İngilizce")
	assert_not_null(_button("Market"))
	assert_true(_main.settings_overlay().visible, "dil değişince ayarlar açık kalır")
	assert_eq(_main.nav_bar().selected(), 0, "etkin sekme korunur")

	_main.settings_overlay().language_control().button(0).pressed.emit()
	await _frames(3)
	assert_eq(_session.settings.language, "tr")
	assert_not_null(_button("Çiftlik"), "Türkçeye geri döndü")


func test_the_reset_button_needs_a_second_confirming_press() -> void:
	_session.wallet.add_credits(999)
	var credits: int = _session.wallet.credits
	_main.open_settings()
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
	_main.open_settings()

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

	UiKit.report(_session.plant_seed(0, 0, "yok"))

	assert_true(_main.toasts().visible_texts().has(tr("ERR_SEED_MISSING")), "hata bildirimi göründü: %s" % str(_main.toasts().visible_texts()))


func test_the_same_toast_repeated_merges_into_one_pill_with_a_counter() -> void:
	await _frames()

	for i: int in 3:
		SignalBus.toast_requested.emit("MSG_SAVED", [])

	var texts: Array[String] = _main.toasts().visible_texts()
	assert_eq(texts.size(), 1, "üç aynı bildirim tek hap")
	assert_eq(texts[0], "%s ×3" % tr("MSG_SAVED"))


func test_toast_arguments_are_formatted_for_the_active_language() -> void:
	await _frames()

	SignalBus.toast_requested.emit("ERR_NOT_ENOUGH_CREDITS", [12480])

	var texts: Array[String] = _main.toasts().visible_texts()
	assert_true(texts[0].contains("12.480"), "Türkçe binlik ayracı: %s" % texts[0])


func test_a_taller_screen_gives_the_farm_more_room_and_keeps_the_tab_bar_inside() -> void:
	await _frames()
	var normal_height: float = _farm_view().size.y

	_main.size = Vector2(1080.0, 2400.0)
	await _frames()

	assert_true(_farm_view().size.y > normal_height + 300.0, "uzun ekranda çiftlik büyür")
	assert_true(_main.nav_bar().get_global_rect().end.y <= 2401.0, "gezinme çubuğu ekranın içinde")


func test_the_largest_text_size_keeps_every_tab_button_inside_the_screen_width() -> void:
	_session.settings.set_text_scale_index(3)  # en büyük yazı
	await _frames()

	var nav: NavBar = _main.nav_bar()
	var last_tab: Button = nav.tab(4)
	assert_true(last_tab.get_global_rect().end.x <= 1080.0, "son sekme düğmesi sağ kenarı aşmıyor (%f)" % last_tab.get_global_rect().end.x)
	assert_true(nav.tab(0).get_global_rect().position.x >= 0.0, "ilk sekme düğmesi sol kenarı aşmıyor")
	_main.open_tab(2)
	await _frames()
	assert_true(_main.panel(2).get_global_rect().end.x <= 1080.0, "pazar paneli ekran genişliğini aşmıyor")
	assert_true(nav.tab(2).get_global_rect().end.x <= 1080.0)


# ------------------------------------------------------------------- rozetler


func test_the_market_tab_gets_a_badge_when_an_order_can_be_delivered() -> void:
	_session.tick(0.5)
	var order: Order = _session.orders.orders[0]
	await _frames()
	assert_false(_main.nav_bar().badge_visible(2), "ürün yokken rozet yok")

	var gene: PlantGene = PlantGene.homozygous(&"stem_reed", &"leaf_oval", order.fruit_id, 0.3)
	gene.uid = "badge-goods"
	var result: HarvestResult = HarvestResult.new()
	result.gene = gene
	result.phenotype = GeneticsEngine.express(gene, _session.catalog.ruleset)
	result.quantity = order.quantity
	result.unit_value = 50.0
	_session.inventory.add_produce(result)
	await _frames()

	assert_true(_main.nav_bar().badge_visible(2), "teslim edilebilir sipariş var")
	_main.open_tab(2)
	assert_false(_main.nav_bar().badge_visible(2), "sekme açılınca rozet söner")


func test_the_upgrades_badge_lights_when_something_becomes_affordable_and_clears_when_opened() -> void:
	await _frames()
	assert_false(_main.nav_bar().badge_visible(4), "başlangıç parasıyla hiçbir şey alınamaz")

	_session.wallet.add_credits(1000)
	await _frames()
	assert_true(_main.nav_bar().badge_visible(4), "yeni bir şey alınabilir")

	_main.open_tab(4)
	assert_false(_main.nav_bar().badge_visible(4), "sekme açılınca söner")


func test_the_farm_badge_shows_ripe_plants_while_another_tab_is_open() -> void:
	_session.plant_seed(0, 0, "starter_reed_berry")
	_main.open_tab(2)
	await _frames()
	assert_false(_main.nav_bar().badge_visible(0))

	_session.farm.get_pot(0, 0).growth = 1.0
	SignalBus.plant_matured.emit(0, 0)
	await _frames()

	assert_true(_main.nav_bar().badge_visible(0), "olgun bitki bekliyor")
	_main.open_tab(0)
	assert_false(_main.nav_bar().badge_visible(0), "çiftliğe dönünce söner")


# --------------------------------------------------------- hedefler ve açılış kartı


func test_the_hud_goal_chip_shows_the_current_goal_and_opens_the_goals_sheet() -> void:
	await _frames()
	var current: GoalDef = _session.goals.current()

	var chip: Button = _button(GoalText.title(current))
	assert_not_null(chip, "HUD'da etkin hedef çipi var")
	chip.pressed.emit()

	assert_true(_main.goals_overlay().visible, "çipe basınca hedefler sayfası açıldı")
	_main._on_back_pressed()
	assert_false(_main.goals_overlay().visible, "geri tuşu sayfayı kapatır")


func test_completing_a_goal_updates_the_chip_and_shows_a_toast() -> void:
	await _frames()
	var first: GoalDef = _session.goals.current()
	var second: GoalDef = _session.goals.defs[1]

	_session.goals.note(first.kind, first.target)
	await _frames()

	assert_not_null(_button(GoalText.title(second)), "çip sıradaki hedefe geçti")
	var shown: String = "\n".join(_main.toasts().visible_texts())
	assert_true(shown.contains(GoalText.title(first)), "tamamlanan hedef bildirimi: %s" % shown)


func test_the_goals_sheet_lists_every_goal_with_the_current_one_highlighted() -> void:
	await _frames()
	_main.open_goals()

	var cards: int = _main.goals_overlay().find_children("*", "PanelContainer", true, false).size()

	assert_true(cards > _session.goals.defs.size(), "her hedef için bir kart (+ özet): %d" % cards)
	var labels: Array[String] = []
	for node: Node in _main.goals_overlay().find_children("*", "Label", true, false):
		labels.append((node as Label).text)
	assert_true(labels.has(GoalText.title(_session.goals.defs[0])))
	assert_true(labels.has(GoalText.title(_session.goals.defs[_session.goals.defs.size() - 1])))


func test_the_intro_card_shows_once_and_closing_it_marks_it_seen() -> void:
	var fresh: Main = (load(MAIN_SCENE) as PackedScene).instantiate() as Main
	fresh.production_mode = false
	fresh.save_path = SAVE_PATH
	fresh.language_override = "tr"
	fresh.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_to_tree(fresh)
	fresh.size = Vector2(1080.0, 1920.0)
	await _frames()

	assert_true(fresh.intro_overlay().visible, "ilk açılışta kart görünür")
	assert_false(fresh.session.settings.intro_seen)

	fresh._on_back_pressed()  # geri tuşu kartı kapatır

	assert_false(fresh.intro_overlay().visible)
	assert_true(fresh.session.settings.intro_seen, "kapanınca görüldü sayıldı")
