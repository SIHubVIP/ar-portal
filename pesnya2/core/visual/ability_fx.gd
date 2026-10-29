class_name AbilityFx
extends RefCounted
## Исполнение способностей: игровой эффект (урон, оглушение, рывок) плюс своя
## постановка у каждой — реквизит, выкрик и клип анимации героя.

const POP_COLORS := {"CLASS_1": Color(1, 0.55, 0.3), "CLASS_2": Color(1, 0.9, 0.35), "CLASS_3": Color(0.45, 0.95, 1)}

static var _complaints := 0


static func perform(p: Player, a: Dictionary, s: Dictionary) -> void:
	var flavor: Dictionary = GameData.ability_flavor.get("abilities", {}).get(a.id, {})
	var anim: String = flavor.get("anim", "")
	var shout: String = flavor.get("shout", a.name)
	if shout.contains("%d"):
		_complaints += 1
		shout = shout % (1000 + _complaints * 37)
	var world: Node = p.get_parent()
	var origin := p.global_position
	var dmg := p.attack_damage(float(s.get("damage", 0.0)))
	pop(world, origin + Vector3(0, 2.6, 0), shout, POP_COLORS.get(GameState.class_id, Color.WHITE))
	match s.effect:
		"strike":
			var e := p.nearest_enemy(s.range)
			if e:
				p.face(e.global_position)
			p.play_action("Bow" if anim == "sorry_bow" else "Attack", 0.5)
			if anim == "backstab_sale" and e:
				# «Скидка за спину»: оказываемся позади цели
				var behind := e.global_position + (e.global_position - origin).normalized() * 1.2
				p.global_position = Vector3(behind.x, origin.y, behind.z)
				p.face(e.global_position)
				pop(world, e.global_position + Vector3(0, 2.2, 0), "-50%", Color(1, 0.3, 0.3))
			if anim == "receipt_slap" and e:
				_paper(world, e.global_position + Vector3(0, 1.5, 0), Color(0.95, 0.95, 0.9), 0.4)
			if e:
				e.take_hit(dmg, origin)
				Kit.ring(world, e.global_position, 1.0, Color(1, 0.6, 0.2))
			if s.has("guard"):
				p.guard_until = p.t + float(s.guard)
		"shot":
			var e := p.nearest_enemy(s.range)
			p.play_action("Cast", 0.4)
			if e:
				p.face(e.global_position)
				var col := Color(0.4, 1, 1) if anim == "ping_beam" else Color(1, 0.9, 0.4)
				Kit.beam(world, origin + Vector3(0, 1.3, 0), e.global_position + Vector3(0, 1, 0), col, 0.25)
				if anim == "truth_shot":
					_paper(world, e.global_position + Vector3(0, 1.4, 0), Color(1, 0.95, 0.6), 0.5)
				e.take_hit(dmg, origin)
		"dash":
			var e := p.nearest_enemy(s.range)
			var dir := p.facing
			if e and dmg > 0.0:
				dir = e.global_position - origin
			p.dash(dir, Player.DODGE_TIME * clampf(s.range / Player.DODGE_DISTANCE, 1.0, 2.0))
			p.play_action("Dodge", 0.4)
			if anim == "shift_escape":
				_cutout(world, origin)
			if anim == "socket_blink":
				for i in 6:
					Kit.ring(world, origin + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)), 0.3, Color(0.6, 0.9, 1), 0.3)
			if e and dmg > 0.0:
				e.take_hit(dmg, origin)
		"guard":
			p.guard_until = p.t + float(s.duration)
			p.play_action("Cast", 0.4)
			if anim == "table_shield":
				_table(p, float(s.duration))
			elif anim == "brick_firewall":
				_firewall(world, origin + p.facing * 1.6, p.facing, float(s.duration))
			else:
				Kit.ring(world, origin, 1.2, Color(0.4, 0.7, 1), float(s.duration))
		"stun":
			p.play_action("Cast" if anim != "complaint_swarm" else "Flex", 0.6)
			Kit.ring(world, origin, s.range, Color(0.8, 0.5, 1))
			for e in p.enemies_in(s.range):
				e.stun(float(s.duration))
				if dmg > 0.0:
					e.take_hit(dmg, origin)
				match anim:
					"complaint_swarm":
						_paper(world, e.global_position + Vector3(0, 2, 0), Color(0.95, 0.95, 0.85), float(s.duration))
					"cloud_control":
						_cloud(world, e.global_position + Vector3(0, 2.4, 0), float(s.duration))
					"fake_ticket":
						pop(world, e.global_position + Vector3(0, 2.2, 0), "Я первый!", Color(1, 1, 0.6))
					"quiet_scandal":
						pop(world, e.global_position + Vector3(0, 2.2, 0), "...что?!", Color(1, 0.6, 0.8))
		"area":
			p.play_action("Attack" if GameState.class_id == "CLASS_1" else "Cast", 0.6)
			match anim:
				"stamp_slam":
					_stamp(world, origin + p.facing * 2.0)
				"leave_chat":
					p.set_visible_body(false)
					p.get_tree().create_timer(0.8).timeout.connect(func(): p.set_visible_body(true))
				"forced_update":
					pop(world, origin + Vector3(0, 3.2, 0), "Не выключайте устройство", Color(0.6, 0.9, 1))
				"fine_volley":
					for e in p.enemies_in(s.range):
						_paper(world, e.global_position + Vector3(0, 1.5, 0), Color(1, 0.85, 0.85), 0.5)
			Kit.ring(world, origin, s.range, Color(1, 0.4, 0.1), 0.5)
			for e in p.enemies_in(s.range):
				e.take_hit(dmg, origin)
		"turret":
			p.play_action("Cast", 0.4)
			_router(p, s)
		"buff":
			p.buff_until = p.t + float(s.duration)
			GameState.heal(GameState.max_hp * 0.25)
			p.play_action("Flex", 0.9)
			Kit.ring(world, origin, 1.0, Color(0.3, 1, 0.5), float(s.duration))


