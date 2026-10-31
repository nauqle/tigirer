class_name GameSession
extends Node
## Oyunun kompozisyon kökü (composition root): tüm servisleri kurar, birbirine bağlar (bağımlılık enjeksiyonu), olaylarını
## SignalBus'a iletir, her karede zamanı ilerletir, otomatik kaydeder ve çevrimdışı ilerlemeyi uygular. Arayüz ve geliştirme
## araçları oyunu YALNIZCA buradaki KOMUTLARLA değiştirir (`plant_seed`, `sell`, `buy_irrigation` ...); her komut bir
## `CommandResult` döndürür. Servisler birbirini bilmez, arayüz servislerin iç durumunu değiştirmez.
##
## Uygular: design/game-brief.md, "Core loop" ve tüm fazlar; mimari kural "decoupled architecture, SignalBus".
##
## [codeblock]
## var session: GameSession = GameSession.new()
## add_child(session)
## session.setup(load("res://assets/data/game_catalog.tres"))
## session.start()                                   # kayıt varsa yükler (çevrimdışı ilerlemeyle), yoksa yeni oyun
## var result: CommandResult = session.plant_all(0, "starter_reed_berry")
## [/codeblock]

## Otomatik kayıt aralığı (gerçek saniye).
const AUTOSAVE_SECONDS: float = 20.0
## Tek karede ilerletilecek en uzun gerçek süre (hata ayıklayıcı duraklaması gibi sıçramalara karşı).
const MAX_FRAME_DELTA: float = 0.25

var catalog: GameCatalog
var time: TimeManager = TimeManager.new()
var wallet: WalletService = WalletService.new()
var inventory: InventoryService = InventoryService.new()
var farm: FarmService = FarmService.new()
var market: MarketService = MarketService.new()
var orders: OrderService = OrderService.new()
var breeding: BreedingService = BreedingService.new()
var automation: AutomationService = AutomationService.new()
var drones: DroneService = DroneService.new()
var dex: SeedDex = SeedDex.new()
var goals: GoalService = GoalService.new()
var settings: GameSettings = GameSettings.new()
var saves: SaveManager = SaveManager.new()
## Son çevrimdışı ilerleme özeti (yoksa null).
var last_offline_report: OfflineReport
## Son çaprazlamanın sonucu (laboratuvar ekranı çocukları buradan okur).
var last_breed: BreedingService.Outcome
## Kapalıysa `_process` zamanı ilerletmez (testler `tick()`'i elle çağırır).
var simulate_enabled: bool = true
## Kapalıysa kayıt yazılmaz (testler ve geliştirme sahneleri).
var autosave_enabled: bool = true
## Pencere kapatılınca kaydedip çıkılsın mı? (Ana sahne açar.)
var quit_on_close: bool = false

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _relay: FarmSignalRelay = FarmSignalRelay.new()
var _wired: bool = false
var _autosave_timer: float = 0.0
var _swipe_combo: int = 0
var _swipe_value: float = 0.0
var _paused_unix: float = 0.0


## Kataloğu ve kayıt yolunu verir; servisleri kurar ve bağlar. Yeni (boş) bir oyun durumu hazırlar. `rng_seed` >= 0 ise
## rastgelelik tohumlanır (testler).
func setup(game_catalog: GameCatalog, save_path: String = SaveManager.DEFAULT_PATH, rng_seed: int = -1) -> void:
	catalog = game_catalog
	saves = SaveManager.new(save_path)
	if rng_seed >= 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	if not _wired:
		_wire_signals()
		_wired = true
	_init_fresh_state()


## Kayıt varsa yükler (çevrimdışı ilerlemeyi uygular), yoksa yeni oyun başlatır. Kayıttan yüklendiyse true.
func start() -> bool:
	if load_game():
		return true
	new_game()
	return false


# ------------------------------------------------------------------ yaşam döngüsü


func _process(delta: float) -> void:
	if not simulate_enabled or catalog == null:
		return
	tick(minf(delta, MAX_FRAME_DELTA))
	if autosave_enabled:
		_autosave_timer += delta
		if _autosave_timer >= AUTOSAVE_SECONDS:
			_autosave_timer = 0.0
			save_game()


