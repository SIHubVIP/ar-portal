class_name Portrait
extends Control
## Рисованный портрет-шарж для диалога. Спецификация из data/dialogues.json -> speakers.*.portrait:
## kind (face, hero, phone, screen, journal), skin, hair, hair_color, eyes, mouth, extra[], bg.
## Портрет чуть «дышит» и моргает, говорящий подпрыгивает на новой реплике.

var spec: Dictionary = {}
var _t := 0.0
var _bounce := 0.0
var _blink := 0.0


func _ready() -> void:
	clip_contents = true


func set_spec(s: Dictionary) -> void:
	spec = s
	if spec.get("kind", "face") == "hero":
		spec = _hero_spec()
	_bounce = 1.0
	queue_redraw()


static func _hero_spec() -> Dictionary:
	match GameState.class_id:
		"CLASS_2":
			return {"kind": "face", "skin": "#e8b896", "hair": "comb", "hair_color": "#2b2018", "eyes": "narrow",
					"mouth": "grin", "extra": ["stubble", "gold_chain"], "bg": "#203a2c"}
		"CLASS_3":
			return {"kind": "face", "skin": "#e8c2a8", "hair": "mohawk", "hair_color": "#7a3fd0", "eyes": "crazy",
					"mouth": "grin", "extra": ["glasses"], "bg": "#2c2050"}
	return {"kind": "face", "skin": "#e2a98a", "hair": "bald", "hair_color": "#3a2a20", "eyes": "narrow",
			"mouth": "frown", "extra": ["stubble", "scar", "tank"], "bg": "#4a1c1a"}


func _process(delta: float) -> void:
	_t += delta
	_bounce = maxf(0.0, _bounce - delta * 3.0)
	_blink -= delta
	if _blink < -3.2:
		_blink = 0.12
	queue_redraw()


func _col(key: String, fallback: Color) -> Color:
	var v = spec.get(key, "")
	return Color.from_string(v, fallback) if v is String and v != "" else fallback


func _draw() -> void:
	var s := size
	var bg := _col("bg", Color(0.15, 0.12, 0.2))
	draw_rect(Rect2(Vector2.ZERO, s), bg.darkened(0.35))
	draw_circle(s * Vector2(0.5, 0.55), s.x * 0.48, bg)
	match spec.get("kind", "face"):
		"phone":
			_draw_phone(s)
		"screen":
			_draw_screen(s)
		"journal":
			_draw_journal(s)
		_:
			_draw_face(s)
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.95, 0.75, 0.3, 0.8), false, 3.0)


