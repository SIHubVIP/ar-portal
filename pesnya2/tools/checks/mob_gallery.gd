extends Node3D
## Витрина: десять уличных мобов и прохожие в ряд — проверить модели одним снимком.
## godot --path . res://tools/checks/mob_gallery.tscn -- --shot=user://mobs.png


func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.27, 0.32)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)
	Kit.box(self, Vector3(40, 0.1, 12), Vector3(0, -0.05, 0), Color(0.35, 0.33, 0.32))
	var ids := MobTypes.PROFILES.keys()
	for i in ids.size():
		var e := EnemyDrone.new()
		e.mob_type = ids[i]
		e.position = Vector3(-11.25 + i * 2.5, 0, 0)
		add_child(e)
		e.process_mode = Node.PROCESS_MODE_DISABLED
		Kit.label(self, String(MobTypes.PROFILES[ids[i]].name), e.position + Vector3(0, 2.8 + (i % 2) * 0.4, 0), 28, Color.WHITE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 8:
		var m := NpcModel.make(NpcModel.random_look(rng))
		m.position = Vector3(-8.0 + i * 2.2, 0, 3.5)
		add_child(m)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 3.5, 11)
	cam.fov = 70
	add_child(cam)
	cam.look_at(Vector3(0, 1.0, 1), Vector3.UP)