## Oyunu `real_delta` GERÇEK saniye ilerletir (hız çarpanı uygulanır).
func tick(real_delta: float) -> void:
	var game_delta: float = time.advance(real_delta)
	if game_delta <= 0.0:
		return
	farm.tick(game_delta)
	drones.tick(game_delta)
	market.tick(game_delta)
	orders.tick(game_delta, time.game_seconds, orders.reputation_level(wallet.reputation))


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_paused_unix = Time.get_unix_time_from_system()
			if autosave_enabled and catalog != null:
				save_game()
		NOTIFICATION_APPLICATION_RESUMED:
			if _paused_unix > 0.0 and catalog != null:
				var gap: float = Time.get_unix_time_from_system() - _paused_unix
				_paused_unix = 0.0
				apply_offline(gap)
		NOTIFICATION_WM_CLOSE_REQUEST:
			if quit_on_close and catalog != null:
				if autosave_enabled:
					save_game()
				get_tree().quit()


## Yeni oyun: her servis sıfırlanır, başlangıç tohumları verilir. Kayıt dosyasına dokunmaz.
func new_game() -> void:
	_init_fresh_state()
	SignalBus.game_reloaded.emit()


## Tüm ilerlemeyi siler (kayıt dahil) ve yeniden başlar.
func reset_game() -> void:
	saves.delete_save()
	new_game()


# --------------------------------------------------------------------- kayıt


## Durumu şifreli dosyaya yazar. Başarılıysa true.
func save_game() -> bool:
	var ok: bool = saves.save(export_state())
	if ok:
		SignalBus.game_saved.emit()
	return ok


## Kayıttan yükler; yoksa ya da bozuksa false. Çevrimdışı geçen süre için ilerleme uygulanır.
func load_game() -> bool:
	var loaded: Dictionary = saves.load_state()
	if loaded.is_empty():
		return false
	import_state(loaded["state"] as Dictionary)
	var away: float = maxf(Time.get_unix_time_from_system() - float(loaded.get("saved_unix", 0.0)), 0.0)
	apply_offline(away)
	SignalBus.game_reloaded.emit()
	return true


## Oyun durumunun JSON uyumlu sözlüğü.
func export_state() -> Dictionary:
	var floor_data: Array = []
	for floor_state: FloorState in farm.floors:
		floor_data.append(floor_state.to_dict())
	return {
		"time": time.game_seconds,
		"wallet": wallet.to_dict(),
		"inventory": inventory.to_dict(),
		"floors": floor_data,
		"market": market.to_dict(),
		"orders": orders.to_dict(),
		"automation": automation.to_dict(),
		"dex": dex.to_dict(),
		"goals": goals.to_dict(),
		"settings": settings.to_dict(),
	}


## Sözlükten durumu kurar. Eksik bölümler yeni oyunun varsayılanında kalır; kayıttaki katlar katalogdaki tanımlara uydurulur.
func import_state(data: Dictionary) -> void:
	_init_fresh_state()
	time.restore(float(data.get("time", 0.0)))
	wallet.load_dict(data.get("wallet", {}) as Dictionary)
	inventory.load_dict(data.get("inventory", {}) as Dictionary)
	var saved_floors: Array = data.get("floors", []) as Array
	var floors: Array[FloorState] = []
	for def: FloorDef in catalog.floors:
		var entry: Variant = saved_floors[def.index] if def.index < saved_floors.size() else null
		if entry is Dictionary:
			floors.append(FloorState.from_dict(entry as Dictionary, def, catalog.ruleset))
		else:
			floors.append(FloorState.from_def(def, def.index == 0, catalog.farm_config.water_start))
	farm.setup(catalog.farm_config, catalog.ruleset, floors)
	drones.setup(catalog.automation_config, farm)
	market.load_dict(data.get("market", {}) as Dictionary)
	orders.load_dict(data.get("orders", {}) as Dictionary)
	automation.load_dict(data.get("automation", {}) as Dictionary)
	dex.load_dict(data.get("dex", {}) as Dictionary)
	goals.load_dict(data.get("goals", {}) as Dictionary)
	goals.note_credits(wallet.credits)
	settings.load_dict(data.get("settings", {}) as Dictionary)


## Oyuncu `seconds_away` saniye uzakta kaldı: çiftlik ilerler, dronlar hasat eder, borsa ve siparişler akar.
## Çok kısa ayrılıklar yok sayılır (null). Özet `last_offline_report`'ta ve `SignalBus.offline_report_ready` ile duyurulur.
func apply_offline(seconds_away: float) -> OfflineReport:
	if seconds_away < catalog.farm_config.offline_min_report_seconds:
		return null
	_relay.enabled = false
	var report: OfflineReport = OfflineProgress.apply(farm, catalog.automation_config, seconds_away)
	_relay.enabled = true
	market.tick(report.seconds_simulated)
	time.restore(time.game_seconds + report.seconds_simulated)
	orders.tick(report.seconds_simulated, time.game_seconds, orders.reputation_level(wallet.reputation))
	last_offline_report = report
	if report.has_news():
		SignalBus.offline_report_ready.emit(report)
	return report


