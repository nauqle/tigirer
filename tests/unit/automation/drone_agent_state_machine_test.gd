extends TestCase
## DroneAgent: AÇIK geçiş tablosu. Her durumdan yalnızca tablodaki durumlara geçilir; başka her geçiş reddedilir ve durumu değiştirmez.

const EXPECTED: Dictionary = {
	DroneAgent.State.IDLE: [DroneAgent.State.SEEKING],
	DroneAgent.State.SEEKING: [DroneAgent.State.FLYING_TO, DroneAgent.State.IDLE],
	DroneAgent.State.FLYING_TO: [DroneAgent.State.HARVESTING, DroneAgent.State.SEEKING],
	DroneAgent.State.HARVESTING: [DroneAgent.State.RETURNING],
	DroneAgent.State.RETURNING: [DroneAgent.State.IDLE],
}


func _agent_in(state: DroneAgent.State) -> DroneAgent:
	var agent: DroneAgent = DroneAgent.new()
	agent.state = state
	return agent


func test_a_new_drone_starts_idle_with_no_target() -> void:
	var agent: DroneAgent = DroneAgent.new()

	assert_eq(agent.state, DroneAgent.State.IDLE)
	assert_eq(agent.target_pot, -1)


func test_every_allowed_transition_succeeds_and_changes_the_state() -> void:
	for from: DroneAgent.State in DroneAgent.State.values():
		for to: DroneAgent.State in EXPECTED[from]:
			var agent: DroneAgent = _agent_in(from)

			assert_true(agent.can_transition(to), "%s -> %s olmalı" % [DroneAgent.State.keys()[from], DroneAgent.State.keys()[to]])
			assert_true(agent.transition(to))
			assert_eq(agent.state, to)


func test_every_other_transition_is_refused_and_leaves_the_state_alone() -> void:
	for from: DroneAgent.State in DroneAgent.State.values():
		for to: DroneAgent.State in DroneAgent.State.values():
			if (EXPECTED[from] as Array).has(to):
				continue
			var agent: DroneAgent = _agent_in(from)

			assert_false(agent.can_transition(to), "%s -> %s yasak olmalı" % [DroneAgent.State.keys()[from], DroneAgent.State.keys()[to]])
			assert_false(agent.transition(to))
			assert_eq(agent.state, from, "durum değişmedi")


func test_the_table_covers_every_state_exactly() -> void:
	assert_eq(DroneAgent.TRANSITIONS.size(), DroneAgent.State.size(), "her durumun satırı var")
	for state: DroneAgent.State in DroneAgent.State.values():
		assert_true(DroneAgent.TRANSITIONS.has(state))
		assert_false((DroneAgent.TRANSITIONS[state] as Array).is_empty(), "çıkışsız (takılan) durum yok")


func test_following_the_table_from_idle_returns_to_idle() -> void:
	var agent: DroneAgent = DroneAgent.new()
	var cycle: Array[DroneAgent.State] = [
		DroneAgent.State.SEEKING,
		DroneAgent.State.FLYING_TO,
		DroneAgent.State.HARVESTING,
		DroneAgent.State.RETURNING,
		DroneAgent.State.IDLE,
	]

	for next_state: DroneAgent.State in cycle:
		assert_true(agent.transition(next_state))

	assert_eq(agent.state, DroneAgent.State.IDLE, "tam bir iş döngüsü")
