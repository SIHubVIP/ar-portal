"""Модели города для Погуляя: панельки, кабриолет, киоск, гаражи, фонари, мусорки, лавки, билборд.

    blender -b --python tools/blender/build_city_assets.py -- <out_dir> [render_dir]

Геометрия собирается из коробок и цилиндров прямо в данные меша (быстро и без зависимостей),
материалы — плоские цвета, окна и фары светятся. Каждая модель — отдельный .glb,
начало координат в центре основания, «лицо» смотрит в -Y Blender (= +Z в Godot).
Панелька строится под конкретное число этажей: panel_<этажи>.glb, 12 x 20 м в плане.
"""
import bpy, sys, os, math, random

argv = sys.argv[sys.argv.index("--") + 1:]
OUT = argv[0]
RENDER = argv[1] if len(argv) > 1 else None
os.makedirs(OUT, exist_ok=True)

PALETTE = {
    "panel": ((0.62, 0.6, 0.56), 0, 0.9), "panel_dark": ((0.42, 0.41, 0.4), 0, 0.9),
    "seam": ((0.3, 0.3, 0.3), 0, 0.9), "roof": ((0.22, 0.22, 0.24), 0, 0.9),
    "win_dark": ((0.12, 0.15, 0.22), 0, 0.3), "win_lit": ((1.0, 0.8, 0.45), 2.5, 0.4),
    "win_tv": ((0.45, 0.6, 1.0), 2.0, 0.4), "frame": ((0.85, 0.83, 0.78), 0, 0.7),
    "balcony": ((0.55, 0.52, 0.5), 0, 0.9), "rust": ((0.45, 0.25, 0.15), 0, 0.9),
    "laundry_a": ((0.9, 0.3, 0.3), 0, 0.9), "laundry_b": ((0.95, 0.95, 0.9), 0, 0.9),
    "door": ((0.25, 0.18, 0.12), 0, 0.8), "metal": ((0.3, 0.32, 0.35), 0, 0.5),
    "car_red": ((0.75, 0.06, 0.08), 0, 0.25), "chrome": ((0.85, 0.85, 0.88), 0, 0.15),
    "tire": ((0.05, 0.05, 0.05), 0, 0.9), "seat": ((0.35, 0.2, 0.12), 0, 0.7),
    "glass": ((0.55, 0.75, 0.85), 0, 0.1), "headlight": ((1.0, 0.95, 0.8), 3.0, 0.2),
    "taillight": ((1.0, 0.1, 0.05), 2.0, 0.2),
    "kiosk_wall": ((0.88, 0.87, 0.82), 0, 0.8), "kiosk_blue": ((0.1, 0.35, 0.8), 0, 0.6),
    "kiosk_window": ((1.0, 0.9, 0.6), 1.5, 0.3), "goods_a": ((0.9, 0.2, 0.2), 0, 0.6),
    "goods_b": ((0.2, 0.7, 0.3), 0, 0.6), "goods_c": ((0.95, 0.8, 0.2), 0, 0.6),
    "garage": ((0.45, 0.43, 0.4), 0, 0.9), "garage_door": ((0.3, 0.42, 0.34), 0, 0.7),
    "garage_door13": ((0.85, 0.6, 0.15), 0, 0.7), "lamp": ((1.0, 0.85, 0.55), 4.0, 0.3),
    "pole": ((0.25, 0.27, 0.28), 0, 0.6), "dumpster": ((0.15, 0.4, 0.22), 0, 0.7),
    "trash": ((0.3, 0.25, 0.2), 0, 0.9), "wood": ((0.5, 0.33, 0.18), 0, 0.8),
    "board": ((0.08, 0.08, 0.1), 0, 0.6), "board_face": ((0.95, 0.35, 0.55), 1.2, 0.5),
    "concrete": ((0.5, 0.5, 0.5), 0, 0.95), "graffiti": ((0.2, 0.8, 0.9), 0.4, 0.8),
}


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitbash
from kitbash import Builder, material
kitbash.PALETTE.update(PALETTE)


def export(ob, name):
    kitbash.export(ob, name, OUT)


# ---------------- панелька ----------------