# ----------------------------------------------------------------- kurulum


func _init_fresh_state() -> void:
	var farm_config: FarmConfig = catalog.farm_config
	var economy: EconomyConfig = catalog.economy_config
	time.setup(farm_config.day_length_seconds, farm_config.max_speed)
	time.restore(0.0)
	time.paused = false
	time.speed = 1.0
	wallet.load_dict({"credits": economy.starting_credits})
	inventory.setup(catalog.ruleset)
	inventory.load_dict({})
	var floors: Array[FloorState] = []
	for def: FloorDef in catalog.floors:
		floors.append(FloorState.from_def(def, def.index == 0, farm_config.water_start))
	farm.setup(farm_config, catalog.ruleset, floors)
	market.setup(economy, catalog.market_events, _rng, _fruit_ids())
	orders.setup(economy, catalog.order_templates, catalog.ruleset, _rng)
	breeding.setup(economy, catalog.ruleset, _rng)
	automation.setup(farm, wallet, catalog.floors, catalog.equipment)
	automation.lab_uv_level = 0
	drones.setup(catalog.automation_config, farm)
	dex.clear()
	for i: int in catalog.starter_seeds.size():
		var gene: PlantGene = catalog.starter_seeds[i]
		inventory.add_seed(gene, catalog.starter_seed_counts[i])
		dex.record(gene, GeneticsEngine.express(gene, catalog.ruleset), 1)
	goals.setup(catalog.goals, wallet)
	goals.note_credits(wallet.credits)
	_swipe_combo = 0
	_swipe_value = 0.0


func _fruit_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for part: PlantPartDef in catalog.ruleset.get_parts_for_layer(PlantPartDef.Layer.FRUIT):
		ids.append(part.id)
	return ids


## Servis sinyallerini SignalBus'a bağlar (bir kez).
func _wire_signals() -> void:
	_relay.connect_to(farm)
	farm.harvested.connect(_on_harvested)
	wallet.credits_changed.connect(SignalBus.credits_changed.emit)
	wallet.reputation_changed.connect(SignalBus.reputation_changed.emit)
	inventory.changed.connect(SignalBus.inventory_changed.emit)
	market.prices_changed.connect(SignalBus.prices_changed.emit)
	market.event_started.connect(SignalBus.market_event_started.emit)
	market.event_ended.connect(SignalBus.market_event_ended.emit)
	market.sold.connect(SignalBus.item_sold.emit)
	orders.order_added.connect(SignalBus.order_added.emit)
	orders.order_completed.connect(SignalBus.order_completed.emit)
	orders.order_expired.connect(SignalBus.order_expired.emit)
	automation.purchased.connect(SignalBus.equipment_purchased.emit)
	automation.floor_unlocked.connect(SignalBus.floor_unlocked.emit)
	breeding.bred.connect(SignalBus.seed_crossbred.emit)
	breeding.mutation_found.connect(SignalBus.mutation_discovered.emit)
	time.day_changed.connect(SignalBus.day_changed.emit)
	goals.completed.connect(SignalBus.goal_completed.emit)
	goals.changed.connect(SignalBus.goals_changed.emit)
	wallet.credits_changed.connect(goals.note_credits)
	market.sold.connect(_on_sold)
	orders.order_completed.connect(_on_order_completed)
	automation.purchased.connect(_on_purchased)
	automation.floor_unlocked.connect(_on_floor_unlocked)


## Her hasat (elle, kaydırarak ya da dronla) ürünü ve dönen tohumu envantere koyar, Seed-Dex'e işler.
func _on_harvested(result: HarvestResult) -> void:
	inventory.add_produce(result)
	if result.seeds_returned > 0:
		inventory.add_seed(result.gene, result.seeds_returned)
	var found: SeedDex.Discovery = dex.record(result.gene, result.phenotype, time.day())
	goals.note(GoalDef.Kind.HARVEST, 1)
	if found.new_species:
		goals.note(GoalDef.Kind.DISCOVER_SPECIES, 1)


