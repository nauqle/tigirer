class_name DroneService
extends RefCounted
## Hasat dronlarının yürütücüsü: her katta `FloorState.drones` kadar dron çalıştırır; her dron `DroneAgent` durum makinesini
## izler (üssü bekler -> olgun bitki arar -> uçar -> biçer ve yeniden diker -> üsse döner). Aynı bitkiye iki dron gitmez
## (hedef rezervasyonu). Hasat `FarmService.harvest` ile yapılır; envanter, ses ve Seed-Dex aynı `harvested` olayını dinler.
##
## Uygular: design/game-brief.md, FAZ 4 "hasat dronları için basit durum makinesi".
##
## [codeblock]
## drones.setup(automation_config, farm_service)
## drones.tick(game_delta)                       # her karede
## for agent: DroneAgent in drones.agents_for_floor(0):
##     draw_drone(agent.position, agent.state)
## [/codeblock]

var config: AutomationConfig
var farm: FarmService

var _agents: Dictionary = {}  # kat (int) -> Array[DroneAgent]
var _reserved: Dictionary = {}  # kat (int) -> {saksı (int): true}


## Ayarları ve çiftlik servisini bağlar.
func setup(automation_config: AutomationConfig, farm_service: FarmService) -> void:
	config = automation_config
	farm = farm_service
	_agents.clear()
	_reserved.clear()


## Bir kattaki dronlar (salt okunur kullanım: arayüz çizer).
func agents_for_floor(floor_index: int) -> Array[DroneAgent]:
	var list: Array[DroneAgent] = []
	list.assign(_agents.get(floor_index, []) as Array)
	return list


## Dronları `delta` oyun saniyesi ilerletir.
func tick(delta: float) -> void:
	for floor_state: FloorState in farm.floors:
		_sync_count(floor_state)
		if not floor_state.unlocked:
			continue
		for agent: DroneAgent in _agents[floor_state.index] as Array:
			_step(agent, floor_state, delta)


## Kattaki dron sayısını `FloorState.drones` ile eşitler: eksikse üste yeni dron ekler, fazlaysa son dronları kaldırır.
func _sync_count(floor_state: FloorState) -> void:
	if not _agents.has(floor_state.index):
		_agents[floor_state.index] = []
		_reserved[floor_state.index] = {}
	var list: Array = _agents[floor_state.index] as Array
	while list.size() < floor_state.drones:
		var agent: DroneAgent = DroneAgent.new()
		agent.dock = config.dock_position
		agent.position = config.dock_position
		list.append(agent)
	while list.size() > floor_state.drones:
		var removed: DroneAgent = list.pop_back() as DroneAgent
		_release(floor_state.index, removed.target_pot)


func _step(agent: DroneAgent, floor_state: FloorState, delta: float) -> void:
	match agent.state:
		DroneAgent.State.IDLE:
			agent.timer -= delta
			if agent.timer <= 0.0:
				agent.transition(DroneAgent.State.SEEKING)
		DroneAgent.State.SEEKING:
			var target: int = _pick_target(agent, floor_state)
			if target >= 0:
				agent.target_pot = target
				(_reserved[floor_state.index] as Dictionary)[target] = true
				agent.transition(DroneAgent.State.FLYING_TO)
			else:
				agent.timer = config.drone_idle_seconds
				agent.transition(DroneAgent.State.IDLE)
		DroneAgent.State.FLYING_TO:
			var pot: PotState = farm.get_pot(floor_state.index, agent.target_pot)
			if pot == null or not pot.is_mature():
				_release(floor_state.index, agent.target_pot)
				agent.target_pot = -1
				agent.transition(DroneAgent.State.SEEKING)
				return
			var goal: Vector2 = cell_center(floor_state, agent.target_pot)
			agent.position = agent.position.move_toward(goal, config.drone_speed * delta)
			if agent.position.distance_to(goal) < 0.02:
				agent.timer = config.drone_harvest_seconds
				agent.transition(DroneAgent.State.HARVESTING)
		DroneAgent.State.HARVESTING:
			agent.timer -= delta
			if agent.timer <= 0.0:
				farm.harvest(floor_state.index, agent.target_pot, 0, true)
				_release(floor_state.index, agent.target_pot)
				agent.target_pot = -1
				agent.transition(DroneAgent.State.RETURNING)
		DroneAgent.State.RETURNING:
			agent.position = agent.position.move_toward(agent.dock, config.drone_speed * delta)
			if agent.position.distance_to(agent.dock) < 0.02:
				agent.timer = config.drone_idle_seconds
				agent.transition(DroneAgent.State.IDLE)


## Dronun konumuna en yakın, başka dronun rezerve etmediği olgun saksı; yoksa -1.
func _pick_target(agent: DroneAgent, floor_state: FloorState) -> int:
	var reserved: Dictionary = _reserved[floor_state.index] as Dictionary
	var best: int = -1
	var best_distance: float = INF
	for pot_index: int in floor_state.pots.size():
		if reserved.has(pot_index) or not floor_state.pots[pot_index].is_mature():
			continue
		var distance: float = agent.position.distance_to(cell_center(floor_state, pot_index))
		if distance < best_distance:
			best_distance = distance
			best = pot_index
	return best


func _release(floor_index: int, pot_index: int) -> void:
	if pot_index >= 0 and _reserved.has(floor_index):
		(_reserved[floor_index] as Dictionary).erase(pot_index)


## Saksının merkezi, hücre biriminde: (sütun + 0.5, satır + 0.5).
static func cell_center(floor_state: FloorState, pot_index: int) -> Vector2:
	return Vector2(float(floor_state.col_of(pot_index)) + 0.5, float(floor_state.row_of(pot_index)) + 0.5)
