class_name LampLights
extends Node3D
## Свет фонарей района (0.10): в районе сотни фонарей, а настоящий источник света дорог
## (на телефоне — не больше 8 на предмет). Поэтому у каждого фонаря светится колпак и пятно
## на земле, а LIGHTS настоящих OmniLight3D перебегают к ближайшим к герою фонарям и
## плавно разгораются там.

const LIGHTS := 6
const REACH_M := 38.0
const FADE_S := 0.35

var player: Node3D
var _lights: Array[OmniLight3D] = []
var _targets: Array[Vector3] = []
var _tick := 0.0


func _ready() -> void:
	name = "LampLights"
	set_meta("map_skip", true)
	for i in LIGHTS:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.76, 0.48)
		l.omni_range = 12.0
		l.omni_attenuation = 1.2
		l.light_energy = 0.0
		l.shadow_enabled = false
		l.visible = false
		add_child(l)
		_lights.append(l)
		_targets.append(Vector3.INF)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.25
		_pick()
	for i in LIGHTS:
		var l := _lights[i]
		var want := 0.0 if _targets[i] == Vector3.INF else 1.9
		if _targets[i] != Vector3.INF and l.position.distance_to(_targets[i]) > 0.1:
			# свет гаснет на старом месте и загорается на новом
			l.light_energy = move_toward(l.light_energy, 0.0, delta * 1.9 / FADE_S)
			if l.light_energy <= 0.0:
				l.position = _targets[i]
		else:
			l.light_energy = move_toward(l.light_energy, want, delta * 1.9 / FADE_S)
		l.visible = l.light_energy > 0.01


## Ближайшие к герою фонари загруженных участков; уже горящие свет не перескакивает.
func _pick() -> void:
	var hero := player.global_position
	var near: Array = []
	for pts: PackedVector3Array in DistrictDressing.lamp_points.values():
		for p in pts:
			var d := (p - hero).length()
			if d < REACH_M:
				near.append([d, p])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var chosen: Array[Vector3] = []
	for i in mini(LIGHTS, near.size()):
		chosen.append(near[i][1])
	# держим свет, который уже стоит у одного из выбранных фонарей
	var free: Array[int] = []
	for i in LIGHTS:
		var idx := chosen.find(_targets[i])
		if idx >= 0:
			chosen.remove_at(idx)
		else:
			free.append(i)
	for i in free:
		_targets[i] = chosen.pop_front() if not chosen.is_empty() else Vector3.INF
