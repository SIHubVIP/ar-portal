class_name InventoryPanel
extends PanelContainer
## Инвентарь героя: вкладки «Снаряжение» (кукла героя со слотами, карманы и ранец сеткой
## с иконками, карточка выбранной вещи), «Характер», «Способности» и «Сундук» на базе.
## Все изменения идут через GameState, панель только перерисовывается по inventory_changed.

signal closed

const RARITY := {"common": Color(0.8, 0.8, 0.78), "uncommon": Color(0.4, 0.9, 0.45), "rare": Color(0.35, 0.65, 1),
		"epic": Color(0.8, 0.45, 1)}
const SLOTS := {"weapon": "Оружие", "head": "Голова", "body": "Тело"}
## Где слот стоит вокруг куклы (левый верхний угол клетки в рамке куклы 380x400).
const SLOT_POS := {"head": Vector2(10, 30), "body": Vector2(10, 160), "weapon": Vector2(290, 160)}
const CELL := 80.0
const ICONS := "res://assets/icons/%s.png"
const TYPES := {"quest": "квестовый", "key": "ключ", "material": "материал", "weapon": "оружие", "armor": "одежда",
		"consumable": "расходник"}

var player: Player
var _tabs: HBoxContainer
var _body: Control
var _tab := "gear"
var _storage_mode := false
## Выбранная вещь: {"id", "from": pockets|backpack|equip|storage, "slot"}.
var _sel: Dictionary = {}
var _toast: Callable


func _ready() -> void:
	visible = false
	var sb := UiSkin.panel(16)
	add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	v.add_child(head)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_tabs)
	var close := UiSkin.icon_button("close", 54, Color(0, 0, 0, 0))
	close.pressed.connect(close_panel)
	head.add_child(close)
	_body = ScrollContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_body)
	EventBus.inventory_changed.connect(func(): if visible: _render())


func set_toast(cb: Callable) -> void:
	_toast = cb


## tab: gear|self|abilities. Старые имена hero и bags ведут в «Снаряжение».
func open(tab := "gear") -> void:
	_storage_mode = false
	_tab = "gear" if tab in ["hero", "bags"] else tab
	_sel = {}
	visible = true
	_render()


## Выбрать вещь из сумок (или надетую) и показать её карточку.
func select(item_id: String) -> void:
	for slot in GameState.equipment:
		if GameState.equipment[slot] == item_id:
			_sel = {"id": item_id, "from": "equip", "slot": slot}
	if GameState.pockets.has(item_id):
		_sel = {"id": item_id, "from": "pockets"}
	elif GameState.backpack.has(item_id):
		_sel = {"id": item_id, "from": "backpack"}
	_render()


## Сундук гаража: перекладывание между героем и хранилищем.
func open_storage() -> void:
	_storage_mode = true
	_tab = "storage"
	_sel = {}
	visible = true
	_render()


func close_panel() -> void:
	if visible:
		visible = false
		closed.emit()


func _render() -> void:
	for c in _tabs.get_children():
		c.queue_free()
	var tabs := [["gear", "Снаряжение"], ["self", "Характер"], ["abilities", "Способности"]]
	if _storage_mode:
		tabs.push_front(["storage", "Сундук"])
	for t in tabs:
		var b := _btn(_tabs, "  %s  " % t[1], func():
			_tab = t[0]
			_sel = {}
			_render(), 24)
		UiSkin.style_tab(b, _tab == t[0])
	for c in _body.get_children():
		c.queue_free()
	match _tab:
		"gear":
			_render_gear()
		"self":
			_render_hero()
		"abilities":
			_render_abilities()
		"storage":
			_render_storage()


# ---------- Герой ----------

func _render_hero() -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(h)
	var face := Portrait.new()
	face.custom_minimum_size = Vector2(170, 220)
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(face)
	face.set_spec({"kind": "hero"})
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 400
	h.add_child(left)
	var cls: Dictionary = GameData.class_by_id.get(GameState.class_id, {})
	_lbl(left, cls.get("name", "Герой"), 30, Color(1, 0.85, 0.55))
	_lbl(left, "Характер: %s" % GameState.character_title(), 22, Color(0.95, 0.6, 0.9))
	_lbl(left, "Уровень %d   ·   опыт %d / %d" % [GameState.level, GameState.xp, GameState.total_xp_for(GameState.level + 1)], 20)
	var dmg := Player.ATTACK_DAMAGE + GameState.stat("damage")
	_lbl(left, "Здоровье %d / %d" % [GameState.hp, GameState.max_hp], 22)
	_lbl(left, "Урон %d   ·   Броня %d" % [roundi(AbilityBook.scaled(dmg, GameState.level, false)), roundi(GameState.stat("armor"))], 22)
	_lbl(left, "Бабки %d   ·   Репутация %d   ·   Кукуха %d/100" % [GameState.babki, GameState.reputation, GameState.kukukha], 20)
	_lbl(left, "Кукуха растёт от выпивки, хамства и шаурмы. Высокая открывает самые отмороженные ответы.", 16,
			Color(0.65, 0.62, 0.58)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl(left, "Как ты разговариваешь", 20, Color(1, 0.85, 0.55))
	for tone in ["green", "orange", "cyan", "purple"]:
		var row := HBoxContainer.new()
		left.add_child(row)
		var l := _lbl(row, "● %s" % DialogView.TONE_HINTS[tone], 18, DialogView.TONE_COLORS[tone])
		l.custom_minimum_size.x = 170
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(200, 14)
		bar.show_percentage = false
		bar.max_value = maxi(5, GameState.tones.values().max() if not GameState.tones.is_empty() else 5)
		bar.value = int(GameState.tones.get(tone, 0))
		var boxes := UiSkin.bar_boxes(DialogView.TONE_COLORS[tone])
		bar.add_theme_stylebox_override("fill", boxes[0])
		bar.add_theme_stylebox_override("background", boxes[1])
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)


