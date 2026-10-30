extends Node
## Автотесты модели. Запуск:
##   godot --headless --path . res://tests/test_runner.tscn
## Печатает TESTS PASSED/FAILED и выходит с кодом 0/1.

var passed := 0
var failed: PackedStringArray = []


func _ready() -> void:
	for m in get_method_list():
		if String(m.name).begins_with("test_"):
			_reset_world()
			call(m.name)
	print("TESTS %s: %d passed, %d failed" % ["PASSED" if failed.is_empty() else "FAILED", passed, failed.size()])
	for f in failed:
		print("  FAIL ", f)
	get_tree().quit(0 if failed.is_empty() else 1)


func check(cond: bool, what: String) -> void:
	if cond:
		passed += 1
	else:
		failed.append(what)


## Точка у площадки: исходные метры «Рубин» → компактный план через окно площадки (D-059).
func _site_point(id: String, source: Vector2) -> Vector2:
	return source + District.site_shift(District.site(id))


func _reset_world() -> void:
	GameState.reset("CLASS_1")
	QuestService.reset()


# ---------- данные ----------

func test_canon_counts_and_ids() -> void:
	var errors := GameData.validate()
	check(errors.is_empty(), "валидатор данных: %s" % ", ".join(errors))


func test_every_npc_has_three_quests() -> void:
	for n in GameData.npcs:
		var ids: Array = n.quests
		check(ids == ["%s_1" % n.id, "%s_2" % n.id, "%s_3" % n.id], "%s: цепочка из трёх" % n.id)


func test_dependency_graph_is_acyclic() -> void:
	var color := {}
	var has_cycle := [false]
	var visit := func(id: String, self_ref: Callable) -> void:
		if color.get(id, 0) == 1:
			has_cycle[0] = true
			return
		if color.get(id, 0) == 2:
			return
		color[id] = 1
		for dep in GameData.quest(id).requires:
			self_ref.call(dep, self_ref)
		color[id] = 2
	for q in GameData.quests:
		visit.call(q.id, visit)
	check(not has_cycle[0], "граф зависимостей без циклов")


## Финал достижим без побочных цепочек: у MAIN только MAIN-зависимости.
func test_main_path_needs_no_side_quests() -> void:
	for q in GameData.quests:
		if q.kind != "main":
			continue
		for dep in q.requires:
			check(String(dep).begins_with("MAIN_"), "%s зависит от побочного %s" % [q.id, dep])


func test_every_quest_has_two_distinct_choices() -> void:
	for q in GameData.quests:
		check(q.choices.A.flag != q.choices.B.flag, "%s: флаги A/B различны" % q.id)


# ---------- квестовый движок ----------

func _play_through(id: String, choice := "A") -> void:
	QuestService.accept(id)
	for st in GameData.quest(id).stages:
		if st.type == "choice":
			QuestService.choose(id, choice)
		else:
			QuestService.advance(id, st.id, int(st.target))
	QuestService.turn_in(id)


func test_full_main_campaign_reaches_finale() -> void:
	for i in range(1, 21):
		var id := "MAIN_%03d" % i
		check(QuestService.state_of(id) == QuestService.AVAILABLE, "%s доступен по порядку" % id)
		_play_through(id, "A" if i % 2 else "B")
		check(QuestService.state_of(id) == QuestService.COMPLETED, "%s завершён" % id)
	check(GameState.has_flag("MAIN_020_B"), "финальный флаг выставлен")


func test_all_127_quests_completable() -> void:
	var safety := 0
	while safety < 200:
		safety += 1
		var avail: Array = GameData.quests.filter(func(q): return QuestService.state_of(q.id) == QuestService.AVAILABLE)
		if avail.is_empty():
			break
		for q in avail:
			_play_through(q.id)
	var done := GameData.quests.filter(func(q): return QuestService.state_of(q.id) == QuestService.COMPLETED).size()
	check(done == 127, "пройдено %d из 127" % done)
	check(GameState.level >= 40, "уровень после всех заданий: %d" % GameState.level)


func test_reward_is_granted_once() -> void:
	_play_through("MAIN_001")
	var babki := GameState.babki
	check(babki == int(GameData.quest("MAIN_001").reward.babki), "награда MAIN_001 начислена")
	check(not QuestService.turn_in("MAIN_001"), "повторная сдача отклонена")
	QuestService.records["MAIN_001"].state = QuestService.TURN_IN_READY
	QuestService.turn_in("MAIN_001")
	check(GameState.babki == babki, "повторное событие не дублирует награду")


func test_stage_order_is_enforced() -> void:
	QuestService.accept("MAIN_001")
	check(not QuestService.advance("MAIN_001", "MAIN_001_S03"), "нельзя перепрыгнуть этап")
	check(QuestService.advance("MAIN_001", "MAIN_001_S01"), "первый этап засчитан")
	check(not QuestService.advance("MAIN_001", "MAIN_001_S01"), "повтор этапа игнорируется")
	check(not QuestService.choose("MAIN_001", "A"), "выбор доступен только на этапе выбора")


func test_failed_recoverable_returns_to_checkpoint() -> void:
	QuestService.accept("MAIN_001")
	QuestService.advance("MAIN_001", "MAIN_001_S01")
	QuestService.advance("MAIN_001", "MAIN_001_S02")
	QuestService.fail_recoverable("MAIN_001")
	check(QuestService.retry("MAIN_001"), "повтор после провала")
	check(QuestService.current_stage("MAIN_001").id == "MAIN_001_S01", "возврат к контрольной точке")


# ---------- экономика ----------

func test_grant_is_atomic_and_logged() -> void:
	check(GameState.grant("t:1", "тест", {"babki": 50}), "начисление")
	check(not GameState.grant("t:1", "тест", {"babki": 50}), "повтор ключа отклонён")
	check(not GameState.grant("t:2", "тест", {"babki": -100}), "уход в минус отклонён")
	check(GameState.babki == 50 and GameState.ledger.size() == 1, "журнал и баланс")


func test_level_cap_is_55() -> void:
	GameState.grant("t:xp", "тест", {"xp": 10000000})
	check(GameState.level == 55, "максимальный уровень 55, получен %d" % GameState.level)


# ---------- сохранения ----------

func test_save_roundtrip() -> void:
	_play_through("MAIN_001", "B")
	QuestService.accept("MAIN_002")
	QuestService.advance("MAIN_002", "MAIN_002_S01")
	GameState.add_item("ITEM_P1_ALIEN_BATTERY")
	var before_state := JSON.stringify(GameState.to_dict())
	var before_quests := JSON.stringify(QuestService.to_dict())
	check(SaveService.save_game(), "сохранение записано")
	_reset_world()
	check(SaveService.load_game(), "сохранение прочитано")
	check(JSON.stringify(GameState.to_dict()) == before_state, "состояние героя совпадает")
	check(JSON.stringify(QuestService.to_dict()) == before_quests, "состояние квестов совпадает")
	check(QuestService.current_stage("MAIN_002").id == "MAIN_002_S02", "этап MAIN_002 восстановлен")


func test_corrupted_save_falls_back_to_backup() -> void:
	GameState.grant("t:a", "тест", {"babki": 10})
	SaveService.save_game()
	GameState.grant("t:b", "тест", {"babki": 20})
	SaveService.save_game()
	var f := FileAccess.open(SaveService.MAIN, FileAccess.WRITE)
	f.store_string("{\"checksum\": \"bad\", \"body\": \"{}\"}")
	f.close()
	_reset_world()
	check(SaveService.load_game(), "загрузка запасной копии")
	check(GameState.babki == 10, "из копии восстановлено 10 бабок, получено %d" % GameState.babki)
	check(FileAccess.file_exists(SaveService.MAIN), "битый файл не удалён")


