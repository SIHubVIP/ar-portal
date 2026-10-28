class_name InventoryPanel
extends PanelContainer
## Инвентарь героя: вкладки «Герой» (характеристики и надетое), «Сумки» (карточки предметов),
## «Способности» (что открыто, когда откроется остальное) и «Сундук» на базе.
## Все изменения идут через GameState, панель только перерисовывается по inventory_changed.

signal closed

const RARITY := {"common": Color(0.8, 0.8, 0.78), "uncommon": Color(0.4, 0.9, 0.45), "rare": Color(0.35, 0.65, 1),
		"epic": Color(0.8, 0.45, 1)}
const SLOTS := {"weapon": "Оружие", "head": "Голова", "body": "Тело"}
const TYPES := {"quest": "квестовый", "key": "ключ", "material": "материал", "weapon": "оружие", "armor": "одежда",
		"consumable": "расходник"}

var player: Player
var _tabs: HBoxContainer
var _body: Control
var _tab := "hero"
var _storage_mode := false
var _toast: Callable


func _ready() -> void:
	visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.08, 0.96)
	sb.border_color = Color(0.85, 0.72, 0.5, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(16)
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
	var close := _btn(head, "  ✕  ", close_panel, 26)
	close.custom_minimum_size.x = 70
	_body = ScrollContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_body)
	EventBus.inventory_changed.connect(func(): if visible: _render())


func set_toast(cb: Callable) -> void:
	_toast = cb


func open(tab := "hero") -> void:
	_storage_mode = false
	_tab = tab
	visible = true
	_render()


## Сундук гаража: перекладывание между героем и хранилищем.
func open_storage() -> void:
	_storage_mode = true
	_tab = "storage"
	visible = true
	_render()


func close_panel() -> void:
	if visible:
		visible = false
		closed.emit()


func _render() -> void:
	for c in _tabs.get_children():
		c.queue_free()
	var tabs := [["hero", "Герой"], ["bags", "Сумки"], ["abilities", "Способности"]]
	if _storage_mode:
		tabs.push_front(["storage", "Сундук"])
	for t in tabs:
		var b := _btn(_tabs, "  %s  " % t[1], func():
			_tab = t[0]
			_render(), 24)
		b.toggle_mode = true
		b.button_pressed = _tab == t[0]
	for c in _body.get_children():
		c.queue_free()
	match _tab:
		"hero":
			_render_hero()
		"bags":
			_render_bags()
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
		var fill := StyleBoxFlat.new()
		fill.bg_color = DialogView.TONE_COLORS[tone]
		bar.add_theme_stylebox_override("fill", fill)
		var back := StyleBoxFlat.new()
		back.bg_color = Color(1, 1, 1, 0.08)
		bar.add_theme_stylebox_override("background", back)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	h.add_child(right)
	_lbl(right, "Надето", 24, Color(1, 0.85, 0.55))
	for slot in SLOTS:
		var id: String = GameState.equipment.get(slot, "")
		var card := _card(right, id, SLOTS[slot])
		if id != "":
			_btn(card, "Снять", func(): GameState.unequip(slot), 20)


# ---------- Сумки ----------

func _render_bags() -> void:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(v)
	_lbl(v, "Карманы %d/%d   ·   Ранец %d/%d" % [GameState.pockets.size(), GameState.POCKET_SLOTS,
			GameState.backpack.size(), GameState.BACKPACK_SLOTS], 20, Color(0.75, 0.72, 0.65))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	var all := {}
	for bag in [GameState.pockets, GameState.backpack]:
		for id in bag:
			all[id] = int(all.get(id, 0)) + int(bag[id])
	if all.is_empty():
		_lbl(v, "Пусто. Даже мелочи нет — как у всего Погуляя.", 22)
	for id in all:
		var it: Dictionary = GameData.item_by_id.get(id, {})
		var card := _card(grid, id, "×%d%s" % [all[id], "  · в кармане" if GameState.pockets.has(id) else ""])
		card.custom_minimum_size.x = 370
		if it.has("slot"):
			_btn(card, "Надеть", func():
				if GameState.equip(id):
					_say("Надето: %s" % it.name), 20)
		if it.has("use"):
			_btn(card, "Использовать", func():
				var msg := GameState.use_item(id)
				if msg != "":
					_say(msg)
					if player:
						player.play_action("Flex", 0.8), 20)


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
	var h := HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 20)
	_body.add_child(h)
	var mine := VBoxContainer.new()
	mine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(mine)
	var chest := VBoxContainer.new()
	chest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(chest)
	_lbl(mine, "При себе", 24, Color(1, 0.85, 0.55))
	_btn(mine, "Сложить всё в сундук", func():
		var n := GameState.stash_backpack()
		_say("В сундук: %d" % n), 20)
	var carried := {}
	for bag in [GameState.pockets, GameState.backpack]:
		for id in bag:
			carried[id] = int(carried.get(id, 0)) + int(bag[id])
	for id in carried:
		var quest: bool = GameData.item_by_id.get(id, {}).get("type", "") == "quest"
		var card := _card(mine, id, "×%d" % carried[id])
		if quest:
			_lbl(card, "квестовый, всегда при себе", 15, Color(0.6, 0.6, 0.6))
		else:
			_btn(card, "В сундук →", func(): GameState.to_storage(id), 20)
	_lbl(chest, "Сундук гаража №13", 24, Color(1, 0.85, 0.55))
	if GameState.storage.is_empty():
		_lbl(chest, "Пусто. Только запах прошлого хозяина и чья-то вставная челюсть.", 18, Color(0.7, 0.7, 0.7)) \
				.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for id in GameState.storage:
		var card := _card(chest, id, "×%d" % GameState.storage[id])
		_btn(card, "← Взять", func(): GameState.from_storage(id), 20)


# ---------- элементы ----------

func _card(parent: Node, id: String, sub: String) -> VBoxContainer:
	var it: Dictionary = GameData.item_by_id.get(id, {})
	var p := _panel(parent, Color(0.13, 0.11, 0.1))
	var v := VBoxContainer.new()
	p.add_child(v)
	if id == "":
		_lbl(v, "%s: пусто" % sub, 20, Color(0.55, 0.55, 0.55))
		return v
	_lbl(v, it.get("name", id), 21, RARITY.get(it.get("rarity", "common"), Color.WHITE))
	var meta: PackedStringArray = [TYPES.get(it.get("type", ""), it.get("type", "")), sub]
	for k in it.get("stats", {}):
		meta.append({"damage": "урон +%d", "armor": "броня +%d", "max_hp": "здоровье +%d"}.get(k, k + " %d") % int(it.stats[k]))
	_lbl(v, " · ".join(meta), 16, Color(0.6, 0.85, 1))
	if it.get("desc", "") != "":
		var d := _lbl(v, it.desc, 16, Color(0.8, 0.77, 0.7))
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size.x = 330
	return v


func _panel(parent: Node, bg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color(0.35, 0.3, 0.25)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(10)
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