## Hedef beslemeleri: satış geliri, teslim edilen sipariş, donanım ve kat alımı.
func _on_sold(_signature: StringName, _quantity: int, credits: int) -> void:
	goals.note(GoalDef.Kind.SELL_CREDITS, credits)


func _on_order_completed(_order: Order) -> void:
	goals.note(GoalDef.Kind.DELIVER_ORDERS, 1)


func _on_purchased(_kind: EquipmentDef.Kind, _floor_index: int, _target: int, _level: int) -> void:
	goals.note(GoalDef.Kind.BUY_EQUIPMENT, 1)


func _on_floor_unlocked(_floor_index: int) -> void:
	goals.note(GoalDef.Kind.UNLOCK_FLOOR, 1)


# ------------------------------------------------------------------ komutlar


## Envanterdeki `seed_uid` tohumunu boş bir saksıya diker (tohum harcanır).
func plant_seed(floor_index: int, pot_index: int, seed_uid: String) -> CommandResult:
	var floor_state: FloorState = farm.get_floor(floor_index)
	var pot: PotState = farm.get_pot(floor_index, pot_index)
	if floor_state == null or pot == null:
		return CommandResult.failure("ERR_INVALID_TARGET")
	if not floor_state.unlocked:
		return CommandResult.failure("ERR_FLOOR_LOCKED")
	if not pot.is_empty():
		return CommandResult.failure("ERR_POT_OCCUPIED")
	if inventory.seed_count(seed_uid) <= 0:
		return CommandResult.failure("ERR_SEED_MISSING")
	farm.plant(floor_index, pot_index, inventory.take_seed(seed_uid))
	return CommandResult.success()


## Katın tüm boş saksılarına, tohum yettiği kadar `seed_uid` diker. Başarıda dikilen sayı `args[0]`'dadır.
func plant_all(floor_index: int, seed_uid: String) -> CommandResult:
	if inventory.seed_count(seed_uid) <= 0:
		return CommandResult.failure("ERR_SEED_MISSING")
	var planted: int = 0
	for pot_index: int in farm.empty_pot_indices(floor_index):
		if plant_seed(floor_index, pot_index, seed_uid).ok:
			planted += 1
	if planted == 0:
		return CommandResult.failure("ERR_NO_EMPTY_POTS")
	return CommandResult.success("MSG_PLANTED_N", [planted])


## Saksıyı sular.
func water_pot(floor_index: int, pot_index: int) -> CommandResult:
	if not farm.water(floor_index, pot_index):
		return CommandResult.failure("ERR_INVALID_TARGET")
	return CommandResult.success()


## Katta bitkisi olan ve suyu eksik tüm saksıları sular.
func water_floor(floor_index: int) -> CommandResult:
	var count: int = farm.water_floor(floor_index)
	if count == 0:
		return CommandResult.failure("ERR_NOTHING_TO_WATER")
	return CommandResult.success("MSG_WATERED_N", [count])


## Olgun bir bitkiyi tek dokunuşla biçer (kombo yok).
func harvest_pot(floor_index: int, pot_index: int) -> CommandResult:
	if farm.harvest(floor_index, pot_index, 0) == null:
		return CommandResult.failure("ERR_NOT_MATURE")
	return CommandResult.success()


## Katta olgun TÜM bitkileri tek kaydırma zinciri olarak biçer (kombo ödülüyle); kaydırması zor olan oyuncular için tek dokunuşluk yol.
func harvest_floor(floor_index: int) -> CommandResult:
	var floor_state: FloorState = farm.get_floor(floor_index)
	if floor_state == null:
		return CommandResult.failure("ERR_INVALID_TARGET")
	if not floor_state.unlocked:
		return CommandResult.failure("ERR_FLOOR_LOCKED")
	var ripe: Array[int] = []
	for pot_index: int in floor_state.pots.size():
		if floor_state.pots[pot_index].is_mature():
			ripe.append(pot_index)
	if ripe.is_empty():
		return CommandResult.failure("ERR_NOTHING_TO_HARVEST")
	begin_swipe()
	var cut: int = 0
	for pot_index: int in ripe:
		if swipe_harvest(floor_index, pot_index):
			cut += 1
	end_swipe()
	return CommandResult.success("MSG_HARVESTED_N", [cut])


## Yeni bir kaydırma başlar: kombo sayacı sıfırlanır.
func begin_swipe() -> void:
	_swipe_combo = 0
	_swipe_value = 0.0