func test_future_schema_is_rejected() -> void:
	check(SaveService.migrate({"schema_version": 999, "state": {}, "quests": {}}).is_empty(), "новая схема не грузится")


func test_every_ability_kind_has_effect() -> void:
	for a in GameData.abilities:
		check(AbilityBook.EFFECTS.has(a.kind), "%s: нет эффекта для типа «%s»" % [a.id, a.kind])


# ---------- 0.2: снаряжение, способности по уровням, диалоги ----------

func test_starter_kit_is_equipped_once() -> void:
	GameState.give_starter_kit()
	GameState.give_starter_kit()
	check(GameState.equipment.get("weapon", "") == "ITEM_P2_CROWBAR", "Вышибала получает монтировку")
	check(GameState.stat("damage") == 6.0 and GameState.stat("armor") == 3.0, "бонусы надетого")
	check(GameState.max_hp == 110.0 and GameState.hp == 110.0, "треники дают +10 здоровья")
	check(GameState.item_count("ITEM_P2_BEER") == 2, "пиво выдано один раз")


func test_equip_and_unequip() -> void:
	GameState.add_item("ITEM_P2_PIPE")
	GameState.add_item("ITEM_P2_CROWBAR")
	check(GameState.equip("ITEM_P2_CROWBAR"), "надеть монтировку")
	check(GameState.equip("ITEM_P2_PIPE"), "заменить на трубу")
	check(GameState.equipment.weapon == "ITEM_P2_PIPE" and GameState.item_count("ITEM_P2_CROWBAR") == 1,
			"прежнее оружие вернулось в ранец")
	check(GameState.stat("damage") == 10.0, "урон трубы")
	check(not GameState.equip("ITEM_P2_BEER"), "пиво не надевается")
	check(GameState.unequip("weapon") and GameState.stat("damage") == 0.0, "снять оружие")
	check(not GameState.equip("ITEM_P2_FOIL_HAT"), "нельзя надеть то, чего нет")


func test_consumable_heals_and_raises_kukukha() -> void:
	GameState.add_item("ITEM_P2_SHAWARMA")
	GameState.damage(80)
	check(GameState.use_item("ITEM_P2_SHAWARMA") != "", "шаурма съедена")
	check(GameState.hp == 80.0 and GameState.kukukha == 8, "лечит 60, кукуха +8")
	check(GameState.use_item("ITEM_P2_SHAWARMA") == "", "второй шаурмы нет")


func test_storage_moves_both_ways_and_keeps_quest_items() -> void:
	GameState.add_item("ITEM_P1_SCRAP", 3)
	GameState.add_item("ITEM_P1_PHONE")
	check(GameState.to_storage("ITEM_P1_SCRAP", 2) and GameState.storage.ITEM_P1_SCRAP == 2, "в сундук")
	check(not GameState.to_storage("ITEM_P1_PHONE"), "квестовый предмет остаётся при себе")
	check(GameState.from_storage("ITEM_P1_SCRAP") and GameState.item_count("ITEM_P1_SCRAP") == 2, "из сундука")
	check(not GameState.from_storage("ITEM_P1_SCRAP", 5), "нельзя взять больше, чем лежит")


func test_loot_table_rolls_known_items() -> void:
	for r in [0.0, 0.3, 0.6, 0.9, 0.999]:
		check(GameData.item_by_id.has(GameState.roll_loot("drone", r)), "трофей %.3f существует" % r)


func test_equipment_survives_save() -> void:
	GameState.give_starter_kit()
	GameState.add_tone("purple")
	var saved := JSON.stringify(GameState.to_dict())
	GameState.reset("CLASS_1")
	GameState.from_dict(JSON.parse_string(saved))
	check(GameState.stat("armor") == 3.0 and GameState.max_hp == 110.0, "снаряжение после загрузки")
	check(int(GameState.tones.get("purple", 0)) == 1, "тоны после загрузки")


func test_abilities_unlock_gradually() -> void:
	check(AbilityBook.unlock_level(0) == 1, "первая способность сразу")
	var prev := 0
	for i in 7:
		check(AbilityBook.unlock_level(i) > prev, "уровни открытия растут (%d)" % i)
		prev = AbilityBook.unlock_level(i)
	check(prev <= GameData.max_level, "последняя открывается до потолка уровня")
	for a in GameData.abilities:
		var d := AbilityBook.describe(a, 1)
		check(d.text != "" and d.shout != "" and d.stats != "", "%s: описание, выкрик, характеристики" % a.id)
		check(GameData.ability_flavor.abilities[a.id].anim != "", "%s: своя анимация" % a.id)


func test_dialogue_graphs_are_valid() -> void:
	var errors := DialogueRunner.validate()
	check(errors.is_empty(), "графы диалогов: %s" % ", ".join(errors))
	for id in ["MAIN_001_INTRO", "PASSER", "TERMINAL", "KIOSK", "GLORP", "ZINA", "PAVEL"]:
		check(GameData.dialogues.has(id), "диалог %s есть" % id)


func test_dialogue_canon_lines_are_verbatim() -> void:
	var lines: Array = GameData.scene_by_id["SCENE_01"].lines
	var found := 0
	for id in GameData.dialogues:
		for nid in GameData.dialogues[id].nodes:
			var n: Dictionary = GameData.dialogues[id].nodes[nid]
			if not n.has("canon"):
				continue
			# canon: «SCENE_01:i» — реплика сцены, «<ID поручения>:i» — ключевая строка поручения
			var src := String(n.canon).get_slice(":", 0)
			var i := int(String(n.canon).get_slice(":", 1))
			if src == "SCENE_01":
				found += 1
				check(n.text == lines[i].text, "%s/%s дословно" % [id, nid])
			else:
				check(n.text == GameData.quest(src).key_lines[i].text, "%s/%s дословно из %s" % [id, nid, src])
	check(found == lines.size(), "все 7 реплик SCENE_01 звучат в диалогах")


func test_dialogue_options_respect_requirements_and_grant_once() -> void:
	var r := DialogueRunner.new("ZINA")
	var opts := r.options()
	check(opts.size() == 4 and opts[1].locked and opts[3].locked, "без денег и кукухи два ответа закрыты")
	check(r.choose(1).is_empty() and r.node_id == "n0", "закрытый ответ не выбирается")
	r.choose(0)
	check(r.node_id == "g" and GameState.reputation == 1, "по-хорошему: +1 репутация")
	r.advance()
	check(GameState.item_count("ITEM_P2_VALERIAN") == 1 and r.finished(), "валерьянка и конец")
	var again := DialogueRunner.new("ZINA")
	again.choose(0)
	again.advance()
	check(GameState.reputation == 1 and GameState.item_count("ITEM_P2_VALERIAN") == 1, "повторный разговор не начисляет")
	check(int(GameState.tones.green) == 1, "тон засчитан один раз")


func test_kiosk_dialogue_leads_to_both_canon_choices() -> void:
	for pair in [["green", "choose_A"], ["purple", "choose_B"]]:
		var r := DialogueRunner.new("KIOSK")
		r.advance()
		r.advance()
		var picked := -1
		for o in r.options():
			if o.tone == pair[0]:
				picked = o.index
		check(r.choose(picked).has(pair[1]), "киоск: %s ведёт к %s" % pair)


func test_terminal_debt_notice_passes_patrol() -> void:
	QuestService.accept("MAIN_001")
	QuestService.advance("MAIN_001", "MAIN_001_S01")
	var r := DialogueRunner.new("TERMINAL")
	check(r.options()[2].locked, "без уведомления умный ответ закрыт")
	GameState.add_item("ITEM_P1_DEBT_NOTICE")
	var ev := r.choose(2)
	check(ev.has("pass") and QuestService.is_on_stage("MAIN_001", "MAIN_001_S03"), "уведомление о долге проводит мимо патруля")


