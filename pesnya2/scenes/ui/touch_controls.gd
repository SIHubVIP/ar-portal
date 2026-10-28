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


## Кнопки: id -> [центр, радиус]. Раскладка считается от правого нижнего угла.
func buttons() -> Dictionary:
	var s := size
	var a := Vector2(s.x - 125, s.y - 125)
	var b := {"attack": [a, 72.0], "dodge": [a + Vector2(-285, 45), 44.0]}
	if interact_label != "":
		b["interact"] = [a + Vector2(0, -330), 48.0]
	b["rot_left"] = [Vector2(s.x - 190, 120), 30.0]
	b["rot_right"] = [Vector2(s.x - 60, 120), 30.0]
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
	# стик
	var base := _stick_origin if _stick_finger >= 0 else Vector2(170, size.y - 170)
	draw_circle(base, STICK_RADIUS, Color(1, 1, 1, 0.10))
	draw_arc(base, STICK_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	var knob := base + ((_stick_pos - _stick_origin).limit_length(STICK_RADIUS) if _stick_finger >= 0 else Vector2.ZERO)
	draw_circle(knob, 38, Color(1, 1, 1, 0.45))
	# кнопки
	var b := buttons()
	for id in b:
		var c: Vector2 = b[id][0]
		var r: float = b[id][1]
		var held := _pressed.values().has(id)
		var col := Color(0.1, 0.1, 0.14, 0.55)
		var text := ""
		var cd := 0.0
		match id:
			"attack":
				col = Color(0.8, 0.2, 0.15, 0.7)
				text = "Удар"
			"dodge":
				text = "Уклон"
			"interact":
				col = Color(0.15, 0.55, 0.3, 0.75)
				text = interact_label
			"rot_left":
				text = "↺"
			"rot_right":
				text = "↻"
			_:
				var i := int(id.get_slice("_", 1))
				text = ability_names[i] if i < ability_names.size() else str(i + 1)
				cd = player.ability_remaining(i) if player else 0.0
				if player and not player.ability_unlocked(i):
					col = Color(0.05, 0.05, 0.07, 0.45)
					text = "с ур.\n%d" % player.unlock_level(i)
					cd = 0.0
		if held:
			col = col.lightened(0.3)
		draw_circle(c, r, col)
		draw_arc(c, r, 0, TAU, 40, Color(1, 1, 1, 0.5), 2.0)
		if cd > 0.0:
			var total: float = player.book.abilities[int(id.get_slice("_", 1))].cooldown_s
			var frac := clampf(cd / total, 0.0, 1.0)
			draw_arc(c, r - 6, -PI / 2, -PI / 2 + TAU * frac, 32, Color(0, 0, 0, 0.6), 12.0)
			text = str(ceili(cd))
		var fs := 16 if r < 45 else 22
		if id.begins_with("rot_"):
			fs = 30
		var lines := text.split("\n")
		var widest := 0.0
		for ln in lines:
			widest = maxf(widest, font.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		if widest > 2.0 * r - 8.0:
			fs = maxi(11, int(fs * (2.0 * r - 6.0) / widest))
		for li in lines.size():
			var w := font.get_string_size(lines[li], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var y := c.y + fs * 0.35 + (li - (lines.size() - 1) * 0.5) * fs
			draw_string_outline(font, Vector2(c.x - w / 2, y), lines[li], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4,
					Color(0, 0, 0, 0.8))
			draw_string(font, Vector2(c.x - w / 2, y), lines[li], HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
