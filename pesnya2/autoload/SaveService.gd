extends Node
## Сохранение user://save: версия схемы, контрольная сумма, временный файл,
## замена после проверки и запасная копия. Битое сохранение не удаляется.

const SCHEMA_VERSION := 1
const DIR := "user://save"
const MAIN := "user://save/slot0.json"
const BACKUP := "user://save/slot0.bak.json"
const TMP := "user://save/slot0.tmp"

var last_error := ""


func has_save() -> bool:
	return FileAccess.file_exists(MAIN) or FileAccess.file_exists(BACKUP)


func save_game() -> bool:
	var payload := {
		"schema_version": SCHEMA_VERSION,
		"game_version": ProjectSettings.get_setting("application/config/version", ""),
		"saved_at": Time.get_unix_time_from_system(),
		"state": GameState.to_dict(),
		"quests": QuestService.to_dict(),
	}
	var body := JSON.stringify(payload)
	var doc := JSON.stringify({"checksum": body.sha256_text(), "body": body})
	DirAccess.make_dir_recursive_absolute(DIR)
	if not _write(TMP, doc) or read_verified(TMP).is_empty():
		last_error = "не удалось записать временный файл"
		return false
	# Прежнее сохранение становится запасным, только если оно целое.
	if FileAccess.file_exists(MAIN) and not read_verified(MAIN).is_empty():
		DirAccess.copy_absolute(MAIN, BACKUP)
	if FileAccess.file_exists(MAIN):
		DirAccess.remove_absolute(MAIN)
	if DirAccess.rename_absolute(TMP, MAIN) != OK:
		last_error = "не удалось заменить сохранение"
		return false
	return true


func load_game() -> bool:
	for path in [MAIN, BACKUP]:
		var payload := read_verified(path)
		if payload.is_empty():
			continue
		payload = migrate(payload)
		if payload.is_empty():
			continue
		GameState.from_dict(payload.state)
		QuestService.from_dict(payload.quests)
		if path == BACKUP:
			push_warning("SaveService: основное сохранение повреждено, загружена запасная копия")
		return true
	last_error = "нет целого сохранения"
	return false


## Возвращает разобранный payload или {} при битом файле / несовпадении суммы.
func read_verified(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var doc = JSON.parse_string(f.get_as_text())
	if not doc is Dictionary or not doc.has("body") or not doc.has("checksum"):
		return {}
	if String(doc.body).sha256_text() != doc.checksum:
		return {}
	var payload = JSON.parse_string(doc.body)
	return payload if payload is Dictionary else {}


## Миграции схемы. Сейчас схема одна; новые версии добавляются здесь по шагам.
func migrate(payload: Dictionary) -> Dictionary:
	var v := int(payload.get("schema_version", 0))
	if v > SCHEMA_VERSION:
		last_error = "сохранение от более новой версии игры"
		return {}
	if not payload.has("state") or not payload.has("quests"):
		return {}
	return payload


func _write(path: String, text: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.flush()
	return true