func test_character_title_follows_tones() -> void:
	check(GameState.character_title() == "Тёмная лошадка", "без ответов — тёмная лошадка")
	for i in 3:
		GameState.add_tone("purple")
	GameState.add_tone("green")
	check(GameState.character_title() == "Отморозок", "чаще хамит — отморозок")


# ---------- 0.3: пол, журнал без спойлеров, добыча ----------

func test_gender_is_saved_and_reset() -> void:
	GameState.gender = "f"
	var d := GameState.to_dict()
	GameState.reset("CLASS_1")
	check(GameState.gender == "m", "новая игра начинается с мужского героя по умолчанию")
	GameState.from_dict(d)
	check(GameState.gender == "f", "пол восстанавливается из сохранения")


func test_female_hero_gets_female_lines() -> void:
	var male: String = DialogueRunner.new("PASSER").node().text
	GameState.gender = "f"
	var female: String = DialogueRunner.new("PASSER").node().text
	check(male != female and female.begins_with("Девушка"), "прохожий обращается к героине по-женски")


func test_quest_log_hides_locked_and_unheard_quests() -> void:
	QuestService.accept("MAIN_001")
	check(QuestLog._shown(GameData.quest("MAIN_001")), "активный сюжет виден")
	check(not QuestLog._shown(GameData.quest("MAIN_002")), "закрытый сюжет не спойлерится")
	var side := GameData.quest("NPC_07_1")
	check(QuestService.state_of(side.id) == QuestService.AVAILABLE and not QuestLog._shown(side),
			"доступное, но не услышанное поручение скрыто")
	GameState.set_flag("offered:NPC_07_1")
	check(QuestLog._shown(side), "после разговора с заказчиком поручение видно")
	var far := GameData.quest("NPC_05_1")
	GameState.set_flag("offered:NPC_05_1")
	check(not QuestLog._shown(far), "поручение не по силам пока скрыто")


func test_trash_loot_table_rolls_known_items() -> void:
	for i in 20:
		var id := GameState.roll_loot("trash", i / 20.0)
		check(GameData.item_by_id.has(id), "мусор даёт существующий предмет: %s" % id)


func test_loot_drop_grants_once() -> void:
	var world := Node3D.new()
	add_child(world)
	var a := LootDrop.drop(world, Vector3.ZERO, "test:loot", "ITEM_P2_BEER", 5)
	a.pick()
	var b := LootDrop.drop(world, Vector3.ZERO, "test:loot", "ITEM_P2_BEER", 5)
	b.pick()
	check(GameState.babki == 5 and GameState.item_count("ITEM_P2_BEER") == 1, "одна и та же добыча начисляется один раз")
	world.queue_free()


func test_breakable_drops_loot_once() -> void:
	var world := Node3D.new()
	add_child(world)
	var box := Breakable.spawn(world, "boxes", Vector3(1, 0, 1))
	box.take_hit(100.0, Vector3.ZERO)
	var drops := world.get_children().filter(func(n): return n is LootDrop).size()
	check(drops >= 1 and not box.is_alive(), "разбитый ящик роняет бабки")
	box.take_hit(100.0, Vector3.ZERO)
	check(world.get_children().filter(func(n): return n is LootDrop).size() == drops, "второй удар не роняет ещё")
	var again := Breakable.spawn(world, "boxes", Vector3(1, 0, 1))
	again.take_hit(100.0, Vector3.ZERO)
	check(world.get_children().filter(func(n): return n is LootDrop).size() == drops, "тот же ящик после перезахода пуст")
	world.queue_free()


# ---------- район «Погуляй» по ТЗ 1.0 ----------

func test_district_manifest_counts() -> void:
	var d := District.data()
	var kinds := {}
	for p in d.points:
		kinds[p.type] = int(kinds.get(p.type, 0)) + 1
	check(kinds == {"npc": 15, "boss": 3, "mob": 30, "place": 18, "safe": 5, "underground": 4}, "75 точек по типам ТЗ")
	check(d.sectors.size() == 9 and d.has("compact"), "9 секторов, район ужат (D-059)")
	# макет «Рубин» (0.11): коллектор, местные улицы, аллеи, тропы и проезды; дома 2–5 этажей и мелкая застройка
	check(District.road_segments().size() > 300, "улицы макета на месте: %d" % District.road_segments().size())
	var big := District.buildings().filter(func(b: Dictionary) -> bool: return b.kind == "house")
	check(big.size() > 50 and District.houses().size() > 1500, "дома макета и застройка промежутков: %d / %d" % [big.size(),
			District.houses().size()])
	check(District.site("market").objects.size() > 0 and District.site("square").objects.size() > 0
			and District.site("start").objects.size() > 0, "ядра рынка, площади и старта — из пакета")


func test_district_chunks_follow_tz_formula() -> void:
	check(District.chunk_of(Vector2(0, 0)) == Vector2i(0, 0), "угол — участок 0,0")
	check(District.chunk_of(Vector2(249.9, 250)) == Vector2i(0, 1), "граница 250 м — следующий участок")
	check(District.chunk_of(Vector2(2000, 1000)) == Vector2i(7, 3), "край 2000 × 1000 м — последний участок")
	check(District.chunk_of(Vector2(999, 999)) == Vector2i(3, 3), "угол Погуляя — участок 3, 3")
	var ok := true
	for p in District.points():
		ok = ok and District.chunk_of(District.pos(p)) == Vector2i(int(p.chunk[0]), int(p.chunk[1]))
	check(ok, "точки лежат в своих участках")


func test_district_coordinates_round_trip() -> void:
	check(District.to_world(District.ORIGIN_M) == Vector3.ZERO, "старт — ноль мира")
	var om: Array = District.layout().get("origin_m", [])
	check(om.size() == 2 and Vector2(om[0], om[1]).distance_to(District.ORIGIN_M) < 0.05,
			"начало мира в коде совпадает с компактной раскладкой")
	var ok := true
	for p in District.points():
		var g: Array = p.godot_position_m
		# формула манифеста (центр района) отличается от нашей только постоянным сдвигом (D-030)
		# 0.17: компактный план, мировые координаты точек пересчитаны от того же начала (D-059)
		var shift := District.to_world(District.pos(p)) - Vector3(g[0], 0, g[2])
		ok = ok and shift.length() < 0.05 \
				and District.to_plan(District.to_world(District.pos(p))).is_equal_approx(District.pos(p))
	check(ok, "план ↔ мир без искажений, сдвиг постоянный")


func test_yard_diorama_is_compact_grid() -> void:
	var g := StartYard.grid()
	StartYard._grid = g
	check(g.size() == 26 and Array(g).all(func(r: String) -> bool: return r.length() == 24), "двор — сетка 24 × 26 клеток по 3 м")
	var sa := District.start_area()
	check(sa.size.x * sa.size.y < 222.0 * 208.0 / 6.0, "двор старта больше чем вшестеро меньше прежнего 222 × 208 м")
	var ok := true
	for p: Vector3 in [StartYard.KIOSK, StartYard.PAVEL, StartYard.BOOTH, StartYard.GARAGE_13, StartYard.QUEUE,
			StartYard.EXIT_ARCH + Vector3(0, 0, 2), StartYard.BARRIER]:
		var ch := StartYard.tile_at(int(floor((p.x - StartYard.GRID_ORIGIN.x) / StartYard.CELL)),
				int(floor((p.z - StartYard.GRID_ORIGIN.y) / StartYard.CELL)))
		ok = ok and not StartYard.is_terrace(ch) and not ch in ["H", "G", "~", " "]
	check(ok, "сюжетные точки двора на ровной земле, не в домах, не на террасах и не в пруду")
	var stairs := 0
	for r in g:
		for k in r.length():
			stairs += 1 if StartYard.is_stair(r[k]) else 0
	check(stairs >= 3 and is_equal_approx(StartYard.ground_y(-12, -129), StartYard.TERRACE_H) and StartYard.ground_y(-8, -106) == 0.0,
			"на террасы ведут лестницы, сквер поднят на 1,2 м, парковка на земле")
	var yard := Rect2(District.to_plan(Vector3(StartYard.BOUNDS.position.x, 0, StartYard.BOUNDS.position.y)), StartYard.BOUNDS.size)
	check(sa.encloses(yard), "диорама целиком в отведённом месте района")


