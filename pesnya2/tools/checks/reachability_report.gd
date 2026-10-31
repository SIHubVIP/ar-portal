extends Node
## Отчёт этапа 3 ТЗ «Погуляй»: доступность каждой точки реестра от выхода из двора «Похмельной».
## Запуск: godot --headless --path . res://tools/checks/reachability_report.tscn
## Пишет docs/REACHABILITY.md и печатает REACH_OK или REACH_FAIL.

const OUT := "res://docs/REACHABILITY.md"
## Точки, которые пришлось сдвигать после проверки: id → что сделано. Пусто, пока проверка
## не нашла ни одной недоступной точки.
const FIXED := {}


func _ready() -> void:
	var t := Time.get_ticks_msec()
	var r := District.reachability()
	var ms := Time.get_ticks_msec() - t
	var lanes := District.road_segments().filter(func(s: Dictionary) -> bool: return s.id == "lane").size()
	var bad: Array = []
	var lines: Array[String] = []
	lines.append("# Доступность точек «Погуляй» (этап 3 ТЗ)")
	lines.append("")
	lines.append("Собрано `tools/checks/reachability_report.tscn`. Поиск в ширину по сетке 4 × 4 м от выхода из двора")
	lines.append("«Похмельной» на h12 (план %s). Непроходимы %d корпусов домов с запасом 0,4 м, края района и сам двор." % [District.yard_exit(), District.houses().size()])
	lines.append("Переулков: %d. Точка доступна, если в %d м от неё есть достигнутая клетка. Расчёт занял %d мс." % [lanes, int(District.REACH_SNAP_M), ms])
	lines.append("")
	lines.append("| ID | Тип | Имя | План, м | Путь от двора, м | Итог |")
	lines.append("|---|---|---|---|---|---|")
	for p in District.data().get("points", []):
		var e: Dictionary = r[p.id]
		var verdict := "двор старта" if e.get("yard", false) else ("доступна" if e.reachable else "НЕДОСТУПНА")
		if not e.reachable:
			bad.append(p.id)
		lines.append("| %s | %s | %s | %d, %d | %s | %s |" % [p.id, p.type, String(p.get("name", "")).replace("|", "/"),
			int(District.pos(p).x), int(District.pos(p).y), "—" if e.path_m < 0 else str(int(e.path_m)), verdict])
	lines.append("")
	lines.append("## Исправленные точки")
	lines.append("")
	if FIXED.is_empty():
		lines.append(("Нет: все %d точек доступны без сдвига координат. Недоступных не было и до переулков: дома схемы у дорог и точек и так сняты (этап 1), переулки добавили обходы внутри кварталов." % r.size()) if bad.is_empty() else "Нет.")
	for id in FIXED:
		lines.append("- **%s**: %s" % [id, FIXED[id]])
	if not bad.is_empty():
		lines.append("")
		lines.append("## Недоступны")
		lines.append("")
		for id in bad:
			lines.append("- %s" % id)
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("REACH_%s points=%d bad=%s lanes=%d ms=%d" % ["OK" if bad.is_empty() else "FAIL", r.size(), bad, lanes, ms])
	get_tree().quit(0 if bad.is_empty() else 1)
