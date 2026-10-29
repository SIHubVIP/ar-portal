class_name DistrictDressing
extends RefCounted
## 0.10: улицы района живут, а не просто тёмный асфальт между коробками. На участок:
##   улица — тротуары с бордюром, фонари со световыми пятнами, деревья, скамейки, ларьки
##   с вывесками, машины у обочины, разметка, зебры и рекламные щиты на перекрёстках, лужи;
##   дом — витрины первого этажа с вывесками и маркизами, кондиционеры, водостоки, бак и
##   антенны на крыше, на торцах у переулков — граффити и объявления.
## Всё мелкое и повторяющееся собирается в MultiMesh по видам (Batch), поэтому на участок
## уходит пара десятков вызовов отрисовки. Вывески — Signboard, видны только вблизи.

const SIDEWALK_M := 3.5
const LAMP_STEP_M := 26.0
const SIGN_FAR_M := 95.0         # камера висит в 60 м от героя: дальше вывески не рисуются
const ROOF_SIGN_FAR_M := 160.0
const YARD_STEP_M := 15.0
## Виды-коробки без текстур: цвет по умолчанию; альфа — «не свечение» (0 — лампа горит).
const PLAIN := {
	"curb": Color(0.55, 0.54, 0.52), "paint": Color(0.85, 0.85, 0.8), "zebra": Color(0.9, 0.9, 0.86),
	"trunk": Color(0.25, 0.18, 0.12), "planter": Color(0.4, 0.39, 0.37), "pipe": Color(0.3, 0.31, 0.33),
	"roof_block": Color(0.32, 0.31, 0.3), "antenna": Color(0.2, 0.2, 0.22), "lamp_post": Color(0.18, 0.18, 0.2),
	"door": Color(0.22, 0.15, 0.1), "canopy": Color(0.45, 0.44, 0.42), "doorlamp": Color(1.0, 0.82, 0.55, 0.0),
	"play": Color(0.8, 0.3, 0.2), "cloth": Color(0.9, 0.9, 0.85), "awning": Color(0.6, 0.2, 0.2),
}
const SHADOW_KINDS := ["crown"]     # деревья: тень кроны под ногами — главное, чем двор живой
const MODELS := ["streetlamp", "bench", "kiosk", "dumpster", "car_wreck", "taxi", "convertible", "billboard", "ac_unit",
	"trash_bags", "boxes", "fence", "garage", "tires"]
const SHOPS := [
	["АПТЕКА\n«ЗДОРОВЬЕ ПО ПОДПИСКЕ»", Color(0.3, 0.95, 0.5)], ["ШАУРМА 25/8", Color(1.0, 0.75, 0.2)],
	["ЛОМБАРД\n«ВСЁ МОЁ — ТВОЁ»", Color(0.3, 1.0, 0.85)], ["МИКРОЗАЙМЫ\nДО ЗАРПЛАТЫ И ПОСЛЕ", Color(1.0, 0.3, 0.25)],
	["ПРОДУКТЫ\n«ПОСЛЕДНИЙ ГЛОТОК»", Color(1.0, 0.9, 0.5)], ["РЕМОНТ ОБУВИ И СУДЕБ", Color(0.9, 0.9, 0.85)],
	["БАР «БЕЗ СЛУХА»", Color(0.9, 0.3, 1.0)], ["САЛОН\n«НОВОЕ ЛИЦО — СТАРЫЕ ДОЛГИ»", Color(1.0, 0.45, 0.8)],
	["ПИВО · ВОДЫ · ЗАБВЕНИЕ", Color(1.0, 0.8, 0.3)], ["ОПТИКА\n«НЕ ВИЖУ ПРОБЛЕМ»", Color(0.4, 0.8, 1.0)],
	["ЦВЕТЫ\nНА ПОХОРОНЫ И СВИДАНИЯ", Color(1.0, 0.5, 0.6)], ["КОПИЦЕНТР «КОПИЯ ТЕБЯ»", Color(0.6, 0.9, 1.0)],
	["СТОМАТОЛОГИЯ\n«УЛЫБКА ПО ГОСТУ»", Color(0.5, 0.85, 1.0)], ["ЗООМАГАЗИН\n«ДРОН-ЩЕНОК»", Color(0.6, 1.0, 0.4)],
	["ХОЗТОВАРЫ\n«ВСЁ ДЛЯ ЗАПОЯ»", Color(1.0, 0.65, 0.25)], ["СЕКОНД-ХЕНД\n«БЫВШИЕ ЛЮДИ»", Color(0.85, 0.6, 1.0)],
	["ПЕКАРНЯ\n«ХЛЕБ И ЗРЕЛИЩА»", Color(1.0, 0.8, 0.45)], ["ТАТУ\n«НАВСЕГДА — ЭТО НЕДОЛГО»", Color(1.0, 0.25, 0.4)],
	["БАНК «ДОВЕРИЕ 0%»", Color(0.4, 0.7, 1.0)], ["ГАДАЛКА\n«ЗНАЮ, ЧТО ТЫ ДОЛЖЕН»", Color(0.8, 0.4, 1.0)],
	["КАРАОКЕ\n«ПЕСНЯ ЗАПРЕЩЕНА»", Color(1.0, 0.3, 0.7)], ["РЮМОЧНАЯ «ПЕРВЫЙ ТОСТ»", Color(1.0, 0.7, 0.3)],
	["ПАРИКМАХЕРСКАЯ\n«ПОД НОЛЬ ПРАВ»", Color(0.9, 0.9, 1.0)], ["СУШИ «ИЗ КАНАЛА»", Color(1.0, 0.4, 0.3)],
	["ИНТЕРНЕТ-КАФЕ\n«ЛАЙК ЗА РУБЛЬ»", Color(0.3, 0.9, 1.0)], ["24 ЧАСА,\nНО НЕ СЕГОДНЯ", Color(1.0, 0.95, 0.6)],
	["ОБМЕН ВАЛЮТЫ\nНА НАДЕЖДУ", Color(0.4, 1.0, 0.6)], ["РИТУАЛЬНЫЕ УСЛУГИ\n«ДО ВСТРЕЧИ»", Color(0.75, 0.75, 0.8)],
	["ФИТНЕС\n«БЕГИ ОТ ДРОНОВ»", Color(0.4, 1.0, 0.3)], ["ХИМЧИСТКА\n«ОТМОЕМ РЕПУТАЦИЮ»", Color(0.5, 0.8, 1.0)],
	["АВТОМОЙКА\n«ТАРЕЛКИ ТОЖЕ»", Color(0.3, 0.8, 1.0)], ["КАЗИНО\n«ВСЁ ИЛИ НИЧЕГО»", Color(1.0, 0.85, 0.2)],
	["ПОЧТА\n«ДОЙДЁТ КОГДА-НИБУДЬ»", Color(0.3, 0.5, 1.0)], ["ЮРИСТ «ЗАКОН НА РАЗ»", Color(0.9, 0.85, 0.7)],
	["ЧЕБУРЕЧНАЯ «ЛАЙКА»", Color(1.0, 0.6, 0.2)], ["ГРИЛЬ-БАР «ПРОЖАРКА»", Color(1.0, 0.35, 0.15)],
]
const ADS := [
	"КРЕДИТ НА ВОЗДУХ\nПЕРВЫЙ ВДОХ БЕСПЛАТНО", "УЛЫБАЙТЕСЬ —\nВАС ОЦЕНИВАЮТ", "ТАРЕЛКА СЛЕДИТ\nЗА ВАШИМ КОМФОРТОМ",
	"ЖКХ: ПЛАТИ СЕЙЧАС,\nЖИВИ ПОТОМ", "ЛАЙК — ЭТО ВАЛЮТА", "СДАЙ СОСЕДА —\nПОЛУЧИ ПАКЕТ ГРЕЧКИ",
	"ПЕНСИЯ 2099:\nОСТАЛОСЬ ЧУТЬ-ЧУТЬ", "НОВЫЙ ЗАКОН:\nГРУСТИТЬ ПО ЗАПИСИ",
]
const ROOF_WORDS := ["ПОГУЛЯЙ", "СЛАВА ТАРЕЛКЕ", "БАНК ДОВЕРИЕ", "ГОСТИНИЦА «ПОХМЕЛЬЕ»", "ТЦ «ВСЁ В КРЕДИТ»"]
const POSTERS := [
	["ВНИМАНИЕ!\nУЛЫБКА\nОБЯЗАТЕЛЬНА", Color(0.1, 0.25, 0.6), Color(0.92, 0.9, 0.84)],
	["ПРОПАЛ КОТ\nзовут Протокол", Color(0.1, 0.1, 0.1), Color(0.92, 0.9, 0.84)],
	["МИКРОЗАЙМ\nЗА 5 МИНУТ", Color(1, 1, 1), Color(0.8, 0.12, 0.1)],
	["СДАМ КОМНАТУ\nПРИШЕЛЬЦАМ", Color(0.1, 0.1, 0.1), Color(0.95, 0.9, 0.5)],
	["РОЗЫСК\nПЕСНЯ", Color(0.6, 0.08, 0.06), Color(0.92, 0.9, 0.84)],
	["КОНЦЕРТ\nОТМЕНЁН", Color(1, 0.9, 0.3), Color(0.15, 0.12, 0.35)],
]
const GRAFFITI := ["ГЛ'ОРП — ЛОХ", "ВЕРНИТЕ ПЕНСИЮ", "ДРОНЫ — ВОН", "ПЕСНЯ ЖИВА", "ТУТ БЫЛ ВАСЯ",
	"НЕ СПИ — ПОСЧИТАЮТ", "ЛЮБЛЮ ЗЕЛЁНУЮ", "ПОГУЛЯЙ НАВСЕГДА", "КТО ПРОЧИТАЛ — ДОЛЖЕН"]
