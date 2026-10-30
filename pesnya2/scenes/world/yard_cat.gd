class_name YardCat
extends Node3D
## Дворовый кот (0.13, концепт 01_start: рыжий кот у будки). Гуляет между случайными точками
## прямоугольника area, иногда садится и машет хвостом; если герой ближе 4 м — удирает рысью
## в сторону от него. Сетка — одна (CarKit-грани, материал plain), хвост — отдельный узел.

const FLEE_M := 4.0
const WALK := 1.1
const RUN := 4.5

var player: Node3D
var area := Rect2(-10, -10, 20, 20)
var fur := Color(0.9, 0.5, 0.18)

var _rng := RandomNumberGenerator.new()
var _goal := Vector3.ZERO
var _sit := 0.0
var _t := 0.0
var _tail: Node3D
var _body: Node3D


func _ready() -> void:
	_rng.seed = hash(area.position)
	_body = Node3D.new()
	add_child(_body)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var belly := Color(0.95, 0.92, 0.85)
	CarKit._box(st, Vector3(0, 0.28, 0), Vector3(0.22, 0.2, 0.5), fur)                  # туловище
	CarKit._box(st, Vector3(0, 0.22, 0.02), Vector3(0.18, 0.08, 0.4), belly)
	CarKit._box(st, Vector3(0, 0.42, 0.3), Vector3(0.18, 0.16, 0.16), fur)              # голова
	CarKit._box(st, Vector3(0, 0.39, 0.385), Vector3(0.1, 0.07, 0.03), belly)           # мордочка
	for sx: float in [-1.0, 1.0]:
		CarKit._box(st, Vector3(sx * 0.055, 0.53, 0.29), Vector3(0.05, 0.07, 0.04), fur)  # уши
		CarKit._box(st, Vector3(sx * 0.045, 0.45, 0.385), Vector3(0.03, 0.025, 0.01), Color(0.4, 0.9, 0.3, 0.2))  # глаза светятся
		for sz: float in [-0.18, 0.18]:
			CarKit._box(st, Vector3(sx * 0.07, 0.09, sz), Vector3(0.06, 0.18, 0.06), fur if sz < 0.0 else belly)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = DistrictDressing._material("plain")
	_body.add_child(mi)
	_tail = Node3D.new()
	_tail.position = Vector3(0, 0.34, -0.25)
	_body.add_child(_tail)
	var tail := Kit.box(_tail, Vector3(0.05, 0.05, 0.34), Vector3(0, 0.1, -0.14), fur.darkened(0.15))
	tail.rotation_degrees.x = -40
	_pick_goal()


func _pick_goal() -> void:
	_goal = Vector3(_rng.randf_range(area.position.x, area.end.x), 0, _rng.randf_range(area.position.y, area.end.y))


func _physics_process(delta: float) -> void:
	_t += delta
	var speed := WALK
	var to := _goal - position
	if player != null:
		var away := position - player.global_position
		away.y = 0.0
		if away.length() < FLEE_M:
			# удирает от героя, не выходя из своего двора
			var run := (position + away.normalized() * 6.0)
			run.x = clampf(run.x, area.position.x, area.end.x)
			run.z = clampf(run.z, area.position.y, area.end.y)
			_goal = run
			to = _goal - position
			_sit = 0.0
			speed = RUN
	_tail.rotation.y = sin(_t * (9.0 if speed > WALK else 2.5)) * 0.5
	if _sit > 0.0:
		_sit -= delta
		_body.position.y = 0.0
		_body.rotation.x = -0.25          # сидит: перед приподнят
		if _sit <= 0.0:
			_body.rotation.x = 0.0
			_pick_goal()
		return
	if to.length() < 0.3:
		if _rng.randf() < 0.5:
			_sit = _rng.randf_range(3.0, 8.0)
		else:
			_pick_goal()
		return
	var step := to.normalized() * speed * delta
	position += step if step.length() < to.length() else to
	rotation.y = atan2(to.x, to.z)
	_body.position.y = absf(sin(_t * speed * 7.0)) * 0.03
