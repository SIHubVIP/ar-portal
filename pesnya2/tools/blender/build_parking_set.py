"""Эталон парковки «Похмельная» (этап 2 ТЗ «Погуляй»): модели по утверждённому ориентиру.

    blender -b --python tools/blender/build_parking_set.py -- <out_dir> [render_dir]

Будка парковки, шлагбаум, киоск «НЛО напрокат» с тарелкой на крыше, кирпичная арка,
перила канала, такси, табличка остановки, лоток рынка с доской, кондиционер.
Тексты вывесок ставит Godot (Label3D), здесь — только щиты под них. Материалы brick и
cobble Godot заменяет текстурами assets/textures. Начало координат — центр основания,
«лицо» смотрит в -Y Blender (= +Z в Godot).
"""
import bpy, sys, os, math

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitbash
from kitbash import Builder

argv = sys.argv[sys.argv.index("--") + 1:]
OUT = argv[0]
RENDER = argv[1] if len(argv) > 1 else None
os.makedirs(OUT, exist_ok=True)

kitbash.PALETTE.update({
    "plank": ((0.42, 0.3, 0.2), 0, 0.85), "plank_dark": ((0.28, 0.2, 0.14), 0, 0.9),
    "plywood": ((0.62, 0.5, 0.36), 0, 0.85), "tin": ((0.4, 0.42, 0.43), 0, 0.45),
    "rust": ((0.45, 0.25, 0.14), 0, 0.9), "win_warm": ((1.0, 0.72, 0.38), 2.2, 0.3),
    "frame": ((0.2, 0.18, 0.16), 0, 0.7), "door": ((0.32, 0.22, 0.14), 0, 0.8),
    "board": ((0.1, 0.09, 0.09), 0, 0.7), "board_trim": ((0.75, 0.55, 0.25), 0, 0.6),
    "p_blue": ((0.1, 0.3, 0.75), 0, 0.5), "p_white": ((0.95, 0.95, 0.95), 0, 0.5),
    "stripe_red": ((0.85, 0.1, 0.1), 0, 0.45), "stripe_white": ((0.95, 0.93, 0.9), 0, 0.45),
    "post_yellow": ((0.95, 0.75, 0.1), 0, 0.5), "post_black": ((0.08, 0.08, 0.08), 0, 0.5),
    "bulb": ((1.0, 0.82, 0.5), 3.0, 0.3), "wire": ((0.05, 0.05, 0.05), 0, 0.6),
    "ufo": ((0.72, 0.74, 0.78), 0, 0.25), "ufo_dark": ((0.32, 0.33, 0.36), 0, 0.4),
    "ufo_dome": ((0.4, 0.85, 1.0), 1.2, 0.1), "ufo_light_a": ((0.3, 1.0, 0.7), 4.0, 0.2),
    "ufo_light_b": ((1.0, 0.3, 0.8), 4.0, 0.2), "alien": ((0.45, 0.85, 0.35), 0.3, 0.6),
    "goods_a": ((0.9, 0.2, 0.2), 0, 0.6), "goods_b": ((0.2, 0.7, 0.3), 0, 0.6),
    "goods_c": ((0.95, 0.8, 0.2), 0, 0.6), "goods_d": ((0.6, 0.3, 0.8), 0, 0.6),
    "brick": ((0.55, 0.27, 0.18), 0, 0.85), "stone": ((0.62, 0.58, 0.52), 0, 0.9),
    "pipe": ((0.35, 0.33, 0.3), 0, 0.5), "lamp_glass": ((1.0, 0.8, 0.45), 4.0, 0.3),
    "iron": ((0.16, 0.16, 0.17), 0, 0.5), "rail_yellow": ((0.95, 0.72, 0.1), 0, 0.5),
    "taxi": ((0.95, 0.72, 0.08), 0, 0.3), "glass": ((0.3, 0.38, 0.45), 0, 0.08),
    "tire": ((0.05, 0.05, 0.05), 0, 0.9), "chrome": ((0.85, 0.85, 0.88), 0, 0.15),
    "headlight": ((1.0, 0.95, 0.8), 3.0, 0.2), "taillight": ((1.0, 0.1, 0.05), 2.0, 0.2),
    "taxi_sign": ((1.0, 0.85, 0.3), 2.0, 0.3), "checker": ((0.06, 0.06, 0.06), 0, 0.4),
    "awning_red": ((0.75, 0.13, 0.12), 0, 0.7), "awning_white": ((0.92, 0.88, 0.8), 0, 0.7),
    "crate": ((0.55, 0.38, 0.22), 0, 0.85), "veg_green": ((0.3, 0.6, 0.2), 0, 0.6),
    "veg_red": ((0.85, 0.15, 0.1), 0, 0.5), "veg_orange": ((0.95, 0.5, 0.1), 0, 0.5),
    "fish": ((0.6, 0.65, 0.7), 0, 0.3), "chalk": ((0.95, 0.93, 0.85), 0, 0.8),
    "ac": ((0.82, 0.82, 0.8), 0, 0.6), "ac_grille": ((0.2, 0.2, 0.2), 0, 0.6),
})

