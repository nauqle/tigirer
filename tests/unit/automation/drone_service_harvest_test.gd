extends TestCase
## DroneService: dronlar olgun bitkiyi bulur, uçar, biçer, yeniden diker, üsse döner; aynı bitkiye iki dron gitmez.
## Ayar (AutomationFixtures): 2 hücre/sn, 0.5 sn biçme, 0.5 sn bekleme, üs (-1, 0). Çiftlik: 2x2 kat.

var _farm: FarmService
var _drones: DroneService


func before_each() -> void:
	_farm = AutomationFixtures.make_farm()
	_drones = DroneService.new()
	_drones.setup(AutomationFixtures.make_config(), _farm)


func _mature(pot_index: int) -> void:
	_farm.plant(0, pot_index, FarmFixtures.make_gene(GeneticsFixtures.FRUIT_A, "gene-%d" % pot_index))
	_farm.get_pot(0, pot_index).growth = 1.0


func _run(seconds: float, step: float = 0.1) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds:
		_drones.tick(step)
		elapsed += step


func test_the_number_of_drones_follows_the_floor_state() -> void:
	_farm.get_floor(0).drones = 2
	_drones.tick(0.1)
	assert_eq(_drones.agents_for_floor(0).size(), 2)

	_farm.get_floor(0).drones = 3
	_drones.tick(0.1)
	assert_eq(_drones.agents_for_floor(0).size(), 3)

	_farm.get_floor(0).drones = 1
	_drones.tick(0.1)
	assert_eq(_drones.agents_for_floor(0).size(), 1, "azalınca fazla dronlar kalkar")


func test_a_floor_without_drones_harvests_nothing() -> void:
	_mature(0)

	_run(30.0)

	assert_true(_farm.get_pot(0, 0).is_mature(), "dron yok, bitki beklemede")
	assert_eq(_drones.agents_for_floor(0).size(), 0)


func test_a_drone_flies_to_a_mature_plant_harvests_and_replants_it() -> void:
	var harvested: Array[HarvestResult] = []
	_farm.harvested.connect(func(result: HarvestResult) -> void: harvested.append(result))
	_farm.get_floor(0).drones = 1
	_mature(3)  # sütun 1, satır 1

	_run(10.0)

	assert_eq(harvested.size(), 1, "tek hasat")
	assert_eq(harvested[0].pot_index, 3)
	var pot: PotState = _farm.get_pot(0, 3)
	assert_false(pot.is_empty(), "aynı gen yeniden dikildi")
	assert_almost_eq(pot.growth, 0.0, 0.001)
	assert_eq(pot.gene.uid, "gene-3")
	assert_eq(harvested[0].seeds_returned, 0, "dönen tohum yeniden ekimde kullanıldı")


func test_a_drone_spends_the_configured_time_cutting_the_plant() -> void:
	_farm.get_floor(0).drones = 1
	_mature(0)
	var agent: DroneAgent = null
	var guard: int = 0
	while guard < 200:
		_drones.tick(0.05)
		guard += 1
		agent = _drones.agents_for_floor(0)[0]
		if agent.state == DroneAgent.State.HARVESTING:
			break

	assert_eq(agent.state, DroneAgent.State.HARVESTING, "dron bitkinin başına geldi")
	assert_true(_farm.get_pot(0, 0).is_mature(), "biçme başlar başlamaz bitmez")
	_drones.tick(0.3)  # biçme süresi 0.5 sn: henüz bitmedi
	assert_true(_farm.get_pot(0, 0).is_mature(), "0.3 sn sonra hâlâ biçiyor")

	_drones.tick(0.3)

	assert_false(_farm.get_pot(0, 0).is_mature(), "0.5 sn dolunca biçildi ve yeniden dikildi")


func test_after_the_job_the_drone_returns_to_its_dock_and_idles() -> void:
	_farm.get_floor(0).drones = 1
	_mature(0)

	_run(12.0)

	var agent: DroneAgent = _drones.agents_for_floor(0)[0]
	# Yeniden dikilen bitki henüz olgun değil: dron her bekleme süresinde bir bakıp (SEEKING) boş dönüp IDLE'a geçer.
	assert_true(agent.state == DroneAgent.State.IDLE or agent.state == DroneAgent.State.SEEKING, "bekleme döngüsünde")
	assert_almost_eq(agent.position.distance_to(agent.dock), 0.0, 0.05, "üste döndü")
	assert_eq(agent.target_pot, -1)