# ---------- Снаряжение ----------

func _render_gear() -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(h)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	h.add_child(left)
	var frame := _panel(left, Color(0.1, 0.08, 0.11))
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(380, 400)
	frame.add_child(stage)
	var doll := HeroDoll.new()
	doll.position = Vector2(90, 0)
	doll.size = Vector2(200, 400)
	stage.add_child(doll)
	for slot in SLOTS:
		var id: String = GameState.equipment.get(slot, "")
		var cell := _cell(stage, id, 0, {"id": id, "from": "equip", "slot": slot}, SLOTS[slot])
		cell.position = SLOT_POS[slot]
		_lbl(stage, SLOTS[slot], 15, Color(0.75, 0.68, 0.55)).position = SLOT_POS[slot] + Vector2(0, CELL + 2)
	var dmg := Player.ATTACK_DAMAGE + GameState.stat("damage")
	var cls: Dictionary = GameData.class_by_id.get(GameState.class_id, {})
	var who := _lbl(stage, "%s\nУр. %d" % [cls.get("name", "Герой"), GameState.level], 20, Color(1, 0.85, 0.55))
	who.position = Vector2(270, 24)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	who.size.x = 100
	var st := _lbl(left, "❤ %d/%d    урон %d    броня %d    бабки %d" % [GameState.hp, GameState.max_hp,
			roundi(AbilityBook.scaled(dmg, GameState.level, false)), roundi(GameState.stat("armor")), GameState.babki], 20)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	h.add_child(right)
	_lbl(right, "Карманы  %d/%d  ·  квестовое всегда при себе" % [GameState.pockets.size(), GameState.POCKET_SLOTS], 17,
			Color(0.85, 0.72, 0.5))
	_bag_grid(right, GameState.pockets, GameState.POCKET_SLOTS, "pockets", 8)
	_lbl(right, "Ранец  %d/%d" % [GameState.backpack.size(), GameState.BACKPACK_SLOTS], 17, Color(0.85, 0.72, 0.5))
	_bag_grid(right, GameState.backpack, GameState.BACKPACK_SLOTS, "backpack", 8)
	_detail(right)


