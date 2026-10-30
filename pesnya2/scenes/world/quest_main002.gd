class_name QuestMain002
extends Node3D
## MAIN_002 «Живой, следовательно должник» (0.17): контора ЖКХ «Вечный долг» у остановки
## такси в Деловом. До 0.17 у задания не было точки старта — стрелка доводила до арки двора
## и гасла. Теперь: пришёл к окошку конторы — задание принято, дальше по этапам карточки:
##   S01 квитанция с ошибочной датой — лежит на лавке у конторы;
##   S02 архив в обход трёх очередей — чёрный ход за архивом;
##   S03 сверить реестры — шкаф у чёрного хода;
##   S04 выбор А/Б из карточки (опубликовать реестр / фиктивная амнистия).
## Реплики Нины и дрона — key_lines карточки, остальное — editorial_P3.

const QID := "MAIN_002"

var world: Node3D        # сцена района: hud, player, _interactables, _zones
var window_pos := Vector3.INF
var receipt_pos := Vector3.INF
var back_door := Vector3.INF
var registry_pos := Vector3.INF
var _receipt: Node3D
var _nina: Node3D


func _ready() -> void:
	name = "QuestMain002"
	set_meta("map_skip", true)


## Строит контору, архив и очереди у остановки такси Делового. stop — план остановки.
func build(stop: Vector2) -> void:
	var office := _free_rect(stop + Vector2(-14, 10), Vector2(9, 7), [])
	var archive := _free_rect(stop + Vector2(16, 18), Vector2(10, 8), [Rect2(office.position - Vector2(8, 8), office.size + Vector2(16, 16))])
	_office(office)
	_archive(archive)
	var hud: Hud = world.hud
	world._zones.append({"pos": window_pos, "radius": 4.5, "cb": _arrive,
			"when": func() -> bool: return QuestService.state_of(QID) == QuestService.AVAILABLE})
	world._zones.append({"pos": receipt_pos, "radius": 2.4, "cb": _take_receipt,
			"when": func() -> bool: return QuestService.is_on_stage(QID, "MAIN_002_S01")})
	world._interactables.append({"pos": window_pos, "radius": 3.0, "label": "Нина", "face": _nina,
			"cb": func() -> void: hud.play_dialog([{"speaker": "Нина", "text": "Окно закрыто. Окно всегда закрыто. Это окно для закрытых вопросов."}]),
			"enabled": func() -> bool: return QuestService.state_of(QID) != QuestService.AVAILABLE})
	world._interactables.append({"pos": back_door, "radius": 3.0, "label": "Чёрный ход", "cb": _sneak,
			"enabled": func() -> bool: return QuestService.is_on_stage(QID, "MAIN_002_S02")})
	world._interactables.append({"pos": registry_pos, "radius": 3.0, "label": "Реестры", "cb": _registry,
			"enabled": func() -> bool: return QuestService.is_on_stage(QID, "MAIN_002_S03") or QuestService.is_on_stage(QID, "MAIN_002_S04")})
	EventBus.quest_stage_changed.connect(func(_q, _s) -> void: _refresh())
	EventBus.quest_state_changed.connect(func(_q, _s) -> void: _refresh())
	_refresh()


## Цель для стрелки: [позиция, подпись, подсказка]; INF — у этого задания цели нет.
func objective() -> Array:
	var st := QuestService.state_of(QID)
	if st == QuestService.AVAILABLE:
		return [window_pos, "Контора ЖКХ", "Контора ЖКХ «Вечный долг» в Деловом. Быстрее — на такси у двора"]
	if QuestService.is_on_stage(QID, "MAIN_002_S01"):
		return [receipt_pos, "Квитанция", "Квитанция где-то у конторы"]
	if QuestService.is_on_stage(QID, "MAIN_002_S02"):
		return [back_door, "Чёрный ход", "Очереди в архив — до пенсии. Обойди сзади"]
	if QuestService.is_on_stage(QID, "MAIN_002_S03") or QuestService.is_on_stage(QID, "MAIN_002_S04"):
		return [registry_pos, "Реестры", "Сверь реестры жильцов"]
	return [Vector3.INF, "", ""]


func _refresh() -> void:
	if is_instance_valid(_receipt):
		_receipt.visible = QuestService.state_of(QID) in [QuestService.AVAILABLE, QuestService.LOCKED] \
				or QuestService.is_on_stage(QID, "MAIN_002_S01")