func _draw_face(s: Vector2) -> void:
	var extra: Array = spec.get("extra", [])
	var skin := _col("skin", Color(0.9, 0.72, 0.6))
	var hair := _col("hair_color", Color(0.25, 0.18, 0.12))
	var breathe := sin(_t * 2.0) * 2.0
	var c := Vector2(s.x * 0.5, s.y * 0.47 - _bounce * 14.0 + breathe)
	var r := s.x * 0.3
	# плечи и одежда
	var body_col := Color(0.2, 0.22, 0.3)
	if extra.has("robe"):
		body_col = Color(0.55, 0.45, 0.6)
	elif extra.has("tank"):
		body_col = Color(0.88, 0.86, 0.78)
	draw_circle(Vector2(s.x * 0.5, s.y + r * 0.55 + breathe), r * 1.55, body_col)
	if extra.has("tank"):
		draw_circle(Vector2(s.x * 0.5, s.y + r * 0.2 + breathe), r * 0.7, skin)
	if extra.has("tie"):
		draw_colored_polygon(PackedVector2Array([c + Vector2(-10, r * 1.15), c + Vector2(10, r * 1.15),
				c + Vector2(16, r * 2.2), c + Vector2(-16, r * 2.2)]), Color(0.8, 0.1, 0.15))
	if extra.has("gold_chain"):
		draw_arc(c + Vector2(0, r * 1.0), r * 0.7, 0.3, PI - 0.3, 16, Color(1, 0.8, 0.2), 5.0)
	draw_rect(Rect2(c + Vector2(-r * 0.32, r * 0.7), Vector2(r * 0.64, r * 0.5)), skin.darkened(0.1))
	# уши и голова
	for side in [-1, 1]:
		draw_circle(c + Vector2(side * r * 0.98, r * 0.08), r * 0.2, skin.darkened(0.08))
	draw_circle(c, r, skin)
	draw_circle(c + Vector2(0, r * 0.35), r * 0.86, skin)
	if extra.has("stubble"):
		draw_circle(c + Vector2(0, r * 0.55), r * 0.62, skin.darkened(0.18))
		draw_circle(c + Vector2(0, r * 0.38), r * 0.58, skin)
	# волосы
	match spec.get("hair", "bald"):
		"bald":
			draw_arc(c + Vector2(-r * 0.3, -r * 0.4), r * 0.25, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.5), 4.0)
		"combover":
			for i in 5:
				draw_arc(c + Vector2(0, r * 0.2), r * 0.95 - i * 3, PI * 1.15, PI * 1.85, 16, hair, 2.0)
		"comb":
			draw_circle(c + Vector2(0, -r * 0.55), r * 0.62, hair)
			draw_circle(c + Vector2(r * 0.3, -r * 0.6), r * 0.45, hair)
		"mohawk":
			for i in 6:
				draw_colored_polygon(PackedVector2Array([c + Vector2(-12 + i * 2, -r * 0.6 + i * 6),
						c + Vector2(12 - i * 2, -r * 0.6 + i * 6), c + Vector2(0, -r * 1.55 + i * 6)]), hair)
		"cap":
			draw_circle(c + Vector2(0, -r * 0.35), r * 0.85, hair)
			draw_rect(Rect2(c + Vector2(-r * 0.95, -r * 0.4), Vector2(r * 2.2, r * 0.22)), hair.darkened(0.3))
			draw_rect(Rect2(c + Vector2(-r * 0.86, -r * 0.42), Vector2(r * 1.72, r * 0.1)), Color(1, 1, 1, 0.85))
		"curlers":
			draw_circle(c + Vector2(0, -r * 0.5), r * 0.75, hair)
			for i in 5:
				var p := c + Vector2(-r * 0.7 + i * r * 0.35, -r * 0.95 + absf(i - 2) * r * 0.18)
				draw_circle(p, r * 0.15, Color(0.95, 0.4, 0.6))
				draw_circle(p, r * 0.07, Color(1, 0.8, 0.85))
		"antenna":
			for side in [-1, 1]:
				var base := c + Vector2(side * r * 0.35, -r * 0.85)
				var tip := base + Vector2(side * r * 0.35 + sin(_t * 3.0 + side) * 6.0, -r * 0.7)
				draw_line(base, tip, hair, 5.0)
				draw_circle(tip, r * 0.13, Color(0.9, 1, 0.4))
	# глаза
	var blink := _blink > 0.0
	for side in [-1, 1]:
		var e := c + Vector2(side * r * 0.36, -r * 0.02)
		match spec.get("eyes", "tired"):
			"huge":
				draw_circle(e, r * 0.28, Color.WHITE)
				if not blink:
					draw_circle(e + Vector2(0, r * 0.04), r * 0.18, Color(0.05, 0.05, 0.1))
					draw_circle(e + Vector2(-r * 0.06, -r * 0.05), r * 0.06, Color.WHITE)
			"crazy":
				draw_circle(e, r * (0.19 if side < 0 else 0.13), Color.WHITE)
				if not blink:
					draw_circle(e + Vector2(side * 3, 2), r * 0.07, Color(0.1, 0.1, 0.1))
			"narrow":
				draw_line(e + Vector2(-r * 0.15, 0), e + Vector2(r * 0.15, 0), Color(0.1, 0.08, 0.06), 5.0)
				draw_line(e + Vector2(-r * 0.18, -r * 0.14), e + Vector2(r * 0.16, -r * 0.1 * side), Color(0.15, 0.1, 0.05), 6.0)
			_:
				draw_circle(e, r * 0.12, Color.WHITE)
				if not blink:
					draw_circle(e + Vector2(0, 2), r * 0.06, Color(0.1, 0.1, 0.1))
				draw_arc(e + Vector2(0, r * 0.14), r * 0.14, 0.2, PI - 0.2, 8, skin.darkened(0.35), 3.0)
		if blink:
			draw_line(e + Vector2(-r * 0.14, 0), e + Vector2(r * 0.14, 0), Color(0.1, 0.08, 0.06), 4.0)
	if extra.has("glasses"):
		for side in [-1, 1]:
			draw_arc(c + Vector2(side * r * 0.36, -r * 0.02), r * 0.22, 0, TAU, 20, Color(0.1, 0.1, 0.1), 4.0)
		draw_line(c + Vector2(-r * 0.14, -r * 0.04), c + Vector2(r * 0.14, -r * 0.04), Color(0.1, 0.1, 0.1), 4.0)
	# нос
	draw_circle(c + Vector2(0, r * 0.28), r * 0.14, skin.darkened(0.12).lerp(Color(0.9, 0.3, 0.3), 0.25))
	if extra.has("scar"):
		draw_line(c + Vector2(r * 0.5, -r * 0.4), c + Vector2(r * 0.28, r * 0.15), Color(0.7, 0.3, 0.3), 3.0)
	if extra.has("mustache"):
		for side in [-1, 1]:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, r * 0.42), c + Vector2(side * r * 0.45, r * 0.5),
					c + Vector2(side * r * 0.4, r * 0.62), c + Vector2(0, r * 0.52)]), hair.darkened(0.2))
	# рот: на новой реплике раскрывается
	var talk := absf(sin(_t * 14.0)) * _bounce
	var m := c + Vector2(0, r * 0.68)
	var lip := Color(0.85, 0.15, 0.25) if extra.has("lipstick") else Color(0.35, 0.12, 0.1)
	match spec.get("mouth", "grin"):
		"grin":
			draw_arc(m + Vector2(0, -r * 0.12), r * 0.32, 0.3, PI - 0.3, 14, lip, 6.0)
		"frown":
			draw_arc(m + Vector2(0, r * 0.18), r * 0.25, PI + 0.5, TAU - 0.5, 12, lip, 6.0)
		"o":
			draw_circle(m, r * (0.09 + talk * 0.08), lip)
		"teeth":
			draw_rect(Rect2(m + Vector2(-r * 0.28, -r * 0.08), Vector2(r * 0.56, r * 0.18)), Color(0.95, 0.92, 0.8))
			if extra.has("gold_tooth"):
				draw_rect(Rect2(m + Vector2(r * 0.04, -r * 0.08), Vector2(r * 0.12, r * 0.18)), Color(1, 0.8, 0.2))
			draw_rect(Rect2(m + Vector2(-r * 0.28, -r * 0.08), Vector2(r * 0.56, r * 0.18)), lip, false, 3.0)
	if talk > 0.2:
		draw_circle(m + Vector2(0, r * 0.05), r * 0.07 * talk, Color(0.2, 0.05, 0.05))
	if extra.has("cigarette"):
		draw_line(m + Vector2(r * 0.2, 0), m + Vector2(r * 0.65, -r * 0.08), Color(0.95, 0.95, 0.9), 6.0)
		draw_circle(m + Vector2(r * 0.66, -r * 0.08), 4.0, Color(1, 0.4, 0.1))
		draw_circle(m + Vector2(r * 0.72, -r * 0.4 - fmod(_t * 12.0, 30.0)), 5.0, Color(0.8, 0.8, 0.85, 0.5))
	if extra.has("sweat"):
		var dy := fmod(_t * 30.0, r * 0.8)
		draw_circle(c + Vector2(r * 0.75, -r * 0.4 + dy), 5.0, Color(0.6, 0.85, 1, 0.9))


