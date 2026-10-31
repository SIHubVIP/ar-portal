"""Низкополигональный человечек для NPC, прохожих и мобов-людей (0.9).

blender -b -P tools/blender/build_npc_body.py -- assets/characters/npc/npc_body.glb

Объекты: Body (торс, ноги, обувь, шея), Head (голова с лицом; начало — у шеи), ArmL/ArmR
(начало — в плече, чтобы махать руками), причёски HairShort/HairBun/HairCurlers и Skirt.
Цвета не в материалах, а в вершинах: красный канал = номер зоны / 8 (кожа, верх, низ,
волосы, обувь, белки, зрачки, рот). Godot красит зоны одним шейдером (npc_palette), поэтому
у каждого куска одна поверхность и один вызов отрисовки.
"""
import bpy, bmesh, math, os, sys

ZONES = {"skin": 0, "top": 1, "bottom": 2, "hair": 3, "shoes": 4, "eye": 5, "pupil": 6, "mouth": 7}

out = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "npc_body.glb"
bpy.ops.wm.read_factory_settings(use_empty=True)


def _paint(ob, zone):
    me = ob.data
    if "Col" not in me.color_attributes:
        me.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    attr = me.color_attributes["Col"]
    v = (ZONES[zone] + 0.5) / 8.0
    for d in attr.data:
        d.color = (v, 0.0, 0.0, 1.0)


def _done(ob, zone, smooth=True):
    _paint(ob, zone)
    if smooth:
        for p in ob.data.polygons:
            p.use_smooth = True
    return ob


def sphere(loc, r, zone, scale=(1, 1, 1), segs=14, rings=9):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segs, ring_count=rings, radius=r, location=loc)
    ob = bpy.context.active_object
    ob.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    return _done(ob, zone)


def cyl(loc, r, depth, zone, r2=None, scale=(1, 1, 1), rot=(0, 0, 0), verts=10):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=depth, location=loc, rotation=rot)
    ob = bpy.context.active_object
    ob.scale = scale
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    return _done(ob, zone)


def box(loc, size, zone):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    ob = bpy.context.active_object
    ob.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return _done(ob, zone, smooth=False)


def join(parts, name, origin):
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    ob = bpy.context.active_object
    ob.name = name
    ob.data.name = name
    bpy.context.scene.cursor.location = origin
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    return ob


# лицо смотрит в −Y Blender = +Z Godot
# ---- тело ----
body = [
    cyl((0, 0, 0.97), 0.16, 0.2, "bottom", scale=(1.15, 0.8, 1)),                     # таз
    cyl((0, 0, 1.25), 0.165, 0.42, "top", r2=0.2, scale=(1, 0.72, 1), verts=12),       # торс
    sphere((0, 0, 1.44), 0.2, "top", scale=(1.05, 0.7, 0.45)),                        # плечи
    cyl((0, 0, 1.55), 0.05, 0.12, "skin"),                                            # шея
]
for sx in (-1, 1):
    body.append(cyl((sx * 0.09, 0, 0.5), 0.075, 0.86, "bottom", r2=0.062))             # ноги
    body.append(box((sx * 0.09, -0.04, 0.045), (0.11, 0.24, 0.09), "shoes"))            # ботинки
body_ob = join(body, "Body", (0, 0, 0))

# ---- голова ----
head = [
    sphere((0, 0, 1.73), 0.13, "skin", scale=(0.95, 0.95, 1.12), segs=16, rings=10),
    cyl((0, -0.13, 1.71), 0.022, 0.06, "skin", r2=0.006, rot=(math.radians(90), 0, 0), verts=8),   # нос
    sphere((-0.125, 0, 1.72), 0.03, "skin", scale=(0.5, 1, 1.2), segs=8, rings=5),                 # уши
    sphere((0.125, 0, 1.72), 0.03, "skin", scale=(0.5, 1, 1.2), segs=8, rings=5),
    box((0, -0.122, 1.655), (0.055, 0.012, 0.014), "mouth"),
]
for sx in (-1, 1):
    head.append(sphere((sx * 0.045, -0.108, 1.75), 0.027, "eye", scale=(1, 0.55, 1), segs=10, rings=6))
    head.append(sphere((sx * 0.045, -0.122, 1.75), 0.013, "pupil", scale=(1, 0.5, 1), segs=8, rings=5))
    head.append(box((sx * 0.047, -0.118, 1.79), (0.055, 0.012, 0.012), "hair"))            # брови
head_ob = join(head, "Head", (0, 0, 1.58))

# ---- руки: начало в плече ----
for name, sx in (("ArmL", 1), ("ArmR", -1)):
    arm = [
        sphere((sx * 0.22, 0, 1.45), 0.06, "top", segs=10, rings=6),
        cyl((sx * 0.235, 0, 1.3), 0.055, 0.3, "top", r2=0.047),
        cyl((sx * 0.24, 0, 1.03), 0.045, 0.26, "skin", r2=0.04),
        sphere((sx * 0.24, -0.01, 0.87), 0.048, "skin", scale=(0.8, 0.6, 1.1), segs=8, rings=6),
    ]
    join(arm, name, (sx * 0.22, 0, 1.45))

# ---- причёски (Godot включает одну) и юбка ----
cap = sphere((0, 0.025, 1.8), 0.138, "hair", scale=(1, 1.02, 0.66), segs=16, rings=9)
join([cap], "HairShort", (0, 0, 1.58))
bun = [sphere((0, 0.03, 1.8), 0.138, "hair", scale=(1, 1.02, 0.66), segs=16, rings=9),
       sphere((0, 0.09, 1.86), 0.07, "hair", segs=10, rings=6)]
join(bun, "HairBun", (0, 0, 1.58))
curl = [sphere((0, 0.02, 1.79), 0.135, "hair", scale=(1, 1, 0.6), segs=14, rings=8)]
for i, (x, y) in enumerate([(-0.07, -0.03), (0.0, -0.05), (0.07, -0.03), (-0.05, 0.05), (0.05, 0.05)]):
    curl.append(cyl((x, y, 1.87), 0.028, 0.07, "top", rot=(0, math.radians(90), 0), verts=8))
join(curl, "HairCurlers", (0, 0, 1.58))
skirt = cyl((0, 0, 0.78), 0.27, 0.42, "bottom", r2=0.16, scale=(1, 0.85, 1), verts=14)
join([skirt], "Skirt", (0, 0, 0))

# материал-заглушка: цвет даёт шейдер Godot
mat = bpy.data.materials.new("npc")
for ob in bpy.data.objects:
    ob.data.materials.clear()
    ob.data.materials.append(mat)

os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_yup=True,
                          export_apply=True, export_animations=False, export_colors=True)
print("exported", out, os.path.getsize(out), "bytes")
for o in bpy.data.objects:
    o.data.calc_loop_triangles()
    print(" ", o.name, len(o.data.loop_triangles), "tris")