## Всплывающая надпись над головой.
static func pop(world: Node, pos: Vector3, text: String, color: Color, size := 56) -> void:
	var l := Kit.label(world, text, pos, size, color)
	l.no_depth_test = true
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", pos.y + 1.2, 1.1)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.1).set_delay(0.5)
	tw.tween_callback(l.queue_free)


static func _paper(world: Node, pos: Vector3, color: Color, life: float) -> void:
	for i in 3:
		var sheet := Kit.box(world, Vector3(0.35, 0.02, 0.5), pos + Vector3(randf_range(-0.4, 0.4), randf() * 0.4, randf_range(-0.4, 0.4)), color)
		sheet.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
		var tw := sheet.create_tween()
		tw.tween_property(sheet, "rotation:y", sheet.rotation.y + TAU, life + 0.3)
		tw.parallel().tween_property(sheet, "position:y", pos.y - 1.2, life + 0.3)
		tw.tween_callback(sheet.queue_free)


static func _table(p: Player, life: float) -> void:
	var table := Node3D.new()
	p.add_child(table)
	table.position = p.facing.rotated(Vector3.UP, -p.rotation.y) * 0.9
	table.rotation.y = atan2(p.facing.x, p.facing.z)
	Kit.box(table, Vector3(1.4, 0.08, 0.9), Vector3(0, 0.75, 0), Color(0.55, 0.36, 0.2))
	for x in [-0.6, 0.6]:
		Kit.box(table, Vector3(0.07, 0.75, 0.07), Vector3(x, 0.37, 0.35), Color(0.45, 0.3, 0.18))
	Kit.sphere(table, 0.15, Vector3(0.3, 0.85, 0), Color(0.95, 0.9, 0.6))  # оливье
	table.rotation.x = -1.4
	var tw := table.create_tween()
	tw.tween_property(table, "rotation:x", 0.0, 0.2)
	tw.tween_interval(life)
	tw.tween_callback(table.queue_free)


static func _firewall(world: Node, pos: Vector3, facing: Vector3, life: float) -> void:
	var wall := Node3D.new()
	world.add_child(wall)
	wall.global_position = pos
	wall.rotation.y = atan2(facing.x, facing.z)
	for x in 5:
		for y in 3:
			Kit.box(wall, Vector3(0.5, 0.3, 0.25), Vector3(-1.0 + x * 0.52 + (y % 2) * 0.2, 0.2 + y * 0.32, 0), Color(1, 0.4, 0.1), 1.8)
	var tw := wall.create_tween()
	tw.tween_interval(life)
	tw.tween_callback(wall.queue_free)


