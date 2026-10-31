"""Иконки предметов для инвентаря: маленькая модель каждого предмета, снятая сверху-сбоку.

    blender -b --python tools/blender/build_item_icons.py -- <out_dir>

Пишет <ITEM_ID>.png 160x160 с прозрачным фоном. Новый предмет — новая функция в ICONS.
"""
import bpy, sys, os, math

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitbash
from kitbash import Builder
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
OUT = argv[0]
os.makedirs(OUT, exist_ok=True)

kitbash.PALETTE.update({
    "steel": ((0.6, 0.62, 0.66), 0, 0.3), "red": ((0.85, 0.12, 0.1), 0, 0.5), "tape": ((0.15, 0.15, 0.15), 0, 0.7),
    "wood": ((0.6, 0.4, 0.2), 0, 0.7), "rubber": ((0.85, 0.5, 0.2), 0, 0.6), "nut": ((0.75, 0.75, 0.7), 0, 0.3),
    "black": ((0.08, 0.08, 0.09), 0, 0.5), "silver": ((0.85, 0.85, 0.9), 0, 0.15), "navy": ((0.06, 0.08, 0.25), 0, 0.7),
    "white": ((0.95, 0.95, 0.95), 0, 0.6), "cap_red": ((0.8, 0.1, 0.12), 0, 0.6), "gold": ((1.0, 0.8, 0.2), 0.3, 0.3),
    "foil": ((0.9, 0.9, 0.95), 0, 0.05), "rust": ((0.5, 0.25, 0.12), 0, 0.8),
    "beer_glass": ((0.45, 0.2, 0.05), 0.2, 0.1), "beer_label": ((0.85, 0.1, 0.15), 0, 0.5),
    "lavash": ((0.95, 0.85, 0.6), 0, 0.8), "meat": ((0.55, 0.25, 0.12), 0, 0.8), "salad": ((0.3, 0.8, 0.3), 0, 0.7),
    "paper": ((0.95, 0.93, 0.85), 0, 0.9), "glass_brown": ((0.4, 0.2, 0.08), 0.1, 0.2), "screen": ((0.1, 0.12, 0.18), 0, 0.2),
    "screen_red": ((1.0, 0.2, 0.2), 1.5, 0.3), "green_glow": ((0.3, 1.0, 0.7), 2.5, 0.3), "blue_card": ((0.15, 0.4, 0.95), 0, 0.4),
    "pcb": ((0.1, 0.55, 0.25), 0, 0.5), "chip_glow": ((0.4, 1.0, 0.6), 2.0, 0.3), "shoe": ((0.2, 0.15, 0.12), 0, 0.6),
    "stamp": ((0.85, 0.1, 0.1), 0, 0.7), "cat": ((0.9, 0.6, 0.2), 0, 0.7),
})


def crowbar(b):
    b.box((0, 0, 0), (0.08, 1.4, 0.08), "red")
    b.box((0, 0.74, 0.12), (0.08, 0.1, 0.3), "red")
    b.box((0, -0.74, -0.05), (0.08, 0.2, 0.06), "red")
    b.box((0, -0.3, 0), (0.1, 0.4, 0.1), "tape")


def slingshot(b):
    b.box((0, 0, -0.35), (0.1, 0.1, 0.6), "wood")
    for s in (-1, 1):
        b.box((s * 0.18, 0, 0.12), (0.08, 0.08, 0.45), "wood", )
        b.box((s * 0.09, 0, -0.06), (0.22, 0.08, 0.08), "wood")
    b.box((0, -0.05, 0.3), (0.38, 0.03, 0.03), "rubber")
    b.cyl((0, -0.1, 0.3), 0.07, 0.05, "nut", axis="y", segs=6)


def antenna(b):
    b.box((0, 0, -0.3), (0.5, 0.25, 0.12), "black")
    for s in (-1, 1):
        b.cyl((s * 0.25, 0, 0.2), 0.02, 1.0, "silver", segs=6)
    b.box((0, -0.14, -0.3), (0.3, 0.02, 0.06), "gold")


def tracksuit(b):
    for s in (-1, 1):
        b.box((s * 0.18, 0, -0.15), (0.28, 0.2, 1.0), "navy")
        b.box((s * 0.33, -0.02, -0.15), (0.03, 0.2, 1.0), "white")
    b.box((0, 0, 0.4), (0.68, 0.22, 0.14), "navy")
    b.box((0, -0.12, 0.42), (0.6, 0.02, 0.04), "white")


def cap(b):
    b.sphere((0, 0, 0), 0.4, "cap_red", segs=14, rings=8, scale=(1, 1, 0.6))
    b.box((0, -0.45, -0.05), (0.6, 0.4, 0.04), "cap_red")
    b.box((0, -0.35, 0.12), (0.3, 0.02, 0.12), "white")


def foil_hat(b):
    b.cyl((0, 0, 0.1), 0.42, 0.7, "foil", segs=10, r2=0.02)
    b.cyl((0, 0, -0.27), 0.5, 0.04, "foil", segs=10)


def pipe(b):
    b.cyl((0, 0, 0), 0.09, 1.3, "rust", axis="y", segs=10)
    b.cyl((0, 0.62, 0.15), 0.09, 0.3, "rust", segs=10)
    b.cyl((0, -0.62, 0), 0.12, 0.08, "steel", axis="y", segs=10)


def beer(b):
    b.cyl((0, 0, -0.1), 0.18, 0.7, "beer_glass", segs=12)
    b.cyl((0, 0, 0.36), 0.12, 0.22, "beer_glass", segs=12, r2=0.06)
    b.cyl((0, 0, 0.5), 0.065, 0.06, "gold", segs=10)
    b.cyl((0, 0, -0.1), 0.185, 0.3, "beer_label", segs=12)