made = {}


def done(b, name):
    ob = b.build()
    kitbash.export(ob, name, OUT)
    made[name] = ob


def bulbs(b, a, c, n, sag):
    """Гирлянда: n лампочек по провисающей дуге от a до c."""
    for i in range(n + 1):
        t = i / n
        p = [a[k] + (c[k] - a[k]) * t for k in range(3)]
        p[2] -= sag * 4 * t * (1 - t)
        b.sphere(tuple(p), 0.06, "bulb", segs=6, rings=4)


def parking_booth():
    """Будка «Парковка платная. Сон тоже»: доски, жесть, тёплые окна, щит под надпись над входом."""
    b = Builder("parking_booth")
    W, D, H = 3.2, 2.2, 2.6
    b.box((0, 0, 0.1), (W + 0.2, D + 0.2, 0.2), "plank_dark")
    for i in range(8):                                           # дощатые стены
        x = -W / 2 + (i + 0.5) * W / 8
        b.box((x, 0, H / 2 + 0.1), (W / 8 - 0.02, D, H), "plank" if i % 3 else "plank_dark")
    b.box((0.35, -D / 2 - 0.02, 1.55), (1.6, 0.06, 0.9), "win_warm")        # окно кассы
    b.box((0.35, -D / 2 - 0.05, 1.05), (1.8, 0.12, 0.08), "frame")
    b.box((0.35, -D / 2 - 0.05, 2.03), (1.8, 0.12, 0.08), "frame")
    b.box((0.35, -D / 2 - 0.25, 1.0), (1.6, 0.4, 0.06), "plank_dark")         # полочка для денег
    b.box((-1.05, -D / 2 - 0.02, 1.0), (0.8, 0.06, 1.8), "door")
    b.box((W / 2 + 0.02, 0, 1.6), (0.06, 1.0, 0.7), "win_warm")              # боковое окно
    b.box((0, 0.1, H + 0.2), (W + 0.6, D + 0.8, 0.12), "tin")                # жестяная крыша
    b.box((0.9, 0.5, H + 0.27), (1.0, 1.0, 0.03), "rust")
    b.box((0, -D / 2 - 0.35, H + 0.75), (W + 0.4, 0.12, 0.95), "board")      # щит вывески
    b.box((0, -D / 2 - 0.42, H + 0.29), (W + 0.5, 0.06, 0.06), "board_trim")
    b.box((0, -D / 2 - 0.42, H + 1.21), (W + 0.5, 0.06, 0.06), "board_trim")
    for sx in (-1, 1):
        b.box((sx * (W / 2 + 0.1), -D / 2 - 0.35, H + 0.6), (0.08, 0.08, 1.4), "frame")
    b.box((-W / 2 - 0.05, -D / 2 + 0.2, 1.3), (0.06, 0.8, 0.8), "p_blue")    # знак P
    b.box((-W / 2 - 0.09, -D / 2 + 0.2, 1.3), (0.02, 0.35, 0.5), "p_white")
    b.cyl((W / 2 - 0.3, -D / 2 - 0.5, H + 1.45), 0.12, 0.2, "lamp_glass", segs=8)
    b.box((W / 2 - 0.3, -D / 2 - 0.3, H + 1.5), (0.04, 0.45, 0.04), "iron")
    done(b, "parking_booth")


