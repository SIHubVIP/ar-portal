extends Node
## Переходы между пространствами: город, личная база (отдельная инстанс-сцена), подземелья.
## Для каждой двери запоминается точка возврата.

const WORLD := "res://scenes/world/pogulyay_parking.tscn"
const BASE := "res://scenes/base/base.tscn"
const TITLE := "res://scenes/ui/title.tscn"

var return_scene := ""
var return_position := Vector3.ZERO


## Для проверки на ПК: -- --shot=user://shot.png [--shot-frames=90] снимает экран и выходит.
func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_take_shot.call_deferred(arg.trim_prefix("--shot="))


func _take_shot(path: String) -> void:
	var frames := 90
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-frames="):
			frames = int(arg.trim_prefix("--shot-frames="))
	for i in frames:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	print("SHOT ", ProjectSettings.globalize_path(path))
	get_tree().quit()


func go_to_world(at := Vector3.INF) -> void:
	if at != Vector3.INF:
		GameState.world_position = at
	GameState.world_scene = WORLD
	get_tree().change_scene_to_file(WORLD)


func go_to_base(from_scene: String, from_position: Vector3) -> void:
	return_scene = from_scene
	return_position = from_position
	GameState.world_scene = from_scene
	GameState.world_position = from_position
	SaveService.save_game()
	get_tree().change_scene_to_file(BASE)


func leave_base() -> void:
	var target := return_scene if return_scene != "" else WORLD
	GameState.world_position = return_position
	get_tree().change_scene_to_file(target)


func go_to_title() -> void:
	get_tree().change_scene_to_file(TITLE)
