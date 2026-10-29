class_name WorldMap
extends PanelContainer
## Большая карта. Вкладка «Район» — Погуляй 3 × 3 км по манифесту владельца (data/district_pogulyay.json):
## сектора A1..C3, дороги с шириной коридора, дома со схемы, все 75 точек реестра с подписью по нажатию.
## Вкладка «Квартал» — двор старта с живыми точками (как мини-карта, но крупно).

signal closed

const KINDS := {"npc": ["NPC", Color(0.45, 0.9, 0.65)], "boss": ["Босс", Color(0.95, 0.38, 0.45)],
		"mob": ["Мобы", Color(1, 0.55, 0.3)], "place": ["Место", Color(0.93, 0.87, 0.75)],
		"safe": ["Отдых", Color(0.45, 0.78, 0.95)], "underground": ["Подземка", Color(0.95, 0.72, 0.3)]}
const FILTERS := [["all", "Всё"], ["npc", "NPC"], ["boss", "Боссы"], ["mob", "Мобы"], ["place", "Места"],
		["safe", "Отдых"], ["underground", "Подземка"]]

var district: Dictionary = {}
var source: Node              # мир: map_points(), объективная точка, игрок
var player: Node3D
var objective := Vector3.INF
var shapes: Array = []
var _tab := "district"
var _filter := "all"
var _tabs: HBoxContainer
var _filters: HBoxContainer
var _area: Control
var _district: _DistrictCanvas
var _quarter: MapCanvas
var _quarter_overlay: Control
var _info: Label


func _ready() -> void:
	visible = false
	district = District.data()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.1, 0.98)
	sb.border_color = Color(0.85, 0.72, 0.5, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(14)
	add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	v.add_child(head)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	head.add_child(_tabs)
	_filters = HBoxContainer.new()
	_filters.add_theme_constant_override("separation", 4)
	_filters.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filters.alignment = BoxContainer.ALIGNMENT_END
	head.add_child(_filters)
	_btn(head, " − ", func(): _zoom(1.0 / 1.4), 26).custom_minimum_size.x = 56
	_btn(head, " + ", func(): _zoom(1.4), 26).custom_minimum_size.x = 56
	var close := _btn(head, "  ✕  ", close_panel, 26)
	close.custom_minimum_size.x = 64
	_area = Control.new()
	_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_area.clip_contents = true
	v.add_child(_area)
	# при первом открытии сразу на квартале размер области ещё ноль: подгоняем, когда он появится
	_area.resized.connect(func() -> void:
		if _tab == "quarter":
			_fit_quarter())
	_district = _DistrictCanvas.new()
	_district.map = self
	_district.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_area.add_child(_district)
	_quarter = MapCanvas.new()
	_quarter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_quarter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.add_child(_quarter)
	_quarter_overlay = Control.new()
	_quarter_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_quarter_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quarter_overlay.draw.connect(_draw_quarter_overlay)
	_area.add_child(_quarter_overlay)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 17)
	_info.add_theme_color_override("font_color", Color(0.85, 0.83, 0.78))
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_info)


func open() -> void:
	visible = true
	_quarter.shapes = shapes
	if _district.zoom == 1.0 and _district.pan == Vector2.ZERO:
		_district.zoom = 3.0
		_district.pan = player_plan() - Vector2(District.SIZE_M, District.SIZE_M) / 2.0
	_render()
	_district.clamp_pan()


func close_panel() -> void:
	if visible:
		visible = false
		closed.emit()


