extends TestCase
## WalletService: kredi ve itibar; bakiye asla negatife inmez, başarısız harcama hiçbir şeyi değiştirmez.

var _wallet: WalletService


func before_each() -> void:
	_wallet = WalletService.new()


func test_adding_credits_raises_the_balance_and_the_lifetime_total() -> void:
	_wallet.add_credits(50)
	_wallet.add_credits(25)

	assert_eq(_wallet.credits, 75)
	assert_eq(_wallet.total_earned, 75)


func test_spending_lowers_the_balance_but_not_the_lifetime_total() -> void:
	_wallet.add_credits(100)

	var ok: bool = _wallet.spend(30)

	assert_true(ok)
	assert_eq(_wallet.credits, 70)
	assert_eq(_wallet.total_earned, 100)


func test_a_purchase_beyond_the_balance_fails_and_changes_nothing() -> void:
	var announcements: Array[int] = []
	_wallet.credits_changed.connect(func(credits: int) -> void: announcements.append(credits))
	_wallet.add_credits(40)
	announcements.clear()

	var ok: bool = _wallet.spend(41)

	assert_false(ok)
	assert_eq(_wallet.credits, 40)
	assert_eq(announcements.size(), 0, "başarısız harcama olay yayınlamaz")


func test_spending_exactly_the_balance_or_zero_is_allowed_and_negative_is_refused() -> void:
	_wallet.add_credits(40)

	assert_true(_wallet.spend(0))
	assert_false(_wallet.spend(-5), "negatif harcama (para basma) reddedilir")
	assert_true(_wallet.spend(40))
	assert_eq(_wallet.credits, 0)


func test_non_positive_additions_are_ignored() -> void:
	_wallet.add_credits(0)
	_wallet.add_credits(-10)
	_wallet.add_reputation(-2)

	assert_eq(_wallet.credits, 0)
	assert_eq(_wallet.reputation, 0)


func test_balance_changes_are_announced_with_the_new_value() -> void:
	var announcements: Array[int] = []
	_wallet.credits_changed.connect(func(credits: int) -> void: announcements.append(credits))

	_wallet.add_credits(30)
	_wallet.spend(10)

	assert_eq(announcements, [30, 20] as Array[int])


func test_the_wallet_survives_a_round_trip() -> void:
	_wallet.add_credits(90)
	_wallet.add_reputation(4)
	var restored: WalletService = WalletService.new()

	restored.load_dict(JSON.parse_string(JSON.stringify(_wallet.to_dict())) as Dictionary)

	assert_eq(restored.credits, 90)
	assert_eq(restored.reputation, 4)
	assert_eq(restored.total_earned, 90)