def shawarma(b):
    b.cyl((0, 0, 0), 0.24, 0.9, "lavash", axis="y", segs=12)
    b.cyl((0, -0.5, 0.0), 0.2, 0.15, "meat", axis="y", segs=10)
    b.cyl((0, -0.52, 0.08), 0.12, 0.1, "salad", axis="y", segs=8)
    b.box((0, 0.25, 0), (0.5, 0.4, 0.5), "paper")


def valerian(b):
    b.cyl((0, 0, -0.05), 0.2, 0.6, "glass_brown", segs=12)
    b.cyl((0, 0, 0.32), 0.12, 0.15, "white", segs=10)
    b.box((0, -0.19, -0.05), (0.25, 0.02, 0.25), "paper")
    b.sphere((0, -0.21, -0.03), 0.07, "cat", segs=8, rings=5)


def phone(b):
    b.box((0, 0, 0), (0.5, 0.9, 0.06), "black")
    b.box((0, 0, 0.035), (0.44, 0.78, 0.01), "screen")
    b.box((0, 0, 0.042), (0.2, 0.08, 0.01), "screen_red")


def shoe(b):
    b.box((0, 0, -0.1), (0.4, 0.95, 0.08), "white")
    b.box((0, 0.1, 0.05), (0.38, 0.8, 0.25), "shoe")
    b.box((0, 0.25, 0.25), (0.34, 0.4, 0.25), "shoe")
    b.box((0, -0.2, 0.18), (0.25, 0.3, 0.02), "white")


def notice(b):
    b.box((0, 0, 0), (0.75, 1.0, 0.02), "paper")
    for i in range(6):
        b.box((-0.05, 0.3 - i * 0.12, 0.015), (0.5 - (i % 2) * 0.15, 0.03, 0.01), "black")
    b.cyl((0.18, -0.32, 0.02), 0.14, 0.01, "stamp", segs=14)


def battery(b):
    b.cyl((0, 0, 0), 0.25, 0.8, "green_glow", segs=12)
    for z in (-0.4, 0.4):
        b.cyl((0, 0, z), 0.28, 0.08, "steel", segs=12)
    b.cyl((0, 0, 0.5), 0.08, 0.12, "steel", segs=8)


def discount(b):
    b.box((0, 0, 0), (0.9, 0.56, 0.03), "blue_card")
    b.box((-0.15, 0.1, 0.02), (0.45, 0.08, 0.01), "white")
    b.box((0.25, -0.12, 0.02), (0.2, 0.15, 0.01), "gold")


def scrap(b):
    b.box((0, 0, 0), (0.6, 0.4, 0.06), "steel", rot_z=0.3)
    b.box((0.15, 0.1, 0.12), (0.4, 0.1, 0.2), "steel", rot_z=-0.5)
    b.cyl((-0.2, -0.1, 0.1), 0.1, 0.1, "screen_red", segs=8)


def chip(b):
    b.box((0, 0, 0), (0.7, 0.7, 0.06), "pcb")
    b.box((0, 0, 0.05), (0.3, 0.3, 0.05), "black")
    b.box((0, 0, 0.08), (0.12, 0.12, 0.02), "chip_glow")
    for i in range(5):
        for s in (-1, 1):
            b.box((-0.24 + i * 0.12, s * 0.33, 0.035), (0.04, 0.08, 0.02), "gold")


ICONS = {
    "ITEM_P2_CROWBAR": crowbar, "ITEM_P2_SLINGSHOT": slingshot, "ITEM_P2_ANTENNA": antenna,
    "ITEM_P2_TRACKSUIT": tracksuit, "ITEM_P2_CAP": cap, "ITEM_P2_FOIL_HAT": foil_hat, "ITEM_P2_PIPE": pipe,
    "ITEM_P2_BEER": beer, "ITEM_P2_SHAWARMA": shawarma, "ITEM_P2_VALERIAN": valerian,
    "ITEM_P1_PHONE": phone, "ITEM_P1_SHOE": shoe, "ITEM_P1_DEBT_NOTICE": notice,
    "ITEM_P1_ALIEN_BATTERY": battery, "ITEM_P1_KIOSK_DISCOUNT": discount, "ITEM_P1_SCRAP": scrap,
    "ITEM_P1_GRATITUDE_CHIP": chip,
}

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 24
scene.cycles.use_denoising = False
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 160
world = bpy.data.worlds.new("w")
world.color = (0.6, 0.6, 0.65)
scene.world = world
for rot, energy in (((50, 0, 30), 3.5), ((60, 0, 200), 1.2)):
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = energy
    sun.rotation_euler = tuple(math.radians(a) for a in rot)
    scene.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
scene.collection.objects.link(cam)
scene.camera = cam
prev = None
for item_id, fn in ICONS.items():
    if prev:
        bpy.data.objects.remove(prev)
    b = Builder(item_id)
    fn(b)
    ob = b.build()
    ob.rotation_euler = (math.radians(-10), math.radians(20), math.radians(35))
    bpy.context.view_layer.update()
    pts = [ob.matrix_world @ Vector(c) for c in ob.bound_box]
    center = sum(pts, Vector()) / 8
    size = max((max(p[i] for p in pts) - min(p[i] for p in pts)) for i in range(3))
    cam.data.ortho_scale = size * 1.25
    d = Vector((0.0, -1.0, 0.75)).normalized()
    cam.location = center + d * 6
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(OUT, item_id + ".png")
    bpy.ops.render.render(write_still=True)
    prev = ob
print("icons:", len(ICONS))
