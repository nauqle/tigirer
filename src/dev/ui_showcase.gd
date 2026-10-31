extends Node
## FAZ 5 geliştirici sahnesi: ana arayüzü (Main) belirli bir oyun durumunda açar. Ekran görüntüsü ve kanıt içindir;
## oyuncuya gösterilmez. Durum yalnızca oyun KOMUTLARIYLA hazırlanır (dron, sulama, çaprazlama ...), sonra bir sekme açılır.
##
## Uygular: design/game-brief.md, FAZ 5 (dikey mobil arayüz, Seed-Dex, çevrimdışı kazanç): "çalıştır ve gözle" kanıtı.
##
## Komut satırı (godot ... -- seçenekler): --scenario=farm|drones|day|tower|market|lab|dex|upgrades|settings|offline|fresh|goals|intro|toasts, --seed=N, --render-stats,
## --scale=0..3 (yazı boyutu), --lang=tr|en, --colorblind, --reduce-motion.
## Dev-only: kullanıcıya dönük metinler bilerek yerelleştirilmedi (src/ui kuralı bu klasörü kapsamaz).

const MAIN_SCENE: PackedScene = preload("res://src/ui/main.tscn")
const SAVE_PATH: String = "user://showcase_save.dat"
const REED: String = "starter_reed_berry"
const VINE: String = "starter_vine_tulip"
const BAMBOO: String = "starter_bamboo_pod"
const CARRIER: String = "starter_cyber_carrier"

var _main: Main


func _ready() -> void:
	var options: Dictionary = _read_options()
	SaveManager.new(SAVE_PATH).delete_save()
	_main = MAIN_SCENE.instantiate() as Main
	_main.production_mode = false
	_main.save_path = SAVE_PATH
	_main.rng_seed = int(options.get("seed", 5))
	_main.language_override = String(options.get("lang", "tr"))
	_main.show_intro_card = false
	add_child(_main)
	var settings: GameSettings = _main.session.settings
	settings.set_text_scale_index(int(options.get("scale", 1)))
	settings.set_colorblind(options.has("colorblind"))
	settings.set_reduce_motion(options.has("reduce-motion"))
	_prepare(String(options.get("scenario", "farm")))
	if options.has("render-stats"):
		_print_render_stats.call_deferred()


## --render-stats: 90 kare sonra çizim çağrısı, nesne, üçgen ve bellek sayılarını yazıp çıkar (bütçe belgesi için; cihaz ölçümü DEĞİLDİR).
func _print_render_stats() -> void:
	for i: int in 90:
		await get_tree().process_frame
	var info: Dictionary = {
		"draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		"primitives": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"texture_mb": snappedf(float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)) / 1048576.0, 0.1),
		"video_mb": snappedf(float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)) / 1048576.0, 0.1),
	}
	print("RENDER_STATS ", JSON.stringify(info))
	get_tree().quit()