static func _cloud(world: Node, pos: Vector3, life: float) -> void:
	var c := Node3D.new()
	world.add_child(c)
	c.global_position = pos
	for i in 4:
		Kit.sphere(c, 0.35, Vector3(i * 0.3 - 0.45, randf() * 0.15, 0), Color(0.85, 0.9, 1))
	Kit.label(c, "синхронизация...", Vector3(0, 0.6, 0), 28, Color(0.7, 0.9, 1))
	var tw := c.create_tween()
	tw.tween_interval(life)
	tw.tween_callback(c.queue_free)


static func _cutout(world: Node, pos: Vector3) -> void:
	var c := Node3D.new()
	world.add_child(c)
	c.global_position = pos
	Kit.box(c, Vector3(0.6, 1.8, 0.03), Vector3(0, 0.9, 0), Color(0.8, 0.65, 0.45))
	Kit.label(c, "ЗАМЕСТИТЕЛЬ", Vector3(0, 1.2, 0.05), 30, Color(0.2, 0.15, 0.1), false)
	var tw := c.create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(c, "rotation:x", -PI / 2, 0.3)
	tw.tween_callback(c.queue_free)


static func _stamp(world: Node, pos: Vector3) -> void:
	var st := Node3D.new()
	world.add_child(st)
	st.global_position = pos + Vector3(0, 8, 0)
	Kit.box(st, Vector3(2.2, 0.5, 1.4), Vector3.ZERO, Color(0.6, 0.1, 0.1))
	Kit.cylinder(st, 0.25, 1.2, Vector3(0, 0.85, 0), Color(0.3, 0.2, 0.15))
	Kit.label(st, "ОТКАЗАНО", Vector3(0, -0.26, 0), 60, Color(1, 0.2, 0.2), false).rotation_degrees.x = 90
	var tw := st.create_tween()
	tw.tween_property(st, "global_position", pos + Vector3(0, 0.25, 0), 0.25).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.6)
	tw.tween_callback(st.queue_free)


static func _router(p: Player, s: Dictionary) -> void:
	var world := p.get_parent()
	var r := Node3D.new()
	world.add_child(r)
	r.global_position = p.global_position + p.facing * 1.5
	Kit.box(r, Vector3(0.6, 0.15, 0.4), Vector3(0, 0.08, 0), Color(0.15, 0.15, 0.18))
	for x in [-0.22, 0.22]:
		Kit.cylinder(r, 0.025, 0.5, Vector3(x, 0.4, -0.15), Color(0.1, 0.1, 0.1))
	for i in 4:
		Kit.sphere(r, 0.03, Vector3(-0.15 + i * 0.1, 0.17, 0.2), Color(0.2, 1, 0.3), 3.0)
	var shots := int(float(s.duration) / 0.8)
	var tw := r.create_tween()
	for i in shots:
		tw.tween_interval(0.8)
		tw.tween_callback(func():
			var e := p.nearest_enemy(s.range, r.global_position)
			if e:
				Kit.beam(world, r.global_position + Vector3(0, 0.4, 0), e.global_position + Vector3(0, 1, 0),
						Color(0.3, 1, 0.4), 0.1)
				e.take_hit(p.attack_damage(float(s.damage)), r.global_position))
	tw.tween_callback(r.queue_free)


## Цифра урона: вылетает в сторону и падает, крупнее при сильном ударе.
static func damage_number(world: Node, pos: Vector3, amount: float, crit := false) -> void:
	var l := Kit.label(world, str(roundi(amount)), pos + Vector3(randf_range(-0.3, 0.3), 0, 0), 64 if crit else 44,
			Color(1, 0.85, 0.2) if crit else Color(1, 1, 1))
	l.no_depth_test = true
	l.outline_size = 10
	var side := randf_range(-0.8, 0.8)
	var tw := l.create_tween()
	tw.tween_property(l, "position", pos + Vector3(side, 1.4, 0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(l, "position", pos + Vector3(side * 1.4, 0.6, 0), 0.4).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


## Искры при попадании.
static func sparks(world: Node, pos: Vector3, color := Color(1, 0.8, 0.3), count := 8) -> void:
	for i in count:
		var s := Kit.box(world, Vector3(0.06, 0.06, 0.06), pos, color, 4.0)
		var dir := Vector3(randf_range(-1, 1), randf_range(0.2, 1.2), randf_range(-1, 1)).normalized()
		var tw := s.create_tween()
		tw.tween_property(s, "position", pos + dir * randf_range(0.6, 1.4), 0.25).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(s, "scale", Vector3.ZERO, 0.3)
		tw.tween_callback(s.queue_free)

