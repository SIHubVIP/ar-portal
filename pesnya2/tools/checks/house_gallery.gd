extends Node3D
## Витрина домов (0.11): BuildingKit — многоквартирные дома 2–5 этажей, общественный корпус,
## мелкие дома (частный сектор, мастерская, гараж, сарай), вечернее солнце.
## godot --path . res://tools/checks/house_gallery.tscn -- --shot=user://houses.png [--yaw=градусы]


func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.55, 0.7)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.62, 0.6, 0.64)
	env.environment.ambient_light_energy = 0.55
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment.glow_enabled = true
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28, -118, 0)
	sun.light_color = Color(1.0, 0.82, 0.62)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	add_child(sun)
	var ground := Kit.box(self, Vector3(200, 0.1, 200), Vector3(0, -0.05, 0), Color.WHITE)
	ground.material_override = Surfaces.slabs()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var x := -40.0
	for f in [2, 3, 4, 5]:
		var built := BuildingKit.house(30, 12, f, Vector3(x, 0, -10), f % 2 == 0, rng)
		var mi := MeshInstance3D.new()
		mi.mesh = built.mesh
		mi.position = Vector3(x, 0, -10)
		add_child(mi)
		x += 34.0
	var b := MeshInstance3D.new()
	b.mesh = BuildingKit.block(30, 16, 12, false, BuildingKit.PLASTER[0], Color(0.3, 0.3, 0.32))
	b.position = Vector3(-30, 0, 20)
	add_child(b)
	var kinds := [["cottage", 1, false], ["cottage", 2, true], ["workshop", 1, true], ["garage", 1, false], ["shed", 1, false]]
	for i in kinds.size():
		var k: Array = kinds[i]
		var m := MultiMesh.new()
		m.transform_format = MultiMesh.TRANSFORM_3D
		m.use_colors = true            # белый: иначе GL-рендер берёт COLOR из пустого буфера
		m.use_custom_data = true
		m.mesh = BuildingKit.unit(k[0], k[1], k[2], i)
		m.instance_count = 1
		var size := Vector3(10, 1, 9) if k[0] != "garage" and k[0] != "shed" else Vector3(4, 1, 6)
		m.set_instance_transform(0, Transform3D(Basis().scaled(size), Vector3(0 + i * 13.0, 0, 22)))
		m.set_instance_color(0, Color.WHITE)
		m.set_instance_custom_data(0, BuildingKit.small_wall_color("plaster" if not k[2] else "brick", rng))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = m
		add_child(mmi)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 90
	var yaw := 45.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--yaw="):
			yaw = float(arg.trim_prefix("--yaw="))
	cam.position = Vector3(0, 60, 0) + Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw))) * 60.0
	add_child(cam)
	cam.look_at(Vector3(0, 4, 5), Vector3.UP)
