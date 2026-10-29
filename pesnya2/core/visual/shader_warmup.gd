class_name ShaderWarmup
extends RefCounted
## Прогрев шейдеров (0.9): материалы, которые появляются только посреди игры (вырез домов,
## вспышка удара, круги атак, метки мобов), один раз рисуются крошечными квадратами у героя
## в первые кадры. Иначе телефон компилирует их в момент первого удара — это и есть фриз.

static func run(world: Node3D, at: Vector3, materials: Array) -> void:
	var holder := Node3D.new()
	holder.name = "ShaderWarmup"
	holder.position = at + Vector3(0, 0.05, 0)
	world.add_child(holder)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.02, 0.02)
	var i := 0
	for m in materials:
		if m == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.material_override = m
		mi.position = Vector3(0.03 * i, 0, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
		i += 1
	# три кадра, чтобы конвейер успел собраться, потом прибрать
	await world.get_tree().process_frame
	await world.get_tree().process_frame
	await world.get_tree().process_frame
	holder.queue_free()
