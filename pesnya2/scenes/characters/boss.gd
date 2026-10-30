class_name Boss
extends CharacterBody3D
## Босс с фазами из data/bosses.json (0.16). Первый — BOSS_01 «Люся Глушительница Лайков».
## Каждая атака сначала рисует на полу опасную зону (полоса, сектор или круг) и ждёт telegraph_s
## фазы. Полосу и сектор закрывает целая рекламная тумба между боссом и героем (AdColumn),
## круг — нет, из него надо выйти. Фазы:
##   1 — «Прицельная очередь»: полоса 2.5 м на героя;
##   2 — «Вспышка спонсорства»: сектор 100°, через раз с кругом под ногами;
##   3 — «Указ о немедленной победе»: три сигнала подряд (веер полос, круги, полоса и сектор),
##       после третьего Люся выдыхается — окно атаки, урон по ней в полтора раза больше.
## На переходе фазы — ударная волна: героя и мелочь отбрасывает от босса.

signal defeated(boss: Boss)
signal phase_changed(boss: Boss, index: int)

const LANE_W := 2.5
const LANE_L := 34.0
const SECTOR_R := 20.0
const SECTOR_DEG := 100.0
const CIRCLE_R := 3.6
const KEEP_M := 11.0
const SPEED := 2.4
const WINDOW_S := 3.2
const ROAR_R := 11.0
const DAMAGE := {"lane": 18.0, "sector": 24.0, "circle": 20.0}

var boss_id := "BOSS_01"
var data: Dictionary = {}
var max_hp := 900.0
var hp := 900.0
var phase := 1
var active := false
var home := Vector3.ZERO
## Прямоугольник арены в мировых x/z: босс не уходит за край
var arena := Rect2()
var player: Player
var attacks_done := 0
var blocked_by_cover := 0

var _cd := 2.0
var _tele_left := 0.0
var _pending: Array = []        # [{kind, origin, dir, center, radius, node}]
var _seq := 0
var _window_left := 0.0
var _invuln_left := 0.0
var _body: Node3D
var _halo: MeshInstance3D
var _t := 0.0


func _ready() -> void:
	data = GameData.boss_by_id.get(boss_id, {})
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer = 4
	collision_mask = 1
	hp = max_hp
	home = global_position
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.8
	cap.height = 2.6
	shape.shape = cap
	shape.position.y = 1.3
	add_child(shape)
	_body = Node3D.new()
	add_child(_body)
	_build_look()


func display_name() -> String:
	return String(data.get("name", "Босс"))


## Люся: стримерша в розовом, кольцевая лампа за спиной, микрофон-глушитель в руке.
func _build_look() -> void:
	var m := NpcModel.make({"skin": Color(0.95, 0.78, 0.68), "top": Color(0.95, 0.3, 0.6), "bottom": Color(0.15, 0.12, 0.18),
			"hair": Color(0.98, 0.55, 0.8), "style": "bun", "skirt": true, "height": 1.0})
	m.scale = Vector3.ONE * 1.5
	_body.add_child(m)
	# свет кольцевой лампы: Люсю видно в темноте площади издалека
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 2.6, 0.6)
	glow.light_color = Color(1, 0.75, 0.9)
	glow.light_energy = 2.5
	glow.omni_range = 7.0
	_body.add_child(glow)
	# кольцевая лампа на штанге за спиной
	Kit.cylinder(_body, 0.05, 2.8, Vector3(0, 1.4, -0.55), Color(0.15, 0.15, 0.17))
	_halo = MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.55
	tor.outer_radius = 0.68
	tor.rings = 24
	tor.ring_segments = 6
	_halo.mesh = tor
	_halo.material_override = Kit.mat(Color(1, 0.95, 0.9), 3.0)
	_halo.rotation.x = PI / 2
	_halo.position = Vector3(0, 2.75, -0.6)
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(_halo)
	# микрофон-глушитель: ствол с поролоновой головкой
	Kit.cylinder(_body, 0.07, 0.9, Vector3(0.55, 1.55, 0.45), Color(0.12, 0.12, 0.14)).rotation.x = PI / 2
	Kit.sphere(_body, 0.2, Vector3(0.55, 1.55, 0.95), Color(0.9, 0.2, 0.4), 1.2)
	# телефон-дрон снимает её сверху
	Kit.box(_body, Vector3(0.35, 0.6, 0.06), Vector3(-0.9, 3.3, 0.3), Color(0.08, 0.08, 0.1))
	Kit.sphere(_body, 0.06, Vector3(-0.9, 3.45, 0.34), Color(1, 0.2, 0.2), 4.0)


