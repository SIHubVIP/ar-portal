class_name TouchControls
extends Control
## Мультитач-управление: стик слева, атака, уклонение, взаимодействие и 7 способностей справа.
## Обрабатывает только InputEventScreenTouch/Drag, поэтому стик и кнопки работают одновременно.

signal attack
signal dodge
signal interact
signal ability(index: int)
signal camera_rotate(radians: float)
signal camera_zoom(amount: float)
signal camera_tilt(radians: float)

const STICK_RADIUS := 90.0

var player: Player
var interact_label := ""
var ability_names: PackedStringArray = []

var _stick_finger := -1
var _stick_origin := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _pressed: Dictionary = {}  # finger -> button id
## Пальцы, которые крутят камеру (свайп по свободной части экрана): index -> позиция
var _cam_fingers: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# диалог прячет управление посреди движения: отпускание пальца тогда не доходит, и стик
	# «залипал» за старым пальцем — новое касание уходило в поворот камеры (баг 0.8)
	visibility_changed.connect(release_all)


## Забыть все пальцы и остановить героя.
func release_all() -> void:
	_stick_finger = -1
	_pressed.clear()
	_cam_fingers.clear()
	if player:
		player.move_input = Vector2.ZERO
	queue_redraw()


## Кнопки: id -> [центр, радиус]. Раскладка считается от правого нижнего угла.
func buttons() -> Dictionary:
	var s := size
	var a := Vector2(s.x - 125, s.y - 125)
	var b := {"attack": [a, 72.0], "dodge": [a + Vector2(-285, 45), 44.0]}
	if interact_label != "":
		b["interact"] = [a + Vector2(0, -330), 48.0]
	# поворот камеры — слева от мини-карты (она в правом верхнем углу)
	b["rot_left"] = [Vector2(s.x - 345, 146), 30.0]
	b["rot_right"] = [Vector2(s.x - 265, 146), 30.0]
	var inner := [180.0, 210.0, 240.0, 270.0]
	var outer := [195.0, 225.0, 255.0]
	for i in 7:
		# закрытые способности не загромождают экран: видна только ближайшая следующая
		if player and not player.ability_unlocked(i) and i > 0 and not player.ability_unlocked(i - 1):
			continue
		var ang: float = deg_to_rad(inner[i] if i < 4 else outer[i - 4])
		var r := 176.0 if i < 4 else 270.0
		b["ability_%d" % i] = [a + Vector2(cos(ang), sin(ang)) * r, 40.0]
	return b


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and event.index == _stick_finger:
			_stick_finger = -1      # этот палец уже отпускали, пока управление было скрыто
		if event.pressed:
			var hit := _button_at(event.position)
			if hit != "":
				_pressed[event.index] = hit
				_fire(hit)
				get_viewport().set_input_as_handled()
			elif event.position.x < size.x * 0.45 and event.position.y > size.y * 0.3 and _stick_finger < 0:
				_stick_finger = event.index
				_stick_origin = event.position
				_stick_pos = event.position
				get_viewport().set_input_as_handled()
			elif event.position.y > 90:
				_cam_fingers[event.index] = event.position
		else:
			_pressed.erase(event.index)
			_cam_fingers.erase(event.index)
			if event.index == _stick_finger:
				_stick_finger = -1
				if player:
					player.move_input = Vector2.ZERO
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == _stick_finger:
			_stick_pos = event.position
			var v: Vector2 = (_stick_pos - _stick_origin) / STICK_RADIUS
			if player:
				player.move_input = v.limit_length(1.0) if v.length() > 0.12 else Vector2.ZERO
			get_viewport().set_input_as_handled()
			queue_redraw()
		elif _cam_fingers.has(event.index):
			var prev: Vector2 = _cam_fingers[event.index]
			if _cam_fingers.size() >= 2:
				# щипок: расстояние между двумя пальцами меняет зум
				var other: Vector2 = _cam_fingers[_cam_fingers.keys().filter(func(k): return k != event.index)[0]]
				camera_zoom.emit((prev.distance_to(other) - event.position.distance_to(other)) * 0.04)
			else:
				# один палец: по горизонтали — поворот, по вертикали — наклон камеры
				camera_rotate.emit(-(event.position.x - prev.x) * 0.008)
				camera_tilt.emit((event.position.y - prev.y) * 0.006)
			_cam_fingers[event.index] = event.position
			get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_J, KEY_SPACE:
			attack.emit()
		KEY_K, KEY_SHIFT:
			dodge.emit()
		KEY_E:
			interact.emit()
		var k when k >= KEY_1 and k <= KEY_7:
			ability.emit(k - KEY_1)


func _button_at(p: Vector2) -> String:
	var b := buttons()
	for id in b:
		if p.distance_to(b[id][0]) <= b[id][1] + 10.0:
			return id
	return ""