func test_with_no_mature_plants_the_drone_waits_at_the_dock() -> void:
	_farm.get_floor(0).drones = 1
	_farm.plant(0, 0, FarmFixtures.make_gene())  # henüz olgun değil

	_run(5.0)

	var agent: DroneAgent = _drones.agents_for_floor(0)[0]
	assert_true(agent.state == DroneAgent.State.IDLE or agent.state == DroneAgent.State.SEEKING, "bekliyor ya da bakıyor")
	assert_almost_eq(agent.position.distance_to(agent.dock), 0.0, 0.001, "yerinden kıpırdamadı")


func test_two_drones_never_chase_the_same_plant() -> void:
	var harvested: Array[int] = []
	_farm.harvested.connect(func(result: HarvestResult) -> void: harvested.append(result.pot_index))
	_farm.get_floor(0).drones = 2
	_mature(0)
	_mature(1)

	_run(0.5)  # ikisi de hedef seçip yola çıktı

	var agents: Array[DroneAgent] = _drones.agents_for_floor(0)
	assert_eq(agents[0].state, DroneAgent.State.FLYING_TO)
	assert_eq(agents[1].state, DroneAgent.State.FLYING_TO)
	assert_ne(agents[0].target_pot, agents[1].target_pot, "rezervasyon: farklı hedefler")

	_run(10.0)

	assert_eq(harvested.size(), 2, "iki bitki, iki hasat")
	assert_ne(harvested[0], harvested[1], "farklı bitkiler")


func test_a_plant_harvested_by_the_player_midflight_sends_the_drone_back_to_seeking() -> void:
	_farm.get_floor(0).drones = 1
	_mature(3)
	_run(1.0, 0.1)  # dron yola çıktı
	var agent: DroneAgent = _drones.agents_for_floor(0)[0]
	assert_eq(agent.state, DroneAgent.State.FLYING_TO, "yolda")

	_farm.harvest(0, 3)  # oyuncu araya girdi
	_drones.tick(0.1)

	assert_eq(agent.state, DroneAgent.State.SEEKING, "hedef kayboldu, yeniden arıyor")
	assert_eq(agent.target_pot, -1)


func test_a_locked_floor_has_no_working_drones() -> void:
	var locked: FloorState = _farm.get_floor(1)
	locked.drones = 2
	# Kilitli katta ekim yapılamaz; olgun bir bitkiyi doğrudan duruma koyarak dronların dokunmadığını sınarız
	locked.pots[0].gene = FarmFixtures.make_gene(GeneticsFixtures.FRUIT_A, "locked-gene")
	locked.pots[0].phenotype = GeneticsEngine.express(locked.pots[0].gene, GeneticsFixtures.make_ruleset())
	locked.pots[0].growth = 1.0

	_run(20.0)

	assert_true(locked.pots[0].is_mature(), "kilitli katta hasat yok")
	for agent: DroneAgent in _drones.agents_for_floor(1):
		assert_eq(agent.position, agent.dock, "dron kıpırdamadı")


func test_the_drone_picks_the_nearest_mature_plant_first() -> void:
	var order: Array[int] = []
	_farm.harvested.connect(func(result: HarvestResult) -> void: order.append(result.pot_index))
	_farm.get_floor(0).drones = 1
	_mature(1)  # sütun 1, satır 0
	_mature(2)  # sütun 0, satır 1
	# Üs (-1, 0): satır 0'daki sütun 0 yakın; sütun 1 daha uzak. İkisi de olgun: önce en yakın (pot 2 -> (0.5, 1.5) mesafe 2.06; pot 1 -> (1.5, 0.5) mesafe 2.55)

	_run(12.0)

	assert_eq(order.size(), 2)
	assert_eq(order[0], 2, "yakın olan önce")