func is_alive() -> bool:
	return hp > 0.0


## Боссу оглушение нипочём: ноги держат.
func stun(_seconds: float) -> void:
	pass


func in_window() -> bool:
	return _window_left > 0.0


func take_hit(damage: float, _from: Vector3) -> void:
	if not is_alive() or _invuln_left > 0.0:
		return
	if in_window():
		damage *= 1.5
	hp = maxf(0.0, hp - damage)
	AbilityFx.damage_number(get_parent(), global_position + Vector3(0, 3.2, 0), damage, in_window())
	AbilityFx.sparks(get_parent(), global_position + Vector3(0, 1.6, 0), Color(1, 0.5, 0.8), 5)
	_body.scale = Vector3(1.08, 0.94, 1.08)
	create_tween().tween_property(_body, "scale", Vector3.ONE, 0.12)
	if hp <= 0.0:
		_die()
		return
	var pct := hp / max_hp * 100.0
	for ph in data.get("phases", []):
		if int(ph.index) > phase and pct <= float(ph.hp_from):
			_enter_phase(int(ph.index))


func phase_info() -> Dictionary:
	for ph in data.get("phases", []):
		if int(ph.index) == phase:
			return ph
	return {}


func telegraph_s() -> float:
	var t := float(phase_info().get("telegraph_s", 1.2))
	# третья фаза — три сигнала подряд: каждый короче, иначе серия длится вечность
	return t * 0.55 if phase == 3 else t


func _enter_phase(index: int) -> void:
	phase = index
	_clear_pending()
	_seq = 0
	_window_left = 0.0
	_invuln_left = 1.4
	_cd = 1.6
	_roar()
	phase_changed.emit(self, index)


## Ударная волна смены фазы: героя отбрасывает, мелочь разлетается, тумбы стоят.
func _roar() -> void:
	var world := get_parent()
	Kit.ring(world, global_position, ROAR_R, Color(1, 0.4, 0.75), 0.5)
	PhysProp.blast(get_tree(), global_position, ROAR_R + 2.0, 9.0)
	Juice.shake(get_tree(), 0.2)
	_say(["Спонсор этой атаки — твоя боль!", "Указ о немедленной победе подписан!"][clampi(phase - 2, 0, 1)])
	if player != null:
		var away := (player.global_position - global_position) * Vector3(1, 0, 1)
		if away.length() < ROAR_R:
			player.knock(away.normalized() * 15.0 if away.length() > 0.1 else Vector3(15, 0, 0))


func reset() -> void:
	_clear_pending()
	active = false
	hp = max_hp
	phase = 1
	_seq = 0
	_cd = 2.0
	_window_left = 0.0
	_invuln_left = 0.0
	global_position = home
	velocity = Vector3.ZERO
	rotation = Vector3.ZERO
	_body.rotation = Vector3.ZERO


func _die() -> void:
	_clear_pending()
	active = false
	remove_from_group("enemies")
	Juice.shake(get_tree(), 0.25)
	var hearts := Kit.particles(get_parent(), global_position + Vector3(0, 2.0, 0), Color(1, 0.35, 0.6), 40, 1.6,
			Vector3(0, 4.0, 0), 1.0, 0.3, Vector3(0.8, 0.8, 0.8))
	hearts.one_shot = true
	hearts.explosiveness = 0.9
	get_tree().create_timer(2.5).timeout.connect(hearts.queue_free)
	var tw := create_tween()
	tw.tween_property(_body, "rotation:x", -PI / 2, 0.6).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_body, "position:y", 0.3, 0.6)
	_halo.material_override = Kit.mat(Color(0.3, 0.3, 0.32))
	defeated.emit(self)


func _physics_process(delta: float) -> void:
	_t += delta
	if not active or not is_alive() or player == null:
		return
	_invuln_left -= delta
	_halo.rotation.z += delta * (4.0 if _tele_left > 0.0 else 0.6)
	var to_p := (player.global_position - global_position) * Vector3(1, 0, 1)
	if _window_left > 0.0:
		# выдохлась: стоит на коленях, лампа мигает
		_window_left -= delta
		_body.rotation.x = -0.35
		_halo.visible = fmod(_t, 0.3) < 0.15
		if _window_left <= 0.0:
			_body.rotation.x = 0.0
			_halo.visible = true
			_cd = 0.8
		return
	if to_p.length() > 0.1:
		look_at(global_position + to_p, Vector3.UP)
	if _tele_left > 0.0:
		_tele_left -= delta
		if _tele_left <= 0.0:
			_resolve()
		return
	# держит дистанцию стрима: не подходит вплотную и не отпускает далеко
	var want := Vector3.ZERO
	if to_p.length() > KEEP_M + 3.0:
		want = to_p.normalized()
	elif to_p.length() < KEEP_M - 3.0:
		want = -to_p.normalized()
	var next := global_position + want * SPEED * delta
	if arena.size != Vector2.ZERO and not arena.grow(-6.0).has_point(Vector2(next.x, next.z)):
		want = Vector3.ZERO
	velocity = want * SPEED
	move_and_slide()
	_cd -= delta
	if _cd <= 0.0 and GameState.hp > 0.0:
		_start_attack()


