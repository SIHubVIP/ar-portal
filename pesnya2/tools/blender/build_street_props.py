"""Уличный мусор и следы вторжения для Погуляя.

    blender -b --python tools/blender/build_street_props.py -- <out_dir> [render_dir]

Мешки, коробки, ящик пива, бутылки, сгоревшая машина, сбитый дрон, бетонный забор,
полицейский барьер, покрышки, люк, лифчик для антенны. Начало координат — центр основания.
"""
import bpy, sys, os, math, random

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitbash
from kitbash import Builder

argv = sys.argv[sys.argv.index("--") + 1:]
OUT = argv[0]
RENDER = argv[1] if len(argv) > 1 else None
os.makedirs(OUT, exist_ok=True)

kitbash.PALETTE.update({
    "bag": ((0.08, 0.08, 0.09), 0, 0.35), "bag_tie": ((0.9, 0.85, 0.2), 0, 0.6),
    "cardboard": ((0.62, 0.45, 0.28), 0, 0.9), "tape": ((0.75, 0.6, 0.35), 0, 0.5),
    "crate_red": ((0.75, 0.12, 0.1), 0, 0.6), "bottle_green": ((0.15, 0.5, 0.2), 0.2, 0.1),
    "bottle_brown": ((0.45, 0.22, 0.08), 0.2, 0.1), "label": ((0.95, 0.85, 0.3), 0, 0.6),
    "burnt": ((0.1, 0.08, 0.07), 0, 0.95), "rust": ((0.45, 0.22, 0.1), 0, 0.9),
    "ember": ((1.0, 0.35, 0.05), 3.0, 0.5), "glass_broken": ((0.4, 0.55, 0.6), 0, 0.1),
    "drone": ((0.72, 0.75, 0.8), 0, 0.3), "drone_dark": ((0.25, 0.25, 0.3), 0, 0.5),
    "drone_eye": ((1.0, 0.1, 0.3), 2.0, 0.3), "drone_screen": ((0.1, 0.9, 0.5), 1.5, 0.3),
    "spark": ((0.4, 1.0, 0.9), 4.0, 0.2), "asphalt_chunk": ((0.2, 0.2, 0.22), 0, 0.95),
    "concrete": ((0.55, 0.54, 0.5), 0, 0.95), "concrete_dark": ((0.4, 0.4, 0.38), 0, 0.95),
    "graffiti_pink": ((1.0, 0.25, 0.6), 0.6, 0.6), "graffiti_cyan": ((0.2, 0.9, 1.0), 0.6, 0.6),
    "graffiti_yellow": ((1.0, 0.85, 0.1), 0.5, 0.6),
    "stripe_red": ((0.85, 0.1, 0.1), 0, 0.5), "stripe_white": ((0.95, 0.95, 0.95), 0, 0.5),
    "tire": ((0.05, 0.05, 0.05), 0, 0.9), "iron": ((0.22, 0.22, 0.24), 0, 0.5),
    "bra": ((1.0, 0.15, 0.5), 0.3, 0.4), "lace": ((0.1, 0.05, 0.08), 0, 0.6),
})

rnd = random.Random(7)
made = {}


def done(b, name, tilt=None):
    ob = b.build()
    if tilt:
        ob.rotation_euler = tilt
        bpy.context.view_layer.objects.active = ob
        ob.select_set(True)
        bpy.ops.object.transform_apply(rotation=True)
        ob.select_set(False)
    kitbash.export(ob, name, OUT)
    made[name] = ob


def trash_bags():
    b = Builder("trash_bags")
    for x, y, r in ((0, 0, 0.42), (0.55, 0.2, 0.36), (0.2, -0.45, 0.33), (-0.45, 0.3, 0.3), (0.3, 0.25, 0.28)):
        z = r * 0.75 + (0.35 if (x, y) == (0.3, 0.25) else 0)
        b.sphere((x, y, z), r, "bag", segs=9, rings=6, scale=(1, 0.9, 0.8))
        b.cyl((x, y, z + r * 0.8), 0.06, 0.12, "bag_tie", segs=6)
    b.box((0.7, -0.35, 0.05), (0.25, 0.08, 0.1), "bottle_green", rot_z=0.6)
    done(b, "trash_bags")


def boxes():
    b = Builder("boxes")
    for (x, y, z, s, rz) in ((0, 0, 0.3, 0.6, 0.1), (0.7, 0.1, 0.25, 0.5, -0.3), (0.3, 0.05, 0.85, 0.5, 0.5)):
        b.box((x, y, z), (s, s * 0.8, s), "cardboard", rot_z=rz)
        b.box((x, y, z + s / 2 + 0.005), (s * 0.15, s * 0.82, 0.01), "tape", rot_z=rz)
    b.box((0.05, -0.3, 0.62), (0.55, 0.02, 0.3), "cardboard", rot_z=0.4)   # отогнутая крышка
    done(b, "boxes")


