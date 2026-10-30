extends TestCase
## Statik tip güvenliği (proje kuralı): `src/` altındaki her değişken, parametre ve dönüş değeri tipli olmalı.
## Bunu insan disiplinine bırakmayız: project.godot'ta `untyped_declaration` HATA düzeyindedir (2), yani tipsiz bir
## bildirim betiği derlenemez yapar. Bu test hem ayarın açık olduğunu hem de `src/` altındaki her betiğin
## derlendiğini doğrular; birinin ayarı gevşetmesi ya da tipsiz kod eklemesi testi kırar.
##
## Uygular: design/game-brief.md, "Statik tip güvenliği" mimari kuralı (proje sahibi konsepti).

const SOURCE_ROOT: String = "res://src"
const UNTYPED_SETTING: String = "debug/gdscript/warnings/untyped_declaration"
## Godot'ta uyarı düzeyleri: 0 yok say, 1 uyar, 2 hata.
const LEVEL_ERROR: int = 2


func test_untyped_declarations_are_configured_as_errors() -> void:
	var level: int = int(ProjectSettings.get_setting(UNTYPED_SETTING, 0))

	assert_eq(level, LEVEL_ERROR, "project.godot [debug] gdscript/warnings/untyped_declaration=2 olmalı")


func test_every_source_script_compiles_with_static_typing_enforced() -> void:
	# Arrange
	var paths: Array[String] = []
	_collect_scripts(SOURCE_ROOT, paths)

	# Assert
	assert_true(paths.size() > 0, "src/ altında betik bulunmalı")
	for path: String in paths:
		var script: Script = load(path) as Script
		assert_true(script != null and script.can_instantiate(), "%s derlenemedi: tipsiz bir bildirim olabilir" % path)


func _collect_scripts(directory: String, into: Array[String]) -> void:
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.ends_with(".gd"):
			into.append(directory.path_join(file_name))
	for sub_directory: String in DirAccess.get_directories_at(directory):
		_collect_scripts(directory.path_join(sub_directory), into)
