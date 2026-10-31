extends TestCase
## GoalService: sıralı hedef zinciri. Etkin hedef = tamamlanmamış ilki; ilerleme TÜM hedefler için birikir (sırası gelmemiş hedefin
## ilerlemesi de sayılır), etkin hedef bitince ödül ödenir, sıradaki zaten tamamsa art arda tamamlanır. Kayıt ve geri yükleme.

var _wallet: WalletService
var _service: GoalService
var _completed: Array[StringName] = []
var _rewards: Array[int] = []


func _goal(id: StringName, kind: GoalDef.Kind, target: int, reward: int) -> GoalDef:
	var def: GoalDef = GoalDef.new()
	def.id = id
	def.kind = kind
	def.target = target
	def.reward = reward
	return def


func before_each() -> void:
	_wallet = WalletService.new()
	_service = GoalService.new()
	_completed = []
	_rewards = []
	var defs: Array[GoalDef] = [
		_goal(&"harvest3", GoalDef.Kind.HARVEST, 3, 40),
		_goal(&"sell100", GoalDef.Kind.SELL_CREDITS, 100, 60),
		_goal(&"rich", GoalDef.Kind.REACH_CREDITS, 500, 200),
	]
	_service.setup(defs, _wallet)
	_service.completed.connect(func(id: StringName, reward: int) -> void:
		_completed.append(id)
		_rewards.append(reward))


func test_the_first_unfinished_goal_is_current_and_starts_at_zero() -> void:
	assert_eq(_service.current().id, &"harvest3")
	assert_eq(_service.progress_of(_service.current()), 0)
	assert_eq(_service.completed_count(), 0)
	assert_false(_service.all_done())


func test_progress_counts_only_matching_events_and_is_capped_at_the_target() -> void:
	_service.note(GoalDef.Kind.SELL_CREDITS, 50)  # başka tür: etkin hedefi ilerletmez
	assert_eq(_service.progress_of(_service.current()), 0)

	_service.note(GoalDef.Kind.HARVEST, 2)
	assert_eq(_service.progress_of(_service.current()), 2)
	_service.note(GoalDef.Kind.HARVEST, 10)

	assert_eq(_service.completed_count(), 1, "hedef bitti")
	assert_eq(_service.progress_of(_service.defs[0]), 3, "ilerleme hedefi aşmaz")


func test_completing_the_current_goal_pays_the_reward_once_and_moves_on() -> void:
	_service.note(GoalDef.Kind.HARVEST, 3)

	assert_eq(_wallet.credits, 40, "ödül ödendi")
	assert_eq(_completed, [&"harvest3"] as Array[StringName])
	assert_eq(_rewards, [40] as Array[int])
	assert_eq(_service.current().id, &"sell100", "sıradaki hedef etkin")

	_service.note(GoalDef.Kind.HARVEST, 5)  # biten hedefe tekrar ödül yok
	assert_eq(_wallet.credits, 40)
	assert_eq(_completed.size(), 1)


func test_progress_made_before_a_goal_becomes_current_counts_and_chains_completions() -> void:
	_service.note(GoalDef.Kind.SELL_CREDITS, 120)  # henüz sırası gelmemiş hedef önceden tamamlanıyor
	assert_eq(_service.completed_count(), 0, "etkin hedef (hasat) bitmeden zincir ilerlemez")

	_service.note(GoalDef.Kind.HARVEST, 3)

	assert_eq(_completed, [&"harvest3", &"sell100"] as Array[StringName], "ikisi art arda tamamlandı")
	assert_eq(_wallet.credits, 40 + 60)
	assert_eq(_service.current().id, &"rich")


func test_reaching_credits_uses_the_highest_balance_seen_not_a_running_sum() -> void:
	_service.note(GoalDef.Kind.HARVEST, 3)
	_service.note(GoalDef.Kind.SELL_CREDITS, 100)

	_service.note_credits(300)
	_service.note_credits(120)  # düşüş ilerlemeyi geri almaz
	assert_eq(_service.progress_of(_service.current()), 300)

	_service.note_credits(500)
	assert_true(_service.all_done())
	assert_eq(_wallet.credits, 40 + 60 + 200)
	assert_null(_service.current(), "hedef kalmadı")


func test_events_after_everything_is_done_change_nothing() -> void:
	_service.note(GoalDef.Kind.HARVEST, 3)
	_service.note(GoalDef.Kind.SELL_CREDITS, 100)
	_service.note_credits(900)
	var credits: int = _wallet.credits

	_service.note(GoalDef.Kind.HARVEST, 100)
	_service.note_credits(9999)

	assert_eq(_wallet.credits, credits)
	assert_eq(_completed.size(), 3)


func test_goals_survive_a_json_round_trip_and_unknown_or_bad_entries_are_ignored() -> void:
	_service.note(GoalDef.Kind.HARVEST, 3)
	_service.note(GoalDef.Kind.SELL_CREDITS, 40)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(_service.to_dict())) as Dictionary
	var restored: GoalService = GoalService.new()
	restored.setup(_service.defs, WalletService.new())

	restored.load_dict(saved)

	assert_eq(restored.completed_count(), 1)
	assert_eq(restored.current().id, &"sell100")
	assert_eq(restored.progress_of(restored.current()), 40)

	var messy: GoalService = GoalService.new()
	messy.setup(_service.defs, WalletService.new())
	messy.load_dict({"done": ["yok", "harvest3", 7], "progress": {"sell100": "bozuk", "yok": 5}})
	assert_eq(messy.completed_count(), 1, "yalnızca bilinen kimlik")
	assert_eq(messy.progress_of(messy.defs[1]), 0, "bozuk sayı sıfır")


func test_an_empty_goal_list_is_simply_finished() -> void:
	var empty: GoalService = GoalService.new()
	empty.setup([] as Array[GoalDef], WalletService.new())

	assert_null(empty.current())
	assert_true(empty.all_done())
	empty.note(GoalDef.Kind.HARVEST, 1)


func test_a_negative_or_zero_amount_never_takes_progress_away() -> void:
	_service.note(GoalDef.Kind.HARVEST, 2)

	_service.note(GoalDef.Kind.HARVEST, -5)
	_service.note(GoalDef.Kind.HARVEST, 0)

	assert_eq(_service.progress_of(_service.current()), 2)


func test_a_goal_saved_as_done_loads_as_fully_progressed_even_if_its_counter_was_lost() -> void:
	_service.load_dict({"done": ["harvest3"], "progress": {"harvest3": 0}})

	assert_true(_service.is_done(_service.defs[0]))
	assert_eq(_service.progress_of(_service.defs[0]), 3, "biten hedefin sayacı hedefe eşitlenir")