func _bag_grid(parent: Node, bag: Dictionary, slots: int, from: String, columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	parent.add_child(grid)
	_fill(grid, bag, slots, from)
	return grid


## Клетки по раскладке GameState: вещь лежит там, куда её положил игрок.
func _fill(grid: GridContainer, bag: Dictionary, _slots: int, from: String) -> void:
	var cells := GameState.bag_cells(from)
	for i in cells.size():
		var id: String = cells[i]
		_cell(grid, id, int(bag.get(id, 0)), {"id": id, "from": from, "index": i}, "карман" if from == "pockets" else "")


## Клетка с иконкой: рамка цвета редкости, количество в углу, выбранная — золотая.
func _cell(parent: Node, id: String, count: int, sel: Dictionary, hint := "") -> Button:
	var it: Dictionary = GameData.item_by_id.get(id, {})
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(CELL, CELL)
	b.size = Vector2(CELL, CELL)
	var picked: bool = id != "" and _sel.get("id", "") == id and _sel.get("from", "") == sel.from
	var edge: Color = RARITY.get(it.get("rarity", "common"), Color.WHITE) if id != "" else Color(0.3, 0.27, 0.24)
	for st in ["normal", "hover", "pressed"]:
		# клетка как ячейка на диораме: светлее, если занята; кант цвета редкости, снизу толще
		var sb := StyleBoxFlat.new()
		sb.bg_color = UiSkin.INK_LIGHT.lightened(0.06) if id != "" else UiSkin.INK.lightened(0.04)
		if st != "normal" and id != "":
			sb.bg_color = sb.bg_color.lightened(0.1)
		sb.border_color = UiSkin.GOLD if picked else (edge.darkened(0.1) if id != "" else Color(UiSkin.OUTLINE, 0.6))
		sb.set_border_width_all(4 if picked else 3)
		sb.border_width_bottom = 6 if id != "" else 3
		sb.set_corner_radius_all(12)
		sb.anti_aliasing = true
		if id != "":
			sb.shadow_color = Color(edge, 0.3)
			sb.shadow_size = 5
		b.add_theme_stylebox_override(st, sb)
	parent.add_child(b)
	b.pressed.connect(func():
		if not _sel.is_empty() and _sel.get("id", "") != "" and not picked and (id == "" or sel.from == "equip"):
			drop(_sel, sel)
			return
		_sel = {} if picked else sel
		_render())
	_droppable(b, sel)
	if id == "":
		if hint != "":
			var l := _lbl(b, hint, 13, Color(0.4, 0.37, 0.33))
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		return b
	var tex := icon_for(id)
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 5
		icon.offset_top = 5
		icon.offset_right = -5
		icon.offset_bottom = -5
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(icon)
	else:
		var l := _lbl(b, String(it.get("name", id)).left(2), 26, edge)
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if count > 1:
		var c := _lbl(b, "%d" % count, 18, Color(1, 0.95, 0.8))
		c.add_theme_constant_override("outline_size", 5)
		c.add_theme_color_override("font_outline_color", Color.BLACK)
		c.position = Vector2(CELL - 26, CELL - 28)
	for n in b.get_children():
		if n is Control:
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## Перетаскивание: вещь тянется пальцем на любую клетку, слот куклы или в сундук.
## Без перетаскивания: выбери вещь касанием, потом коснись пустой клетки или слота.
func _droppable(b: Button, sel: Dictionary) -> void:
	b.set_drag_forwarding(func(_at: Vector2) -> Variant:
		if sel.id == "":
			return null
		var ghost := TextureRect.new()
		ghost.texture = icon_for(sel.id)
		ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost.size = Vector2(CELL, CELL)
		ghost.modulate.a = 0.85
		var holder := Control.new()
		holder.add_child(ghost)
		ghost.position = -ghost.size / 2.0
		b.set_drag_preview(holder)
		return sel,
	func(_at: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("from") and data != sel,
	func(_at: Vector2, data: Variant) -> void:
		drop(data, sel))


## Перенос вещи src → dst (обе — описания клеток). Публичный, чтобы тесты и касания шли одним путём.
func drop(src: Dictionary, dst: Dictionary) -> void:
	var why := ""
	if dst.from == "equip":
		var it: Dictionary = GameData.item_by_id.get(src.id, {})
		if src.from == "equip":
			why = ""
		elif src.from == "storage":
			why = "Сначала возьми из сундука"
		elif it.get("slot", "") != dst.slot:
			why = "Сюда это не надеть"
		elif not GameState.equip(src.id):
			why = "Не получилось надеть"
	elif src.from == "equip":
		why = GameState.unequip_to(src.slot, dst.from, int(dst.index))
	else:
		why = GameState.move_item(src.from, src.id, dst.from, int(dst.index))
	if why != "":
		_say(why)
	_sel = {}
	_render()


## Карточка выбранной вещи с действиями. Без выбора — подсказка.
func _detail(parent: Node) -> void:
	var p := _panel(parent, Color(0.12, 0.1, 0.09))
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var id: String = _sel.get("id", "")
	if id == "":
		var hint := _lbl(p, "Тащи вещь пальцем в любую клетку, на куклу или в сундук. Или нажми на вещь, потом на пустую клетку. Нажми — и рассмотри: свет тут хороший, в отличие от жизни.", 18,
				Color(0.6, 0.57, 0.52))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return
	var it: Dictionary = GameData.item_by_id.get(id, {})
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)
	var rarity: Color = RARITY.get(it.get("rarity", "common"), Color.WHITE)
	_lbl(v, it.get("name", id), 24, rarity)
	var meta: PackedStringArray = [TYPES.get(it.get("type", ""), it.get("type", ""))]
	for k in it.get("stats", {}):
		meta.append({"damage": "урон +%d", "armor": "броня +%d", "max_hp": "здоровье +%d"}.get(k, k + " %d") % int(it.stats[k]))
	var use: Dictionary = it.get("use", {})
	if use.has("heal"):
		meta.append("лечит %d" % int(use.heal))
	_lbl(v, " · ".join(meta), 16, Color(0.6, 0.85, 1))
	if it.get("desc", "") != "":
		var d := _lbl(v, it.desc, 16, Color(0.85, 0.82, 0.75))
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var acts := VBoxContainer.new()
	acts.add_theme_constant_override("separation", 6)
	acts.custom_minimum_size.x = 190
	h.add_child(acts)
	match String(_sel.get("from", "")):
		"equip":
			_btn(acts, "Снять", func():
				GameState.unequip(_sel.slot)
				_sel = {}, 20)
		"storage":
			_btn(acts, "← Взять", func():
				GameState.from_storage(id)
				if GameState.storage.get(id, 0) == 0:
					_sel = {}, 20)
		_:
			if it.has("slot"):
				_btn(acts, "Надеть", func():
					if GameState.equip(id):
						_say("Надето: %s" % it.name)
						_sel = {}
						_render(), 20)
			if it.has("use"):
				_btn(acts, "Использовать", func():
					var msg := GameState.use_item(id)
					if msg != "":
						_say(msg)
						if GameState.item_count(id) == 0:
							_sel = {}
						if player:
							player.play_action("Flex", 0.8), 20)
			if _storage_mode:
				if it.get("type", "") == "quest":
					_lbl(acts, "квестовое, всегда при себе", 15, Color(0.6, 0.6, 0.6))
				else:
					_btn(acts, "В сундук →", func():
						GameState.to_storage(id)
						if GameState.item_count(id) == 0:
							_sel = {}, 20)


# ---------- Способности ----------

func _render_abilities() -> void:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	_body.add_child(v)
	var list: Array = GameData.class_abilities(GameState.class_id if GameState.class_id != "" else "CLASS_1")
	for i in list.size():
		var a: Dictionary = list[i]
		var need := AbilityBook.unlock_level(i)
		var open := GameState.level >= need
		var d := AbilityBook.describe(a, GameState.level)
		var p := _panel(v, Color(0.12, 0.11, 0.1) if open else Color(0.08, 0.08, 0.08))
		var col := VBoxContainer.new()
		p.add_child(col)
		var title := "%s  ·  %s" % [a.name, a.kind]
		_lbl(col, title, 22, Color(1, 0.85, 0.55) if open else Color(0.55, 0.55, 0.55))
		if open:
			_lbl(col, d.stats, 18, Color(0.6, 0.9, 1))
			var t := _lbl(col, "%s  Выкрик: «%s»" % [d.text, d.shout], 18)
			t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			_lbl(col, "Откроется на %d уровне. До него %d опыта." % [need, maxi(0, GameState.total_xp_for(need) - GameState.xp)],
					18, Color(0.6, 0.6, 0.6))


# ---------- Сундук ----------

func _render_storage() -> void:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	_body.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	v.add_child(h)
	var mine := VBoxContainer.new()
	h.add_child(mine)
	var chest := VBoxContainer.new()
	h.add_child(chest)
	var head := HBoxContainer.new()
	mine.add_child(head)
	_lbl(head, "При себе", 20, Color(0.85, 0.72, 0.5))
	_btn(head, "Сложить ранец в сундук", func():
		var n := GameState.stash_backpack()
		_sel = {}
		_say("В сундук: %d" % n), 17).custom_minimum_size.y = 36
	# карманы и ранец одной сеткой: первые четыре клетки — карманы
	var g := _bag_grid(mine, GameState.pockets, GameState.POCKET_SLOTS, "pockets", 7)
	_fill(g, GameState.backpack, GameState.BACKPACK_SLOTS, "backpack")
	_lbl(chest, "Сундук гаража №13  ·  предметов: %d" % GameState.storage.size(), 20, Color(0.85, 0.72, 0.5))
	_bag_grid(chest, GameState.storage, 24, "storage", 6)
	if GameState.storage.is_empty():
		_lbl(chest, "Пусто. Только запах прошлого хозяина и чья-то вставная челюсть.", 16, Color(0.6, 0.6, 0.6))
	_detail(v)


# ---------- элементы ----------

## Значок вещи: свой рисунок из assets/icons, иначе общий значок вида из assets/ui (вещи поручений).
static func icon_for(id: String) -> Texture2D:
	if ResourceLoader.exists(ICONS % id):
		return load(ICONS % id)
	var ui: String = GameData.item_by_id.get(id, {}).get("icon", "")
	return UiSkin.icon(ui) if ui != "" else null


func _panel(parent: Node, bg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UiSkin.card(Color(0, 0, 0, 0), 1.0, 10)
	sb.bg_color = bg.lerp(UiSkin.INK_LIGHT, 0.6)
	sb.border_color = Color(UiSkin.OUTLINE, 0.7)
	sb.set_border_width_all(2)
	sb.content_margin_left = 10
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	return p


func _lbl(parent: Node, text: String, fs: int, color := Color(0.95, 0.93, 0.88)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _btn(parent: Node, text: String, cb: Callable, fs := 22) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", fs)
	b.custom_minimum_size.y = 48
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _say(text: String) -> void:
	if _toast.is_valid():
		_toast.call(text)