func test_start_yard_sits_between_roads() -> void:
	var yard := District.start_area()
	var ok := true
	for s in District.road_segments():
		# точки оси дороги через 2 м не заходят в двор, раздутый на полуширину коридора
		var steps := int(s.a.distance_to(s.b) / 2.0) + 1
		for i in steps + 1:
			ok = ok and not yard.grow(s.w / 2.0 - 0.01).has_point(s.a.lerp(s.b, float(i) / steps))
	check(ok, "двор «Похмельной» не залезает на дороги (между h12 и главной осью)")
	check(District.sector_at(District.ORIGIN_M).id == "C1", "старт в секторе C1")


func test_district_houses_avoid_roads_points_and_arenas() -> void:
	var ok := true
	for bl in District.buildings():
		if bl.get("site", "") == "start":
			continue          # корпуса двора старта строит StartYard, они и есть двор
		var h: Rect2 = bl.rect
		var c := h.get_center()
		for s in District.road_segments():
			ok = ok and District.dist_to_segment(c, s.a, s.b) > s.w / 2.0
		for b in District.points("boss"):
			ok = ok and not Rect2(District.pos(b) - District.m(b.arena_size_m) / 2.0, District.m(b.arena_size_m)).has_point(c)
		ok = ok and not District.start_area().has_point(c)
	check(ok, "ни один дом не стоит на дороге, арене или во дворе")


func test_lanes_cut_through_blocks_without_houses() -> void:
	var lanes := District.road_segments().filter(func(s: Dictionary) -> bool: return s.id == "lane")
	check(lanes.size() > 100, "в кварталах проложены переулки и проезды (%d)" % lanes.size())
	var clear := true
	var ends_on_streets := true
	for s in lanes:
		var lane := Rect2(s.a, Vector2.ZERO).expand(s.b).grow(s.w / 2.0)
		for h in District.houses():
			clear = clear and not lane.intersects(h)
		ends_on_streets = ends_on_streets and not District.start_area().has_point(s.a) and not District.start_area().has_point(s.b)
	check(clear, "ни один дом не стоит в переулке")
	check(ends_on_streets, "переулки не заходят во двор старта")


func test_every_point_reachable_from_yard_exit() -> void:
	var r := District.reachability()
	var bad: Array = []
	for id in r:
		if not r[id].reachable:
			bad.append(id)
	check(r.size() == 75 and bad.is_empty(), "до всех 75 точек можно дойти от выхода из двора, недоступны: %s" % [bad])


func test_safe_zones_cover_their_points() -> void:
	var ok := true
	for p in District.points("safe"):
		ok = ok and District.safe_zone_at(District.pos(p)).get("id", "") == p.id
	check(District.points("safe").size() == 5 and ok, "S0–S4 распознаются по своей точке")
	check(District.safe_zone_at(District.yard_exit()).is_empty(), "выход из двора не в безопасной зоне")


func test_safe_zone_blocks_hits() -> void:
	var pl := Player.new()
	add_child(pl)
	var before := GameState.hp
	pl.safe_zone = "S1"
	pl.take_hit(30.0)
	check(is_equal_approx(GameState.hp, before), "в безопасной зоне удар не проходит")
	pl.safe_zone = ""
	pl.take_hit(30.0)
	check(GameState.hp < before, "вне зоны удар проходит")
	GameState.heal(GameState.max_hp)
	pl.queue_free()


func test_every_manifest_mob_type_has_a_profile() -> void:
	var ok := true
	for t in District.data().get("mob_types", []):
		var p := MobTypes.profile(t.id)
		ok = ok and not p.is_empty() and p.name == t.name and p.kind in ["melee", "ranged", "lunge"]
	check(ok and MobTypes.PROFILES.size() == 10, "у всех 10 типов мобов манифеста есть профиль с тем же именем")


func test_mob_group_spawns_by_manifest_rules() -> void:
	var pl := Node3D.new()
	add_child(pl)
	var dm := DistrictMobs.new()
	dm.player = pl
	add_child(dm)
	var p := District.point("M10-1")
	pl.global_position = District.to_world(District.pos(p) + Vector2(0, 40))
	dm.update_now()
	var n := dm.alive_count("M10-1")
	check(n >= 4 and n <= 6, "группа M10-1: 4–6 дорожных паразитов (%d)" % n)
	var far_enough := true
	for m in dm.get_children():
		if m is EnemyDrone:
			far_enough = far_enough and District.to_plan(m.global_position).distance_to(District.to_plan(pl.global_position)) >= 25.0
			far_enough = far_enough and District.walkable(District.to_plan(m.global_position))
	check(far_enough, "мобы появились не ближе 25 м к герою и не в доме")
	for m in dm.get_children():
		if m is EnemyDrone:
			m.take_hit(999.0, m.global_position + Vector3.LEFT)
	Engine.time_scale = 1.0
	check(dm.alive_count("M10-1") == 0 and dm._groups["M10-1"].respawn_at >= 179.0, "перебитая группа вернётся через 180 с")
	pl.global_position = District.to_world(District.pos(p) + Vector2(0, 1000))
	dm.update_now()
	check(dm.alive_count() == 0, "далеко от зон никого нет")
	dm.queue_free()
	pl.queue_free()


func test_no_mob_spawn_in_safe_zones() -> void:
	var ok := true
	for p in District.points("mob"):
		ok = ok and District.safe_zone_at(District.pos(p)).is_empty()
	check(ok, "ни одна точка спавна не стоит в безопасной зоне")


func test_camera_cutout_works_without_vulkan_and_restores() -> void:
	var cam := IsoCamera.new()
	var body := Kit.solid_box(self, Vector3(2, 2, 2), Vector3.ZERO, Color(0.5, 0.5, 0.5), 0.0, true)
	var mi: MeshInstance3D = body.find_children("*", "MeshInstance3D", true, false)[0]
	var orig := mi.material_override
	cam._set_alpha(body, 0.0)
	var faded := mi.material_override as ShaderMaterial
	check(faded != null and faded.shader == IsoCamera.SEE_THROUGH_SHADER and faded.get_shader_parameter("albedo") == (orig as BaseMaterial3D).albedo_color,
			"дом у героя вырезается непрозрачным шейдером (работает и в OpenGL)")
	cam._set_alpha(body, 1.0)
	check(mi.material_override == orig and not mi.has_meta("fade_orig"), "после ухода героя материал дома прежний")
	check(IsoCamera.DEFAULT_SIZE == 12.0, "кадр камеры 12 м")
	body.queue_free()
	cam.free()


func test_stick_survives_hidden_release() -> void:
	var tc := TouchControls.new()
	tc.size = Vector2(1280, 720)
	add_child(tc)
	var pl := Player.new()
	add_child(pl)
	tc.player = pl
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = Vector2(200, 550)
	tc._input(press)
	tc.visible = false          # открылся диалог, палец отпустили, пока управление скрыто
	tc.visible = true
	press.index = 1
	tc._input(press)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = Vector2(260, 550)
	tc._input(drag)
	check(pl.move_input.x > 0.5, "после диалога стик снова ведёт героя, а не крутит камеру")
	tc.queue_free()
	pl.queue_free()