const GRAFFITI_COLORS := [Color(0.3, 1, 0.85), Color(1, 0.85, 0.1), Color(1, 0.35, 0.65), Color(0.95, 0.95, 0.95),
	Color(1, 0.5, 0.2)]

## Фонари загруженных участков: LampLights ставит настоящий свет только у ближайших.
static var lamp_points: Dictionary = {}     # Vector2i → PackedVector3Array
## Точки для физических предметов (урны, конусы, ящики): PhysicsProps оживляет ближайшие.
static var prop_points: Dictionary = {}     # Vector2i → Array [[Vector3, kind]]

static var _meshes: Dictionary = {}
static var _model_parts: Dictionary = {}


## Сборщик одинаковых мелочей участка: вид → список (Transform3D, цвет).
class Batch:
	var items: Dictionary = {}
	var lamps := PackedVector3Array()
	var props: Array = []
	## Тяжёлые куски (улица, вывеска) — отдельными шагами: участок строится по 3 мс за кадр.
	var jobs: Array[Callable] = []

	## Вывеска откладывается в jobs; fit — ужать до ширины/высоты (м), если не влезает.
	func sign(root: Node3D, text: String, kind: String, color: Color, pos: Vector3, yaw_deg: float, height_m: float,
			opts: Dictionary, fit := Vector2.ZERO) -> void:
		jobs.append(func() -> void:
			if not is_instance_valid(root):
				return
			var sb := Signboard.make(root, text, kind, color, pos, yaw_deg, height_m, opts)
			if fit.x > 0.0:
				var k := minf(fit.x / sb.panel_size.x, fit.y / sb.panel_size.y if fit.y > 0.0 else 1.0)
				if k < 1.0:
					sb.scale = Vector3.ONE * k)

	func add(kind: String, xf: Transform3D, color := Color.WHITE) -> void:
		# простые цветные коробки всех видов — один MultiMesh «plain» (один вызов отрисовки)
		if PLAIN.has(kind):
			color = PLAIN[kind] if color == Color.WHITE else Color(color, PLAIN[kind].a)
			kind = "plain"
		if not items.has(kind):
			items[kind] = []
		items[kind].append([xf, color])

	func box(kind: String, center: Vector3, size: Vector3, yaw := 0.0, color := Color.WHITE) -> void:
		add(kind, Transform3D(Basis(Vector3.UP, yaw).scaled(size), center), color)

	func model(name: String, pos: Vector3, yaw := 0.0, scale := 1.0) -> void:
		add("model:" + name, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale), pos))


# ---------- улица ----------

## Улицы участка: всё вдоль отрезков дорог (кроме переулков) и перекрёстки.
static func streets(root: Node3D, c: Vector2i, segments: Array, batch: Batch) -> void:
	var rect := District.chunk_rect(c)
	var start := District.start_area().grow(3)
	var reach := rect.grow(30.0)
	# поперечные улицы рядом с участком (включая диагональ), только они режут тротуары
	var near: Array = []
	for s in segments:
		if s.id != "lane" and not DistrictChunks._clip(s.a, s.b, reach.grow(float(s.w))).is_empty():
			near.append(s)
	for s in near:
		batch.jobs.append(_street.bind(root, rect, start, reach, s, near, batch))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(c) + 17
	batch.jobs.append(_crossings.bind(root, rect, near, batch, rng))
	batch.jobs.append(_yards.bind(root, c, near, batch))