def panel_block(floors, seed):
    rnd = random.Random(seed)
    W, D, FH = 12.0, 20.0, 3.0
    H = floors * FH
    b = Builder(f"panel_{floors}")
    b.box((0, 0, H / 2), (W, D, H), "panel")
    b.box((0, 0, 0.4), (W + 0.1, D + 0.1, 0.8), "panel_dark")          # цоколь
    b.box((0, 0, H + 0.3), (W + 0.3, D + 0.3, 0.6), "roof")            # парапет
    b.box((2, 4, H + 1.0), (2.5, 2.5, 1.6), "roof")                     # будка лифта
    for i in range(3):                                                   # антенны
        x, y = rnd.uniform(-4, 4), rnd.uniform(-8, 8)
        b.cyl((x, y, H + 1.2), 0.04, 2.4, "metal", segs=6)
        b.box((x, y, H + 2.2), (1.2, 0.05, 0.05), "metal")
    for f in range(1, floors):                                           # межэтажные швы
        b.box((0, 0, f * FH), (W + 0.04, D + 0.04, 0.08), "seam")

    def window(c, along_x, lit_bias=0.22):
        """Окно с рамой на грани. along_x — грань ортогональна Y (короткая сторона)."""
        r = rnd.random()
        glass = "win_lit" if r < lit_bias else ("win_tv" if r < lit_bias + 0.04 else "win_dark")
        if along_x:
            b.box(c, (1.5, 0.12, 1.7), "frame")
            b.box((c[0], c[1] + math.copysign(0.03, c[1]), c[2]), (1.3, 0.12, 1.5), glass)
        else:
            b.box(c, (0.12, 1.5, 1.7), "frame")
            b.box((c[0] + math.copysign(0.03, c[0]), c[1], c[2]), (0.12, 1.3, 1.5), glass)

    cols_long = 6
    cols_short = 3
    for f in range(floors):
        z = f * FH + 1.7
        for side in (-1, 1):
            # длинные стороны (±X): окна, балконы через одно окно, у подъездов — лестничные окна
            for ci in range(cols_long):
                y = -D / 2 + (ci + 0.5) * D / cols_long
                x = side * (W / 2 + 0.02)
                if side > 0 and ci in (1, 4) and f == 0:
                    continue  # на первом этаже там двери подъездов
                window((x, y, z), False)
                if f > 0 and ci % 2 == 0:
                    bx = side * (W / 2 + 0.65)
                    b.box((bx, y, z - 1.2), (1.3, 2.6, 0.15), "balcony")            # плита
                    b.box((side * (W / 2 + 1.28), y, z - 0.7), (0.06, 2.6, 0.9), "balcony")
                    for e in (-1, 1):
                        b.box((bx, y + e * 1.28, z - 0.7), (1.3, 0.06, 0.9), "balcony")
                    deco = rnd.random()
                    if deco < 0.3:                                                    # бельё
                        b.box((bx, y, z + 0.6), (0.02, 2.4, 0.02), "metal")
                        for k in range(3):
                            b.box((bx, y - 0.8 + k * 0.7, z + 0.3), (0.03, 0.5, 0.55),
                                  rnd.choice(["laundry_a", "laundry_b"]))
                    elif deco < 0.45:                                                 # ржавый хлам
                        b.box((bx, y + 0.6, z - 0.9), (0.6, 0.8, 0.5), "rust")
                    elif deco < 0.55:                                                 # тарелка ТВ
                        b.cyl((side * (W / 2 + 1.3), y - 0.8, z + 0.4), 0.35, 0.06, "frame", axis="x", segs=10)
        for side in (-1, 1):
            for ci in range(cols_short):
                x = -W / 2 + (ci + 0.5) * W / cols_short
                window((x, side * (D / 2 + 0.02), z), True)
    # подъезды на +X: дверь, козырёк, лампа, лавка
    for ci in (1, 4):
        y = -D / 2 + (ci + 0.5) * D / cols_long
        b.box((W / 2 + 0.05, y, 1.15), (0.15, 1.4, 2.3), "door")
        b.box((W / 2 + 0.9, y, 2.6), (1.8, 2.2, 0.15), "concrete")
        b.box((W / 2 + 0.1, y, 2.4), (0.2, 0.4, 0.2), "lamp")
        b.box((W / 2 + 0.6, y + 0.9, 0.15), (1.2, 0.5, 0.3), "concrete")              # ступени
        b.box((W / 2 + 0.07, y - 0.9, 1.5), (0.04, 0.5, 0.6), "graffiti")
        # лестничные окна на этажах над подъездом
        for f in range(1, floors):
            b.box((W / 2 + 0.03, y, f * FH + 0.4), (0.12, 0.9, 1.2), "win_dark" if rnd.random() < 0.7 else "win_lit")
    ob = b.build()
    export(ob, f"panel_{floors}")
    return ob


# ---------------- кабриолет ----------------