func test_npc_model_parts_and_styles() -> void:
	var m := NpcModel.make({"style": "curlers", "skirt": true, "height": 1.1, "top": Color(1, 0, 0)})
	add_child(m)
	var head := m.find_child("Head", true, false) as Node3D
	check(head != null and m.find_child("ArmL", true, false) != null and m.find_child("ArmR", true, false) != null,
			"у человечка есть голова и обе руки")
	check(head != null and head.get_node_or_null("HairCurlers") != null and (head.get_node("HairCurlers") as Node3D).visible,
			"бигуди на голове и крутятся вместе с ней")
	check(head != null and not (head.get_node("HairBun") as Node3D).visible, "видна одна причёска")
	check(is_equal_approx(m.scale.y, 1.1), "рост из облика")
	var mi := head as MeshInstance3D
	check(mi != null and (mi.material_override as ShaderMaterial).get_shader_parameter("top") == Color(1, 0, 0),
			"цвет одежды — параметр общего шейдера, а не отдельный материал на кусок")
	m.set_talking(true)
	check(m.process_mode == Node.PROCESS_MODE_ALWAYS, "в разговоре (игра на паузе) собеседник жестикулирует")
	m.set_talking(false)
	check(m.process_mode == Node.PROCESS_MODE_INHERIT and not m.is_in_group("npc_talking"), "после разговора — как все")
	m.queue_free()


func test_humanoid_mobs_use_npc_model() -> void:
	for id in ["mob_02", "mob_04", "mob_05", "mob_06", "mob_08", "mob_09"]:
		var body := Node3D.new()
		add_child(body)
		MobTypes.build_body(body, id)
		var model := body.get_node_or_null("Model") as NpcModel
		check(model != null and is_equal_approx(model.position.y, -MobTypes.HUMAN_BASE_Y),
				"%s — человек с ногами на земле" % id)
		body.queue_free()
	var drone := Node3D.new()
	add_child(drone)
	MobTypes.build_body(drone, "mob_01")
	check(drone.get_node_or_null("Model") == null, "дрон остаётся дроном")
	drone.queue_free()