## Дворы между домами: не пустырь, а деревья, гаражи, площадки, машины, сушка белья.
## Сетка через YARD_STEP_M; клетка занята, если рядом улица, дом или двор старта.
static func _yards(root: Node3D, c: Vector2i, near: Array, batch: Batch) -> void:
	if not is_instance_valid(root):
		return
	var rect := District.chunk_rect(c)
	var start := District.start_area().grow(8)
	var houses: Array[Rect2] = []
	for h in District.houses():
		if h.grow(6).intersects(rect):
			houses.append(h.grow(3.5))
	var blockers: Array = []
	for o in near:
		blockers.append([o.a, o.b, float(o.w) / 2.0, Rect2(o.a, Vector2.ZERO).expand(o.b).grow(float(o.w) / 2.0 + 14.0)])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(c) * 7 + 3
	var y := rect.position.y + YARD_STEP_M / 2.0
	while y < rect.end.y:
		var x := rect.position.x + YARD_STEP_M / 2.0
		while x < rect.end.x:
			var p := Vector2(x, y) + Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4))
			x += YARD_STEP_M
			var roll := rng.randf()
			if _blocked(p, blockers, SIDEWALK_M + 3.0, start):
				continue
			var inside := false
			for h in houses:
				if h.has_point(p):
					inside = true
					break
			if inside:
				continue
			var at := District.to_world(p)
			var yaw := rng.randi_range(0, 3) * PI / 2.0
			if roll < 0.42:
				_tree(batch, at, rng)
				if rng.randf() < 0.5:
					_tree(batch, at + Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5)), rng)
			elif roll < 0.52:
				var car_name: String = ["car_wreck", "taxi", "convertible"][rng.randi() % 3]
				batch.model(car_name, at, yaw + rng.randf_range(-0.3, 0.3))
				var cb := Props.collider(root, Vector3(1.9, 1.4, 4.4), at + Vector3(0, 0.7, 0))
				cb.rotation.y = yaw
			elif roll < 0.58:
				# ряд ржавых гаражей
				for i in rng.randi_range(2, 4):
					var g := at + Vector3(cos(yaw), 0, -sin(yaw)) * (i * 3.3)
					batch.model("garage", g, yaw)
					var gb := Props.collider(root, Vector3(3.2, 2.6, 6.0), g + Vector3(0, 1.3, 0))
					gb.rotation.y = yaw
				if rng.randf() < 0.6:
					batch.sign(root, GRAFFITI[rng.randi() % GRAFFITI.size()], "graffiti",
							GRAFFITI_COLORS[rng.randi() % GRAFFITI_COLORS.size()],
							at + Vector3(sin(yaw), 0, cos(yaw)) * 3.05 + Vector3(0, 1.4, 0), rad_to_deg(yaw), 0.5,
							{"far": SIGN_FAR_M})
			elif roll < 0.64:
				_playground(batch, at, yaw, rng)
			elif roll < 0.72:
				batch.model("bench", at, yaw)
				batch.props.append([at + Vector3(1.6, 0, 0), "bin"])
				batch.box("lamp_post", at + Vector3(-1.8, 1.6, 0), Vector3(0.1, 3.2, 0.1))
				batch.box("doorlamp", at + Vector3(-1.8, 3.25, 0), Vector3(0.3, 0.15, 0.3))
				batch.add("spill", Transform3D(Basis().scaled(Vector3(6, 1, 6)), at + Vector3(-1.0, 0.07, 0)), Color(0.75, 0.6, 0.38))
				batch.lamps.append(at + Vector3(-1.8, 3.1, 0))
			elif roll < 0.77:
				batch.model("dumpster", at, yaw)
				batch.model("trash_bags", at + Vector3(1.6, 0, 0.5), rng.randf() * TAU)
				Props.collider(root, Vector3(1.8, 1.6, 1.3), at + Vector3(0, 0.8, 0))
				batch.props.append([at + Vector3(-1.5, 0, 0.8), "box"])
			elif roll < 0.81:
				# сушка белья между двумя столбами
				var side := Vector3(cos(yaw), 0, -sin(yaw))
				batch.box("lamp_post", at - side * 2.5 + Vector3(0, 1.1, 0), Vector3(0.08, 2.2, 0.08))
				batch.box("lamp_post", at + side * 2.5 + Vector3(0, 1.1, 0), Vector3(0.08, 2.2, 0.08))
				for i in 6:
					var cloth := at - side * 2.0 + side * (i * 0.8) + Vector3(0, 1.75, 0)
					batch.add("cloth", Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(0.6, 0.7, 0.03)), cloth),
							[Color(0.85, 0.3, 0.3), Color(0.9, 0.9, 0.85), Color(0.3, 0.5, 0.8), Color(0.9, 0.8, 0.3)][rng.randi() % 4])
			elif roll < 0.86:
				batch.model("tires", at, rng.randf() * TAU)
				batch.props.append([at + Vector3(1.2, 0, 0), "tire"])
		y += YARD_STEP_M