def boom_gate():
    """Шлагбаум: жёлто-чёрная тумба и красно-белая стрела 5 м вдоль +X."""
    b = Builder("boom_gate")
    b.box((0, 0, 0.55), (0.4, 0.4, 1.1), "post_yellow")
    for k in range(3):
        b.box((0, 0, 0.2 + k * 0.35), (0.42, 0.42, 0.12), "post_black")
    b.box((0, 0, 1.15), (0.5, 0.5, 0.1), "post_black")
    for i in range(10):
        b.box((0.4 + i * 0.5, 0, 1.0), (0.5, 0.1, 0.12), "stripe_red" if i % 2 == 0 else "stripe_white")
    b.box((5.0, 0, 0.5), (0.08, 0.08, 1.0), "post_black")                    # опора конца стрелы
    done(b, "boom_gate")


def ufo_kiosk():
    """Временный прокатный киоск «НЛО напрокат»: фанера, витрина, гирлянда, тарелка на крыше."""
    b = Builder("ufo_kiosk")
    W, D, H = 4.0, 2.6, 2.6
    b.box((0, 0, H / 2), (W, D, H), "plywood")
    b.box((0, 0, 0.1), (W + 0.1, D + 0.1, 0.2), "plank_dark")
    b.box((0, -D / 2 - 0.01, 1.55), (3.0, 0.04, 1.1), "win_warm")            # витрина
    for i, m in enumerate(["goods_a", "goods_b", "goods_c", "goods_d", "goods_b", "goods_a"]):
        b.box((-1.25 + i * 0.5, -D / 2 - 0.05, 1.25 + (i % 2) * 0.35), (0.3, 0.1, 0.25), m)
    b.box((0, -D / 2 - 0.35, 0.95), (3.4, 0.7, 0.08), "plank")               # прилавок
    b.box((0, -D / 2 - 0.35, 0.47), (3.4, 0.6, 0.94), "plywood")
    for i in range(3):                                                       # зелёные человечки
        b.sphere((-1.2 + i * 1.2, -D / 2 - 0.5, 1.2), 0.12, "alien", segs=8, rings=5, scale=(1, 1, 1.3))
    b.box((0, -D / 2 - 0.6, 2.35), (W + 0.6, 1.3, 0.08), "tin")              # козырёк
    bulbs(b, (-W / 2 - 0.2, -D / 2 - 1.2, 2.3), (W / 2 + 0.2, -D / 2 - 1.2, 2.3), 12, 0.25)
    b.box((0, 0, H + 0.08), (W + 0.2, D + 0.2, 0.16), "tin")
    b.box((0, -D / 2 - 0.1, H + 0.55), (W, 0.12, 0.8), "board")              # щит неона
    # тарелка на крыше
    b.cyl((0, 0.3, H + 0.75), 0.15, 0.6, "iron", segs=8)
    b.sphere((0, 0.3, H + 1.15), 1.7, "ufo", segs=20, rings=8, scale=(1, 1, 0.22))
    b.sphere((0, 0.3, H + 1.0), 1.0, "ufo_dark", segs=16, rings=6, scale=(1, 1, 0.3))
    b.sphere((0, 0.3, H + 1.45), 0.6, "ufo_dome", segs=14, rings=7, scale=(1, 1, 0.7))
    for i in range(12):
        a = 2 * math.pi * i / 12
        b.sphere((math.cos(a) * 1.45, 0.3 + math.sin(a) * 1.45, H + 1.12), 0.09,
                 "ufo_light_a" if i % 2 else "ufo_light_b", segs=6, rings=4)
    b.box((W / 2 + 0.3, 0.6, 0.45), (0.5, 0.5, 0.9), "crate")                # ящики сбоку
    b.box((W / 2 + 0.35, 0.0, 0.25), (0.5, 0.5, 0.5), "crate")
    done(b, "ufo_kiosk")