func test_signboard_styles_build_real_objects() -> void:
	var root := Node3D.new()
	add_child(root)
	for kind in Signboard.STYLES:
		var sb := Signboard.make(root, "ШАУРМА 25/8", kind, Color(1, 0.5, 0.2), Vector3.ZERO, 0.0, 0.4, {"far": 50.0})
		check(sb.text_node != null and sb.text_node.text == "ШАУРМА 25/8", "%s: надпись на месте" % kind)
		check(sb.panel_size.x >= sb.text_size.x and sb.text_size.x > 1.0, "%s: размер по тексту" % kind)
		var meshes := sb.find_children("*", "MeshInstance3D", true, false)
		check(kind == "graffiti" or kind == "letters" or meshes.size() >= 1, "%s: не голая надпись, есть щит" % kind)
		for gi in sb.find_children("*", "GeometryInstance3D", true, false):
			check((gi as GeometryInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
					"%s: вывеска не рисуется в карту теней" % kind)
			check(is_equal_approx((gi as GeometryInstance3D).visibility_range_end, 50.0), "%s: дальние не рисуются" % kind)
			break
	var lb := Signboard.make(root, "А", "lightbox", Color.WHITE, Vector3.ZERO, 0.0, 0.4)
	check(lb.find_children("*", "MeshInstance3D", true, false).size() <= 2, "короб — одна сетка рамки и поля плюс отсвет")
	root.queue_free()


func test_delovoy_district_joins_pogulyay() -> void:
	check(District.district_at(Vector2(500, 500)).id == "PG" and District.district_at(Vector2(1500, 500)).id == "DL",
			"Погуляй на западе, Деловой на востоке")
	check(String(District.sector_at(Vector2(1500, 500)).get("name", "")) == "Последний талон"
			and String(District.sector_at(Vector2(1833, 167)).get("name", "")) == "Кредит доверчивым"
			and String(District.sector_at(Vector2(1167, 500)).get("name", "")) == "Двор свидетелей", "сектора Делового по брифу")
	for id in ["dl_mfc", "dl_credit", "dl_yard", "dl_school", "dl_zags", "dl_archive", "dl_station", "dl_passage", "dl_greenhouses"]:
		check(not District.site(id).is_empty(), "площадка %s есть в макете" % id)
	District.reachability()
	check(District.reached(_site_point("dl_mfc", Vector2(4500, 1590))) and District.reached(_site_point("dl_credit", Vector2(5500, 598)))
			and District.reached(_site_point("dl_yard", Vector2(3500, 1590))), "до трёх площадок Делового можно дойти пешком со двора")
	check(District.chunk_of(Vector2(1500, 500)).x > 3, "участки Делового — правее Погуляя")


func test_delovoy_sites_build() -> void:
	var root := Node3D.new()
	add_child(root)
	var b := DistrictDressing.Batch.new()
	for id in ["dl_mfc", "dl_credit", "dl_yard"]:
		DistrictSites.build(root, District.site(id), b)
	check(root.get_node_or_null("StuckUfo") != null and root.get_node_or_null("ProbeHeld") != null, "тарелка у администрации и зонд у бабушки")
	var bodies := root.find_children("*", "StaticBody3D", true, false).size()
	check(bodies > 30, "корпуса, машины и ограды площадок с коллизией: %d" % bodies)
	var signs := b.jobs.size()
	check(signs >= 25, "вывески площадок в очереди: %d" % signs)
	root.queue_free()


func test_dosvidaniya_north_of_delovoy() -> void:
	check(District.district_at(Vector2(1500, -500)).id == "DS" and District.district_at(Vector2(1500, 500)).id == "DL",
			"«До свидания» к северу от Делового")
	check(not District.in_city(Vector2(500, -500)) and District.in_city(Vector2(1333, 0)) and not District.walkable(Vector2(500, -3)),
			"над Погуляем пусто, стык Делового и «До свидания» — не край")
	check(String(District.sector_at(Vector2(1500, -500)).get("name", "")) == "Базар под куполом"
			and String(District.sector_at(Vector2(1167, -167)).get("name", "")) == "Гаражи без вопросов"
			and String(District.sector_at(Vector2(1500, -167)).get("name", "")) == "Котельная прощаний", "сектора «До свидания» по брифу")
	check(District.chunk_of(Vector2(1500, -500)) == Vector2i(6, -2) and District.chunk_of(Vector2(2000, -1000)) == Vector2i(7, -4),
			"участки к северу — с отрицательным номером по y")
	for id in ["ds_bazaar", "ds_garages", "ds_boiler", "ds_depot", "ds_scrap", "ds_cemetery", "ds_dorm", "ds_bath", "ds_canal"]:
		check(not District.site(id).is_empty(), "площадка %s есть в макете" % id)
	District.reachability()
	check(District.reached(_site_point("ds_bazaar", Vector2(4500, -1395))) and District.reached(_site_point("ds_garages", Vector2(3500, -395)))
			and District.reached(_site_point("ds_boiler", Vector2(4500, -395))), "до трёх площадок «До свидания» можно дойти пешком со двора")
	check(not District.reached(Vector2(500, -500)), "в пустой квадрат над Погуляем не пройти")
	var root := Node3D.new()
	add_child(root)
	var b := DistrictDressing.Batch.new()
	for id in ["ds_bazaar", "ds_garages", "ds_boiler"]:
		DistrictSites.build(root, District.site(id), b)
	check(root.get_node_or_null("BazaarStation") != null and root.get_node_or_null("HoistEngine") != null
			and root.get_node_or_null("HeatCore") != null, "станция над куполом, двигатель на тали, ядро у котельной")
	var bodies := root.find_children("*", "StaticBody3D", true, false).size()
	check(bodies > 60, "гаражи, корпуса и опоры площадок с коллизией: %d" % bodies)
	root.queue_free()


func test_rotated_box_keeps_its_size() -> void:
	var b := DistrictDressing.Batch.new()
	b.box("site", Vector3.ZERO, Vector3(4, 1, 1), PI / 4.0)
	var xf: Transform3D = b.items.plain[0][0]
	check(absf(xf.basis.x.length() - 4.0) < 0.01 and absf(xf.basis.z.length() - 1.0) < 0.01, "повёрнутая коробка не перекошена")


func test_car_kit_builds_cached_cars() -> void:
	var a := CarKit.mesh(Color(0.3, 0.45, 0.42))
	check(a == CarKit.mesh(Color(0.3, 0.45, 0.42)), "машина одного цвета и вида — одна сетка")
	check(a != CarKit.mesh(Color(0.3, 0.45, 0.42), true), "машина с горящими фарами — своя сетка")
	var aabb := a.get_aabb()
	check(absf(aabb.size.z - CarKit.LENGTH) < 0.3 and aabb.position.y > -0.01 and aabb.end.y < 1.6,
			"машина 4,3 м, стоит колёсами на земле: %s" % aabb)
	var glow := false
	for c: Color in CarKit.mesh(Color.RED, true).surface_get_arrays(0)[Mesh.ARRAY_COLOR]:
		glow = glow or c.a < 0.01
	check(glow, "у машины на ходу фары светятся")


func test_yard_cat_runs_from_hero() -> void:
	var hero_node := Node3D.new()
	add_child(hero_node)
	var cat := YardCat.new()
	cat.area = Rect2(-10, -10, 20, 20)
	cat.player = hero_node
	add_child(cat)
	hero_node.position = Vector3(1.5, 0, 0)
	for i in 30:
		cat._physics_process(0.05)
	check(cat.position.x < -1.0, "кот удирает от героя: %s" % cat.position)
	check(cat.area.has_point(Vector2(cat.position.x, cat.position.z)), "и не выходит из своего двора")
	cat.queue_free()
	hero_node.queue_free()


func test_district_chunk_is_dressed() -> void:
	var root := Node3D.new()
	add_child(root)
	var c := District.chunk_of(Vector2(1220, 1220))
	var b := DistrictDressing.Batch.new()
	DistrictDressing.streets(root, c, District.road_segments(), b)
	var rng := RandomNumberGenerator.new()
	for h in District.houses():
		if District.chunk_rect(c).has_point(h.get_center()):
			DistrictDressing.facades(root, h, 18.0, District.road_segments(), b, rng)
	var guard := 0
	while not b.jobs.is_empty() and guard < 2000:
		var job: Callable = b.jobs.pop_front()
		job.call()
		guard += 1
	check(b.items.has("sidewalk") and b.items.has("model:streetlamp") and b.items.has("plain"),
			"на участке тротуары, фонари и мелочь")
	check(b.lamps.size() >= 10, "фонари зарегистрированы для настоящего света: %d" % b.lamps.size())
	check(root.find_children("*", "Signboard", true, false).size() >= 5, "на участке есть вывески")
	DistrictDressing.flush(root, c, b)
	check(DistrictDressing.lamp_points.has(c), "участок отдал фонари LampLights")
	var mms := root.find_children("*", "MultiMeshInstance3D", true, false)
	# 0.20: большой вид режется на клетки по 40 м, но сетка у всех клеток вида одна
	var kinds := {}
	for m in mms:
		kinds[(m as MultiMeshInstance3D).multimesh.mesh] = true
	check(kinds.size() < 40 and mms.size() < 40 * 49, "мелочь участка собрана в MultiMesh по видам: %d видов, %d клеток" % [kinds.size(), mms.size()])
	root.free()
	check(not DistrictDressing.lamp_points.has(c), "выгруженный участок забирает свои фонари")


func test_lamp_lights_follow_nearest_lamps() -> void:
	var hero := Node3D.new()
	add_child(hero)
	DistrictDressing.lamp_points[Vector2i(-9, -9)] = PackedVector3Array([Vector3(3, 5.7, 0), Vector3(100, 5.7, 0),
			Vector3(-6, 5.7, 2)])
	var ll := LampLights.new()
	ll.player = hero
	add_child(ll)
	ll._pick()
	var targets := ll._targets.filter(func(v: Vector3) -> bool: return v != Vector3.INF)
	check(targets.size() == 2 and targets.has(Vector3(3, 5.7, 0)), "свет у двух ближних фонарей, дальний без света")
	DistrictDressing.lamp_points.erase(Vector2i(-9, -9))
	ll.queue_free()
	hero.queue_free()


func test_phys_props_blast_and_push() -> void:
	var root := Node3D.new()
	add_child(root)
	var cone := PhysProp.make("cone", Vector3(1, 0, 0))
	root.add_child(cone)
	var far := PhysProp.make("bin", Vector3(20, 0, 0))
	root.add_child(far)
	var n := PhysProp.blast(get_tree(), Vector3.ZERO, 3.0, 6.0)
	check(n == 1, "удар задевает только ближние предметы")
	check(not cone.sleeping, "конус проснулся и полетит (импульс применится на шаге физики)")
	check(far.sleeping, "дальняя урна спит")
	root.queue_free()


func test_physics_props_pool_limits_bodies() -> void:
	var hero := Node3D.new()
	add_child(hero)
	var pool := PhysicsProps.new()
	pool.player = hero
	for i in 60:
		pool.extra.append([Vector3(i % 10, 0, i / 10), "box"])
	pool.extra.append([Vector3(200, 0, 0), "bin"])
	add_child(pool)
	pool.update_now()
	check(pool.alive_count() == PhysicsProps.MAX_BODIES, "живых тел не больше %d" % PhysicsProps.MAX_BODIES)
	hero.position = Vector3(200, 0, 0)
	pool.update_now()
	check(pool.alive_count() == 1, "ушёл — ближние убраны, у новой точки свой предмет")
	pool.queue_free()
	hero.queue_free()


func test_pavel_single_copy_by_quest_state() -> void:
	var c := "MAIN_001_started_and_not_completed"
	check(not District.condition_met(c, QuestService.AVAILABLE), "до MAIN_001 Павла у киоска нет")
	check(District.condition_met(c, QuestService.ACTIVE) and District.condition_met(c, QuestService.TURN_IN_READY),
			"пока идёт MAIN_001 — у киоска")
	check(not District.condition_met(c, QuestService.COMPLETED), "после MAIN_001 — в парке")
	QuestService.accept("MAIN_001")
	var yard := District.npc_pos("N07")
	check(District.start_area().has_point(yard), "киоск «НЛО напрокат» во дворе старта")
	check(District.to_plan(StartYard.PAVEL).distance_to(yard) < 1.0, "Павел стоит там, где сказано в данных")
	var r := DialogueRunner.new("PAVEL")
	while not r.finished():
		r.advance()
	check(GameState.has_flag("offered:NPC_07_1"), "Павел рассказал про «НЛО напрокат»")


func test_parking_reference_assets_exist() -> void:
	var ok := true
	for m in ["parking_booth", "boom_gate", "ufo_kiosk", "brick_arch", "canal_rail", "taxi", "taxi_sign", "market_stall",
			"chalk_board", "ac_unit"]:
		ok = ok and Props.exists(m)
	check(ok, "10 моделей эталона парковки на месте")
	ok = true
	for t in ["cobble", "brick"]:
		for k in ["albedo", "normal", "rough"]:
			ok = ok and ResourceLoader.exists("res://assets/textures/%s_%s.png" % [t, k])
	check(ok, "текстуры брусчатки и кирпича на месте")


# ---------- инвентарь: перенос из клетки в клетку ----------

func test_inventory_move_between_cells() -> void:
	GameState.add_item("ITEM_P2_BEER", 3)
	GameState.add_item("ITEM_P1_SCRAP", 2)
	var cells := GameState.bag_cells("backpack")
	check(cells.size() == GameState.BACKPACK_SLOTS and cells[0] == "ITEM_P2_BEER", "новые вещи — в первые клетки")
	check(GameState.move_item("backpack", "ITEM_P2_BEER", "backpack", 10) == "", "пиво в клетку 10")
	cells = GameState.bag_cells("backpack")
	check(cells[10] == "ITEM_P2_BEER" and cells[0] == "", "клетка запомнилась, старая освободилась")
	GameState.move_item("backpack", "ITEM_P1_SCRAP", "backpack", 10)
	cells = GameState.bag_cells("backpack")
	check(cells[10] == "ITEM_P1_SCRAP" and cells[1] == "ITEM_P2_BEER", "на занятую клетку — меняются местами")
	check(GameState.move_item("backpack", "ITEM_P2_BEER", "pockets", 2) == "", "пиво в карман")
	check(int(GameState.pockets.get("ITEM_P2_BEER", 0)) == 3 and not GameState.backpack.has("ITEM_P2_BEER")
			and GameState.bag_cells("pockets")[2] == "ITEM_P2_BEER", "вся стопка переехала в карман")
	GameState.add_item("ITEM_P1_PHONE")
	check(GameState.move_item("pockets", "ITEM_P1_PHONE", "storage", 0) != "", "квестовое в сундук не кладётся")
	check(GameState.move_item("pockets", "ITEM_P2_BEER", "storage", 5) == "" and GameState.bag_cells("storage")[5] == "ITEM_P2_BEER",
			"в сундук — в выбранную клетку")
	var saved := JSON.stringify(GameState.to_dict())
	GameState.reset("CLASS_1")
	GameState.from_dict(JSON.parse_string(saved))
	check(GameState.bag_cells("backpack")[10] == "ITEM_P1_SCRAP" and GameState.bag_cells("storage")[5] == "ITEM_P2_BEER",
			"раскладка сохраняется")


func test_inventory_drag_to_doll_and_back() -> void:
	GameState.give_starter_kit()
	var panel := InventoryPanel.new()
	add_child(panel)
	var cap: String = GameState.equipment.get("head", "")
	panel.drop({"id": cap, "from": "equip", "slot": "head"}, {"id": "", "from": "backpack", "index": 7})
	check(not GameState.equipment.has("head") and GameState.bag_cells("backpack")[7] == cap, "кепка снята прямо в клетку 7")
	panel.drop({"id": cap, "from": "backpack", "index": 7}, {"id": "", "from": "equip", "slot": "weapon"})
	check(not GameState.equipment.has("head"), "кепку не надеть в слот оружия")
	panel.drop({"id": cap, "from": "backpack", "index": 7}, {"id": "", "from": "equip", "slot": "head"})
	check(GameState.equipment.get("head", "") == cap, "перетащил на голову — надета")
	panel.queue_free()


func test_boss_lyusya_phases_and_cover() -> void:
	var root := Node3D.new()
	add_child(root)
	var pl := Player.new()
	root.add_child(pl)
	var boss := Boss.new()
	boss.position = Vector3(0, 0, -12)
	boss.player = pl
	root.add_child(boss)
	check(boss.display_name() == "Люся Глушительница Лайков" and boss.data.phases.size() == 3, "Люся читает три фазы из bosses.json")
	check(Boss._lane_hit(Vector3.ZERO, Vector3.FORWARD, Vector3(1.0, 0, -20)) and not Boss._lane_hit(Vector3.ZERO, Vector3.FORWARD, Vector3(2.5, 0, -20))
			and not Boss._lane_hit(Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, 5)), "полоса 2.5 м: в ней — попал, сбоку и сзади — нет")
	check(Boss._sector_hit(Vector3.ZERO, Vector3.FORWARD, Vector3(-10, 0, -10)) and not Boss._sector_hit(Vector3.ZERO, Vector3.FORWARD, Vector3(-10, 0, -2)),
			"сектор 100°: под 45° задевает, под 79° — нет")
	var col := AdColumn.new()
	col.position = Vector3(0, 0, -6)
	root.add_child(col)
	check(AdColumn.blocker(get_tree(), boss.position, pl.position) == col and AdColumn.blocker(get_tree(), boss.position, Vector3(6, 0, 0)) == null,
			"тумба на линии огня закрывает, в стороне — нет")
	# фаза 1: полоса на героя упирается в тумбу
	boss.active = true
	boss._start_attack()
	check(boss.pending_kinds() == ["lane"], "фаза 1 — прицельная очередь полосой")
	var hp0 := GameState.hp
	boss._resolve()
	check(is_equal_approx(GameState.hp, hp0) and col.hp == AdColumn.MAX_HP - 1 and boss.blocked_by_cover == 1,
			"за тумбой урона нет, с тумбы сорван плакат")
	col.take_cover_hit(boss.position)
	col.take_cover_hit(boss.position)
	check(not col.is_standing() and AdColumn.blocker(get_tree(), boss.position, pl.position) == null, "третий выстрел валит тумбу — укрытия больше нет")
	boss._start_attack()
	boss._resolve()
	check(GameState.hp < hp0, "без укрытия полоса попадает")
	col.restore()
	check(col.is_standing() and col.hp == AdColumn.MAX_HP, "новый бой — тумба снова стоит")
	# переход в фазу 2: ударная волна отбрасывает героя
	pl.position = Vector3(0, 0, -6.5) + Vector3(3, 0, 0)
	boss.take_hit(boss.max_hp * 0.31, pl.position)
	check(boss.phase == 2 and pl._knock.length() > 5.0, "70%% — вспышка спонсорства, героя отбросило волной")
	boss._invuln_left = 0.0
	boss._start_attack()
	check("sector" in boss.pending_kinds(), "фаза 2 — сектор")
	boss._clear_pending()
	boss.take_hit(boss.max_hp * 0.35, pl.position)
	check(boss.phase == 3, "35%% — указ о немедленной победе")
	boss._invuln_left = 0.0
	var kinds := []
	for i in 3:
		boss._start_attack()
		kinds.append(boss.pending_kinds())
		GameState.heal(GameState.max_hp)
		boss._resolve()
	check(kinds[0] == ["lane", "lane", "lane"] and kinds[1] == ["circle", "circle", "circle"] and boss.in_window(),
			"три сигнала: веер полос, круги, затем окно атаки")
	var before := boss.hp
	boss.take_hit(10.0, pl.position)
	check(is_equal_approx(before - boss.hp, 15.0), "в окно атаки урон в полтора раза больше")
	boss.reset()
	check(boss.hp == boss.max_hp and boss.phase == 1 and not boss.active, "сброс: здоровье и фаза с начала")
	GameState.heal(GameState.max_hp)
	root.queue_free()


