class_name MiniMap
extends Control
## Круглая мини-карта как на ориентире геймплея: квартал сверху в серых тонах, белая рамка,
## «N» ездит по ободу (карта крутится вместе с камерой), голубая стрелка — герой,
## жёлтая «!» — цель задания (за краем прижимается к ободу), белые точки — с кем говорить,
## красные — дроны, значки транспорта и базы. Нажатие открывает большую карту.

signal opened

const RADIUS := 100.0
const METERS := 26.0          # радиус обзора в метрах
const CYAN := Color(0.2, 0.95, 1.0)
const GOLD := Color(1, 0.8, 0.15)

var camera: IsoCamera
var player: Node3D
var source: Node                # мир с методом map_points()
var objective := Vector3.INF
var _canvas: MapCanvas
var _overlay: Control
var _tick := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(RADIUS * 2 + 8, RADIUS * 2 + 8)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var mask := _Mask.new()
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	mask.position = Vector2(4, 4)
	mask.size = Vector2(RADIUS * 2, RADIUS * 2)
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mask)
	_canvas = MapCanvas.new()
	_canvas.size = mask.size
	_canvas.scale_px = RADIUS / METERS
	_canvas.district = true
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.add_child(_canvas)
	_overlay = Control.new()
	_overlay.size = size
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


func set_shapes(shapes: Array) -> void:
	_canvas.shapes = shapes


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		opened.emit()
		accept_event()


func _process(delta: float) -> void:
	_tick += delta
	if _tick < 0.1 or player == null or not is_instance_valid(player):
		return
	_tick = 0.0
	_canvas.origin = Vector2(player.global_position.x, player.global_position.z)
	_canvas.rot = camera.yaw if camera else 0.0
	_canvas.queue_redraw()
	_overlay.queue_redraw()


func _draw_overlay() -> void:
	if player == null or not is_instance_valid(player):
		return
	var c := Vector2(RADIUS + 4, RADIUS + 4)
	var off := c - _canvas.size / 2.0 - Vector2(4, 4)
	# обод как у кнопок: тёмный контур, кремовый кант
	_overlay.draw_arc(c, RADIUS + 1, 0, TAU, 72, UiSkin.OUTLINE, 9.0, true)
	_overlay.draw_arc(c, RADIUS, 0, TAU, 72, UiSkin.CREAM, 4.0, true)
	if source and source.has_method("map_points"):
		for p in source.map_points():
			var at: Vector2 = _canvas.to_screen(p.pos) + Vector2(4, 4) + off
			if at.distance_to(c) > RADIUS - 6:
				continue
			MapIcons.draw(_overlay, p.kind, at, 1.0)
	if objective != Vector3.INF:
		var at: Vector2 = _canvas.to_screen(objective) + Vector2(4, 4) + off
		if at.distance_to(c) > RADIUS - 14:
			at = c + (at - c).normalized() * (RADIUS - 14)
		MapIcons.draw(_overlay, "quest", at, 1.0)
	# герой: стрелка смотрит туда же, куда он
	var facing: Vector3 = player.get("facing") if player and "facing" in player else Vector3(0, 0, -1)
	var dir: Vector2 = (_canvas.to_screen(player.global_position + facing) - _canvas.to_screen(player.global_position)).normalized()
	MapIcons.arrow(_overlay, c, dir, CYAN, 11.0)
	# север на ободе
	var yaw := camera.yaw if camera else 0.0
	var n := c + Vector2(sin(yaw), -cos(yaw)) * RADIUS
	_overlay.draw_circle(n, 14, UiSkin.RED)
	_overlay.draw_arc(n, 14, 0, TAU, 24, UiSkin.OUTLINE, 3.0, true)
	var font := get_theme_default_font()
	_overlay.draw_string(font, n + Vector2(-6, 6), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)


class _Mask extends Control:
	func _draw() -> void:
		draw_circle(size / 2.0, size.x / 2.0, Color.WHITE)
