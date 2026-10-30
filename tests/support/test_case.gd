class_name TestCase
extends RefCounted
## Geçici birim test tabanı. gdUnit4 kurulana kadar `tests/support/test_runner.gd` ile birlikte kullanılır
## (bkz. tests/README.md). Doğrulamalar hatayı kaydeder ve testi durdurmaz; koşucu sonunda raporlar.
##
## Kullanım:
## [codeblock]
## extends TestCase
##
## func test_two_plus_two_is_four() -> void:
##     assert_eq(2 + 2, 4)
## [/codeblock]
##
## Dosya adı `[sistem]_[özellik]_test.gd`, test adı `test_[senaryo]_[beklenen]` olmalıdır
## (.claude/rules/test-standards.md).

## Koşucu tarafından atanır; Node gerektiren testler için sahne ağacı.
var tree: SceneTree
## Bu testte yapılan doğrulama sayısı. Sıfırsa koşucu testi "doğrulama yok" diye başarısız sayar.
var assertion_count: int = 0
## Başarısız doğrulamaların açıklamaları.
var failures: Array[String] = []

var _owned_nodes: Array[Node] = []


## Her testten önce çağrılır. Alt sınıf geçersiz kılabilir.
func before_each() -> void:
	pass


## Her testten sonra çağrılır. Alt sınıf geçersiz kılabilir.
func after_each() -> void:
	pass


## Node'u sahne ağacının köküne ekler ve test bitince otomatik serbest bırakılmasını sağlar.
func add_to_tree(node: Node) -> Node:
	tree.root.add_child(node)
	_owned_nodes.append(node)
	return node


## Koşucu tarafından, her testten sonra çağrılır.
func free_owned_nodes() -> void:
	for node: Node in _owned_nodes:
		if is_instance_valid(node):
			node.free()
	_owned_nodes.clear()


func fail(message: String) -> void:
	assertion_count += 1
	failures.append(message)


func assert_true(condition: bool, message: String = "") -> void:
	assertion_count += 1
	if not condition:
		failures.append("true bekleniyordu. %s" % message)


func assert_false(condition: bool, message: String = "") -> void:
	assertion_count += 1
	if condition:
		failures.append("false bekleniyordu. %s" % message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	assertion_count += 1
	if actual != expected:
		failures.append("beklenen %s, gelen %s. %s" % [str(expected), str(actual), message])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	assertion_count += 1
	if actual == unexpected:
		failures.append("%s beklenmiyordu. %s" % [str(unexpected), message])


func assert_almost_eq(actual: float, expected: float, tolerance: float, message: String = "") -> void:
	assertion_count += 1
	if absf(actual - expected) > tolerance:
		failures.append("beklenen %s ± %s, gelen %s. %s" % [str(expected), str(tolerance), str(actual), message])


func assert_between(value: float, low: float, high: float, message: String = "") -> void:
	assertion_count += 1
	if value < low or value > high:
		failures.append("%s, [%s, %s] aralığında olmalıydı. %s" % [str(value), str(low), str(high), message])


func assert_not_null(value: Variant, message: String = "") -> void:
	assertion_count += 1
	if value == null:
		failures.append("null olmaması gerekiyordu. %s" % message)


func assert_null(value: Variant, message: String = "") -> void:
	assertion_count += 1
	if value != null:
		failures.append("null bekleniyordu, gelen %s. %s" % [str(value), message])