func test_boss_arena_reward_once() -> void:
	var pl := Player.new()
	add_child(pl)
	var arena := BossArena.new()
	arena.player = pl
	add_child(arena)
	arena.build()
	check(arena.columns.size() == 10 and arena.boss != null and arena.rect().size == Vector2(72, 58), "арена 72 × 58 (ужата с городом) с десятью тумбами")
	check(District.district_at(District.to_plan(arena.center)).id == "PG" and arena.rect().has_point(Vector2(arena.center.x, arena.center.z)),
			"площадь Люси — в Погуляе у точки B1")
	arena.start_fight()
	check(arena.boss.active, "бой начался")
	var babki := GameState.babki
	arena.boss.take_hit(99999.0, pl.position)
	check(arena.is_won() and GameState.item_count("ITEM_P3_MUTE_CORE") == 1 and GameState.babki == babki + 250
			and not arena.boss.is_in_group("enemies"), "победа: ядро глушилки, 250 бабок, босс больше не цель")
	check(not GameState.grant(BossArena.key(), "повтор", BossArena.REWARD), "награда за босса — один раз")
	arena.queue_free()
	pl.queue_free()


func test_workbench_crafts_from_bags_and_storage() -> void:
	check(not Crafting.can_craft("R_FOIL_HAT") and Crafting.missing("R_FOIL_HAT").contains("×3"), "без материалов — нельзя, видно, чего не хватает")
	GameState.add_item("ITEM_P1_SCRAP", 1)
	GameState.storage["ITEM_P1_SCRAP"] = 4
	check(Crafting.craft("R_FOIL_HAT"), "шапочка из фольги: обломок из ранца и два из сундука")
	check(GameState.item_count("ITEM_P1_SCRAP") == 0 and int(GameState.storage.get("ITEM_P1_SCRAP", 0)) == 2
			and GameState.item_count("ITEM_P2_FOIL_HAT") == 1, "списано сначала из сумок, потом из сундука")
	check(not Crafting.can_craft("R_MIC_BAT"), "бита Люси — только с ядром глушилки")
	GameState.grant(BossArena.key(), "тест", BossArena.REWARD)
	GameState.storage["ITEM_P1_SCRAP"] = 3
	check(Crafting.craft("R_MIC_BAT") and GameState.equip("ITEM_P3_MIC_BAT") and GameState.stat("damage") >= 16.0,
			"ядро с босса → бита «Микрофон Люси», урон +16")
	check(Crafting.trophies().size() == 1 and Crafting.trophies()[0].id == "BOSS_01", "трофей Люси на стенде")
	for r in Crafting.RECIPES:
		check(GameData.item_by_id.has(r.out) and r.needs.keys().all(func(k): return GameData.item_by_id.has(k)), "рецепт %s из настоящих предметов" % r.id)