func _prepare(scenario: String) -> void:
	var session: GameSession = _main.session
	session.wallet.add_credits(4000)
	match scenario:
		"intro":
			_main.intro_overlay().show_intro()
		"goals":
			session.goals.note(GoalDef.Kind.HARVEST, 3)
			session.goals.note(GoalDef.Kind.SELL_CREDITS, 25)
			_main.open_goals()
		"fresh":
			session.wallet.spend(session.wallet.credits - 120)
			_main.open_tab(0)
		"farm":
			session.buy_irrigation(0, 0)
			session.buy_irrigation(0, 1)
			session.buy_uv_lamp(0, 0)
			session.plant_all(0, REED)
			session.plant_all(0, VINE)
			var floor_state: FloorState = session.farm.get_floor(0)
			var growth: Array[float] = [1.0, 0.7, 0.35, 1.0, 0.15, 0.0]
			for i: int in growth.size():
				floor_state.pots[i].growth = growth[i]
			floor_state.pots[2].water = 0.1
			session.tick(0.2)
			_main.open_tab(0)
		"drones":
			session.buy_irrigation(0, 0)
			session.buy_irrigation(0, 1)
			session.buy_uv_lamp(0, 1)
			session.buy_drone(0)
			session.plant_all(0, REED)
			session.plant_all(0, VINE)
			var drone_floor: FloorState = session.farm.get_floor(0)
			for i: int in drone_floor.pots.size():
				drone_floor.pots[i].growth = 1.0 if i % 2 == 0 else 0.5
			session.tick(1.5)
			_main.open_tab(0)
		"tower":
			session.wallet.add_credits(40000)
			for floor_index: int in range(1, session.catalog.floors.size()):
				session.unlock_floor(floor_index)
			var top: int = session.catalog.floors.size() - 1
			for row: int in session.farm.get_floor(top).rows:
				session.buy_irrigation(top, row)
				session.buy_uv_lamp(top, row)
			session.buy_drone(top)
			session.plant_all(top, REED)
			session.plant_all(top, VINE)
			session.plant_all(top, BAMBOO)
			var tower_floor: FloorState = session.farm.get_floor(top)
			for i: int in tower_floor.pots.size():
				tower_floor.pots[i].growth = [1.0, 0.8, 0.55, 0.3, 1.0, 0.1, 0.65, 1.0, 0.4, 0.9, 0.2, 0.7, 1.0, 0.5, 0.0, 0.85][i % 16]
			(_main.panel(0) as FarmPanel).select_floor(top)
			session.tick(0.5)
			_main.open_tab(0)
		"day":
			session.buy_irrigation(0, 0)
			session.buy_uv_lamp(0, 0)
			session.plant_all(0, CARRIER)
			var day_floor: FloorState = session.farm.get_floor(0)
			var day_growth: Array[float] = [1.0, 0.8, 0.55, 0.3, 1.0, 0.0]
			for i: int in day_floor.pots.size():
				day_floor.pots[i].growth = day_growth[i]
			session.time.game_seconds = 0.5 * session.catalog.farm_config.day_length_seconds
			_main.open_tab(0)
		"market":
			_stock_produce(session)
			session.market.start_event(session.catalog.market_events[0])
			session.market.start_event(session.catalog.market_events[1])
			session.tick(0.5)
			_main.open_tab(2)
		"lab":
			session.crossbreed(REED, VINE)
			session.crossbreed(CARRIER, CARRIER)
			_main.open_tab(1)
		"dex":
			_discover_many(session)
			_main.open_tab(3)
		"upgrades":
			session.unlock_floor(1)
			session.buy_irrigation(0, 0)
			session.buy_drone(0)
			_main.open_tab(4)
		"toasts":
			session.market.start_event(session.catalog.market_events[0])
			session.crossbreed(REED, VINE)
			session.goals.note(GoalDef.Kind.HARVEST, 3)
			_main.open_tab(0)
		"settings":
			_main.open_settings()
		"offline":
			session.buy_irrigation(0, 0)
			session.buy_irrigation(0, 1)
			session.buy_drone(0)
			session.plant_all(0, REED)
			session.plant_all(0, VINE)
			session.apply_offline(5400.0)
			_main.open_tab(0)
	await get_tree().process_frame
	# Durumu hazırlayan komutlar bildirim ve "+N" üretir; ekran görüntüsü sakin olsun diye temizlenir (yalnız "toasts" onları gösterir).
	if scenario != "toasts":
		_main.toasts().clear()
		_main.hud().clear_floats()


## Çiftlikte birkaç bitki olgunlaştırıp hasat eder: envanterde ürün olur.
func _stock_produce(session: GameSession) -> void:
	for uid: String in [REED, VINE, CARRIER]:
		session.plant_all(0, uid)
		for pot_index: int in session.farm.get_floor(0).pots.size():
			session.farm.get_pot(0, pot_index).growth = 1.0
		for pot_index: int in session.farm.get_floor(0).pots.size():
			session.harvest_pot(0, pot_index)
	session.tick(0.6)


## Birçok çaprazlama yaparak Seed-Dex'i çeşitlendirir.
func _discover_many(session: GameSession) -> void:
	session.wallet.add_credits(20000)
	for round_index: int in 18:
		var seeds: Array[SeedItem] = session.inventory.seeds()
		var first: SeedItem = seeds[round_index % seeds.size()]
		var second: SeedItem = seeds[(round_index * 7 + 3) % seeds.size()]
		session.crossbreed(first.gene.uid, second.gene.uid)


func _read_options() -> Dictionary:
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			continue
		var body: String = argument.substr(2)
		var split: int = body.find("=")
		if split < 0:
			options[body] = true
		else:
			options[body.substr(0, split)] = body.substr(split + 1)
	return options