def convertible():
    b = Builder("convertible")
    b.box((0, 0, 0.55), (1.9, 4.3, 0.55), "car_red")             # кузов
    b.box((0, -1.45, 0.88), (1.85, 1.3, 0.14), "car_red")        # капот
    b.box((0, 1.55, 0.88), (1.85, 1.1, 0.14), "car_red")         # багажник
    for s in (-1, 1):
        b.box((s * 0.9, 0.2, 0.92), (0.1, 2.0, 0.22), "car_red")  # борта
        b.box((s * 0.97, 0, 0.6), (0.04, 4.0, 0.06), "chrome")    # молдинг
        b.box((s * 0.45, 0.65, 0.75), (0.7, 0.6, 0.2), "seat")    # задний диван
        b.box((s * 0.45, 0.95, 1.05), (0.7, 0.12, 0.5), "seat")
        b.box((s * 0.45, -0.25, 0.75), (0.6, 0.55, 0.2), "seat")  # передние кресла
        b.box((s * 0.45, 0.02, 1.08), (0.6, 0.12, 0.55), "seat")
        b.box((s * 0.65, -2.16, 0.68), (0.35, 0.05, 0.16), "headlight")
        b.box((s * 0.7, 2.16, 0.7), (0.3, 0.05, 0.12), "taillight")
        for y in (-1.35, 1.35):
            b.cyl((s * 0.88, y, 0.36), 0.36, 0.28, "tire", axis="x", segs=14)
            b.cyl((s * 1.03, y, 0.36), 0.2, 0.03, "chrome", axis="x", segs=10)
    b.box((0, -0.8, 1.15), (1.8, 0.06, 0.5), "glass", )          # лобовое
    b.box((0, -0.82, 1.42), (1.84, 0.08, 0.06), "chrome")
    b.cyl((-0.45, -0.55, 1.0), 0.18, 0.04, "board", axis="y", segs=12)  # руль
    b.box((0, -2.18, 0.42), (1.9, 0.12, 0.12), "chrome")          # бамперы
    b.box((0, 2.18, 0.42), (1.9, 0.12, 0.12), "chrome")
    b.box((0, 0.8, 0.86), (0.25, 0.4, 0.06), "laundry_b")         # чья-то бумажка на сиденье
    ob = b.build()
    export(ob, "convertible")
    return ob


# ---------------- киоск ----------------

def kiosk():
    b = Builder("kiosk")
    b.box((0, 0, 1.5), (4, 3, 3), "kiosk_wall")
    b.box((0, 0, 0.15), (4.1, 3.1, 0.3), "panel_dark")
    b.box((0, -1.52, 1.6), (2.8, 0.06, 1.2), "kiosk_window")       # витрина
    for i, m in enumerate(["goods_a", "goods_b", "goods_c", "goods_a", "goods_c"]):
        b.box((-1.1 + i * 0.55, -1.4, 1.2), (0.4, 0.2, 0.5 + (i % 2) * 0.2), m)
    b.box((0, -1.6, 1.0), (3.0, 0.3, 0.08), "metal")                # прилавок
    b.box((0, -1.9, 2.55), (4.4, 1.0, 0.1), "kiosk_blue")           # козырёк
    b.box((0, 0, 3.3), (4.4, 3.4, 0.6), "kiosk_blue")               # короб вывески
    b.box((1.6, 1.55, 1.1), (0.7, 0.08, 2.0), "door")
    b.box((-2.4, -0.6, 0.8), (0.7, 0.7, 1.6), "goods_a")            # холодильник с газировкой
    b.box((-2.4, -0.97, 0.9), (0.55, 0.05, 1.2), "glass")
    b.box((2.1, -1.0, 0.25), (0.5, 0.5, 0.5), "wood")               # ящики
    b.box((2.2, -0.4, 0.25), (0.5, 0.5, 0.5), "wood")
    b.box((2.15, -0.7, 0.75), (0.5, 0.5, 0.5), "wood")
    ob = b.build()
    export(ob, "kiosk")
    return ob


# ---------------- гараж ----------------

def garage(name, door):
    b = Builder(name)
    b.box((0, 0, 1.5), (4, 4, 3), "garage")
    b.box((0, 0.2, 3.1), (4.3, 4.6, 0.2), "roof")
    b.box((0, -2.02, 1.2), (3.0, 0.06, 2.4), door)
    for k in range(10):                                            # гофра ворот
        b.box((0, -2.06, 0.15 + k * 0.24), (3.0, 0.04, 0.05), "metal")
    b.box((0, -2.04, 2.5), (3.2, 0.1, 0.12), "rust")
    b.box((1.2, -2.07, 1.2), (0.12, 0.05, 0.2), "chrome")            # замок
    b.box((-1.7, -2.04, 1.0), (0.2, 0.05, 1.8), "rust")              # потёки
    ob = b.build()
    export(ob, name)
    return ob