func _render() -> void:
	for c in _tabs.get_children():
		c.queue_free()
	for t in [["district", "Район · Погуляй"], ["quarter", "Квартал · Старт"]]:
		var b := _btn(_tabs, "  %s  " % t[1], func():
			_tab = t[0]
			_render(), 22)
		b.toggle_mode = true
		b.button_pressed = _tab == t[0]
	for c in _filters.get_children():
		c.queue_free()
	if _tab == "district":
		for fl in FILTERS:
			var b := _btn(_filters, fl[1], func():
				_filter = fl[0]
				_render(), 17)
			b.toggle_mode = true
			b.button_pressed = _filter == fl[0]
			b.custom_minimum_size.y = 40
	_district.visible = _tab == "district"
	_quarter.visible = _tab == "quarter"
	_quarter_overlay.visible = _tab == "quarter"
	if _tab == "district":
		_info.text = "Погуляй, 3 × 3 км, 9 секторов. Ты в «Похмельной» (C1). Двигай карту пальцем, нажми на точку — " \
				+ "покажу, что там. Метки — разметка этапа 1: персонажи и бои появятся позже."
		_district.queue_redraw()
	else:
		_info.text = "Белые точки — с кем поговорить, красные — дроны, «!» — цель задания, поезд — выход в другой район."
		_fit_quarter.call_deferred()


func _fit_quarter() -> void:
	var r := PogulyayDressing.BOUNDS
	if _area.size.x < 1.0 or _area.size.y < 1.0:
		return
	_quarter.origin = r.get_center()
	_quarter.rot = -PI / 2.0     # квартал вытянут на север: кладём его вдоль экрана, север слева
	_quarter.scale_px = minf(_area.size.x / r.size.y, _area.size.y / r.size.x) * 0.95
	_quarter.queue_redraw()
	_quarter_overlay.queue_redraw()


func _zoom(k: float) -> void:
	if _tab == "district":
		_district.zoom = clampf(_district.zoom * k, 1.0, 16.0)
		_district.clamp_pan()
	else:
		_quarter.scale_px *= k
		_quarter.queue_redraw()
		_quarter_overlay.queue_redraw()


func _draw_quarter_overlay() -> void:
	if source and source.has_method("map_points"):
		for p in source.map_points():
			MapIcons.draw(_quarter_overlay, p.kind, _quarter.to_screen(p.pos), 1.4)
			if p.get("label", "") != "":
				_text(_quarter_overlay, _quarter.to_screen(p.pos) + Vector2(0, 26), p.label, 15, Color(0.95, 0.93, 0.85))
	if objective != Vector3.INF:
		MapIcons.draw(_quarter_overlay, "quest", _quarter.to_screen(objective), 1.4)
	if player and is_instance_valid(player):
		var at := _quarter.to_screen(player.global_position)
		var facing: Vector3 = player.get("facing") if "facing" in player else Vector3(0, 0, -1)
		var dir := (_quarter.to_screen(player.global_position + facing) - at).normalized()
		MapIcons.arrow(_quarter_overlay, at, dir, MiniMap.CYAN, 14.0)
		_text(_quarter_overlay, at + Vector2(0, -22), "Ты", 16, MiniMap.CYAN)
	# север
	var n := _quarter.to_screen(Vector3(_quarter.origin.x, 0, _quarter.origin.y - 1)) - _quarter.to_screen(
			Vector3(_quarter.origin.x, 0, _quarter.origin.y))
	var at_n := Vector2(40, 40)
	MapIcons.arrow(_quarter_overlay, at_n, n.normalized(), Color(1, 0.8, 0.3), 12.0)
	_text(_quarter_overlay, at_n + n.normalized() * 30, "С", 16, Color(1, 0.8, 0.3))


## Точка игрока на плане района, метры.
func player_plan() -> Vector2:
	if player == null or not is_instance_valid(player):
		return District.ORIGIN_M
	return District.to_plan(player.global_position)


func show_point(p: Dictionary) -> void:
	var kind: Array = KINDS.get(p.type, ["Точка", Color.WHITE])
	var sec := District.sector_at(District.pos(p))
	var at := District.pos(p)
	_info.text = "%s · %s — %s\n%s · сектор %s «%s» · %d м от тебя\n%s" % [p.id, p.name, kind[0], p.get("meta", ""),
			sec.get("id", "?"), sec.get("name", ""), int(at.distance_to(player_plan())), p.get("text", "")]