## Цель для проверки серии: считает удары, всегда жива.
class _Dummy extends Node3D:
	var hits: Array[float] = []

	func _ready() -> void:
		add_to_group("enemies")

	func is_alive() -> bool:
		return true

	func take_hit(damage: float, _from: Vector3) -> void:
		hits.append(damage)


func test_combo_third_hit_sweeps() -> void:
	var pl := Player.new()
	add_child(pl)
	var a := _Dummy.new()
	var b := _Dummy.new()
	add_child(a)
	add_child(b)
	a.global_position = pl.global_position + Vector3(1.5, 0, 0)
	b.global_position = a.global_position + Vector3(0, 0, 2)    # дальше удара, но в размахе от цели
	var seen: Array[int] = []
	pl.combo.connect(func(n: int) -> void: seen.append(n))
	for k in 3:
		pl.t += Player.ATTACK_COOLDOWN + 0.05
		pl.basic_attack()
	check(seen == [1, 2, 3] and a.hits.size() == 3, "три удара подряд — серия 1, 2, 3")
	check(a.hits[2] > a.hits[0] * 1.7 and b.hits.size() == 1, "третий удар серии сильнее и задевает соседа")
	pl.t += Player.COMBO_WINDOW + 1.0
	pl.basic_attack()
	check(pl.combo_count == 1, "после паузы серия начинается заново")
	a.queue_free()
	b.queue_free()
	pl.queue_free()


func test_perfect_dodge_doubles_next_hit() -> void:
	var pl := Player.new()
	add_child(pl)
	var a := _Dummy.new()
	add_child(a)
	a.global_position = pl.global_position + Vector3(1.5, 0, 0)
	var hp := GameState.hp
	var fired := [false]
	pl.perfect_dodge.connect(func() -> void: fired[0] = true)
	pl.dodge()
	pl.take_hit(40.0)
	check(fired[0] and is_equal_approx(GameState.hp, hp), "удар сквозь уклон не ранит и засчитан как ловкий")
	pl._dodge_left = 0.0
	pl.t += 1.0
	pl.basic_attack()
	pl.t += Player.COMBO_WINDOW + 1.0
	pl.basic_attack()
	check(a.hits.size() == 2 and is_equal_approx(a.hits[0], a.hits[1] * Player.PERFECT_MULT), "после ловкого уклона удар двойной, один раз")
	a.queue_free()
	pl.queue_free()


func test_ui_skin_has_drawn_icons() -> void:
	var ok := true
	for c in ["CLASS_1", "CLASS_2", "CLASS_3"]:
		for ab in GameData.class_abilities(c):
			ok = ok and UiSkin.icon(ab.id) != null
	for n in ["bag", "quests", "menu", "map", "heart", "coin", "rep", "kukukha", "close", "lock", "fist", "dodge", "hand",
			"rot_left", "rot_right"]:
		ok = ok and UiSkin.icon(n) != null
	check(ok, "у всех 21 способности и кнопок интерфейса есть рисованный значок")
	var th := UiSkin.theme()
	check(th.get_stylebox("normal", "Button") is StyleBoxFlat and (th.get_stylebox("normal", "Button") as StyleBoxFlat).border_width_bottom > 3,
			"кнопки по умолчанию — с бортиком")


func test_big_multimesh_is_split_into_cells() -> void:
	var root := Node3D.new()
	add_child(root)
	var list: Array = []
	for i in 200:
		list.append([Transform3D(Basis(), Vector3(i * 1.0, 0, 0)), Color.WHITE])
	DistrictDressing._multimesh(root, BoxMesh.new(), null, list, Transform3D(), false, DistrictDressing.SMALL_FAR_M)
	var n := 0
	var total := 0
	var culled := true
	for c in root.get_children():
		n += 1
		total += (c as MultiMeshInstance3D).multimesh.instance_count
		culled = culled and (c as MultiMeshInstance3D).visibility_range_end > 0.0
	check(n == 5 and total == 200 and culled, "200 вещей на 200 м режутся на 5 клеток по 40 м, мелочь гаснет вдали")
	root.queue_free()


func test_errands_cover_pogulyay_npcs() -> void:
	check(GameData.errands.size() == 15, "15 поручений жителей Погуляя")
	var ok := true
	for e in GameData.errands:
		var q := GameData.quest(e.quest)
		ok = ok and q.npc_id == e.npc and not District.point(e.point).is_empty()
		ok = ok and MobTypes.PROFILES.has(e.elite.base) and MobTypes.PROFILES.has(e.stack.base)
		for part in [e.elite, e.stack, e.craft]:
			ok = ok and GameData.item_by_id.get(part.item.id, {}).get("type", "") == "quest" and UiSkin.icon(part.item.icon) != null
		ok = ok and GameData.dialogues_speakers.has(e.speaker) and e.lines.hello.size() >= 1 and e.lines.done.size() >= 1
		ok = ok and int(e.stack.count) == int(String(q.stages[2].text).get_slice("/", 1).get_slice(" ", 0))
	check(ok, "у каждого поручения — житель на карте, вещи со значками, портрет, реплики и число трофеев из карточки")
	var k := NpcErrands.level_k("NPC_13_1")
	check(k.x > NpcErrands.level_k("NPC_07_1").x and is_equal_approx(NpcErrands.level_k("NPC_07_1").x, 1.08), "враги поручения крепче с рекомендуемым уровнем")


func test_tracked_quest_follows_last_accepted() -> void:
	QuestService.reset()
	QuestService.accept("MAIN_001")
	QuestService.accept("NPC_07_1")
	check(QuestService.tracked_quest().get("id", "") == "NPC_07_1", "трекер ведёт последнее принятое задание")
	QuestService.advance("MAIN_001", "MAIN_001_S01", 99)
	check(QuestService.tracked_quest().get("id", "") == "MAIN_001", "и переключается на продвинутое")
	QuestService.reset()
