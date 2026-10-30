class_name StreetLife
extends Node3D
## Улица живёт вокруг героя: прохожие на тротуарах и в переулках, машины на дорогах.
## Это пул из нескольких фигур: кто ушёл далеко от героя, появляется снова рядом с ним
## на случайной улице. Машины тормозят перед героем, прохожие бросают реплики, если подойти.

const PEDESTRIANS := 12
const CARS := 5
const NEAR_M := 18.0
const FAR_M := 75.0
const LINES := [
	"Лайкни меня, я существую.",
	"Я не пьяный, я в режиме энергосбережения.",
	"Говорят, за улыбку теперь штраф. Или за её отсутствие.",
	"Мне камера подмигнула. Это флирт или протокол?",
	"Заплатил за воздух — дышу на все деньги.",
	"Не смотри на дронов. Они от этого заводятся.",
	"У меня ипотека на ипотеку.",
	"Шаурма сегодня подозрительно молчит.",
	"Песню видел? Её запретили до того, как написали.",
	"Тише! Тут даже мысли согласовывают.",
	"Я в очереди за очередью стоял.",
	"Мама говорила: не ходи в Погуляй ночью. Но мама и днём не ходила.",
	"Курьер пропусков опять бегает. Значит, кому-то не повезло.",
	"У слизней сегодня бизнес-ланч. Из прохожих.",
	"Если что — я тебя не видел. И ты меня. И вообще никто никого.",
	"Сон платный, бодрствование по подписке.",
]
const CAR_COLORS := [Color(0.8, 0.12, 0.1), Color(0.95, 0.8, 0.1), Color(0.15, 0.2, 0.35), Color(0.85, 0.85, 0.85),
		Color(0.1, 0.1, 0.1), Color(0.2, 0.5, 0.35)]

var player: Node3D
var _peds: Array = []     # {node, a, b, t, speed, side, cd}
var _cars: Array = []
var _walk_segs: Array = []
var _drive_segs: Array = []
var _rng := RandomNumberGenerator.new()
var _t := 0.0


func _ready() -> void:
	name = "StreetLife"
	set_meta("map_skip", true)
	_rng.randomize()
	var yard := District.start_area().grow(4)
	for s in District.road_segments():
		if yard.has_point(s.a) and yard.has_point(s.b):
			continue
		_walk_segs.append(s)
		if s.id != "lane":
			_drive_segs.append(s)
	for i in PEDESTRIANS:
		_peds.append(_make_ped())
	for i in CARS:
		_cars.append(_make_car())


func _make_ped() -> Dictionary:
	var n := Node3D.new()
	add_child(n)
	var body := Node3D.new()
	n.add_child(body)
	var look := NpcModel.random_look(_rng)
	var model := NpcModel.make(look)
	model.walk = 1.0
	body.add_child(model)
	if _rng.randf() < 0.4:   # у каждого второго светится телефон — уткнулся в экран
		Kit.box(body, Vector3(0.08, 0.14, 0.02), Vector3(-0.1, 1.22, 0.24) * float(look.height),
				Color(0.6, 0.85, 1.0), 2.5).rotation_degrees.x = -30.0
	n.visible = false
	return {"node": n, "body": body, "model": model, "a": Vector2.ZERO, "b": Vector2.ZERO, "t": 1.0, "len": 1.0,
			"speed": _rng.randf_range(1.0, 1.6), "side": 0.0, "cd": 0.0, "phase": _rng.randf() * TAU}


func _make_car() -> Dictionary:
	var n := Node3D.new()
	add_child(n)
	var c: Color = CAR_COLORS[_rng.randi() % CAR_COLORS.size()]
	CarKit.make(n, c, true, _rng.randi() % 3)
	n.visible = false
	return {"node": n, "a": Vector2.ZERO, "b": Vector2.ZERO, "t": 1.0, "len": 1.0, "speed": 0.0,
			"cruise": _rng.randf_range(8.0, 12.0), "lane": 0.0, "honk": 0.0}


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_t += delta
	var pp := District.to_plan(player.global_position)
	for p in _peds:
		_step_ped(p, pp, delta)
	for c in _cars:
		_step_car(c, pp, delta)