def brick_arch():
    """Кирпичная арка в торцевом доме: проём 7 × 6 м, каменная обводка, трубы и фонарь."""
    b = Builder("brick_arch")
    W, D, H = 12.0, 4.0, 9.0
    half, spring, rise = 3.5, 4.4, 1.8                                       # полупролёт, пята, стрела
    for sx in (-1, 1):
        b.box((sx * (half + (W / 2 - half) / 2), 0, H / 2), (W / 2 - half, D, H), "brick")
        b.box((sx * (half + 0.15), -D / 2 - 0.08, spring / 2), (0.3, 0.16, spring), "stone")   # обводка пилонов
        b.box((sx * (W / 2 - 0.2), -D / 2 - 0.05, H / 2), (0.4, 0.1, H), "stone")
    n = 18
    for i in range(n):                                                        # свод из полос
        x0 = -half + 2 * half * i / n
        x1 = -half + 2 * half * (i + 1) / n
        xm = (x0 + x1) / 2
        z = spring + rise * math.sqrt(max(0.0, 1 - (xm / half) ** 2))
        b.box((xm, 0, (z + H) / 2), (x1 - x0 + 0.01, D, H - z), "brick")
        b.box((xm, -D / 2 - 0.08, z + 0.2), (x1 - x0 + 0.02, 0.16, 0.4), "stone")
    b.box((0, -D / 2 - 0.12, spring + rise + 0.5), (0.7, 0.24, 0.9), "stone")    # замковый камень
    b.box((0, -D / 2 - 0.06, H - 0.3), (W, 0.12, 0.6), "stone")                  # карниз
    b.box((0, 0, H + 0.1), (W + 0.2, D + 0.2, 0.2), "stone")
    for x in (-5.0, 4.6):                                                     # водосточные трубы
        b.cyl((x, -D / 2 - 0.2, H / 2), 0.1, H, "pipe", segs=8)
    b.cyl((-4.2, -D / 2 - 0.25, 3.0), 0.08, 3.6, "pipe", axis="x", segs=8)
    b.box((0, -D / 2 - 0.35, spring + rise + 1.3), (0.06, 0.5, 0.06), "iron")
    b.cyl((0, -D / 2 - 0.6, spring + rise + 1.15), 0.16, 0.28, "lamp_glass", segs=8)
    done(b, "brick_arch")


def canal_rail():
    """Перила канала, секция 4 м вдоль X: стойки через метр, две жёлтые трубы."""
    b = Builder("canal_rail")
    for i in range(5):
        b.box((-2 + i, 0, 0.55), (0.07, 0.07, 1.1), "iron")
    b.cyl((0, 0, 1.1), 0.04, 4.0, "rail_yellow", axis="x", segs=8)
    b.cyl((0, 0, 0.6), 0.03, 4.0, "iron", axis="x", segs=8)
    done(b, "canal_rail")


def taxi():
    """Жёлтое такси с шашечками, 1.8 × 4.3 м, нос в -Y."""
    b = Builder("taxi")
    b.box((0, 0, 0.6), (1.8, 4.3, 0.55), "taxi")
    b.box((0, 0.25, 1.15), (1.6, 2.1, 0.6), "taxi")
    b.box((0, -0.85, 1.15), (1.5, 0.08, 0.5), "glass")
    b.box((0, 1.35, 1.15), (1.5, 0.08, 0.5), "glass")
    for sx in (-1, 1):
        b.box((sx * 0.81, 0.25, 1.15), (0.04, 1.9, 0.45), "glass")
        for i in range(8):                                                    # шашечки
            b.box((sx * 0.91, -1.4 + i * 0.4, 0.72), (0.02, 0.2, 0.12), "checker")
        b.box((sx * 0.6, -2.16, 0.65), (0.35, 0.04, 0.16), "headlight")
        b.box((sx * 0.65, 2.16, 0.65), (0.3, 0.04, 0.14), "taillight")
        for y in (-1.35, 1.35):
            b.cyl((sx * 0.85, y, 0.34), 0.34, 0.24, "tire", axis="x", segs=12)
    b.box((0, -2.18, 0.4), (1.8, 0.1, 0.16), "chrome")
    b.box((0, 2.18, 0.4), (1.8, 0.1, 0.16), "chrome")
    b.box((0, 0.25, 1.55), (0.7, 0.3, 0.2), "taxi_sign")
    done(b, "taxi")


