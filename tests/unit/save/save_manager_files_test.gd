extends TestCase
## SaveManager: şifreli dosya, sağlama toplamı, atomik yazma, yedeğe düşme, bozuk dosya ve sürüm denetimi.

const TEST_PATH: String = "user://test_save_manager.dat"

var _saves: SaveManager


func before_each() -> void:
	_saves = SaveManager.new(TEST_PATH)
	_saves.delete_save()


func after_each() -> void:
	_saves.delete_save()


func _corrupt(file_path: String) -> void:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string("bozuk veri, şifreli dosya değil")
	file.close()


func test_a_saved_state_loads_back_with_a_recent_timestamp() -> void:
	var state: Dictionary = {"credits": 250, "list": [1, 2, 3], "nested": {"a": "b"}}

	var ok: bool = _saves.save(state)
	var loaded: Dictionary = _saves.load_state()

	assert_true(ok)
	assert_true(_saves.has_save())
	assert_eq((loaded["state"] as Dictionary)["credits"], 250.0, "JSON sayıları ondalık okunur")
	assert_eq(((loaded["state"] as Dictionary)["nested"] as Dictionary)["a"], "b")
	assert_between(Time.get_unix_time_from_system() - float(loaded["saved_unix"]), -1.0, 10.0, "yazılma zamanı yakın")


func test_the_file_on_disk_is_encrypted_and_not_readable_text() -> void:
	_saves.save({"secret_marker_credits": 99999})

	var raw: PackedByteArray = FileAccess.get_file_as_bytes(TEST_PATH)

	assert_true(raw.size() > 16)
	assert_false(raw.get_string_from_ascii().contains("secret_marker_credits"), "düz metin görünmemeli")
	assert_false(raw.get_string_from_ascii().contains("99999"))


func test_a_missing_save_loads_as_empty() -> void:
	assert_false(_saves.has_save())
	assert_true(_saves.load_state().is_empty())


func test_the_previous_save_is_kept_as_a_backup_and_used_when_the_main_file_is_corrupt() -> void:
	_saves.save({"generation": 1})
	_saves.save({"generation": 2})

	_corrupt(TEST_PATH)
	var loaded: Dictionary = _saves.load_state()

	assert_false(loaded.is_empty(), "yedeğe düşüldü")
	assert_eq((loaded["state"] as Dictionary)["generation"], 1.0, "yedek bir önceki kayıt")


func test_when_both_files_are_corrupt_the_result_is_empty_not_a_crash() -> void:
	_saves.save({"generation": 1})
	_saves.save({"generation": 2})
	_corrupt(TEST_PATH)
	_corrupt(TEST_PATH + ".bak")

	assert_true(_saves.load_state().is_empty())


func test_a_tampered_checksum_is_rejected() -> void:
	var payload: String = JSON.stringify({"version": SaveManager.SAVE_VERSION, "saved_unix": 1.0, "state": {"credits": 1}})
	var forged: String = JSON.stringify({"checksum": "0000", "payload": payload})
	var file: FileAccess = FileAccess.open_encrypted_with_pass(TEST_PATH, FileAccess.WRITE, _saves._key())
	file.store_string(forged)
	file.close()

	assert_true(_saves.load_state().is_empty(), "sağlama toplamı tutmayan kayıt reddedilir")


func test_a_save_from_another_version_is_ignored() -> void:
	var payload: String = JSON.stringify({"version": 999, "saved_unix": 1.0, "state": {"credits": 1}})
	var envelope: String = JSON.stringify({"checksum": payload.sha256_text(), "payload": payload})
	var file: FileAccess = FileAccess.open_encrypted_with_pass(TEST_PATH, FileAccess.WRITE, _saves._key())
	file.store_string(envelope)
	file.close()

	assert_true(_saves.load_state().is_empty(), "bilinmeyen sürüm okunmaz")


func test_a_failed_write_reports_false_and_keeps_the_old_save() -> void:
	_saves.save({"generation": 1})
	var broken: SaveManager = SaveManager.new("user://no_such_directory_xyz/save.dat")

	var ok: bool = broken.save({"generation": 2})

	assert_false(ok, "yazılamayan yol")
	assert_eq((_saves.load_state()["state"] as Dictionary)["generation"], 1.0, "başka yoldaki kayıt etkilenmez")


func test_deleting_removes_the_main_file_the_backup_and_any_temp_file() -> void:
	_saves.save({"a": 1})
	_saves.save({"a": 2})

	_saves.delete_save()

	assert_false(_saves.has_save())
	assert_false(FileAccess.file_exists(TEST_PATH + ".bak"))
	assert_false(FileAccess.file_exists(TEST_PATH + ".tmp"))


func test_a_wrong_key_cannot_read_the_file() -> void:
	_saves.save({"credits": 5})

	var file: FileAccess = FileAccess.open_encrypted_with_pass(TEST_PATH, FileAccess.READ, "yanlis-anahtar")

	assert_null(file, "farklı anahtarla açılamaz")


func test_a_lone_backup_still_counts_as_a_save_and_loads() -> void:
	_saves.save({"generation": 1})
	_saves.save({"generation": 2})
	DirAccess.remove_absolute(TEST_PATH)

	assert_false(FileAccess.file_exists(TEST_PATH), "ana dosya yok")
	assert_true(_saves.has_save(), "yedek tek başına kayıt sayılır")
	assert_eq((_saves.load_state()["state"] as Dictionary)["generation"], 1.0)

