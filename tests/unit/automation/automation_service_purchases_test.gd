extends TestCase
## AutomationService: sulama, UV, dron, laboratuvar UV ve kat açma satın almaları; para, sınır ve geçerlilik kuralları.
## Donanım (AutomationFixtures): sulama 100 (1 sv), UV 200 x2.0 (2 sv), dron 300 x2.0 (3 adet), lab UV 400 x2.0 (3 sv, +%3/sv).
## Katlar: 0 açık, 1 maliyet 500, 2 maliyet 1000.

var _farm: FarmService
var _wallet: WalletService
var _service: AutomationService


func before_each() -> void:
	_farm = AutomationFixtures.make_farm()
	_wallet = WalletService.new()
	_wallet.add_credits(10000)
	_service = AutomationFixtures.make_service(_farm, _wallet)


func test_buying_irrigation_charges_the_price_and_waters_that_row_only() -> void:
	var result: CommandResult = _service.buy_irrigation(0, 1)

	assert_true(result.ok)
	assert_eq(result.message_key, "MSG_IRRIGATION_BUILT")
	assert_eq(_wallet.credits, 9900)
	assert_true(_farm.get_floor(0).irrigation_rows[1])
	assert_false(_farm.get_floor(0).irrigation_rows[0], "diğer satır etkilenmez")


func test_irrigation_cannot_be_bought_twice_for_the_same_row() -> void:
	_service.buy_irrigation(0, 0)

	var again: CommandResult = _service.buy_irrigation(0, 0)

	assert_false(again.ok)
	assert_eq(again.message_key, "ERR_MAX_LEVEL")
	assert_eq(_wallet.credits, 9900, "ikinci ücret alınmadı")


func test_uv_lamp_levels_cost_more_each_time_and_stop_at_the_maximum() -> void:
	var first: CommandResult = _service.buy_uv_lamp(0, 0)  # 200
	var second: CommandResult = _service.buy_uv_lamp(0, 0)  # 400
	var third: CommandResult = _service.buy_uv_lamp(0, 0)  # sınır

	assert_true(first.ok and second.ok)
	assert_eq(_farm.get_floor(0).uv_rows[0], 2)
	assert_eq(_wallet.credits, 10000 - 200 - 400)
	assert_false(third.ok)
	assert_eq(third.message_key, "ERR_MAX_LEVEL")


func test_drones_are_bought_per_floor_with_growing_prices_up_to_the_cap() -> void:
	for i: int in 3:
		assert_true(_service.buy_drone(0).ok)

	assert_eq(_farm.get_floor(0).drones, 3)
	assert_eq(_wallet.credits, 10000 - 300 - 600 - 1200, "300, 600, 1200")
	assert_eq(_service.buy_drone(0).message_key, "ERR_MAX_LEVEL")


func test_a_purchase_without_enough_credits_changes_nothing_and_names_the_price() -> void:
	var poor: WalletService = WalletService.new()
	poor.add_credits(99)
	var service: AutomationService = AutomationFixtures.make_service(_farm, poor)

	var result: CommandResult = service.buy_irrigation(0, 0)

	assert_false(result.ok)
	assert_eq(result.message_key, "ERR_NOT_ENOUGH_CREDITS")
	assert_eq(result.args, [100] as Array)
	assert_eq(poor.credits, 99)
	assert_false(_farm.get_floor(0).irrigation_rows[0])


func test_locked_floors_and_bad_targets_are_refused() -> void:
	assert_eq(_service.buy_irrigation(1, 0).message_key, "ERR_FLOOR_LOCKED", "kilitli kat")
	assert_eq(_service.buy_drone(2).message_key, "ERR_FLOOR_LOCKED")
	assert_eq(_service.buy_uv_lamp(0, 5).message_key, "ERR_INVALID_TARGET", "olmayan satır")
	assert_eq(_service.buy_uv_lamp(0, -1).message_key, "ERR_INVALID_TARGET")
	assert_eq(_service.buy_irrigation(9, 0).message_key, "ERR_INVALID_TARGET", "olmayan kat")
	assert_eq(_wallet.credits, 10000, "hiçbiri ücret almadı")