func _arrive() -> void:
	if not QuestService.accept(QID):
		return
	var q := GameData.quest(QID)
	world.hud.play_dialog([{"speaker": "Нина", "text": "У нас конец света по субботам не принимают."},
			{"speaker": "journal", "text": "%s" % q.setup},
			{"speaker": "Нина", "text": "Квитанцию потеряли? Все теряют. Поищите на лавочке, туда всё и кладут."}])


func _take_receipt() -> void:
	if QuestService.advance(QID, "MAIN_002_S01"):
		_receipt.visible = false
		world.hud.show_toast("Квитанция: «Оплатить до вчера. Пени начислены заранее»")


func _sneak() -> void:
	if QuestService.advance(QID, "MAIN_002_S02"):
		world.hud.play_dialog([{"speaker": "journal", "text": "Три очереди смотрят тебе в спину. Одна — за справкой, другая — за справкой о справке, третья — просто привыкла."},
				{"speaker": "Дрон", "text": "Ваша жизнь продлена до оплаты пени."}])


func _registry() -> void:
	if QuestService.is_on_stage(QID, "MAIN_002_S03"):
		QuestService.advance(QID, "MAIN_002_S03")
		var q := GameData.quest(QID)
		world.hud.play_dialog([{"speaker": "journal", "text": "Реестр жильцов и реестр должников совпадают. Даже соседи, которые улетели."},
				{"speaker": "journal", "text": "Поворот: %s" % q.twist}], _ask)
	else:
		_ask()


func _ask() -> void:
	var q := GameData.quest(QID)
	world.hud.ask_choice("Что делать с реестром?", [
		{"key": "A", "key_label": "А", "text": q.choices.A.text, "hint": q.choices.A.result, "tone": "green"},
		{"key": "B", "key_label": "Б", "text": q.choices.B.text, "hint": q.choices.B.result, "tone": "purple"}], _choose)


func _choose(key: String) -> void:
	if not QuestService.choose(QID, key):
		return
	var q := GameData.quest(QID)
	QuestService.turn_in(QID)
	world.hud.play_dialog([{"speaker": "journal", "text": "%s." % q.choices[key].result}])


# ---------- постройки ----------

## Свободный прямоугольник size около точки плана: все клетки проходимы и не в запретных.
func _free_rect(near: Vector2, size: Vector2, avoid: Array) -> Rect2:
	# не на проезжей части и тротуаре: дороги в 120 м от точки
	var roads := District.road_segments().filter(func(s: Dictionary) -> bool:
		return District.dist_to_segment(near, s.a, s.b) < 120.0)
	var clear := func(q: Vector2) -> bool:
		for s: Dictionary in roads:
			if District.dist_to_segment(q, s.a, s.b) < float(s.w) / 2.0 + (3.5 if s.id == "street" else 1.0):
				return false
		return District.walkable(q)
	for rad in range(0, 90, 2):
		for a in range(0, 360, 20):
			var c := near + Vector2.from_angle(deg_to_rad(a)) * rad
			var r := Rect2(c - size / 2.0, size)
			var ok := true
			for x in range(0, 5):
				for y in range(0, 5):
					var q := r.position + Vector2(r.size.x * x / 4.0, r.size.y * y / 4.0)
					ok = ok and clear.call(q) and clear.call(q + Vector2(0, 4))
			for b: Rect2 in avoid:
				ok = ok and not b.intersects(r)
			if ok:
				return r
			if rad == 0:
				break
	return Rect2(near - size / 2.0, size)