def beer_crate():
    b = Builder("beer_crate")
    b.box((0, 0, 0.17), (0.6, 0.4, 0.06), "crate_red")
    for sx in (-1, 1):
        b.box((sx * 0.29, 0, 0.2), (0.03, 0.4, 0.34), "crate_red")
        b.box((0, sx * 0.19, 0.2), (0.6, 0.03, 0.34), "crate_red")
    for i in range(4):
        for j in range(3):
            if rnd.random() < 0.75:
                c = (-0.21 + i * 0.14, -0.12 + j * 0.12, 0.35)
                m = rnd.choice(["bottle_green", "bottle_brown"])
                b.cyl(c, 0.045, 0.3, m, segs=8)
                b.cyl((c[0], c[1], 0.55), 0.016, 0.1, m, segs=6)
    for i in range(5):                                                        # пустые рядом
        a = rnd.uniform(0, 6.28)
        x, y = 0.6 + math.cos(a) * 0.3, math.sin(a) * 0.4
        b.cyl((x, y, 0.045), 0.045, 0.28, rnd.choice(["bottle_green", "bottle_brown"]), axis="x", segs=8)
    b.box((0, 0, 0.0), (0.6, 0.4, 0.0001), "crate_red")
    done(b, "beer_crate")


def car_wreck():
    b = Builder("car_wreck")
    b.box((0, 0, 0.55), (1.9, 4.2, 0.6), "burnt")
    b.box((0, 0.3, 1.1), (1.7, 2.0, 0.55), "burnt")
    b.box((0, -0.75, 1.05), (1.6, 0.06, 0.45), "glass_broken", rot_z=0.05)
    for sx in (-1, 1):
        b.box((sx * 0.96, 0.3, 1.1), (0.04, 1.6, 0.4), "rust")
        for y in (-1.35, 1.35):
            if not (sx == 1 and y == 1.35):
                b.cyl((sx * 0.85, y, 0.3), 0.3, 0.25, "rust", axis="x", segs=10)
    b.box((0, -1.6, 0.9), (1.8, 1.0, 0.1), "burnt", rot_z=0.2)               # вздёрнутый капот
    for i in range(6):
        b.box((rnd.uniform(-0.6, 0.6), rnd.uniform(-1.8, 1.8), 0.88), (0.12, 0.12, 0.05), "ember")
    b.box((0, 2.15, 0.6), (1.2, 0.05, 0.25), "stripe_white")                  # номер
    done(b, "car_wreck", tilt=(0, math.radians(6), 0))


def drone_wreck():
    b = Builder("drone_wreck")
    b.sphere((0, 0, 0.35), 0.55, "drone", segs=12, rings=8, scale=(1, 1, 0.9))
    b.cyl((0.2, 0.1, 0.45), 0.9, 0.07, "drone_dark", segs=14)                 # погнутое кольцо
    b.box((0.35, -0.45, 0.55), (0.3, 0.05, 0.12), "drone_screen", rot_z=0.4)
    b.sphere((0.05, -0.5, 0.45), 0.14, "drone_eye", segs=8, rings=5)
    for i in range(7):                                                        # обломки асфальта
        a = i * 0.9
        b.box((math.cos(a) * 1.0, math.sin(a) * 1.0, 0.08), (0.35, 0.25, 0.16), "asphalt_chunk", rot_z=a)
    for i in range(4):
        b.box((rnd.uniform(-0.4, 0.4), rnd.uniform(-0.4, 0.4), 0.9 + i * 0.05), (0.04, 0.04, 0.04), "spark")
    done(b, "drone_wreck", tilt=(math.radians(18), 0, 0))


def fence():
    """Бетонный забор ПО-2: 2.5 м секция с ромбами, на ней граффити."""
    b = Builder("fence")
    b.box((0, 0, 1.0), (2.5, 0.15, 2.0), "concrete")
    for i in range(4):
        for j in range(3):
            b.box((-0.94 + i * 0.62, -0.08, 0.4 + j * 0.6), (0.3, 0.03, 0.3), "concrete_dark", rot_z=0.0)
    b.box((0, 0, 2.03), (2.5, 0.18, 0.06), "concrete_dark")
    b.box((-1.3, 0, 1.0), (0.12, 0.25, 2.1), "concrete_dark")
    done(b, "fence")


def barrier():
    b = Builder("barrier")
    for x in (-0.9, 0.9):
        b.box((x, 0, 0.45), (0.08, 0.08, 0.9), "iron")
        b.box((x, 0, 0.03), (0.08, 0.5, 0.06), "iron")
    for i in range(6):
        b.box((-0.75 + i * 0.3, 0, 0.75), (0.3, 0.05, 0.2), "stripe_red" if i % 2 == 0 else "stripe_white")
    done(b, "barrier")


def tires():
    b = Builder("tires")
    for i, (x, y, z) in enumerate(((0, 0, 0.13), (0, 0, 0.39), (0.05, 0.02, 0.65), (0.75, 0.1, 0.13))):
        b.cyl((x, y, z), 0.34, 0.24, "tire", segs=14)
        b.cyl((x, y, z), 0.17, 0.26, "iron", segs=10)
    done(b, "tires")


def bra():
    """Лифчик для антенны тёти Зины. Две чашки и бретели."""
    b = Builder("bra")
    for sx in (-1, 1):
        b.sphere((sx * 0.11, 0, 0), 0.1, "bra", segs=10, rings=5, scale=(1, 0.6, 1))
        b.box((sx * 0.11, -0.04, 0.0), (0.16, 0.02, 0.03), "lace")
    b.box((0, 0.02, 0.0), (0.5, 0.015, 0.02), "bra")
    b.box((-0.17, 0.02, 0.15), (0.015, 0.015, 0.3), "bra")
    done(b, "bra")


bpy.ops.wm.read_factory_settings(use_empty=True)
trash_bags()
boxes()
beer_crate()
car_wreck()
drone_wreck()
fence()
barrier()
tires()
bra()

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
