extends TestCase
## Yerelleştirme: `src/ui` ve `src/gameplay` altındaki her `tr("ANAHTAR")` çağrısının anahtarı çeviri tablosunda
## (assets/i18n/strings.csv) bulunmalı; yoksa oyuncu ham anahtarı görür. Tablodaki her satır tam iki sütunludur.

const CSV_PATH: String = "res://assets/i18n/strings.csv"
const SCAN_ROOTS: Array[String] = ["res://src/ui", "res://src/gameplay"]


func _csv_keys() -> Dictionary:
	var keys: Dictionary = {}
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_not_null(file, "çeviri tablosu açılabilmeli")
	if file == null:
		return keys
	var header: PackedStringArray = file.get_csv_line()
	assert_eq(header[0], "keys", "ilk sütun anahtar")
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue
		assert_eq(row.size(), header.size(), "satır sütun sayısı tutarlı: %s" % str(row))
		keys[row[0]] = row[1] if row.size() > 1 else ""
	return keys


func _collect_scripts(directory: String, into: Array[String]) -> void:
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.ends_with(".gd"):
			into.append(directory.path_join(file_name))
	for sub_directory: String in DirAccess.get_directories_at(directory):
		_collect_scripts(directory.path_join(sub_directory), into)


func test_every_translation_key_used_in_code_exists_in_the_table() -> void:
	var keys: Dictionary = _csv_keys()
	var pattern: RegEx = RegEx.new()
	pattern.compile("\\btr\\(&?\"([A-Z][A-Z0-9_]+)\"\\)")
	var scripts: Array[String] = []
	for root: String in SCAN_ROOTS:
		_collect_scripts(root, scripts)

	var used: int = 0
	for path: String in scripts:
		var text: String = FileAccess.get_file_as_string(path)
		for match: RegExMatch in pattern.search_all(text):
			used += 1
			var key: String = match.get_string(1)
			assert_true(keys.has(key), "%s: çeviri anahtarı tabloda yok: %s" % [path, key])
	assert_true(used > 0, "kodda en az bir tr() anahtarı kullanılmalı")


func test_no_translation_value_is_empty() -> void:
	var keys: Dictionary = _csv_keys()

	for key: String in keys.keys():
		assert_true(String(keys[key]).strip_edges() != "", "boş çeviri: %s" % key)
