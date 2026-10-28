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