## Детская площадка: качели, горка, песочница.
static func _playground(batch: Batch, at: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var b := Basis(Vector3.UP, yaw)
	var col: Color = [Color(0.85, 0.25, 0.2), Color(0.25, 0.5, 0.85), Color(0.95, 0.75, 0.2)][rng.randi() % 3]
	for sx: float in [-1.0, 1.0]:
		batch.add("play", Transform3D(b * Basis(Vector3.BACK, sx * 0.25).scaled(Vector3(0.1, 2.4, 0.1)), at + b * Vector3(sx * 1.4, 1.15, 0)), col)
	batch.add("play", Transform3D(b.scaled(Vector3(3.2, 0.1, 0.1)), at + b * Vector3(0, 2.3, 0)), col)
	batch.add("play", Transform3D(b.scaled(Vector3(0.6, 0.06, 0.3)), at + b * Vector3(0, 0.55, 0)), Color(0.3, 0.2, 0.12))
	batch.add("play", Transform3D(b * Basis(Vector3.RIGHT, 0.6).scaled(Vector3(0.7, 0.06, 3.0)), at + b * Vector3(4.0, 0.9, 0)), col.lightened(0.2))
	batch.add("play", Transform3D(b.scaled(Vector3(0.7, 1.8, 0.7)), at + b * Vector3(4.0, 0.9, -1.6)), col.darkened(0.3))
	batch.add("play", Transform3D(b.scaled(Vector3(3.0, 0.25, 3.0)), at + b * Vector3(0, 0.125, 3.5)), Color(0.55, 0.45, 0.3))
	batch.add("play", Transform3D(b.scaled(Vector3(2.6, 0.27, 2.6)), at + b * Vector3(0, 0.13, 3.5)), Color(0.75, 0.66, 0.45))


## Одна улица в пределах участка: тротуары, разметка, фонари и всё, что между ними.
static func _street(root: Node3D, rect: Rect2, start: Rect2, reach: Rect2, s: Dictionary, near: Array, batch: Batch) -> void:
	if not is_instance_valid(root):
		return
	var rng := RandomNumberGenerator.new()
	var a: Vector2 = s.a
	var b: Vector2 = s.b
	var length := a.distance_to(b)
	if length < 1.0:
		return
	var clip := DistrictChunks._clip(a, b, reach)
	if clip.is_empty():
		return
	var t_lo := a.distance_to(clip[0])
	var t_hi := a.distance_to(clip[1])
	var dir := (b - a) / length
	var nrm := Vector2(-dir.y, dir.x)
	var w := float(s.w)
	var yaw_along := atan2(dir.x, dir.y)
	var blockers: Array = []          # [a, b, полуширина, рамка для быстрой проверки]
	for o in near:
		if o != s:
			var box := Rect2(o.a, Vector2.ZERO).expand(o.b).grow(float(o.w) / 2.0 + 6.0)
			if box.intersects(reach):
				blockers.append([o.a, o.b, float(o.w) / 2.0, box])
	# тротуары и бордюры по обе стороны, разрезанные поперечными улицами
	for side: float in [-1.0, 1.0]:
		var off_walk := nrm * side * (w / 2.0 + SIDEWALK_M / 2.0)
		var off_curb := nrm * side * (w / 2.0 + 0.1)
		for iv in _free(a, dir, t_lo, t_hi, off_walk, SIDEWALK_M / 2.0 + 0.3, blockers, start, rect):
			var p0: Vector2 = a + dir * iv[0]
			var p1: Vector2 = a + dir * iv[1]
			var mid := (p0 + p1) / 2.0
			var len_: float = iv[1] - iv[0]
			batch.box("sidewalk", District.to_world(mid + off_walk, 0.03), Vector3(SIDEWALK_M, 0.06, len_), yaw_along)
			batch.box("curb", District.to_world(mid + off_curb, 0.08), Vector3(0.25, 0.16, len_), yaw_along)
	# разметка: штрихи по оси
	if w >= 12.0:
		var t := 3.0 + ceilf((t_lo - 3.0) / 7.0) * 7.0
		while t < t_hi:
			var q: Vector2 = a + dir * t
			if rect.has_point(q) and not _blocked(q, blockers, 1.0, start):
				batch.box("paint", District.to_world(q, 0.045), Vector3(0.16, 0.012, 3.0), yaw_along)
			t += 7.0
	# фонари через LAMP_STEP_M, сторона чередуется; между ними деревья, скамейки, ларьки
	var k := maxi(0, int(floorf((t_lo - LAMP_STEP_M / 2.0) / LAMP_STEP_M)))
	var t2 := LAMP_STEP_M / 2.0 + k * LAMP_STEP_M
	while t2 < t_hi:
		# своё зерно у каждой точки: соседний участок поставит то же самое
		rng.seed = hash(Vector3i(int(a.x), int(a.y), k)) + hash(String(s.id))
		var side2 := 1.0 if k % 2 == 0 else -1.0
		var q2: Vector2 = a + dir * t2
		var lamp_at := q2 + nrm * side2 * (w / 2.0 + 0.6)
		if rect.has_point(lamp_at) and not _blocked(lamp_at, blockers, 2.0, start):
			var face := atan2(-nrm.x * side2, -nrm.y * side2)    # плечо фонаря — к дороге
			batch.model("streetlamp", District.to_world(lamp_at), face)
			var head := District.to_world(lamp_at - nrm * side2 * 1.7, 5.7)
			batch.lamps.append(head)
			batch.box("pool", Vector3(head.x, 0.07, head.z), Vector3(9.0, 1.0, 9.0))
			if rng.randf() < 0.5:
				batch.props.append([District.to_world(lamp_at + dir * 1.2), "bin"])
		var mid_at := a + dir * (t2 + LAMP_STEP_M / 2.0) + nrm * side2 * (w / 2.0 + SIDEWALK_M + 1.6)
		if rect.has_point(mid_at) and not _blocked(mid_at, blockers, 3.0, start):
			var roll := rng.randf()
			var ground_yaw := atan2(-nrm.x * side2, -nrm.y * side2)
			if roll < 0.4:
				_tree(batch, District.to_world(mid_at), rng)
			elif roll < 0.55:
				batch.model("bench", District.to_world(mid_at), ground_yaw)
			elif roll < 0.72:
				_kiosk(root, batch, District.to_world(mid_at + nrm * side2 * 1.6), ground_yaw, rng)
			elif roll < 0.8:
				batch.model("dumpster", District.to_world(mid_at), ground_yaw + PI)
				Props.collider(root, Vector3(1.8, 1.6, 1.3), District.to_world(mid_at, 0.8))
				batch.props.append([District.to_world(mid_at + dir * 1.6), "box"])
			elif roll < 0.86:
				batch.props.append([District.to_world(mid_at), "cone"])
				batch.props.append([District.to_world(mid_at + dir * 1.0), "cone"])
		# машины у обочины широких улиц
		if w >= 20.0 and rng.randf() < 0.45:
			var car_at := q2 + dir * 6.0 + nrm * -side2 * (w / 2.0 - 1.5)
			if rect.has_point(car_at) and not _blocked(car_at, blockers, 4.0, start):
				var car_name: String = ["car_wreck", "taxi", "convertible"][rng.randi() % 3]
				var car_yaw := yaw_along + (PI if rng.randf() < 0.5 else 0.0)
				batch.model(car_name, District.to_world(car_at), car_yaw)
				var cb := Props.collider(root, Vector3(1.9, 1.4, 4.4), District.to_world(car_at, 0.7))
				cb.rotation.y = car_yaw
		# лужи на проезжей части
		if rng.randf() < 0.6:
			var pud := q2 + dir * rng.randf_range(-8, 8) + nrm * rng.randf_range(-w / 2.0 + 1.0, w / 2.0 - 1.0)
			if rect.has_point(pud) and not start.has_point(pud):
				batch.box("puddle", District.to_world(pud, 0.035), Vector3(rng.randf_range(1.5, 3.5), 1.0,
						rng.randf_range(1.2, 2.6)), rng.randf() * TAU)
		k += 1
		t2 += LAMP_STEP_M


## Перекрёстки участка: зебры на подходах и рекламный щит на углу.
static func _crossings(root: Node3D, rect: Rect2, segments: Array, batch: Batch, rng: RandomNumberGenerator) -> void:
	var vs: Array = []
	var hs: Array = []
	for s in segments:
		if s.id == "lane":
			continue
		if absf(s.a.x - s.b.x) < 0.5:
			vs.append(s)
		elif absf(s.a.y - s.b.y) < 0.5:
			hs.append(s)
	var start := District.start_area().grow(6)
	for v in vs:
		for h in hs:
			var x: float = v.a.x
			var y: float = h.a.y
			if y < minf(v.a.y, v.b.y) or y > maxf(v.a.y, v.b.y) or x < minf(h.a.x, h.b.x) or x > maxf(h.a.x, h.b.x):
				continue
			var p := Vector2(x, y)
			if not rect.has_point(p) or start.has_point(p):
				continue
			var vw := float(v.w)
			var hw := float(h.w)
			# зебры: поперёк вертикальной улицы выше и ниже перекрёстка, поперёк горизонтальной — слева и справа
			for sy: float in [-1.0, 1.0]:
				var cy := y + sy * (hw / 2.0 + 2.0)
				var xx := x - vw / 2.0 + 0.8
				while xx < x + vw / 2.0 - 0.5:
					batch.box("zebra", District.to_world(Vector2(xx, cy), 0.045), Vector3(0.55, 0.012, 3.0))
					xx += 1.2
			for sx: float in [-1.0, 1.0]:
				var cx := x + sx * (vw / 2.0 + 2.0)
				var yy := y - hw / 2.0 + 0.8
				while yy < y + hw / 2.0 - 0.5:
					batch.box("zebra", District.to_world(Vector2(cx, yy), 0.045), Vector3(3.0, 0.012, 0.55))
					yy += 1.2
			# рекламный щит на одном из углов
			if rng.randf() < 0.7:
				var corner := Vector2(rng.randi_range(0, 1) * 2 - 1, rng.randi_range(0, 1) * 2 - 1)
				var at := p + Vector2(corner.x * (vw / 2.0 + SIDEWALK_M + 3.0), corner.y * (hw / 2.0 + SIDEWALK_M + 3.0))
				var yaw := atan2(-corner.x, -corner.y)       # лицом к перекрёстку
				var w3 := District.to_world(at)
				batch.model("billboard", w3, yaw)
				Props.collider(root, Vector3(1.0, 4.0, 1.0), w3 + Vector3(0, 2, 0))
				var ad: String = ADS[rng.randi() % ADS.size()]
				var bg: Color = [Color(0.95, 0.85, 0.3), Color(0.3, 0.6, 0.95), Color(0.95, 0.3, 0.3), Color(0.9, 0.9, 0.85)][rng.randi() % 4]
				batch.sign(root, ad, "lightbox", Color.WHITE, w3 + Vector3(0, 6.2, 0) + Vector3(sin(yaw), 0, cos(yaw)) * 0.2,
						rad_to_deg(yaw), 0.62, {"bg": bg, "ink": Color(0.08, 0.06, 0.05) if bg.v > 0.8 else Color.WHITE,
						"far": ROOF_SIGN_FAR_M}, Vector2(6.6, 3.1))


static func _tree(batch: Batch, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var h := rng.randf_range(3.5, 5.5)
	batch.box("trunk", pos + Vector3(0, h * 0.35, 0), Vector3(0.28, h * 0.7, 0.28))
	var crown := Color(0.16, 0.3, 0.16).lerp(Color(0.3, 0.38, 0.14), rng.randf())
	batch.add("crown", Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(2.6, 2.4, 2.6) * rng.randf_range(0.8, 1.2)),
			pos + Vector3(0, h * 0.8, 0)), crown)
	batch.box("planter", pos + Vector3(0, 0.12, 0), Vector3(1.3, 0.24, 1.3))


