class_name OfflineProgress
extends RefCounted
## Çevrimdışı ilerleme (Idle/Overgrowth): oyuncu uzaktayken çiftliği büyük adımlarla ilerletir. Sulamalı satırlar büyümeyi
## sürdürür, susuz saksılar suyu bitince durur; dronlar kapasiteleri kadar olgun bitkiyi biçip yeniden diker (her dron
## `offline_drone_cycle_seconds`'ta bir hasat); dronsuz olgun bitkiler beklerken AŞIRI OLGUNLAŞIR ve değer kaybeder.
## Süre `FarmConfig.offline_max_hours` ile sınırlıdır. Saf mantık: sahneye bağlı değil; hasatlar `FarmService.harvested`
## üzerinden envantere akar (oyun oturumu zaten dinler).
##
## Uygular: design/game-brief.md, FAZ 5 "çevrimdışı kazanç [Idle/Overgrowth] hesaplaması".
## Formüller: docs/architecture/floralab-architecture.md, "Çevrimdışı ilerleme".
##
## [codeblock]
## var report: OfflineReport = OfflineProgress.apply(farm, automation_config, seconds_away)
## if report.has_news():
##     show_welcome_back(report)
## [/codeblock]


## `seconds_away` saniyelik ayrılığı çiftlik üzerinde uygular ve özetini döndürür.
static func apply(farm: FarmService, automation_config: AutomationConfig, seconds_away: float) -> OfflineReport:
	var config: FarmConfig = farm.config
	var report: OfflineReport = OfflineReport.new()
	report.seconds_away = maxf(seconds_away, 0.0)
	var limit: float = config.offline_max_hours * 3600.0
	report.seconds_simulated = minf(report.seconds_away, limit)
	report.capped = report.seconds_away > limit

	var previous_factor: float = farm.yield_factor
	farm.yield_factor = config.offline_yield_factor
	var budgets: Dictionary = {}  # kat -> biriken hasat hakkı (kesirli)
	var elapsed: float = 0.0
	while elapsed < report.seconds_simulated:
		var step: float = minf(config.offline_step_seconds, report.seconds_simulated - elapsed)
		farm.tick_with_step(step, step)
		for floor_state: FloorState in farm.floors:
			if floor_state.unlocked and floor_state.drones > 0:
				_run_drones(farm, floor_state, automation_config, step, budgets, report)
		elapsed += step

	farm.yield_factor = previous_factor
	_summarize_waiting(farm, report)
	return report


## Dronların bu adımdaki hasat haklarını (dron sayısı x süre / döngü) en uzun süredir bekleyen olgun bitkilere harcar.
static func _run_drones(farm: FarmService, floor_state: FloorState, automation_config: AutomationConfig, step: float, budgets: Dictionary, report: OfflineReport) -> void:
	var budget: float = float(budgets.get(floor_state.index, 0.0)) + float(floor_state.drones) * step / automation_config.offline_drone_cycle_seconds
	while budget >= 1.0:
		var pot_index: int = _most_overgrown(floor_state)
		if pot_index < 0:
			budget = 0.0  # biçilecek bitki yok: haklar birikmez, dronlar boşta bekledi
			break
		var result: HarvestResult = farm.harvest(floor_state.index, pot_index, 0, true)
		if result != null:
			report.harvests += 1
			report.harvested_units += result.quantity
			report.harvested_value += result.total_value()
		budget -= 1.0
	budgets[floor_state.index] = minf(budget, 1.0)


## Katta en uzun süredir bekleyen olgun saksı; yoksa -1.
static func _most_overgrown(floor_state: FloorState) -> int:
	var best: int = -1
	var best_wait: float = -1.0
	for pot_index: int in floor_state.pots.size():
		var pot: PotState = floor_state.pots[pot_index]
		if pot.is_mature() and pot.overgrowth_seconds > best_wait:
			best_wait = pot.overgrowth_seconds
			best = pot_index
	return best


## Dönüşte hâlâ bekleyen olgun bitkileri ve aşırı olgunluk kaybını sayar.
static func _summarize_waiting(farm: FarmService, report: OfflineReport) -> void:
	for floor_state: FloorState in farm.floors:
		if not floor_state.unlocked:
			continue
		for pot: PotState in floor_state.pots:
			if not pot.is_mature():
				continue
			report.waiting_mature += 1
			var factor: float = GrowthModel.overgrowth_factor(pot.overgrowth_seconds, farm.config)
			if factor < 1.0:
				report.overgrown += 1
				report.value_lost += (1.0 - factor) * float(farm.config.base_yield_units) * pot.phenotype.market_value