func _fire(id: String) -> void:
	match id:
		"attack": attack.emit()
		"dodge": dodge.emit()
		"interact": interact.emit()
		"rot_left": camera_rotate.emit(deg_to_rad(-45.0))
		"rot_right": camera_rotate.emit(deg_to_rad(45.0))
		_: ability.emit(int(id.get_slice("_", 1)))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	# стик: кольцо с насечками и рисованная «шайба»
	var base := _stick_origin if _stick_finger >= 0 else Vector2(170, size.y - 170)
	draw_circle(base, STICK_RADIUS, Color(UiSkin.INK, 0.28))
	draw_arc(base, STICK_RADIUS, 0, TAU, 64, Color(UiSkin.CREAM, 0.55), 4.0, true)
	for k in 4:
		var ang := k * PI / 2
		draw_line(base + Vector2.from_angle(ang) * (STICK_RADIUS - 14), base + Vector2.from_angle(ang) * (STICK_RADIUS - 4),
				Color(UiSkin.CREAM, 0.6), 4.0)
	var knob := base + ((_stick_pos - _stick_origin).limit_length(STICK_RADIUS) if _stick_finger >= 0 else Vector2.ZERO)
	_disc(knob, 40, Color(UiSkin.CREAM, 0.85), false)
	# кнопки — круглые «таблетки» с бортиком и рисованными значками (0.20)
	var b := buttons()
	for id in b:
		var c: Vector2 = b[id][0]
		var r: float = b[id][1]
		var held := _pressed.values().has(id)
		var col := UiSkin.INK_LIGHT
		var icon := ""
		var caption := ""
		var cd := 0.0
		var total := 1.0
		var locked := false
		match id:
			"attack":
				col = Color(0.93, 0.3, 0.26)
				icon = "fist"
			"dodge":
				col = Color(0.3, 0.62, 0.95)
				icon = "dodge"
			"interact":
				col = Color(0.3, 0.72, 0.4)
				icon = "hand"
				caption = interact_label
			"rot_left", "rot_right":
				col = Color(UiSkin.INK_LIGHT, 0.85)
				icon = id
			_:
				var i := int(id.get_slice("_", 1))
				var a: Dictionary = player.book.abilities[i] if player and i < player.book.abilities.size() else {}
				icon = String(a.get("id", ""))
				col = Color(0.42, 0.3, 0.55)
				if player and not player.ability_unlocked(i):
					locked = true
					icon = "lock"
					caption = "ур. %d" % player.unlock_level(i)
					col = Color(0.2, 0.17, 0.24)
				elif player:
					cd = player.ability_remaining(i)
					total = maxf(0.1, float(a.get("cooldown_s", 1.0)))
		_disc(c, r, col, held)
		var tex := UiSkin.icon(icon) if icon != "" else null
		if tex:
			var px := r * (1.25 if not locked else 0.95)
			var off := Vector2(0, (3 if held else -2) - (8 if locked else 0))
			draw_texture_rect(tex, Rect2(c + off - Vector2(px, px) / 2, Vector2(px, px)), false,
					Color(1, 1, 1, 0.45 if cd > 0.0 else 1.0))
		if cd > 0.0:
			# остаток перезарядки — тёмный сектор и цифра поверх значка
			var frac := clampf(cd / total, 0.0, 1.0)
			var pts := PackedVector2Array([c])
			for k in 33:
				pts.append(c + Vector2.from_angle(-PI / 2 + TAU * frac * k / 32.0) * (r - 3))
			if frac > 0.01:
				draw_colored_polygon(pts, Color(0, 0, 0, 0.5))
			_text(font, c + Vector2(0, 9), str(ceili(cd)), 26, UiSkin.TEXT)
		if locked:
			_text(font, c + Vector2(0, r * 0.62), caption, 14, UiSkin.TEXT)
		elif caption != "":
			_text(font, c + Vector2(0, r + 20), caption, 17, UiSkin.TEXT)


## Круг с тенью, тёмным контуром и бликом сверху; нажатый — ниже и темнее.
func _disc(c: Vector2, r: float, col: Color, held: bool) -> void:
	var dy := 4.0 if held else 0.0
	draw_circle(c + Vector2(0, 6), r + 2, Color(0, 0, 0, 0.3))
	draw_circle(c + Vector2(0, 5), r, UiSkin.OUTLINE)
	draw_circle(c + Vector2(0, dy), r, UiSkin.OUTLINE)
	draw_circle(c + Vector2(0, dy), r - 3.5, col.darkened(0.12) if held else col)
	draw_arc(c + Vector2(0, dy), r - 9, deg_to_rad(200), deg_to_rad(320), 16, Color(1, 1, 1, 0.28), 5.0, true)


func _text(font: Font, at: Vector2, text: String, fs: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string_outline(font, Vector2(at.x - w / 2, at.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, UiSkin.OUTLINE)
	draw_string(font, Vector2(at.x - w / 2, at.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