func test_the_lab_uv_room_raises_the_mutation_bonus_per_level() -> void:
	assert_almost_eq(_service.lab_mutation_bonus(), 0.0, 0.0001)

	_service.buy_lab_uv()
	_service.buy_lab_uv()

	assert_eq(_service.lab_uv_level, 2)
	assert_almost_eq(_service.lab_mutation_bonus(), 0.06, 0.0001, "2 x %3")
	assert_eq(_wallet.credits, 10000 - 400 - 800)


func test_floors_unlock_in_order_and_pay_their_price() -> void:
	var skipped: CommandResult = _service.unlock_floor(2)
	var first: CommandResult = _service.unlock_floor(1)
	var second: CommandResult = _service.unlock_floor(2)

	assert_false(skipped.ok)
	assert_eq(skipped.message_key, "ERR_PREVIOUS_FLOOR_LOCKED", "sırayı atlamak yok")
	assert_true(first.ok and second.ok)
	assert_true(_farm.get_floor(1).unlocked and _farm.get_floor(2).unlocked)
	assert_eq(_wallet.credits, 10000 - 500 - 1000)
	assert_eq(_service.unlock_floor(1).message_key, "ERR_ALREADY_UNLOCKED")


func test_unlocking_without_enough_credits_fails_and_keeps_the_floor_locked() -> void:
	var poor: WalletService = WalletService.new()
	poor.add_credits(499)
	var service: AutomationService = AutomationFixtures.make_service(_farm, poor)

	var result: CommandResult = service.unlock_floor(1)

	assert_false(result.ok)
	assert_eq(result.message_key, "ERR_NOT_ENOUGH_CREDITS")
	assert_false(_farm.get_floor(1).unlocked)
	assert_eq(poor.credits, 499)


func test_purchases_announce_themselves() -> void:
	var log: Array[String] = []
	_service.purchased.connect(func(kind: EquipmentDef.Kind, floor_index: int, target: int, level: int) -> void: log.append("%d/%d/%d/%d" % [kind, floor_index, target, level]))
	_service.floor_unlocked.connect(func(floor_index: int) -> void: log.append("kat%d" % floor_index))

	_service.buy_irrigation(0, 1)
	_service.buy_drone(0)
	_service.unlock_floor(1)

	assert_eq(log, ["0/0/1/1", "2/0/-1/1", "kat1"] as Array[String])


func test_next_cost_and_current_level_describe_the_state_for_the_shop() -> void:
	assert_eq(_service.next_cost(EquipmentDef.Kind.IRRIGATION, 0, 0), 100)
	assert_eq(_service.current_level(EquipmentDef.Kind.IRRIGATION, 0, 0), 0)
	_service.buy_irrigation(0, 0)
	assert_eq(_service.next_cost(EquipmentDef.Kind.IRRIGATION, 0, 0), -1, "sınıra gelindi")
	assert_eq(_service.current_level(EquipmentDef.Kind.IRRIGATION, 0, 0), 1)
	assert_eq(_service.next_cost(EquipmentDef.Kind.UV_LAMP, 0, 0), 200)
	_service.buy_uv_lamp(0, 0)
	assert_eq(_service.next_cost(EquipmentDef.Kind.UV_LAMP, 0, 0), 400)
	assert_eq(_service.next_cost(EquipmentDef.Kind.DRONE, 0), 300)
	assert_eq(_service.next_cost(EquipmentDef.Kind.LAB_UV), 400)
	assert_eq(_service.current_level(EquipmentDef.Kind.UV_LAMP, 0, 9), -1, "geçersiz satır")
	assert_eq(_service.floor_unlock_cost(1), 500)
	assert_eq(_service.floor_unlock_cost(9), -1)


func test_equipment_cost_formula_grows_geometrically() -> void:
	var def: EquipmentDef = AutomationFixtures.make_equipment(&"x", EquipmentDef.Kind.DRONE, 100, 1.5, 5)

	assert_eq(def.cost_for_level(0), 100)
	assert_eq(def.cost_for_level(1), 150)
	assert_eq(def.cost_for_level(2), 225)
	assert_eq(def.cost_for_level(-3), 100, "negatif seviye 0 sayılır")


