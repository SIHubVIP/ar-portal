class_name HeroDoll
extends SubViewportContainer
## Кукла героя для инвентаря: 3D-модель класса (с учётом пола) на подсвеченном постаменте,
## медленно крутится, пальцем можно повернуть. У классов без модели — портрет.
## Живёт в своём мире и работает на паузе (инвентарь открывается поверх остановленной игры).

var _pivot: Node3D
var _drag := false
var _spin := 0.6


func _ready() -> void:
	stretch = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.5, 0.6)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	vp.add_child(env)
	var cam := Camera3D.new()
	cam.fov = 32.0
	cam.position = Vector3(0, 1.25, 4.6)
	cam.rotation_degrees.x = -6.0
	vp.add_child(cam)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 30, 0)
	key.light_energy = 1.3
	key.light_color = Color(1, 0.9, 0.8)
	vp.add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-1.2, 2.2, -1.5)
	rim.light_color = Color(1, 0.35, 0.75)
	rim.light_energy = 2.5
	rim.omni_range = 5.0
	vp.add_child(rim)
	var under := OmniLight3D.new()
	under.position = Vector3(0, 0.3, 0.8)
	under.light_color = Color(1, 0.75, 0.3)
	under.light_energy = 0.6
	under.omni_range = 2.5
	vp.add_child(under)
	# постамент: тёмная шайба с золотым ободом
	Kit.cylinder(vp, 0.75, 0.12, Vector3(0, -0.06, 0), Color(0.16, 0.13, 0.14))
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.74
	torus.outer_radius = 0.8
	ring.mesh = torus
	ring.scale.y = 0.5
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(1, 0.75, 0.25)
	rm.emission_enabled = true
	rm.emission = Color(1, 0.7, 0.2)
	rm.emission_energy_multiplier = 1.2
	ring.material_override = rm
	vp.add_child(ring)
	_pivot = Node3D.new()
	_pivot.rotation_degrees.y = 20.0
	vp.add_child(_pivot)
	var cid := GameState.class_id if GameState.class_id != "" else "CLASS_1"
	var path: String = Player.MODELS.get(cid + ("_f" if GameState.gender == "f" else ""), Player.MODELS.get(cid, ""))
	if path != "" and ResourceLoader.exists(path):
		var model: Node3D = load(path).instantiate()
		_pivot.add_child(model)
		var anim: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
		if anim and anim.has_animation("Idle"):
			anim.process_mode = Node.PROCESS_MODE_ALWAYS
			anim.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
			anim.play("Idle")
	else:
		var face := Portrait.new()
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(face)
		face.set_spec({"kind": "hero"})


func _process(delta: float) -> void:
	if not _drag and _pivot:
		_pivot.rotation.y += _spin * delta * 0.5


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		_drag = event.pressed
	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and _drag and _pivot:
		_pivot.rotation.y += event.relative.x * 0.012
		_spin = signf(event.relative.x) if event.relative.x != 0.0 else _spin
