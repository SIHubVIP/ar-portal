class_name CityMap
extends Control
## 0.7: the map of Рубин — districts, open places, places coming in the next updates, markers («!», remix, Сингл Принц)
## and Pilot's aerotaxi (tap a place → «Лететь»).

const PURPLE := Color("b06eff")

var g      # main game
var hud    # Hud (fonts, button helpers)
var sel := ""
var area := Rect2()
var fly_btn: Button
var close_btn: Button


func setup(game, h) -> void:
	g = game
	hud = h
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	close_btn = hud._secondary(hud._btn("ЗАКРЫТЬ", func(): g.close_list(), 170))
	add_child(close_btn)
	fly_btn = hud._btn("ЛЕТЕТЬ", func(): g.fly_to(_sel_map()), 330)
	add_child(fly_btn)
	resized.connect(func():
		if visible:
			_layout())


func open() -> void:
	sel = g.map_id
	visible = true
	_layout()
	queue_redraw()


func refresh() -> void:
	_layout()
	queue_redraw()


func _place(id: String) -> Dictionary:
	for pl in GameData.CITY_PLACES:
		if pl.id == id:
			return pl
	return {}


func _sel_map() -> String:
	var pl := _place(sel)
	return str(pl.get("map", ""))


func _pt(p: Vector2) -> Vector2:
	return area.position + Vector2(p.x * area.size.x, p.y * area.size.y)


func _layout() -> void:
	var s := size
	area = Rect2(28, 96, s.x - 56, s.y - 96 - 128)
	close_btn.position = Vector2(s.x - 200, 22)
	close_btn.size = Vector2(172, 54)
	fly_btn.position = Vector2(s.x - 362, s.y - 96)
	fly_btn.size = Vector2(330, 62)
	var m := _sel_map()
	if m == "":
		fly_btn.text = "ОТКРОЕТСЯ ПОЗЖЕ"
		fly_btn.disabled = true
	elif m == g.map_id:
		fly_btn.text = "ТЫ ЗДЕСЬ"
		fly_btn.disabled = true
	elif not g.map_open(m):
		fly_btn.text = "ЕЩЁ НЕ ОТКРЫТО"
		fly_btn.disabled = true
	elif not g.taxi:
		fly_btn.text = "АЭРОТАКСИ ЗАКРЫТО"
		fly_btn.disabled = true
	else:
		var price := GameData.taxi_price(g.map_id, m)
		fly_btn.text = "ЛЕТЕТЬ · %d МОНЕТ" % price
		fly_btn.disabled = g.coins < price


func _gui_input(e: InputEvent) -> void:
	var tap: bool = (e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT)
	if tap:
		var p: Vector2 = e.position
		var best := ""
		var bd := 48.0
		for pl in GameData.CITY_PLACES:
			var d := _pt(pl.p).distance_to(p)
			if d < bd:
				bd = d
				best = pl.id
		if best != "":
			select(best)
			accept_event()


func select(id: String) -> void:
	if id != sel:
		g.play_sfx("ui", 1.2, -6.0)
	sel = id
	_layout()
	queue_redraw()