def taxi_sign():
    """Столб остановки такси со щитом под надпись (щит смотрит в -Y)."""
    b = Builder("taxi_sign")
    b.cyl((0, 0, 1.4), 0.05, 2.8, "iron", segs=8)
    b.box((0, -0.04, 2.5), (0.9, 0.06, 0.55), "taxi")
    b.box((0, -0.08, 2.5), (0.8, 0.02, 0.12), "checker")
    b.box((0, 0, 0.05), (0.4, 0.4, 0.1), "iron")
    done(b, "taxi_sign")


def market_stall():
    """Лоток у канала: стол с ящиками овощей и рыбой, красно-белый навес, гирлянда."""
    b = Builder("market_stall")
    W, D = 3.0, 1.4
    b.box((0, 0, 0.85), (W, D, 0.08), "plank")
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.box((sx * (W / 2 - 0.1), sy * (D / 2 - 0.1), 0.42), (0.08, 0.08, 0.84), "plank_dark")
            b.box((sx * (W / 2 - 0.05), sy * (D / 2 + 0.3), 1.25), (0.06, 0.06, 2.5), "iron")
    for i, veg in enumerate(["veg_green", "veg_red", "veg_orange", "veg_green"]):
        x = -1.1 + i * 0.73
        b.box((x, -0.15, 1.0), (0.65, 0.9, 0.22), "crate")
        for k in range(6):
            b.sphere((x - 0.2 + (k % 3) * 0.2, -0.4 + (k // 3) * 0.4, 1.17), 0.1, veg, segs=7, rings=4)
    for i in range(3):
        b.sphere((-0.6 + i * 0.6, -0.68, 0.95), 0.08, "fish", segs=8, rings=4, scale=(3, 1, 0.8))
    for i in range(6):                                                         # полосатый навес
        b.box((-W / 2 + (i + 0.5) * W / 6 - 0.05, 0, 2.45), (W / 6, D + 0.9, 0.05),
              "awning_red" if i % 2 == 0 else "awning_white")
    bulbs(b, (-W / 2, -D / 2 - 0.45, 2.4), (W / 2, -D / 2 - 0.45, 2.4), 8, 0.15)
    done(b, "market_stall")


def chalk_board():
    """Стоячая доска на ножках под надпись «Свежее дешевле, чем завтра» (лицо -Y)."""
    b = Builder("chalk_board")
    b.box((0, 0, 1.0), (0.9, 0.06, 1.2), "awning_white")
    b.box((0, -0.035, 1.0), (0.8, 0.02, 1.1), "chalk")
    b.box((0, -0.05, 0.55), (0.5, 0.02, 0.12), "fish")
    for sx in (-1, 1):
        b.box((sx * 0.42, 0.05, 0.6), (0.06, 0.06, 1.2), "plank_dark")
    done(b, "chalk_board")


def ac_unit():
    """Наружный блок кондиционера (лицо -Y): корпус и решётка вентилятора."""
    b = Builder("ac_unit")
    b.box((0, 0, 0.3), (0.85, 0.32, 0.6), "ac")
    b.cyl((0.12, -0.17, 0.3), 0.21, 0.02, "ac_grille", axis="y", segs=14)
    for i in range(4):
        b.box((-0.3, -0.17, 0.12 + i * 0.12), (0.18, 0.02, 0.03), "ac_grille")
    done(b, "ac_unit")


bpy.ops.wm.read_factory_settings(use_empty=True)
parking_booth()
boom_gate()
ufo_kiosk()
brick_arch()
canal_rail()
taxi()
taxi_sign()
market_stall()
chalk_board()
ac_unit()

if RENDER:
    from mathutils import Vector
    os.makedirs(RENDER, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 8
    scene.cycles.use_denoising = False
    world = bpy.data.worlds.new("w")
    world.color = (0.5, 0.5, 0.55)
    scene.world = world
    scene.render.resolution_x, scene.render.resolution_y = 320, 240
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    for name, ob in made.items():
        for o in made.values():
            o.hide_render = o is not ob
        d = max(ob.dimensions) * 1.6 + 0.5
        cam.location = (d * 0.7, -d * 0.9, d * 0.7)
        cam.rotation_euler = Vector((-cam.location[0], -cam.location[1], ob.dimensions.z * 0.4 - cam.location[2])) \
            .to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(RENDER, name + ".png")
        bpy.ops.render.render(write_still=True)