## Ларёк у тротуара: модель, вывеска на крыше, тёплое пятно света перед окошком.
static func _kiosk(root: Node3D, batch: Batch, pos: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	batch.model("kiosk", pos, yaw, 0.8)
	var col := Props.collider(root, Vector3(4.2, 2.9, 3.3), pos + Vector3(0, 1.45, 0))
	col.rotation.y = yaw
	var shop: Array = SHOPS[rng.randi() % SHOPS.size()]
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	var style := "lightbox" if rng.randf() < 0.6 else "neon"
	var text := String(shop[0]).replace("\n", " ") if String(shop[0]).length() < 22 else String(shop[0])
	batch.sign(root, text, style, shop[1], pos + Vector3(0, 3.25, 0) + fwd * 1.35, rad_to_deg(yaw), 0.3,
			{"bg": Color(shop[1]).lerp(Color.WHITE, 0.55), "far": SIGN_FAR_M, "flicker": rng.randf() < 0.2})
	batch.add("spill", Transform3D(Basis().scaled(Vector3(5.0, 1.0, 4.0)), pos + fwd * 2.6 + Vector3(0, 0.08, 0)),
			Color(shop[1]).lerp(Color(1, 0.8, 0.5), 0.5))


# ---------- дом ----------

## Фасады дома, обращённые к улицам: витрины с вывесками; к переулкам — граффити.
static func facades(root: Node3D, h: Rect2, height: float, segments: Array, batch: Batch, rng: RandomNumberGenerator) -> void:
	var edges := [
		[Vector2(h.position.x, h.position.y), Vector2(h.end.x, h.position.y), Vector2(0, -1)],     # север
		[Vector2(h.end.x, h.end.y), Vector2(h.position.x, h.end.y), Vector2(0, 1)],               # юг
		[Vector2(h.position.x, h.end.y), Vector2(h.position.x, h.position.y), Vector2(-1, 0)],     # запад
		[Vector2(h.end.x, h.position.y), Vector2(h.end.x, h.end.y), Vector2(1, 0)],               # восток
	]
	for e in edges:
		var info := _edge_info(e[0], e[1], e[2], segments)
		var kind: String = info[0]
		if kind == "":
			continue
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var n: Vector2 = e[2]
		var length := a.distance_to(b)
		var dir := (b - a) / length
		var yaw := atan2(n.x, n.y)
		var units := maxi(1, int(length / 9.0))
		var unit_w := length / units
		for i in units:
			var u := a + dir * (unit_w * (i + 0.5))
			var wall := District.to_world(u + n * 0.02)
			var out := Vector3(n.x, 0, n.y)
			var roll := rng.randf()
			var entrance := false
			if kind == "street" and roll < 0.55:
				_shopfront(root, batch, wall, out, yaw, unit_w, rng)
				entrance = true
			else:
				if roll < 0.8:
					_wall_paper(root, batch, wall + Vector3(dir.x, 0, dir.y) * (unit_w * 0.25), yaw, rng, kind == "lane")
				if kind == "street" and i % 2 == 0:
					_door(batch, wall, out, yaw)
					entrance = true
			# дорожка от двери к тротуару через газон
			if kind == "street" and entrance and float(info[1]) > 4.0:
				var gap := float(info[1])
				batch.box("path", District.to_world(u + n * (gap / 2.0), 0.045), Vector3(1.8, 0.03, gap), yaw)
			# кондиционеры на верхних этажах
			for _f in rng.randi_range(0, 2):
				var floor_i := rng.randi_range(1, maxi(1, int(height / DistrictChunks.HOUSE_FLOOR_M) - 1))
				var along := dir * rng.randf_range(-unit_w * 0.35, unit_w * 0.35)
				var ac := District.to_world(u + along + n * 0.17, floor_i * DistrictChunks.HOUSE_FLOOR_M + 0.3)
				batch.model("ac_unit", ac, yaw)
		if kind == "street" and float(info[1]) > 5.0:
			_front_yard(root, batch, a, dir, n, length, float(info[1]), units, unit_w, rng)
		# водосток на углу
		var pipe := District.to_world(a + dir * 0.35 + n * 0.12, height / 2.0)
		batch.box("pipe", pipe, Vector3(0.14, height, 0.14))
		# у дверей мусор
		if rng.randf() < 0.5:
			var at := a + dir * rng.randf_range(2.0, length - 2.0) + n * 1.2
			batch.model("trash_bags" if rng.randf() < 0.6 else "boxes", District.to_world(at), rng.randf() * TAU)
	# крыша: бак, антенны, тарелка; иногда большие буквы, видные издалека
	var top := District.to_world(h.get_center(), height)
	batch.box("roof_block", top + Vector3(rng.randf_range(-4, 4), 1.1, rng.randf_range(-4, 4)), Vector3(3.0, 2.2, 3.0))
	batch.add("tank", Transform3D(Basis().scaled(Vector3(2.0, 2.4, 2.0)),
			top + Vector3(rng.randf_range(-h.size.x / 3, h.size.x / 3), 1.2, rng.randf_range(-h.size.y / 3, h.size.y / 3))),
			Color(0.42, 0.38, 0.33))
	for i in rng.randi_range(1, 3):
		batch.box("antenna", top + Vector3(rng.randf_range(-h.size.x / 2.5, h.size.x / 2.5), 1.5,
				rng.randf_range(-h.size.y / 2.5, h.size.y / 2.5)), Vector3(0.06, 3.0, 0.06))
	if height >= 18.0 and rng.randf() < 0.18:
		var e2: Array = edges[rng.randi() % 4]
		if _edge_kind(e2[0], e2[1], e2[2], segments) == "street":
			var mid: Vector2 = (e2[0] + e2[1]) / 2.0
			var n2: Vector2 = e2[2]
			var word: String = ROOF_WORDS[rng.randi() % ROOF_WORDS.size()]
			var col: Color = [Color(1, 0.25, 0.2), Color(1, 0.3, 0.75), Color(0.3, 0.9, 1.0), Color(1, 0.8, 0.3)][rng.randi() % 4]
			batch.sign(root, word, "letters", col, District.to_world(mid + n2 * 0.1, height + 1.2), rad_to_deg(atan2(n2.x, n2.y)),
					1.6, {"far": ROOF_SIGN_FAR_M}, Vector2((e2[0] as Vector2).distance_to(e2[1]) - 2.0, 0.0))


## Что за гранью дома: "street" — улица рядом (витрины), "lane" — переулок вплотную, "" — двор.
static func _edge_kind(a: Vector2, b: Vector2, n: Vector2, segments: Array) -> String:
	return _edge_info(a, b, n, segments)[0]


## [вид грани, просвет от стены до края коридора улицы в метрах].
static func _edge_info(a: Vector2, b: Vector2, n: Vector2, segments: Array) -> Array:
	var mid := (a + b) / 2.0
	var best := ""
	var best_d := 1e9
	for s in segments:
		var vertical := absf(s.a.x - s.b.x) < 0.5
		if not vertical and absf(s.a.y - s.b.y) >= 0.5:
			continue          # диагональ: витрины к ней не разворачиваем
		var w := float(s.w)
		var d := 1e9
		if vertical and absf(n.x) > 0.5:
			if mid.y < minf(s.a.y, s.b.y) or mid.y > maxf(s.a.y, s.b.y):
				continue
			d = (s.a.x - mid.x) * n.x - w / 2.0
		elif not vertical and absf(n.y) > 0.5:
			if mid.x < minf(s.a.x, s.b.x) or mid.x > maxf(s.a.x, s.b.x):
				continue
			d = (s.a.y - mid.y) * n.y - w / 2.0
		else:
			continue
		if d < -0.5 or d > 45.0:
			continue
		if d < best_d:
			best_d = d
			best = "lane" if s.id == "lane" else "street"
	return [best, best_d]


## Подъезд: дверь, козырёк, лампочка над ней и пятно света на крыльце.
static func _door(batch: Batch, wall: Vector3, out: Vector3, yaw: float) -> void:
	batch.box("door", wall + Vector3(0, 1.1, 0) + out * 0.03, Vector3(1.3, 2.2, 0.08), yaw)
	batch.box("canopy", wall + Vector3(0, 2.55, 0) + out * 0.6, Vector3(2.2, 0.14, 1.2), yaw)
	batch.box("doorlamp", wall + Vector3(0, 2.35, 0) + out * 0.12, Vector3(0.25, 0.12, 0.12), yaw)
	batch.add("spill", Transform3D(Basis().scaled(Vector3(3.5, 1.0, 3.5)), wall + out * 1.4 + Vector3(0, 0.075, 0)),
			Color(0.75, 0.6, 0.38))


## Палисадник между домом и тротуаром: газон, деревья, низкий забор у тротуара, иногда
## карман парковки с машинами носом к дому.
static func _front_yard(root: Node3D, batch: Batch, a: Vector2, dir: Vector2, n: Vector2, length: float, gap: float,
		units: int, unit_w: float, rng: RandomNumberGenerator) -> void:
	var yaw := atan2(n.x, n.y)
	var lawn_mid := a + dir * (length / 2.0) + n * (1.6 + (gap - 2.4) / 2.0)
	batch.add("lawn", Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(length - 1.0, 0.04, gap - 2.4)),
			District.to_world(lawn_mid, 0.025)), Color(0.8, 1.05, 0.7).lerp(Color(1.0, 0.95, 0.8), rng.randf()))
	# забор вдоль тротуара секциями, с разрывами у дорожек
	var t := 1.5
	while t < length - 1.5:
		var unit_center := (floorf(t / unit_w) + 0.5) * unit_w
		if absf(t - unit_center) > 1.8:
			batch.model("fence", District.to_world(a + dir * t + n * (gap - 0.3)), yaw, 0.55)
		t += 1.45
	var pocket := gap >= 10.0 and rng.randf() < 0.45
	for i in units:
		var c := (i + 0.5) * unit_w
		if pocket and i % 2 == 1:
			# машины носом к дому, между дорожками
			for j in 2:
				var at := a + dir * (c - 1.3 + j * 2.6) + n * (gap - 3.4)
				if rng.randf() < 0.8:
					var car_name: String = ["car_wreck", "taxi", "convertible"][rng.randi() % 3]
					batch.model(car_name, District.to_world(at), yaw + PI)
					var cb := Props.collider(root, Vector3(1.9, 1.4, 4.4), District.to_world(at, 0.7))
					cb.rotation.y = yaw
			batch.box("pocket", District.to_world(a + dir * c + n * (gap - 3.4), 0.03), Vector3(unit_w - 2.5, 0.05, 5.6), yaw)
		elif rng.randf() < 0.65:
			_tree(batch, District.to_world(a + dir * (c + unit_w * 0.3) + n * (gap * 0.55)), rng)
			if rng.randf() < 0.4:
				batch.model("bench", District.to_world(a + dir * (c - 1.6) + n * (gap * 0.5)), yaw + PI / 2.0)