func _step_ped(p: Dictionary, pp: Vector2, delta: float) -> void:
	var n: Node3D = p.node
	var at := p.a.lerp(p.b, p.t) as Vector2
	if p.t >= 1.0 or at.distance_to(pp) > FAR_M:
		if not _place(p, _walk_segs, pp, true):
			n.visible = false
			return
	p.t = minf(1.0, p.t + p.speed * delta / p.len)
	var dir: Vector2 = (p.b - p.a).normalized()
	var side: Vector2 = Vector2(-dir.y, dir.x) * float(p.side)
	var q: Vector2 = p.a.lerp(p.b, p.t) + side
	n.position = District.to_world(q)
	n.rotation.y = atan2(dir.x, dir.y)
	n.visible = true
	var body: Node3D = p.body
	body.position.y = absf(sin(_t * 7.0 + p.phase)) * 0.04
	body.rotation.z = sin(_t * 7.0 + p.phase) * 0.03
	p.cd -= delta
	if p.cd <= 0.0 and q.distance_to(pp) < 3.5:
		p.cd = 25.0
		var l := Kit.label(n, LINES[_rng.randi() % LINES.size()], Vector3(0, 2.3, 0), 32, Color(0.95, 0.95, 1))
		l.no_depth_test = true
		var tw := l.create_tween()
		tw.tween_interval(2.6)
		tw.tween_property(l, "modulate:a", 0.0, 0.4)
		tw.tween_callback(l.queue_free)


func _step_car(c: Dictionary, pp: Vector2, delta: float) -> void:
	var n: Node3D = c.node
	var at := c.a.lerp(c.b, c.t) as Vector2
	if c.t >= 1.0 or at.distance_to(pp) > FAR_M + 30.0:
		if not _place(c, _drive_segs, pp, false):
			n.visible = false
			return
		c.speed = c.cruise
	var dir: Vector2 = (c.b - c.a).normalized()
	var lane: Vector2 = Vector2(-dir.y, dir.x) * float(c.lane)
	var here: Vector2 = c.a.lerp(c.b, c.t) + lane
	# тормозит, если герой или другая машина впереди в своей полосе
	var ahead := pp - here
	var blocked: bool = ahead.dot(dir) > 0.0 and ahead.dot(dir) < 9.0 and absf(ahead.dot(Vector2(-dir.y, dir.x))) < 1.8
	for o in _cars:
		if o != c and o.node.visible:
			var oa: Vector2 = o.a.lerp(o.b, o.t) - here
			blocked = blocked or (oa.dot(dir) > 0.0 and oa.dot(dir) < 8.0 and absf(oa.dot(Vector2(-dir.y, dir.x))) < 1.5)
	var target_speed: float = 0.0 if blocked else c.cruise
	c.speed = move_toward(c.speed, target_speed, (22.0 if blocked else 5.0) * delta)
	c.honk -= delta
	if blocked and ahead.length() < 9.0 and c.honk <= 0.0:
		c.honk = 6.0
		var l := Kit.label(n, "БИ-БИП!", Vector3(0, 2.4, 0), 44, Color(1, 0.85, 0.3))
		l.no_depth_test = true
		l.create_tween().tween_property(l, "modulate:a", 0.0, 1.2)
		get_tree().create_timer(1.3).timeout.connect(l.queue_free)
	c.t = minf(1.0, c.t + c.speed * delta / c.len)
	n.position = District.to_world(c.a.lerp(c.b, c.t) + lane)
	n.rotation.y = atan2(dir.x, dir.y)
	n.visible = true


## Ставит фигуру на случайную улицу у героя: на ближайшую к нему точку отрезка плюс сдвиг,
## подальше, чем NEAR_M, чтобы не возникать перед носом. Направление случайное.
func _place(e: Dictionary, segs: Array, pp: Vector2, walker: bool) -> bool:
	for attempt in 8:
		var s: Dictionary = segs[_rng.randi() % segs.size()]
		var ab: Vector2 = s.b - s.a
		var len := ab.length()
		if len < 10.0:
			continue
		var t0 := clampf((pp - s.a).dot(ab) / (len * len), 0.0, 1.0)
		var closest: Vector2 = s.a + ab * t0
		if closest.distance_to(pp) > FAR_M * 0.7:
			continue
		var off := _rng.randf_range(NEAR_M, FAR_M * 0.6) * (1.0 if _rng.randf() < 0.5 else -1.0)
		var t := clampf(t0 + off / len, 0.0, 1.0)
		var span := minf(len, 160.0) / len     # короткий отрезок пути, потом снова к герою
		var forward := _rng.randf() < 0.5
		var ta := t
		var tb := clampf(t + span if forward else t - span, 0.0, 1.0)
		if absf(tb - ta) * len < 8.0:
			continue
		e.a = s.a + ab * ta
		e.b = s.a + ab * tb
		e.len = absf(tb - ta) * len
		e.t = 0.0
		var w := float(s.w)
		if walker:
			e.side = (w / 2.0 + 1.2 if s.id != "lane" else _rng.randf_range(-1.5, 1.5)) * (1.0 if _rng.randf() < 0.5 else -1.0)
		else:
			e.lane = w / 4.0
		var start: Vector2 = e.a + Vector2(-(e.b - e.a).normalized().y, (e.b - e.a).normalized().x) * (e.side if walker else e.lane)
		if District.start_area().grow(3).has_point(start) or (walker and not District.walkable(start)):
			continue
		return true
	e.t = 1.0
	return false
