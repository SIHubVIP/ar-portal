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
	if OS.get_cmdline_user_args().has("--stats"):
		print_stats()
	get_tree().quit()


## Нагрузка кадра для оптимизации: вызовы отрисовки, объекты, треугольники, свет, частицы.
func print_stats() -> void:
	var root := get_tree().current_scene
	var count := func(cls: String) -> int: return root.find_children("*", cls, true, false).size() if root else 0
	print("STATS draw_calls=%d objects=%d primitives=%d omni=%d spot=%d particles=%d meshes=%d labels=%d fps=%d" % [
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			count.call("OmniLight3D"), count.call("SpotLight3D"), count.call("GPUParticles3D"),
			count.call("MeshInstance3D"), count.call("Label3D"), Engine.get_frames_per_second()])
	if OS.get_cmdline_user_args().has("--stats-detail") and root:
		var tally := {}
		for n in root.find_children("*", "GeometryInstance3D", true, false):
			var tris := 0
			if n is MeshInstance3D and n.mesh:
				tris = n.mesh.get_faces().size() / 3
			elif n is MultiMeshInstance3D and n.multimesh and n.multimesh.mesh:
				tris = n.multimesh.mesh.get_faces().size() / 3 * n.multimesh.instance_count
			var top: Node = n
			while top.get_parent() != root:
				top = top.get_parent()
			var key := String(top.name).left(14) if top.get_child_count() > 0 else top.get_class()
			var t: Array = tally.get(key, [0, 0])
			tally[key] = [t[0] + 1, t[1] + tris]
		var keys := tally.keys()
		keys.sort_custom(func(a, b): return tally[a][1] > tally[b][1])
		for k in keys.slice(0, 15):
			print("STATS  %s: %d узлов, %d треугольников" % [k, tally[k][0], tally[k][1]])


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
