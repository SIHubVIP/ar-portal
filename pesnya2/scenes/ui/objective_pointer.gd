class_name ObjectivePointer
extends Control
## Стрелка «куда идти»: если цель за краем экрана — золотая стрелка у края с расстоянием,
## если на экране — метка с расстоянием над целью. Цель задаёт мир через Hud.set_objective().

var camera: Camera3D
var player: Node3D
var target := Vector3.INF
var label := ""
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if target == Vector3.INF or camera == null or player == null or not is_instance_valid(camera):
		return
	var dist := (player.global_position * Vector3(1, 0, 1)).distance_to(target * Vector3(1, 0, 1))
	if dist < 2.0:
		return
	var font := get_theme_default_font()
	var gold := Color(1, 0.82, 0.25)
	var head := target + Vector3(0, 2.6, 0)
	var behind := camera.is_position_behind(head)
	var p := camera.unproject_position(head)
	var margin := 70.0
	var rect := Rect2(Vector2(margin, margin + 40), size - Vector2(margin * 2, margin * 2 + 40))
	var text := "%d м" % roundi(dist)
	if not behind and rect.has_point(p):
		var y := p.y - 30 + sin(_t * 4.0) * 5.0
		_chevron(Vector2(p.x, y), Vector2.DOWN, gold, 16.0)
		_text(font, Vector2(p.x, y - 22), text, gold, 20)
		return
	var c := size / 2.0
	var dir := (p - c) * (-1.0 if behind else 1.0)
	if dir.length() < 1.0:
		dir = Vector2.UP
	dir = dir.normalized()
	# точка на краю прямоугольника по направлению
	var tx := (rect.size.x / 2.0) / maxf(absf(dir.x), 0.001)
	var ty := (rect.size.y / 2.0) / maxf(absf(dir.y), 0.001)
	var edge := c + dir * minf(tx, ty)
	var pulse := 1.0 + sin(_t * 5.0) * 0.12
	draw_circle(edge, 30.0 * pulse, Color(0, 0, 0, 0.55))
	draw_arc(edge, 30.0 * pulse, 0, TAU, 32, gold, 3.0)
	_chevron(edge, dir, gold, 14.0)
	_text(font, edge - dir * 48.0, text, gold, 20)
	if label != "":
		_text(font, edge - dir * 48.0 + Vector2(0, 22), label, Color(1, 0.95, 0.8), 16)


func _chevron(at: Vector2, dir: Vector2, color: Color, s: float) -> void:
	var side := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([at + dir * s, at - dir * s * 0.6 + side * s, at - dir * s * 0.2,
			at - dir * s * 0.6 - side * s]), color)


func _text(font: Font, at: Vector2, text: String, color: Color, fs: int) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string_outline(font, at - Vector2(w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.85))
	draw_string(font, at - Vector2(w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