func test_the_lab_level_survives_a_round_trip() -> void:
	_service.buy_lab_uv()
	var restored: AutomationService = AutomationFixtures.make_service(_farm, _wallet)

	restored.load_dict(JSON.parse_string(JSON.stringify(_service.to_dict())) as Dictionary)

	assert_eq(restored.lab_uv_level, 1)


func test_the_cheapest_purchase_is_the_lowest_next_price_across_open_floors_and_the_next_unlock() -> void:
	# Başlangıç: sulama 100 (satır başına), UV 200, dron 300, lab UV 400, 1. katı açma 500 -> en ucuz 100
	assert_eq(_service.cheapest_purchase_cost(), 100)

	for row: int in _farm.get_floor(0).rows:
		_service.buy_irrigation(0, row)  # tüm sulamalar bitti: en ucuz UV (200)

	assert_eq(_service.cheapest_purchase_cost(), 200, "sulama kalmadı, UV en ucuz")


func test_the_cheapest_purchase_ignores_maxed_out_and_locked_floor_equipment() -> void:
	for row: int in _farm.get_floor(0).rows:
		_service.buy_irrigation(0, row)
		_service.buy_uv_lamp(0, row)
		_service.buy_uv_lamp(0, row)  # UV 2 seviye de bitti
	for i: int in 3:
		_service.buy_drone(0)  # 3 dron bitti
	for i: int in 3:
		_service.buy_lab_uv()  # lab UV bitti

	# Kalan: yalnızca 1. katı açma (500); kilitli 1. katın donanımı sayılmaz, 2. kat önceki açılmadan sayılmaz
	assert_eq(_service.cheapest_purchase_cost(), 500)

	_service.unlock_floor(1)
	assert_true(_service.cheapest_purchase_cost() >= 100, "yeni katın donanımı artık sayılır")


func test_with_nothing_left_to_buy_the_cheapest_cost_is_minus_one() -> void:
	_wallet.add_credits(1000000)
	for index: int in _service.floor_defs.size():
		if index > 0:
			_service.unlock_floor(index)
		var floor_state: FloorState = _farm.get_floor(index)
		for row: int in floor_state.rows:
			_service.buy_irrigation(index, row)
			for level: int in 4:
				_service.buy_uv_lamp(index, row)
		for level: int in 6:
			_service.buy_drone(index)
	for level: int in 6:
		_service.buy_lab_uv()

	assert_eq(_service.cheapest_purchase_cost(), -1)


func test_the_lab_uv_room_is_the_cheapest_purchase_when_it_is_cheaper_than_the_next_floor() -> void:
	for row: int in _farm.get_floor(0).rows:
		_service.buy_irrigation(0, row)
		_service.buy_uv_lamp(0, row)
		_service.buy_uv_lamp(0, row)
	for i: int in 3:
		_service.buy_drone(0)

	# Kalan: lab UV odası (400) ve 1. katı açma (500)
	assert_eq(_service.cheapest_purchase_cost(), 400)


func test_a_maxed_item_checked_last_does_not_hide_cheaper_purchases() -> void:
	_wallet.add_credits(100000)
	_service.unlock_floor(1)
	_service.unlock_floor(2)
	var last_floor: int = _service.floor_defs.size() - 1
	for i: int in 3:
		_service.buy_drone(last_floor)  # taranan son kalem bitti (-1)

	assert_eq(_service.cheapest_purchase_cost(), 100, "sulama hâlâ en ucuz")


func test_only_the_next_floor_unlock_counts_even_if_a_farther_floor_would_be_cheaper() -> void:
	_service.floor_defs[2].unlock_cost = 50  # 2. kat, 1. kat açılmadan açılamaz
	for row: int in _farm.get_floor(0).rows:
		_service.buy_irrigation(0, row)
		_service.buy_uv_lamp(0, row)
		_service.buy_uv_lamp(0, row)
	for i: int in 3:
		_service.buy_drone(0)
	for i: int in 3:
		_service.buy_lab_uv()

	assert_eq(_service.cheapest_purchase_cost(), 500, "açılamayan 2. katın ucuz fiyatı sayılmaz")
