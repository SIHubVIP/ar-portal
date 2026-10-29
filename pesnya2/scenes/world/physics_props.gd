class_name PhysicsProps
extends Node3D
## Физические мелочи вокруг героя (0.10): точки урн, конусов, коробок и покрышек знает
## обстановка участков (DistrictDressing.prop_points) и двор (extra). Живых тел не больше
## MAX_BODIES — только в радиусе SPAWN_M; ушёл дальше DESPAWN_M — предмет убирается,
## а вернёшься — снова стоит на месте (как мусор, который за ночь собрали).

const MAX_BODIES := 28
const SPAWN_M := 30.0
const DESPAWN_M := 45.0

var player: Node3D
var extra: Array = []                 # [[Vector3, kind]] — точки двора «Похмельной»
var _alive: Dictionary = {}           # ключ точки → PhysProp
var _tick := 0.0


func _ready() -> void:
	name = "PhysicsProps"
	set_meta("map_skip", true)


func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 0.5
	update_now()


func update_now() -> void:
	var hero := player.global_position
	for key in _alive.keys():
		var p: PhysProp = _alive[key]
		if not is_instance_valid(p) or (p.global_position - hero).length() > DESPAWN_M:
			if is_instance_valid(p):
				p.queue_free()
			_alive.erase(key)
	var near: Array = []
	for pts: Array in DistrictDressing.prop_points.values():
		_collect(pts, hero, near)
	_collect(extra, hero, near)
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for e in near:
		if _alive.size() >= MAX_BODIES:
			break
		var key: Vector3i = e[3]
		if _alive.has(key):
			continue
		var pos: Vector3 = e[1]
		var p := PhysProp.make(e[2], pos + Vector3(0, 0.02, 0), float(key.x * 7 + key.z * 13) * 0.1)
		add_child(p)
		_alive[key] = p


func _collect(pts: Array, hero: Vector3, out: Array) -> void:
	for pt in pts:
		var pos: Vector3 = pt[0]
		var d := (pos - hero).length()
		if d < SPAWN_M:
			out.append([d, pos, pt[1], Vector3i(roundi(pos.x * 4), 0, roundi(pos.z * 4))])


func alive_count() -> int:
	return _alive.size()
