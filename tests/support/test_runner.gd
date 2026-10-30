extends SceneTree
## Geçici başsız test koşucusu. gdUnit4 kurulana kadar kullanılır (bkz. tests/README.md).
##
## Kullanım (proje kökünden; önce `godot --headless --path . --import` ile sınıf önbelleği kurulmalı):
## [codeblock]
## godot --headless --path . -s res://tests/support/test_runner.gd
## godot --headless --path . -s res://tests/support/test_runner.gd -- --filter=genetics
## [/codeblock]
## Ya da sarmalayıcıyla: `bash tools/run_tests.sh [--filter=...]`.
##
## Çıkış kodları gdUnit4'ünkilerle aynı anlamdadır:
##   0   tüm testler geçti
##   100 en az bir test başarısız
##   105 bir test dosyası yüklenemedi (ayrıştırma hatası)
##   2   hiç test bulunamadı (sıfır test bir "geçti" değildir)

const TEST_ROOTS: Array[String] = ["res://tests/unit", "res://tests/integration"]
const TEST_FILE_SUFFIX: String = "_test.gd"
const TEST_METHOD_PREFIX: String = "test_"
const EXIT_PASSED: int = 0
const EXIT_NO_TESTS: int = 2
const EXIT_FAILED: int = 100
const EXIT_PARSE_ERROR: int = 105


func _initialize() -> void:
	# Ağaç ilk kareye kadar "çalışmaya başlamış" sayılmaz: `add_child` ile eklenen düğümlerin `_ready()`'si
	# ancak ondan sonra tetiklenir. Node gerektiren (entegrasyon) testler için bir kare beklenir.
	await process_frame
	var filter: String = _read_filter()
	var files: Array[String] = []
	for root: String in TEST_ROOTS:
		_collect_test_files(root, files)
	files.sort()

	var passed: int = 0
	var failed: int = 0
	var load_errors: int = 0

	for path: String in files:
		if filter != "" and not path.contains(filter):
			continue
		var script: Script = load(path) as Script
		if script == null or not script.can_instantiate():
			printerr("[LOAD ERROR] ", path)
			load_errors += 1
			continue
		var method_names: Array[String] = _collect_test_methods(script)
		for method_name: String in method_names:
			var outcome: Dictionary = await _run_one(script, method_name)
			var label: String = "%s :: %s" % [path, method_name]
			if outcome["failures"].is_empty():
				passed += 1
				print("[PASS] %s (%d doğrulama)" % [label, outcome["assertions"]])
			else:
				failed += 1
				print("[FAIL] %s" % label)
				for message: String in outcome["failures"]:
					print("         - ", message)

	print("")
	print("Testler: %d geçti, %d başarısız, %d dosya yüklenemedi" % [passed, failed, load_errors])
	if load_errors > 0:
		quit(EXIT_PARSE_ERROR)
	elif failed > 0:
		quit(EXIT_FAILED)
	elif passed == 0:
		print("Hiç test bulunamadı. Bu bir geçti sayılmaz.")
		quit(EXIT_NO_TESTS)
	else:
		quit(EXIT_PASSED)


## Tek bir testi, her seferinde taze bir örnekle çalıştırır. Sözlük döndürür: failures, assertions.
func _run_one(script: Script, method_name: String) -> Dictionary:
	var test_case: TestCase = script.new() as TestCase
	if test_case == null:
		return {"failures": ["Betik TestCase'ten türemiyor."], "assertions": 0}
	test_case.tree = self
	test_case.before_each()
	await test_case.call(method_name)
	test_case.after_each()
	test_case.free_owned_nodes()
	var failures: Array[String] = test_case.failures.duplicate()
	if failures.is_empty() and test_case.assertion_count == 0:
		failures.append("Hiç doğrulama yapılmadı. Hata verip sessizce çıkan bir test geçmiş sayılmaz.")
	return {"failures": failures, "assertions": test_case.assertion_count}


func _collect_test_methods(script: Script) -> Array[String]:
	var names: Array[String] = []
	for method: Dictionary in script.get_script_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with(TEST_METHOD_PREFIX):
			names.append(method_name)
	names.sort()
	return names


func _collect_test_files(directory: String, into: Array[String]) -> void:
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.ends_with(TEST_FILE_SUFFIX):
			into.append(directory.path_join(file_name))
	for sub_directory: String in DirAccess.get_directories_at(directory):
		_collect_test_files(directory.path_join(sub_directory), into)


func _read_filter() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--filter="):
			return argument.substr("--filter=".length())
	return ""