func _start_attack() -> void:
	var at := player.global_position * Vector3(1, 0, 1) + Vector3(0, global_position.y, 0)
	var dir := ((at - global_position) * Vector3(1, 0, 1)).normalized()
	if dir == Vector3.ZERO:
		dir = Vector3.FORWARD
	match phase:
		1:
			_lane(dir)
		2:
			_sector(dir)
			if attacks_done % 2 == 1:
				_circle(at, 4.0)
		_:
			match _seq:
				0:
					for deg in [-22.0, 0.0, 22.0]:
						_lane(dir.rotated(Vector3.UP, deg_to_rad(deg)))
				1:
					_circle(at, CIRCLE_R)
					for k in 2:
						_circle(at + Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU) * randf_range(4.0, 7.0), CIRCLE_R)
				_:
					_lane(dir)
					_sector(dir.rotated(Vector3.UP, PI))      # сзади тоже не стой
	_tele_left = telegraph_s()
	_say_attack()


func _say_attack() -> void:
	if phase < 3 or _seq == 0:
		AbilityFx.pop(get_parent(), global_position + Vector3(0, 3.8, 0), String(phase_info().get("attack", "")),
				Color(1, 0.6, 0.8), 34)


## Полоса от босса вперёд: ширина LANE_W, длина LANE_L.
func _lane(dir: Vector3) -> void:
	var origin := global_position * Vector3(1, 0, 1)
	var n := _floor_node(origin + dir * LANE_L * 0.5, atan2(dir.x, dir.z))
	Kit.box(n, Vector3(LANE_W, 0.03, LANE_L), Vector3.ZERO, Color(1, 0.15, 0.25, 0.4), 1.5)
	var fill := Kit.box(n, Vector3(LANE_W * 0.9, 0.04, LANE_L), Vector3.ZERO, Color(1, 0.3, 0.2, 0.5), 2.0)
	_grow(fill, Vector3(0.05, 1, 1))
	_pending.append({"kind": "lane", "origin": origin, "dir": dir, "node": n})


## Сектор 100° радиусом SECTOR_R: веер «вспышки спонсорства».
func _sector(dir: Vector3) -> void:
	var origin := global_position * Vector3(1, 0, 1)
	var n := _floor_node(origin, atan2(dir.x, dir.z))
	var mi := MeshInstance3D.new()
	mi.mesh = _fan_mesh(SECTOR_R, SECTOR_DEG)
	mi.material_override = Kit.mat(Color(1, 0.7, 0.15, 0.2), 0.6)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	var fill := MeshInstance3D.new()
	fill.mesh = mi.mesh
	fill.material_override = Kit.mat(Color(1, 0.4, 0.1, 0.3), 0.9)
	fill.position.y = 0.01
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(fill)
	_grow(fill, Vector3(0.05, 1, 0.05))
	_pending.append({"kind": "sector", "origin": origin, "dir": dir, "node": n})


func _circle(center: Vector3, radius: float) -> void:
	var c := center * Vector3(1, 0, 1)
	var n := _floor_node(c, 0.0)
	Kit.cylinder(n, radius, 0.03, Vector3.ZERO, Color(1, 0.15, 0.1, 0.35), 1.5)
	var fill := Kit.cylinder(n, radius, 0.04, Vector3(0, 0.01, 0), Color(1, 0.3, 0.1, 0.5), 2.0)
	_grow(fill, Vector3(0.1, 1, 0.1))
	_pending.append({"kind": "circle", "center": c, "radius": radius, "node": n})


func _floor_node(at: Vector3, yaw: float) -> Node3D:
	var n := Node3D.new()
	n.position = at + Vector3(0, 0.09, 0)
	n.rotation.y = yaw
	n.set_meta("map_skip", true)
	get_parent().add_child(n)
	return n


func _grow(mi: Node3D, from: Vector3) -> void:
	mi.scale = from
	mi.create_tween().tween_property(mi, "scale", Vector3.ONE, telegraph_s())