static func _shopfront(root: Node3D, batch: Batch, wall: Vector3, out: Vector3, yaw: float, unit_w: float,
		rng: RandomNumberGenerator) -> void:
	var shop: Array = SHOPS[rng.randi() % SHOPS.size()]
	var col: Color = shop[1]
	var text := String(shop[0])
	var roll := rng.randf()
	var style := "lightbox" if roll < 0.5 else ("neon" if roll < 0.85 else "board")
	# вывеска стоит над козырьком с наклоном к небу: камера смотрит сверху, плоский короб на стене виден ребром
	var opts := {"far": SIGN_FAR_M, "flicker": style == "neon" and rng.randf() < 0.25, "lean": 32.0}
	match style:
		"lightbox":
			opts.bg = col.lerp(Color.WHITE, 0.5) if rng.randf() < 0.6 else col
			opts.ink = Color(0.08, 0.06, 0.05) if Color(opts.bg).v > 0.75 else Color.WHITE
		"board":
			opts.bg = col.darkened(0.55)
			opts.lamp = true
	# слишком длинная вывеска не лезет в витрину — ужать
	batch.sign(root, text, style, col if style != "board" else col.lightened(0.4), wall + out * 0.35 + Vector3(0, 3.0, 0),
			rad_to_deg(yaw), 0.42, opts, Vector2(unit_w - 0.6, 0.0))
	var aw := Color(col).darkened(0.25)
	batch.add("awning", Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, deg_to_rad(18.0))
			* Basis.from_scale(Vector3(unit_w * 0.8, 0.08, 1.3)), wall + out * 0.65 + Vector3(0, 2.3, 0)), aw)
	batch.add("spill", Transform3D(Basis().scaled(Vector3(unit_w * 0.8, 1.0, 3.5)).rotated(Vector3.UP, yaw),
			wall + out * 1.8 + Vector3(0, 0.075, 0)), col.lerp(Color(1, 0.85, 0.6), 0.4))