def streetlamp():
    b = Builder("streetlamp")
    b.cyl((0, 0, 3.0), 0.09, 6.0, "pole", segs=8, r2=0.06)
    b.box((0, -0.8, 5.95), (0.08, 1.6, 0.08), "pole")
    b.box((0, -1.55, 5.8), (0.35, 0.6, 0.2), "pole")
    b.box((0, -1.55, 5.68), (0.28, 0.5, 0.05), "lamp")
    b.cyl((0, 0, 0.2), 0.18, 0.4, "concrete", segs=8)
    ob = b.build()
    export(ob, "streetlamp")
    return ob


def dumpster():
    b = Builder("dumpster")
    b.box((0, 0, 0.6), (1.7, 1.1, 1.0), "dumpster")
    b.box((0, 0, 0.08), (1.75, 1.15, 0.16), "metal")
    b.box((-0.43, 0.1, 1.2), (0.85, 1.1, 0.06), "dumpster", rot_z=0.0)
    b.box((0.45, 0.25, 1.35), (0.85, 0.06, 0.6), "dumpster")         # открытая крышка
    for x, y, m in ((0.4, -0.1, "trash"), (0.2, 0.2, "laundry_b"), (0.55, 0.0, "goods_a")):
        b.box((x, y, 1.15), (0.4, 0.35, 0.35), m)
    for x in (-0.7, 0.7):
        for y in (-0.45, 0.45):
            b.cyl((x, y, 0.07), 0.07, 0.06, "tire", axis="x", segs=8)
    b.box((0, -0.56, 0.6), (0.9, 0.03, 0.35), "graffiti")
    ob = b.build()
    export(ob, "dumpster")
    return ob


def bench():
    b = Builder("bench")
    for k in range(3):
        b.box((0, -0.15 + k * 0.17, 0.45), (2.2, 0.13, 0.05), "wood")
    for k in range(2):
        b.box((0, 0.3, 0.65 + k * 0.17), (2.2, 0.04, 0.12), "wood")
    for x in (-0.9, 0.9):
        b.box((x, 0.05, 0.22), (0.08, 0.55, 0.44), "concrete")
    b.box((0.6, 0.0, 0.53), (0.1, 0.1, 0.12), "goods_b")              # забытая бутылка
    ob = b.build()
    export(ob, "bench")
    return ob


def billboard():
    b = Builder("billboard")
    for x in (-2.2, 2.2):
        b.box((x, 0, 3.0), (0.25, 0.25, 6.0), "pole")
    b.box((0, 0, 6.2), (7.0, 0.3, 3.4), "board")
    b.box((0, -0.17, 6.2), (6.6, 0.05, 3.0), "board_face")
    b.box((0, -0.5, 4.45), (7.0, 0.6, 0.08), "metal")                # мостик
    for x in (-2.5, 0, 2.5):
        b.box((x, -0.6, 7.95), (0.2, 0.4, 0.15), "lamp")
    ob = b.build()
    export(ob, "billboard")
    return ob


bpy.ops.wm.read_factory_settings(use_empty=True)
made = {}
for floors, seed in ((5, 11), (6, 12), (8, 13), (9, 14)):
    made[f"panel_{floors}"] = panel_block(floors, seed)
made["convertible"] = convertible()
made["kiosk"] = kiosk()
made["garage"] = garage("garage", "garage_door")
made["garage_13"] = garage("garage_13", "garage_door13")
made["streetlamp"] = streetlamp()
made["dumpster"] = dumpster()
made["bench"] = bench()
made["billboard"] = billboard()

if RENDER:
    os.makedirs(RENDER, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 10
    scene.cycles.use_denoising = False
    scene.render.resolution_x, scene.render.resolution_y = 420, 320
    world = bpy.data.worlds.new("w")
    world.color = (0.3, 0.3, 0.35)
    scene.world = world
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = 3
    sun.rotation_euler = (math.radians(50), 0, math.radians(-40))
    scene.collection.objects.link(sun)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    for name, ob in made.items():
        for o in made.values():
            o.hide_render = o is not ob
        dims = ob.dimensions
        r = max(dims) * 1.5
        cam.location = (r * 0.75, -r * 0.9, dims.z * 0.5 + r * 0.45)
        direction = (-cam.location[0], -cam.location[1], dims.z * 0.45 - cam.location[2])
        from mathutils import Vector
        cam.rotation_euler = Vector(direction).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(RENDER, name + ".png")
        bpy.ops.render.render(write_still=True)