func _office(r: Rect2) -> void:
	var c := District.to_world(r.get_center())
	var front := c + Vector3(0, 0, r.size.y / 2.0)
	Kit.solid_box(self, Vector3(r.size.x, 3.2, r.size.y - 2.0), c + Vector3(0, 1.6, -1.0), Color(0.62, 0.66, 0.58))
	Kit.box(self, Vector3(r.size.x + 0.4, 0.25, r.size.y - 1.6), c + Vector3(0, 3.3, -1.0), Color(0.3, 0.3, 0.32))
	Signboard.make(self, "ЖКХ «ВЕЧНЫЙ ДОЛГ»", "lightbox", Color(0.15, 0.2, 0.5), front + Vector3(0, 2.6, -1.95), 0.0, 0.45)
	Signboard.make(self, "КОНЕЦ СВЕТА\nПО СУББОТАМ\nНЕ ПРИНИМАЕМ", "poster", Color(0.1, 0.1, 0.1), front + Vector3(2.6, 1.5, -1.95), 0.0, 0.16,
			{"bg": Color(0.95, 0.93, 0.85)})
	Signboard.make(self, "ОБЕД С 9 ДО 18", "board", Color(0.95, 0.9, 0.8), front + Vector3(-2.6, 1.6, -1.95), 0.0, 0.18)
	# окошко с решёткой и Нина за ним
	Kit.box(self, Vector3(1.4, 1.0, 0.06), front + Vector3(0, 1.5, -1.96), Color(0.95, 0.85, 0.55), 1.0)
	for k in 4:
		Kit.box(self, Vector3(0.04, 1.0, 0.04), front + Vector3(-0.5 + k * 0.33, 1.5, -1.9), Color(0.2, 0.2, 0.22))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2002
	_nina = DistrictSites._person(self, front + Vector3(0, 0, -2.6), 0.0, rng,
			{"style": "bun", "skirt": true, "hair": Color(0.55, 0.2, 0.1), "top": Color(0.4, 0.55, 0.75), "height": 0.96})
	_nina.name = "Nina"
	_nina.set_meta("head_y", 1.68)
	window_pos = front + Vector3(0, 0, 0.8)
	# лавка с квитанцией
	var bench := front + Vector3(-r.size.x / 2.0 - 2.5, 0, 1.5)
	Props.place(self, "bench", bench, 90.0)
	receipt_pos = bench + Vector3(0.8, 0, 0)
	_receipt = Node3D.new()
	_receipt.position = receipt_pos
	add_child(_receipt)
	Kit.box(_receipt, Vector3(0.4, 0.02, 0.28), Vector3(0, 0.6, 0), Color(1, 0.95, 0.75), 2.5)
	Kit.label(_receipt, "Квитанция", Vector3(0, 1.3, 0), 30, Color(1, 0.95, 0.7))
	var tw := _receipt.create_tween().set_loops()
	tw.tween_property(_receipt, "position:y", 0.15, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_receipt, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)


func _archive(r: Rect2) -> void:
	var c := District.to_world(r.get_center())
	var front := c + Vector3(0, 0, r.size.y / 2.0 - 1.5)
	var back := c - Vector3(0, 0, r.size.y / 2.0 - 1.5)
	Kit.solid_box(self, Vector3(r.size.x, 4.0, r.size.y - 3.0), c + Vector3(0, 2.0, 0), Color(0.55, 0.45, 0.38))
	Signboard.make(self, "АРХИВ · ВХОД ПО ТАЛОНАМ", "board", Color(0.95, 0.9, 0.8), front + Vector3(0, 3.0, 0.02), 0.0, 0.32)
	Kit.box(self, Vector3(1.2, 2.1, 0.08), front + Vector3(0, 1.05, 0.02), Color(0.35, 0.25, 0.18))
	# три очереди у парадного: за справкой, за справкой о справке и просто по привычке
	var rng := RandomNumberGenerator.new()
	rng.seed = 2003
	for q in 3:
		for k in 4:
			var at := front + Vector3(-2.4 + q * 2.4, 0, 1.2 + k * 0.9)
			DistrictSites._person(self, at, PI, rng, {"style": "curlers", "skirt": true} if (q + k) % 3 == 0 else {})
	Signboard.make(self, "ЗА СПРАВКОЙ · ЗА СПРАВКОЙ О СПРАВКЕ · ПО ПРИВЫЧКЕ", "chalk", Color(0.95, 0.95, 0.9),
			front + Vector3(0, 0.9, 5.6), 180.0, 0.14)
	# чёрный ход сзади и шкаф реестров у него
	Kit.box(self, Vector3(1.0, 2.0, 0.08), back + Vector3(0, 1.0, -0.02), Color(0.2, 0.2, 0.22))
	Signboard.make(self, "ЧЁРНЫЙ ХОД\nДЛЯ СВОИХ", "graffiti", Color(1, 0.85, 0.2), back + Vector3(0, 2.4, -0.03), 180.0, 0.25)
	back_door = back + Vector3(0, 0, -1.2)
	Kit.solid_box(self, Vector3(1.6, 1.9, 0.6), back + Vector3(2.0, 0.95, -0.5), Color(0.45, 0.35, 0.25))
	for k in 3:
		Kit.box(self, Vector3(1.4, 0.04, 0.5), back + Vector3(2.0, 0.5 + k * 0.55, -0.82), Color(0.9, 0.88, 0.8))
	registry_pos = back + Vector3(2.0, 0, -1.6)
