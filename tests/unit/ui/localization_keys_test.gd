extends TestCase
## Yerelleştirme: (1) kodda kullanılan her çeviri anahtarı tabloda var, (2) her satır iki dilde dolu ve biçim işaretçileri (%d, %s) iki
## dilde aynı, (3) oyun verisindeki (bitki parçası, mutasyon, olay, sipariş, kat, ekipman) her metin anahtarı iki dilde çözülüyor,
## (4) oyuncuya görünen hiçbir metinde cihazın yedek fontuna bağımlı sembol glifi yok, (5) paketlenen yazı tipleri tüm metin karakterlerini
## içeriyor (yazı tipi hatası geri gelmesin).

const CSV_PATHS: Array[String] = ["res://assets/i18n/strings.csv", "res://assets/i18n/content.csv"]
const SCAN_ROOTS: Array[String] = ["res://src/ui", "res://src/gameplay"]
const LANGUAGES: Array[String] = ["tr", "en"]
## Yedek fonta bağımlı glifler: oyuncuya görünen metinde YASAK (ikon kullanılır). "×", "·" ve "…" yazı tiplerinde doğrulanır (aşağıdaki font testi)'dedir, serbest.
const FORBIDDEN_GLYPHS: String = "◆▲▼★✓▬◀▶•≥≈→←↑↓"


## Tüm tablolar: anahtar -> {"tr": metin, "en": metin}.
func _tables() -> Dictionary:
	var table: Dictionary = {}
	for path: String in CSV_PATHS:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		assert_not_null(file, "çeviri tablosu açılabilmeli: %s" % path)
		if file == null:
			continue
		var header: PackedStringArray = file.get_csv_line()
		assert_eq(header, PackedStringArray(["keys", "tr", "en"]), "başlık: %s" % path)
		while not file.eof_reached():
			var row: PackedStringArray = file.get_csv_line()
			if row.size() == 1 and row[0] == "":
				continue
			assert_eq(row.size(), 3, "satır tam üç sütun: %s" % str(row))
			assert_false(table.has(row[0]), "yinelenen anahtar: %s" % row[0])
			table[row[0]] = {"tr": row[1], "en": row[2]}
	return table


func _collect_scripts(directory: String, into: Array[String]) -> void:
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.ends_with(".gd"):
			into.append(directory.path_join(file_name))
	for sub_directory: String in DirAccess.get_directories_at(directory):
		_collect_scripts(directory.path_join(sub_directory), into)


## Biçim işaretçilerinin sıralı dizisi ("%d %s %%" -> ["%d", "%s"]); "%%" sayılmaz.
func _specifiers(text: String) -> Array[String]:
	var found: Array[String] = []
	var pattern: RegEx = RegEx.new()
	pattern.compile("%%|%[-+0-9.]*[dsf]")
	for match: RegExMatch in pattern.search_all(text):
		if match.get_string() != "%%":
			found.append(match.get_string())
	return found


func test_every_translation_key_used_in_code_exists_in_the_tables() -> void:
	var table: Dictionary = _tables()
	var pattern: RegEx = RegEx.new()
	pattern.compile("\"((?:ERR|MSG|HINT|TAB|TOAST|SET|HUD|LAB|DEX|UPG|FARM|MARKET|ORDER|OFFLINE|GENE|BTN|FX|HELP|RARITY|GOAL|TUT|FLORA|CREDITS)_[A-Z0-9_]+)\"")
	var scripts: Array[String] = []
	for root: String in SCAN_ROOTS:
		_collect_scripts(root, scripts)

	var used: int = 0
	for path: String in scripts:
		var text: String = FileAccess.get_file_as_string(path)
		for match: RegExMatch in pattern.search_all(text):
			used += 1
			var key: String = match.get_string(1)
			assert_true(table.has(key), "%s: çeviri anahtarı tabloda yok: %s" % [path, key])
	assert_true(used > 20, "kodda yeterince çeviri anahtarı kullanılmalı (%d)" % used)
	for i: int in GameSettings.TEXT_SCALES.size():
		assert_true(table.has("SET_SIZE_%d" % i), "yazı boyutu basamağı %d çevirisi" % i)
	for i: int in 4:
		assert_true(table.has("RARITY_%d" % i), "nadirlik %d çevirisi" % i)