func _txt(p: Vector2, s: String, sz: int, col: Color, display := false, center := false, outline := 4) -> void:
	var f: FontFile = hud.fd if display else hud.fb
	var pp := p
	if center:
		pp.x -= f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x / 2
	if outline > 0:
		draw_string_outline(f, pp, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, outline, Color(0, 0, 0, 0.85))
	draw_string(f, pp, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _rrect(r: Rect2, col: Color, rad := 14, border := 0.0, bcol := Color.WHITE) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(rad)
	if border > 0.0:
		sb.set_border_width_all(int(border))
		sb.border_color = bcol
	draw_style_box(sb, r)


func _draw() -> void:
	if g == null:
		return
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.035, 0.05, 0.1, 0.97))
	_txt(Vector2(30, 50), "КАРТА РУБИНА", 32, Hud.GOLD, true, false, 0)
	var sub := "Страна «Богатая» · вселенная «Песня» · "
	sub += ("Аэротакси «Ложка»: выбери место и жми «Лететь»" if g.taxi else "Аэротакси откроет Шустрый Пилот («Воздушный патруль»)")
	_txt(Vector2(32, 80), sub, 16, Color(0.78, 0.84, 0.92), false, false, 0)
	# districts
	for dd in GameData.CITY_DISTRICTS:
		var r: Rect2 = dd[1]
		var rr := Rect2(_pt(r.position), Vector2(r.size.x * area.size.x, r.size.y * area.size.y))
		_rrect(rr, Color(1, 1, 1, 0.045), 16, 2.0, Color(1, 1, 1, 0.12))
		_txt(rr.position + Vector2(12, 20), str(dd[0]).to_upper(), 13, Color(0.55, 0.85, 0.8), false, false, 0)
	# the river with Kalinov bridge
	var ry := area.position.y + 0.70 * area.size.y
	var rx0 := area.position.x + 0.285 * area.size.x
	var rx1 := area.position.x + 0.985 * area.size.x
	draw_rect(Rect2(rx0, ry - 9, rx1 - rx0, 18), Color("2a6a9a"))
	draw_line(_pt(Vector2(0.42, 0.66)), _pt(Vector2(0.42, 0.74)), Color("c8b8a0"), 10.0)
	_txt(Vector2(rx1 - 140, ry + 26), "река", 13, Color("7ab8e8"), false, false, 0)
	_txt(_pt(Vector2(0.44, 0.705)) + Vector2(6, 5), "Калинов мост", 13, Color("e8d8b8"), false, false, 0)
	# roads between places
	for l in GameData.CITY_LINKS:
		var a := _place(l[0])
		var b := _place(l[1])
		var both: bool = g.map_open(a.map) and g.map_open(b.map)
		var col := Color(0.55, 0.85, 0.8, 0.8) if both else Color(1, 1, 1, 0.18)
		var pa := _pt(a.p)
		var pb := _pt(b.p)
		if both:
			draw_line(pa, pb, col, 4.0)
		else:
			var n := int(pa.distance_to(pb) / 14.0)
			for k in range(n):
				if k % 2 == 0:
					draw_line(pa.lerp(pb, k / float(n)), pa.lerp(pb, (k + 1) / float(n)), col, 3.0)
	# places
	for pl in GameData.CITY_PLACES:
		var c := _pt(pl.p)
		var is_sel: bool = pl.id == sel
		if pl.has("map"):
			var m: String = pl.map
			var open: bool = g.map_open(m)
			var here: bool = m == g.map_id
			if here:
				var pulse := 1.0 + 0.12 * sin(g.time * 5.0)
				draw_circle(c, 26 * pulse, Color(Hud.GOLD, 0.25))
			draw_circle(c, 17, Hud.GOLD if here else (Hud.TEAL if open else Color(0.35, 0.38, 0.45)))
			draw_arc(c, 17, 0, TAU, 32, Color(1, 1, 1, 0.8 if is_sel else 0.35), 3.0 if is_sel else 2.0)
			if not open:
				_txt(c + Vector2(0, 7), "?", 20, Color(0.9, 0.92, 1.0), true, true, 0)
			var up: bool = pl.get("up", false)
			_txt(c + Vector2(0, -28 if up else 40), pl.name, 17, Hud.CREAM if open else Color(0.65, 0.68, 0.75), true, true)
			if here:
				_txt(c + Vector2(0, -46 if up else 58), "ты здесь", 13, Hud.GOLD, false, true)
			var mk: String = g.map_marker(m) if open else ""
			if mk != "":
				_txt(c + (Vector2(22, 30) if up else Vector2(20, -12)), mk, 30, Hud.GOLD, true, false, 5)
			var badges := []
			for bkey in GameData.REMIX_ORDER:
				if GameData.REMIX[bkey].map == m and g.remix_open(bkey):
					badges.append("R")
			if badges.size() > 0:
				draw_circle(c + Vector2(-22, -16), 10, PURPLE)
				_txt(c + Vector2(-22, -10), "R", 14, Color.WHITE, true, true, 0)
			if not g.prince_npc.is_empty() and g.prince.map == m:
				var cc := c + Vector2(24, 18)
				draw_circle(cc, 12, Hud.GOLD)
				draw_colored_polygon(PackedVector2Array([cc + Vector2(-7, 4), cc + Vector2(-7, -5), cc + Vector2(-3.5, -1), cc + Vector2(0, -7),
					cc + Vector2(3.5, -1), cc + Vector2(7, -5), cc + Vector2(7, 4)]), Hud.NAVY)
		else:
			draw_circle(c, 10, Color(0.3, 0.32, 0.4, 0.9))
			draw_arc(c, 10, 0, TAU, 24, Color(1, 1, 1, 0.75 if is_sel else 0.2), 2.0)
			_txt(c + Vector2(0, 28), pl.name, 13, Color(0.6, 0.63, 0.72), false, true)
			_txt(c + Vector2(14, -6), str(pl.ver), 12, Color(0.85, 0.7, 1.0), true, false, 3)
	# info about the selected place
	var info := Rect2(28, s.y - 116, s.x - 410, 100)
	_rrect(info, Color(0.06, 0.08, 0.15, 0.95), 16, 2.0, Color(1, 1, 1, 0.12))
	var pl2 := _place(sel)
	if pl2.is_empty():
		return
	if pl2.has("map"):
		var m2: String = pl2.map
		var ci: Array = GameData.CITY_INFO.get(m2, ["", "", ""])
		_txt(info.position + Vector2(18, 30), pl2.name, 21, Hud.GOLD, true, false, 0)
		if g.map_open(m2):
			_txt(info.position + Vector2(18, 56), str(ci[0]), 15, Hud.CREAM, false, false, 0)
			_txt(info.position + Vector2(18, 78), str(ci[1]), 15, Color(0.75, 0.82, 0.92), false, false, 0)
			var rmx := []
			for bkey in GameData.REMIX_ORDER:
				if GameData.REMIX[bkey].map == m2 and g.remix_open(bkey):
					rmx.append("ремикс «%s»" % GameData.REMIX[bkey].title)
			_txt(info.position + Vector2(18, 96), ("Как дойти: " + str(ci[2])) + ((" · " + ", ".join(rmx)) if rmx.size() > 0 else ""), 13, Color(0.6, 0.85, 0.8), false, false, 0)
		else:
			_txt(info.position + Vector2(18, 58), "Ещё не открыто: проходи сюжет — откроется само", 16, Hud.CREAM, false, false, 0)
			_txt(info.position + Vector2(18, 82), "Подсказка: " + str(ci[2]), 15, Color(0.7, 0.76, 0.86), false, false, 0)
	else:
		_txt(info.position + Vector2(18, 30), "%s · обновление %s" % [pl2.name, pl2.ver], 21, Color(0.85, 0.7, 1.0), true, false, 0)
		_txt(info.position + Vector2(18, 58), str(pl2.get("about", "")), 16, Hud.CREAM, false, false, 0)
		_txt(info.position + Vector2(18, 82), "Скоро: это место уже в плане обновлений", 14, Color(0.7, 0.76, 0.86), false, false, 0)