static func _wall_paper(root: Node3D, batch: Batch, wall: Vector3, yaw: float, rng: RandomNumberGenerator,
		lane: bool) -> void:
	if lane or rng.randf() < 0.5:
		batch.sign(root, GRAFFITI[rng.randi() % GRAFFITI.size()], "graffiti",
				GRAFFITI_COLORS[rng.randi() % GRAFFITI_COLORS.size()], wall + Vector3(0, rng.randf_range(1.2, 2.0), 0),
				rad_to_deg(yaw), rng.randf_range(0.45, 0.8), {"far": SIGN_FAR_M})
	else:
		var p: Array = POSTERS[rng.randi() % POSTERS.size()]
		batch.sign(root, p[0], "poster", p[1], wall + Vector3(0, 1.7, 0), rad_to_deg(yaw), 0.2,
				{"bg": p[2], "far": SIGN_FAR_M})


# ---------- сборка ----------

## Модели города заранее (на старте, под заставкой): иначе первая загрузка — рывок посреди улицы.
static func warm() -> void:
	for m in MODELS:
		_parts(m)
	# текстуры асфальта, плитки и земли грузятся при первом материале — тоже заранее
	for kind in ["plain", "sidewalk", "path", "lawn", "pocket", "curb", "paint", "zebra", "trunk", "crown", "planter", "pipe",
			"roof_block", "tank", "antenna", "awning", "puddle", "pool", "spill", "lamp_post", "cloth", "play", "door",
			"canopy", "doorlamp"]:
		_material(kind)
		_mesh(kind)
	Surfaces.asphalt()
	Surfaces.dirt()


## Строит MultiMesh всех видов участка и регистрирует фонари и точки физики.
static func flush(root: Node3D, c: Vector2i, batch: Batch) -> void:
	for step in flush_steps(root, c, batch):
		step.call()


## То же по шагу на вид: участок достраивается без рывка.
static func flush_steps(root: Node3D, c: Vector2i, batch: Batch) -> Array[Callable]:
	var out: Array[Callable] = []
	for kind: String in batch.items:
		var list: Array = batch.items[kind]
		out.append(func() -> void:
			if not is_instance_valid(root):
				return
			if kind.begins_with("model:"):
				var model := kind.trim_prefix("model:")
				for part in _parts(model):
					_multimesh(root, part[0], null, list, part[1], SHADOW_KINDS.has(model))
			else:
				_multimesh(root, _mesh(kind), _material(kind), list, Transform3D(), SHADOW_KINDS.has(kind)))
	out.append(func() -> void:
		if not is_instance_valid(root):
			return
		lamp_points[c] = batch.lamps
		prop_points[c] = batch.props
		root.tree_exiting.connect(func() -> void:
			lamp_points.erase(c)
			prop_points.erase(c)))
	return out


