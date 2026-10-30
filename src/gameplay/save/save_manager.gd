class_name SaveManager
extends RefCounted
## Şifreli kayıt dosyası: durum sözlüğünü JSON'a çevirir, SHA-256 sağlama toplamıyla mühürler ve AES ile şifreli dosyaya yazar
## (`FileAccess.open_encrypted_with_pass`). Yazma ATOMİKTİR: önce geçici dosyaya yazılır, doğrulanır, sonra yerine taşınır;
## önceki kayıt `.bak` olarak saklanır. Okuma, bozuk/şifresi çözülemeyen/sağlaması tutmayan dosyada yedeğe düşer.
## Oyun sınıflarını BİLMEZ: yalnızca sözlük okur/yazar (kolay test edilir).
##
## DÜRÜST SINIR: anahtar uygulamanın içindedir. Şifreleme kaydı elle düzenlemeye karşı CAYDIRICIDIR, gerçek güvenlik değildir.
##
## Uygular: design/game-brief.md, FAZ 5 "JSON tabanlı şifreli SaveManager".
##
## [codeblock]
## var saves: SaveManager = SaveManager.new()
## saves.save({"credits": 5})
## var loaded: Dictionary = saves.load_state()   # {"state": {...}, "saved_unix": 1.7e9} ya da {} (kayıt yok/bozuk)
## [/codeblock]

const SAVE_VERSION: int = 1
const DEFAULT_PATH: String = "user://floralab_save.dat"
## Uygulamaya özgü sabit tuz (anahtar türetmek için); bkz. sınıf açıklamasındaki dürüst sınır.
const _KEY_SALT: String = "FloraLab:CyberHarvest:save:v1"

## Kayıt dosyasının yolu.
var path: String = DEFAULT_PATH


func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path


## Durumu yazar. Başarılıysa true; yazma/taşıma hatasında eski kayda dokunmaz ve false döner.
func save(state: Dictionary) -> bool:
	var payload: String = JSON.stringify({"version": SAVE_VERSION, "saved_unix": Time.get_unix_time_from_system(), "state": state})
	var envelope: String = JSON.stringify({"checksum": payload.sha256_text(), "payload": payload})
	var temp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open_encrypted_with_pass(temp_path, FileAccess.WRITE, _key())
	if file == null:
		push_warning("SaveManager: geçici kayıt dosyası açılamadı: %s" % temp_path)
		return false
	file.store_string(envelope)
	file.close()
	if _read_envelope(temp_path).is_empty():
		DirAccess.remove_absolute(temp_path)
		push_warning("SaveManager: yazılan kayıt doğrulanamadı, eski kayıt korundu.")
		return false
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
	return DirAccess.rename_absolute(temp_path, path) == OK


## Kaydı okur: {"state": Dictionary, "saved_unix": float}. Kayıt yoksa ya da ana dosya ve yedek bozuksa boş sözlük.
func load_state() -> Dictionary:
	for candidate: String in [path, path + ".bak"]:
		var parsed: Dictionary = _read_envelope(candidate)
		if not parsed.is_empty():
			return parsed
	return {}


func has_save() -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")


## Kayıt dosyalarını siler (yeni oyun / sıfırlama).
func delete_save() -> void:
	for candidate: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(candidate)


## Tek bir dosyayı okur, şifresini çözer, sağlamasını ve sürümünü denetler. Geçersizse boş sözlük.
func _read_envelope(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var file: FileAccess = FileAccess.open_encrypted_with_pass(file_path, FileAccess.READ, _key())
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var envelope: Variant = JSON.parse_string(text)
	if not envelope is Dictionary:
		return {}
	var payload: String = String((envelope as Dictionary).get("payload", ""))
	if payload == "" or payload.sha256_text() != String((envelope as Dictionary).get("checksum", "")):
		return {}
	var content: Variant = JSON.parse_string(payload)
	if not content is Dictionary or int((content as Dictionary).get("version", 0)) != SAVE_VERSION:
		return {}
	var state: Variant = (content as Dictionary).get("state", null)
	if not state is Dictionary:
		return {}
	return {"state": state, "saved_unix": float((content as Dictionary).get("saved_unix", 0.0))}


func _key() -> String:
	return _KEY_SALT.sha256_text()