func _draw_phone(s: Vector2) -> void:
	var r := Rect2(s.x * 0.28, s.y * 0.12 - _bounce * 10.0, s.x * 0.44, s.y * 0.76)
	draw_rect(r, Color(0.08, 0.08, 0.1))
	draw_rect(r.grow(-8), Color(0.15, 0.35, 0.5))
	for i in 9:
		var h := (0.2 + absf(sin(_t * 9.0 + i * 1.3))) * s.y * 0.12
		draw_rect(Rect2(r.position.x + 18 + i * (r.size.x - 36) / 9.0, r.get_center().y - h * 0.5, 6, h), Color(0.5, 1, 0.9))
	draw_string(get_theme_default_font(), r.position + Vector2(14, 34), "ЖКХ ∞", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)


func _draw_screen(s: Vector2) -> void:
	var r := Rect2(s.x * 0.12, s.y * 0.18 - _bounce * 8.0, s.x * 0.76, s.y * 0.56)
	draw_rect(r.grow(10), Color(0.25, 0.25, 0.3))
	draw_rect(r, Color(0.05, 0.6, 0.3))
	for y in range(int(r.position.y), int(r.end.y), 6):
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(0, 0, 0, 0.15), 2.0)
	var c := r.get_center()
	for side in [-1, 1]:
		draw_rect(Rect2(c + Vector2(side * 40 - 10, -30), Vector2(20, 28)), Color(0.7, 1, 0.8))
	draw_arc(c + Vector2(0, 50), 40, PI + 0.4, TAU - 0.4, 12, Color(0.7, 1, 0.8), 8.0)
	draw_rect(Rect2(s.x * 0.47, r.end.y + 10, s.x * 0.06, s.y * 0.2), Color(0.25, 0.25, 0.3))


func _draw_journal(s: Vector2) -> void:
	var r := Rect2(s.x * 0.2, s.y * 0.15, s.x * 0.6, s.y * 0.7)
	draw_rect(r, Color(0.85, 0.8, 0.65))
	for i in 7:
		draw_line(Vector2(r.position.x + 14, r.position.y + 30 + i * 24),
				Vector2(r.end.x - 14 - (i % 3) * 20, r.position.y + 30 + i * 24), Color(0.3, 0.25, 0.2), 3.0)
	draw_rect(r, Color(0.3, 0.2, 0.1), false, 4.0)