static func _fan_mesh(radius: float, deg: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 16
	var half := deg_to_rad(deg) * 0.5
	for i in steps:
		var a0 := -half + 2.0 * half * i / steps
		var a1 := -half + 2.0 * half * (i + 1) / steps
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(sin(a1), 0, cos(a1)) * radius)
		st.add_vertex(Vector3(sin(a0), 0, cos(a0)) * radius)
	return st.commit()


## Выстрел: кто в зоне и не за тумбой — получает. Тумба на линии огня принимает удар на себя.
func _resolve() -> void:
	var hit_any := false
	var pp := player.global_position * Vector3(1, 0, 1)
	var world := get_parent()
	for a: Dictionary in _pending:
		match String(a.kind):
			"lane", "sector":
				var inside := _in_lane(a, pp) if a.kind == "lane" else _in_sector(a, pp)
				var o: Vector3 = a.origin
				if a.kind == "lane":
					# очередь бьёт по первой тумбе на полосе, даже если героя за ней нет
					var end: Vector3 = o + a.dir * LANE_L
					var first := AdColumn.blocker(get_tree(), o, end, LANE_W * 0.5)
					var stop := first.global_position * Vector3(1, 0, 1) if first else end
					if inside:
						var cover := AdColumn.blocker(get_tree(), o, pp)
						if cover != null:
							inside = false
							blocked_by_cover += 1
							if cover != first:
								cover.take_cover_hit(o)
					if first != null:
						first.take_cover_hit(o)
					Kit.beam(world, o + Vector3(0, 1.5, 0), stop + Vector3(0, 1.5, 0), Color(1, 0.35, 0.5), 0.2)
				elif inside:
					var cover := AdColumn.blocker(get_tree(), o, pp)
					if cover != null:
						inside = false
						blocked_by_cover += 1
						cover.take_cover_hit(o)
				if inside:
					hit_any = true
					player.take_hit(DAMAGE[a.kind] * (1.2 if phase == 3 else 1.0))
				if a.kind == "sector":
					Kit.ring(world, o, SECTOR_R * 0.5, Color(1, 0.7, 0.2), 0.3)
			"circle":
				var c: Vector3 = a.center
				Kit.ring(world, c, a.radius, Color(1, 0.3, 0.1), 0.3)
				if pp.distance_to(c) <= a.radius:
					hit_any = true
					player.take_hit(DAMAGE.circle * (1.2 if phase == 3 else 1.0))
					var away := pp - c
					player.knock((away.normalized() if away.length() > 0.1 else Vector3.RIGHT) * 9.0)
	_clear_pending()
	attacks_done += 1
	if hit_any:
		Juice.shake(get_tree(), 0.12)
	if phase == 3:
		_seq += 1
		if _seq >= 3:
			_seq = 0
			_window_left = WINDOW_S
			AbilityFx.pop(world, global_position + Vector3(0, 3.6, 0), "ОКНО АТАКИ!", Color(0.5, 1, 0.6), 48)
			return
		_cd = 0.35
	else:
		_cd = randf_range(1.1, 1.8) if phase == 1 else randf_range(1.3, 2.0)


static func _lane_hit(origin: Vector3, dir: Vector3, p: Vector3) -> bool:
	var d := p - origin
	var along := d.dot(dir)
	var side := absf(d.dot(Vector3(dir.z, 0, -dir.x)))
	return along >= 0.0 and along <= LANE_L and side <= LANE_W * 0.5 + 0.35


static func _sector_hit(origin: Vector3, dir: Vector3, p: Vector3) -> bool:
	var d := p - origin
	if d.length() > SECTOR_R:
		return false
	if d.length() < 1.0:
		return true
	return rad_to_deg(dir.angle_to(d.normalized())) <= SECTOR_DEG * 0.5


func _in_lane(a: Dictionary, p: Vector3) -> bool:
	return _lane_hit(a.origin, a.dir, p)


func _in_sector(a: Dictionary, p: Vector3) -> bool:
	return _sector_hit(a.origin, a.dir, p)


func _clear_pending() -> void:
	for a: Dictionary in _pending:
		if is_instance_valid(a.node):
			a.node.queue_free()
	_pending.clear()
	_tele_left = 0.0


func pending_kinds() -> Array:
	return _pending.map(func(a: Dictionary) -> String: return a.kind)


func _say(text: String) -> void:
	var l := Kit.label(self, text, Vector3(0, 4.3, 0), 40, Color(1, 0.85, 0.95))
	l.no_depth_test = true
	var tw := l.create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


func taunt() -> void:
	_say(String(data.get("taunt", "")))