static func _multimesh(root: Node3D, mesh: Mesh, mat: Material, list: Array, local: Transform3D, shadow := false) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = mat != null
	mm.mesh = mesh
	mm.instance_count = list.size()
	for i in list.size():
		mm.set_instance_transform(i, list[i][0] * local)
		if mm.use_colors:
			mm.set_instance_color(i, list[i][1])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	if mat != null:
		mmi.material_override = mat
	# тень дают только крупные вещи: рамка MultiMesh — весь участок, и каждый вид иначе
	# рисуется второй раз в проход теней
	if not shadow:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)


## Части модели города: (сетка, её положение в модели). Материалы — внутри сетки.
static func _parts(name: String) -> Array:
	if _model_parts.has(name):
		return _model_parts[name]
	var out: Array = []
	if Props.exists(name):
		var sc: Node3D = load(Props.DIR % name).instantiate()
		for mi in sc.find_children("*", "MeshInstance3D", true, false):
			var m: MeshInstance3D = mi
			var xf := m.transform
			var p := m.get_parent()
			while p != sc and p != null:
				xf = (p as Node3D).transform * xf
				p = p.get_parent()
			out.append([m.mesh, xf])
		sc.free()
	_model_parts[name] = out
	return out


static func _mesh(kind: String) -> Mesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var m: Mesh
	match kind:
		"pool", "spill":
			var q := PlaneMesh.new()
			q.size = Vector2.ONE
			m = q
		"puddle":
			var cy := CylinderMesh.new()
			cy.top_radius = 0.5
			cy.bottom_radius = 0.5
			cy.height = 0.01
			cy.radial_segments = 14
			cy.rings = 1
			m = cy
		"crown":
			var sp := SphereMesh.new()
			sp.radius = 0.5
			sp.height = 1.0
			sp.radial_segments = 7
			sp.rings = 4
			m = sp
		"tank":
			var cy2 := CylinderMesh.new()
			cy2.top_radius = 0.5
			cy2.bottom_radius = 0.5
			cy2.height = 1.0
			cy2.radial_segments = 10
			cy2.rings = 1
			m = cy2
		_:
			m = BoxMesh.new()
	_meshes[kind] = m
	return m


static var _mats: Dictionary = {}


static func _material(kind: String) -> Material:
	if _mats.has(kind):
		return _mats[kind]
	if kind == "plain" or kind == "crown" or kind == "tank":
		var sm := ShaderMaterial.new()
		sm.shader = Signboard.PLAIN_SHADER
		sm.set_shader_parameter("roughness_value", 0.9 if kind == "crown" else 0.7)
		_mats[kind] = sm
		return sm
	var m := StandardMaterial3D.new()
	match kind:
		"sidewalk", "path":
			m = Surfaces.slabs(Color(0.95, 0.93, 0.9) if kind == "sidewalk" else Color(0.8, 0.78, 0.75)).duplicate()
		"lawn":
			m = Surfaces.dirt().duplicate()
		"pocket":
			m = Surfaces.asphalt(Color(1.3, 1.25, 1.2)).duplicate()
	m.vertex_color_use_as_albedo = true
	match kind:
		"curb":
			m.albedo_color = Color(0.55, 0.54, 0.52)
			m.roughness = 0.7
		"paint":
			m.albedo_color = Color(0.85, 0.85, 0.8)
			m.roughness = 0.6
		"zebra":
			m.albedo_color = Color(0.9, 0.9, 0.86)
			m.roughness = 0.6
		"trunk":
			m.albedo_color = Color(0.25, 0.18, 0.12)
		"crown":
			m.roughness = 0.95
		"planter":
			m.albedo_color = Color(0.4, 0.39, 0.37)
		"pipe":
			m.albedo_color = Color(0.3, 0.31, 0.33)
			m.roughness = 0.5
			m.metallic = 0.4
		"roof_block":
			m.albedo_color = Color(0.32, 0.31, 0.3)
		"tank":
			m.albedo_color = Color(0.42, 0.38, 0.33)
			m.roughness = 0.6
			m.metallic = 0.3
		"antenna":
			m.albedo_color = Color(0.2, 0.2, 0.22)
			m.metallic = 0.6
		"lamp_post":
			m.albedo_color = Color(0.18, 0.18, 0.2)
			m.metallic = 0.5
		"cloth":
			m.roughness = 0.95
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"play":
			m.roughness = 0.6
		"door":
			m.albedo_color = Color(0.22, 0.15, 0.1)
			m.roughness = 0.6
		"canopy":
			m.albedo_color = Color(0.45, 0.44, 0.42)
		"doorlamp":
			m.albedo_color = Color(1.0, 0.82, 0.55)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.8, 0.5)
			m.emission_energy_multiplier = 4.0
		"awning":
			m.roughness = 0.9
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"puddle":
			# мокрый асфальт: почти зеркальный, блики фонарей и вывесок
			m.albedo_color = Color(0.03, 0.035, 0.045)
			m.roughness = 0.04
			m.metallic_specular = 1.0
		"pool", "spill":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.albedo_texture = Signboard._halo_texture()
			m.albedo_color = Color(0.42, 0.33, 0.2) if kind == "pool" else Color(0.5, 0.5, 0.5)
			m.disable_receive_shadows = true
	_mats[kind] = m
	return m


## Свободные куски [t_lo, t_hi] луча a + dir·t (метры), где полоса со сдвигом off не лезет
## в поперечные улицы и двор старта и лежит в участке rect. Шаг проверки — 2 м.
static func _free(a: Vector2, dir: Vector2, t_lo: float, t_hi: float, off: Vector2, half_w: float, blockers: Array,
		start: Rect2, rect: Rect2) -> Array:
	var out: Array = []
	var run_start := -1.0
	var t := t_lo
	while t <= t_hi:
		var q := a + dir * t + off
		var ok := rect.has_point(q) and not _blocked(q, blockers, half_w, start)
		if ok and run_start < 0.0:
			run_start = t
		elif not ok and run_start >= 0.0:
			if t - run_start > 1.5:
				out.append([run_start, t])
			run_start = -1.0
		t += 2.0
	if run_start >= 0.0 and t_hi - run_start > 1.5:
		out.append([run_start, t_hi])
	return out


## Точка в коридоре другой улицы (с запасом margin) или во дворе старта.
static func _blocked(q: Vector2, blockers: Array, margin: float, start: Rect2) -> bool:
	if start.has_point(q):
		return true
	for o in blockers:
		if not (o[3] as Rect2).has_point(q):
			continue
		var cp := Geometry2D.get_closest_point_to_segment(q, o[0], o[1])
		if cp.distance_to(q) < float(o[2]) + margin:
			return true
	return false