func test_every_row_is_filled_in_both_languages_with_matching_format_specifiers() -> void:
	var table: Dictionary = _tables()

	for key: String in table.keys():
		var row: Dictionary = table[key] as Dictionary
		for language: String in LANGUAGES:
			assert_true(String(row[language]).strip_edges() != "", "boş çeviri: %s [%s]" % [key, language])
		assert_eq(_specifiers(String(row["tr"])), _specifiers(String(row["en"])), "biçim işaretçileri iki dilde aynı olmalı: %s" % key)
	assert_true(table.size() > 200, "tablo beklenen büyüklükte (%d)" % table.size())


func test_no_player_visible_text_uses_a_fallback_dependent_symbol_glyph() -> void:
	var table: Dictionary = _tables()
	for key: String in table.keys():
		for language: String in LANGUAGES:
			for glyph: String in FORBIDDEN_GLYPHS:
				assert_false(String(table[key][language]).contains(glyph), "%s [%s] yasak glif içeriyor: %s" % [key, language, glyph])

	var scripts: Array[String] = []
	for root: String in SCAN_ROOTS:
		_collect_scripts(root, scripts)
	for path: String in scripts:
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			var code: String = line.split("#")[0]  # yorumlar serbest
			for glyph: String in FORBIDDEN_GLYPHS:
				assert_false(code.contains(glyph), "%s: kodda yasak sembol glifi: %s" % [path, line.strip_edges()])


func test_game_data_text_keys_resolve_in_both_languages() -> void:
	var catalog: GameCatalog = load("res://assets/data/game_catalog.tres") as GameCatalog
	var table: Dictionary = _tables()
	var keys: Array[String] = []
	for part: PlantPartDef in catalog.ruleset.parts:
		keys.append(part.display_name)
	for mutation: MutationDef in catalog.ruleset.mutations:
		keys.append(mutation.display_name)
	for seed_gene: PlantGene in catalog.starter_seeds:
		keys.append(seed_gene.display_name)
	for floor_def: FloorDef in catalog.floors:
		keys.append(floor_def.display_name)
	for equipment: EquipmentDef in catalog.equipment:
		keys.append(equipment.display_name)
		keys.append(equipment.description)
	for event_def: MarketEventDef in catalog.market_events:
		keys.append(event_def.headline)
		keys.append(event_def.body)
	for template: OrderTemplateDef in catalog.order_templates:
		keys.append(template.title)
		for customer: String in template.customers:
			keys.append(customer)

	assert_true(keys.size() > 60, "veri anahtarları toplandı (%d)" % keys.size())
	for key: String in keys:
		assert_true(table.has(key), "veri metni çeviri tablosunda yok: %s" % key)


func test_the_bundled_fonts_contain_every_character_the_game_text_uses() -> void:
	var table: Dictionary = _tables()
	var body: Font = UiFonts.body(UiTokens.WEIGHT_REGULAR)
	var display: Font = UiFonts.display(UiTokens.WEIGHT_DISPLAY)
	var missing: Dictionary = {}
	for key: String in table.keys():
		for language: String in LANGUAGES:
			for character: String in String(table[key][language]):
				if character == "\n" or character == "\r":
					continue
				if not body.has_char(character.unicode_at(0)) or not display.has_char(character.unicode_at(0)):
					missing[character] = key
	assert_true(missing.is_empty(), "yazı tipinde olmayan karakterler (karakter: ilk görüldüğü anahtar): %s" % str(missing))
	# Türkçenin ayırt edici harfleri
	for character: String in "İıĞğŞşÇçÖöÜü":
		assert_true(body.has_char(character.unicode_at(0)) and display.has_char(character.unicode_at(0)), "Türkçe harf yazı tiplerinde: %s" % character)