## Kaydırma bu olgun bitkinin üzerinden geçti: biçilir, kombo bir artar. Biçildiyse true.
func swipe_harvest(floor_index: int, pot_index: int) -> bool:
	var result: HarvestResult = farm.harvest(floor_index, pot_index, _swipe_combo)
	if result == null:
		return false
	_swipe_combo += 1
	_swipe_value += result.total_value()
	return true


## Kaydırma bitti: en az bir bitki biçildiyse özet olay yayınlanır.
func end_swipe() -> void:
	if _swipe_combo > 0:
		SignalBus.harvest_swipe_finished.emit(_swipe_combo, _swipe_value)
	_swipe_combo = 0
	_swipe_value = 0.0


## Yığından `quantity` birim satar.
func sell(signature: StringName, quantity: int) -> CommandResult:
	var credits: int = market.sell(inventory, wallet, signature, quantity)
	if credits <= 0:
		return CommandResult.failure("ERR_NOTHING_TO_SELL")
	return CommandResult.success("MSG_SOLD", [credits])


## Yığının tamamını satar.
func sell_all_of(signature: StringName) -> CommandResult:
	var stack: ProduceStack = inventory.stack(signature)
	if stack == null:
		return CommandResult.failure("ERR_NOTHING_TO_SELL")
	return sell(signature, stack.count)


## Envanterdeki tüm ürünü satar.
func sell_everything() -> CommandResult:
	var total: int = 0
	for stack: ProduceStack in inventory.stacks():
		total += market.sell(inventory, wallet, stack.signature, stack.count)
	if total <= 0:
		return CommandResult.failure("ERR_NOTHING_TO_SELL")
	return CommandResult.success("MSG_SOLD", [total])


## Açık bir VIP siparişi envanterden karşılar.
func fulfil_order(order_id: int) -> CommandResult:
	var order: Order = orders.get_order(order_id)
	if order == null:
		return CommandResult.failure("ERR_ORDER_NOT_READY")
	var reward: int = order.reward
	if not orders.fulfil(order_id, inventory, wallet):
		return CommandResult.failure("ERR_ORDER_NOT_READY")
	return CommandResult.success("MSG_ORDER_DONE", [reward])


## İki tohumu çaprazlar (ücret ödenir); çocuklar envantere girer, Seed-Dex'e işlenir, yeni tür/varyant ödül verir.
## Sonuç `last_breed`'de durur.
func crossbreed(uid_a: String, uid_b: String) -> CommandResult:
	last_breed = breeding.crossbreed(inventory, wallet, uid_a, uid_b, automation.lab_mutation_bonus())
	if not last_breed.ok:
		var args: Array = [catalog.economy_config.cross_cost] if last_breed.error_key == "ERR_NOT_ENOUGH_CREDITS" else []
		return CommandResult.failure(last_breed.error_key, args)
	for child: PlantGene in last_breed.children:
		var found: SeedDex.Discovery = dex.record(child, GeneticsEngine.express(child, catalog.ruleset), time.day())
		var bonus: int = 0
		if found.new_species:
			bonus = catalog.economy_config.discovery_bonus_species
			goals.note(GoalDef.Kind.DISCOVER_SPECIES, 1)
		elif found.new_variant:
			bonus = catalog.economy_config.discovery_bonus_variant
		if bonus > 0:
			wallet.add_credits(bonus)
			SignalBus.dex_discovery.emit(found.morph_id, found.new_species, bonus)
	goals.note(GoalDef.Kind.CROSSBREED, 1)
	return CommandResult.success("MSG_CROSS_DONE", [last_breed.children.size()])


func buy_irrigation(floor_index: int, row: int) -> CommandResult:
	return automation.buy_irrigation(floor_index, row)


func buy_uv_lamp(floor_index: int, row: int) -> CommandResult:
	return automation.buy_uv_lamp(floor_index, row)


func buy_drone(floor_index: int) -> CommandResult:
	return automation.buy_drone(floor_index)


func buy_lab_uv() -> CommandResult:
	return automation.buy_lab_uv()


func unlock_floor(floor_index: int) -> CommandResult:
	return automation.unlock_floor(floor_index)


## Başlangıç öğreticisini bitmiş sayar (ilk satıştan sonra).
func complete_tutorial() -> void:
	if not settings.tutorial_done:
		settings.set_tutorial_done(true)


## Oyun hızını ayarlar (0 = duraklat, en çok `FarmConfig.max_speed`).
func set_speed(multiplier: float) -> void:
	time.set_speed(multiplier)
	SignalBus.speed_changed.emit(time.speed)
