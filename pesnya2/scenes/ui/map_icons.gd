class_name MapIcons
extends RefCounted
## Значки карты, нарисованные примитивами (без картинок): одинаковые на мини-карте и большой.

const GOLD := Color(1, 0.8, 0.15)
const LEGEND := [["quest", "Цель задания"], ["npc", "С кем поговорить"], ["enemy", "Дроны-сборщики"],
		["transport", "Транспорт, выход в другой район"], ["base", "Твоя база"], ["shop", "Торговля"]]


static func draw(ci: CanvasItem, kind: String, at: Vector2, s: float) -> void:
	match kind:
		"npc":
			ci.draw_circle(at, 4.5 * s, Color(0, 0, 0, 0.6))
			ci.draw_circle(at, 3.5 * s, Color(0.97, 0.97, 0.95))
		"enemy":
			ci.draw_circle(at, 4.5 * s, Color(0, 0, 0, 0.6))
			ci.draw_circle(at, 3.5 * s, Color(1, 0.25, 0.25))
		"quest":
			_pin(ci, at, s)
		"transport":
			_train(ci, at, s)
		"base":
			_house(ci, at, s)
		"shop":
			ci.draw_circle(at, 9 * s, Color(0, 0, 0, 0.6))
			ci.draw_rect(Rect2(at + Vector2(-6, -2) * s, Vector2(12, 8) * s), Color(1, 0.6, 0.85))
			ci.draw_rect(Rect2(at + Vector2(-7, -6) * s, Vector2(14, 4) * s), Color(1, 0.35, 0.7))


## Голубая стрелка героя, dir — куда смотрит (единичный вектор на экране).
static func arrow(ci: CanvasItem, at: Vector2, dir: Vector2, color: Color, s: float) -> void:
	var side := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array([at + dir * s * 1.3, at - dir * s * 0.8 + side * s * 0.85, at - dir * s * 0.35,
			at - dir * s * 0.8 - side * s * 0.85])
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(1.5, 2))
	ci.draw_colored_polygon(shadow, Color(0, 0, 0, 0.55))
	ci.draw_colored_polygon(pts, color)


static func _pin(ci: CanvasItem, at: Vector2, s: float) -> void:
	var head := at + Vector2(0, -16) * s
	ci.draw_colored_polygon(PackedVector2Array([at, head + Vector2(-8, 5) * s, head + Vector2(8, 5) * s]), GOLD.darkened(0.15))
	ci.draw_circle(head + Vector2(1, 2), 11 * s, Color(0, 0, 0, 0.5))
	ci.draw_circle(head, 11 * s, GOLD)
	ci.draw_rect(Rect2(head + Vector2(-1.8, -7) * s, Vector2(3.6, 9) * s), Color(0.12, 0.1, 0.05))
	ci.draw_circle(head + Vector2(0, 5) * s, 2 * s, Color(0.12, 0.1, 0.05))


static func _train(ci: CanvasItem, at: Vector2, s: float) -> void:
	var w := Color(0.97, 0.97, 0.95)
	ci.draw_rect(Rect2(at + Vector2(-8, -10) * s, Vector2(16, 17) * s), w)
	ci.draw_rect(Rect2(at + Vector2(-6, -8) * s, Vector2(12, 6) * s), Color(0.15, 0.15, 0.17))
	ci.draw_circle(at + Vector2(-4, 3) * s, 1.8 * s, Color(0.15, 0.15, 0.17))
	ci.draw_circle(at + Vector2(4, 3) * s, 1.8 * s, Color(0.15, 0.15, 0.17))
	ci.draw_line(at + Vector2(-5, 7) * s, at + Vector2(-8, 11) * s, w, 2 * s)
	ci.draw_line(at + Vector2(5, 7) * s, at + Vector2(8, 11) * s, w, 2 * s)


static func _house(ci: CanvasItem, at: Vector2, s: float) -> void:
	var w := Color(1, 0.85, 0.5)
	ci.draw_circle(at, 11 * s, Color(0, 0, 0, 0.6))
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -8) * s, at + Vector2(8, -1) * s, at + Vector2(-8, -1) * s]), w)
	ci.draw_rect(Rect2(at + Vector2(-6, -1) * s, Vector2(12, 8) * s), w)
	ci.draw_rect(Rect2(at + Vector2(-2, 2) * s, Vector2(4, 5) * s), Color(0.15, 0.12, 0.08))