static func _text(ci: CanvasItem, at: Vector2, text: String, fs: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string_outline(font, at - Vector2(w / 2.0, -fs / 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5,
			Color(0, 0, 0, 0.85))
	ci.draw_string(font, at - Vector2(w / 2.0, -fs / 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _btn(parent: Node, text: String, cb: Callable, fs := 22) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", fs)
	b.custom_minimum_size.y = 48
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## План района в метрах: zoom 1 — весь район в кадре, pan — центр кадра от центра района.
class _DistrictCanvas extends Control:
	var map: WorldMap
	var zoom := 1.0
	var pan := Vector2.ZERO
	var _drag := false
	var _moved := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(clamp_pan)

	## Пикселей на метр.
	func k() -> float:
		return minf(size.x, size.y) * 0.96 * zoom / District.SIZE_M

	func to_px(m: Vector2) -> Vector2:
		return size / 2.0 + (m - Vector2(District.SIZE_M, District.SIZE_M) / 2.0 - pan) * k()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.pressed:
				_drag = true
				_moved = 0.0
			else:
				_drag = false
				if _moved < 12.0:
					_tap(event.position)
		elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and _drag:
			pan -= event.relative / k()
			_moved += event.relative.length()
			clamp_pan()

	## Край района не уезжает внутрь кадра, пока район больше кадра.
	func clamp_pan() -> void:
		if k() <= 0.0:
			return
		var lim := (Vector2(District.SIZE_M, District.SIZE_M) - size / k()) / 2.0
		lim = lim.max(Vector2.ZERO)
		pan = pan.clamp(-lim, lim)
		queue_redraw()

	func _tap(at: Vector2) -> void:
		var best: Dictionary = {}
		var best_d := 22.0
		for p in District.points():
			var d := to_px(_pos(p)).distance_to(at)
			if _shown(p) and d < best_d:
				best_d = d
				best = p
		if not best.is_empty():
			map.show_point(best)

	## NPC с действующим переопределением рисуется там, где он сейчас (одна копия).
	func _pos(p: Dictionary) -> Vector2:
		return District.npc_pos(p.id) if p.type == "npc" else District.pos(p)

	func _shown(p: Dictionary) -> bool:
		return map._filter == "all" or map._filter == p.type

	func _draw() -> void:
		var d := map.district
		if d.is_empty():
			return
		var kk := k()
		var o := to_px(Vector2.ZERO)
		var full := District.SIZE_M * kk
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.08, 0.1))
		draw_rect(Rect2(o, Vector2(full, full)), Color(0.2, 0.22, 0.23))
		# сектора: подложка парка и рынка, граница, подпись
		for z in d.get("sectors", []):
			var b: Array = z.bounds_plan_m
			var r := Rect2(to_px(Vector2(b[0], b[1])), Vector2(b[2] - b[0], b[3] - b[1]) * kk)
			if z.id == "A1":
				draw_rect(r, Color(0.19, 0.29, 0.21))
			elif z.id == "C2":
				draw_rect(r, Color(0.27, 0.23, 0.2))
			draw_rect(r, Color(0.5, 0.52, 0.5, 0.5), false, 1.5)
		# дома со схемы
		for h in District.houses():
			draw_rect(Rect2(to_px(h.position), h.size * kk), Color(0.33, 0.35, 0.38))
		# переулки внутри кварталов (этап 3)
		for s in District.road_segments():
			if s.id == "lane":
				draw_line(to_px(s.a), to_px(s.b), Color(0.36, 0.33, 0.3), maxf(1.0, s.w * kk))
		# дороги с шириной коридора
		for road in d.get("road_centerlines", []):
			var pts := PackedVector2Array()
			for q in road.polyline_plan_m:
				pts.append(to_px(Vector2(q[0], q[1])))
			var w := float(road.corridor_width_m)
			var col := Color(0.82, 0.68, 0.42) if road.id in ["tram_loop", "main_spine"] else (
					Color(0.55, 0.58, 0.58) if w >= 20.0 else Color(0.42, 0.45, 0.46))
			draw_polyline(pts, col, maxf(1.5, w * kk), true)
		# двор старта
		var sa := District.start_area()
		draw_rect(Rect2(to_px(sa.position), sa.size * kk), Color(0.85, 0.72, 0.5, 0.35))
		for z in d.get("sectors", []):
			var b: Array = z.bounds_plan_m
			var c := to_px(Vector2((b[0] + b[2]) / 2.0, b[1] + 60.0))
			WorldMap._text(self, c, "%s · %s" % [z.id, String(z.name).to_upper()], 17,
					Color(1, 0.95, 0.7) if z.id == "C1" else Color(0.85, 0.87, 0.85))
		# зоны точек: арены, радиусы мобов и отдыха
		for p in District.points():
			if not _shown(p):
				continue
			var c := to_px(District.pos(p))
			var col: Color = WorldMap.KINDS.get(p.type, ["", Color.WHITE])[1]
			if p.type == "boss":
				var a := District.m(p.arena_size_m) * kk
				draw_rect(Rect2(c - a / 2.0, a), Color(col, 0.25))
				draw_rect(Rect2(c - a / 2.0, a), col, false, 2.0)
			elif p.has("radius_m"):
				draw_circle(c, float(p.radius_m) * kk, Color(col, 0.12))
				draw_arc(c, float(p.radius_m) * kk, 0, TAU, 40, Color(col, 0.6), 1.5)
		# точки
		var r := clampf(kk * 14.0, 9.0, 16.0)
		for p in District.points():
			if not _shown(p):
				continue
			var c := to_px(_pos(p))
			var col: Color = WorldMap.KINDS.get(p.type, ["", Color.WHITE])[1]
			var rr := r * (1.4 if p.type == "boss" else (0.75 if p.type == "mob" else 1.0))
			draw_circle(c + Vector2(1, 2), rr + 2, Color(0, 0, 0, 0.6))
			draw_circle(c, rr, col)
			if zoom >= 2.0 or p.type == "boss":
				var id := String(p.id)
				var fs := int(maxf(10.0, rr * 0.8))
				var w := ThemeDB.fallback_font.get_string_size(id, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string(ThemeDB.fallback_font, c + Vector2(-w / 2.0, fs / 3.0), id, HORIZONTAL_ALIGNMENT_LEFT, -1,
						fs, Color(0.08, 0.08, 0.1))
			if zoom >= 4.0:
				WorldMap._text(self, c + Vector2(0, rr + 12), String(p.name), 14, Color(0.95, 0.93, 0.86))
		# герой
		var me := to_px(map.player_plan())
		draw_arc(me, r * 1.7, 0, TAU, 32, MiniMap.CYAN, 3.0)
		var facing: Vector3 = map.player.get("facing") if map.player and "facing" in map.player else Vector3(0, 0, -1)
		MapIcons.arrow(self, me, Vector2(facing.x, facing.z).normalized(), MiniMap.CYAN, r)
		WorldMap._text(self, me + Vector2(0, -r * 2.6), "Ты здесь", 16, MiniMap.CYAN)
		# масштаб и север
		var bar := 500.0 * kk
		var b0 := Vector2(20, size.y - 24)
		draw_line(b0, b0 + Vector2(bar, 0), Color(0.9, 0.9, 0.85), 2)
		WorldMap._text(self, b0 + Vector2(bar / 2, -14), "500 м", 15, Color(0.9, 0.9, 0.85))
		WorldMap._text(self, Vector2(size.x - 50, 24), "↑ СЕВЕР", 15, Color(1, 0.8, 0.4))
		# легенда
		var lx := 20.0
		for kind in WorldMap.KINDS:
			draw_circle(Vector2(lx + 7, 20), 7, WorldMap.KINDS[kind][1])
			var name: String = WorldMap.KINDS[kind][0]
			draw_string(ThemeDB.fallback_font, Vector2(lx + 18, 26), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
					Color(0.85, 0.85, 0.82))
			lx += 28 + ThemeDB.fallback_font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
