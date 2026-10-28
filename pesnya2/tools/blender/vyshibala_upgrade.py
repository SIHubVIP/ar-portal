"""Доработка модели Вышибалы: одежда и набор анимаций для игры.

    blender -b --python tools/blender/vyshibala_upgrade.py -- <src.glb> <out.glb> [render_dir] [--female]

Берёт тестовую модель (риг + Idle) и добавляет:
- майку-алкоголичку, треники с лампасами и кеды (вес костей копируется с тела);
- анимации Walk, Run, Attack, Hit, Cast, Dodge, Bow, Flex.
С --female строится героиня: фигура перекраивается по вершинам (грудь, талия, бёдра,
тонкие руки и шея), прическа «рубиновый блонд» с хвостом и свой комплект: топ и легинсы.
Оси костей: у ног и рук отрицательный поворот по локальной X — вперёд,
у позвоночника (локальная X смотрит в -X) отрицательный — наклон вперёд.
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
FEMALE = "--female" in argv
argv = [a for a in argv if a != "--female"]
SRC, OUT = argv[0], argv[1]
RENDER = argv[2] if len(argv) > 2 else None

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
bpy.ops.import_scene.gltf(filepath=SRC)
for o in list(bpy.data.objects):
    if o.name.startswith("Icosphere"):
        bpy.data.objects.remove(o)
rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
body = bpy.data.objects["Body"]
shorts = bpy.data.objects.get("Shorts")


def bump(x, c, w):
    """Плавный горб: 1 в центре c, 0 дальше w."""
    t = abs(x - c) / w
    return (1 - t * t) ** 2 if t < 1 else 0.0


def feminize():
    arm = rig.data.bones
    groups = {g.index: g.name for g in body.vertex_groups}
    segs = {}
    for side in ("Left", "Right"):
        segs[side + "UpperArm"] = (arm[side + "UpperArm"].head_local, arm[side + "LowerArm"].head_local)
        segs[side + "LowerArm"] = (arm[side + "LowerArm"].head_local, arm[side + "Hand"].head_local)
    for v in body.data.vertices:
        co = v.co.copy()
        main = max(v.groups, key=lambda g: g.weight) if len(v.groups) else None
        gname = groups.get(main.group, "") if main else ""
        if gname in segs:                                   # тоньше руки: к оси кости
            a, b = segs[gname]
            ab = b - a
            t = max(0.0, min(1.0, (co - a).dot(ab) / ab.length_squared))
            p = a + ab * t
            co = p + (co - p) * 0.84
        elif abs(co.x) < 0.22 or co.z < 0.98:
            # грудь
            for sx in (-1, 1):
                c = Vector((sx * 0.085, -0.10, 1.275))
                d = Vector((co.x - c.x, 0, co.z - c.z)).length
                if co.y < -0.02 and d < 0.115:
                    k = (1 - (d / 0.115) ** 2) ** 2
                    co.y -= 0.065 * k
                    co.z -= 0.012 * k
            # талия уже, бёдра шире, ягодицы круглее
            w = bump(co.z, 1.06, 0.1)
            co.x *= 1 - 0.13 * w
            co.y = co.y * (1 - 0.1 * w)
            h = bump(co.z, 0.9, 0.12)
            co.x *= 1 + 0.1 * h
            if co.y > 0:
                co.y += 0.025 * bump(co.z, 0.88, 0.1)
            # плечи и шея
            if 1.36 < co.z < 1.56:
                co.x *= 1 - 0.1 * bump(co.z, 1.46, 0.1)
                if abs(co.x) < 0.1:
                    co.y *= 0.88
                    co.x *= 0.88
        v.co = co
    old_hair = bpy.data.objects.get("Hair")
    if old_hair:
        bpy.data.objects.remove(old_hair)
    # причёска: шапка волос, чёлка и высокий хвост с резинкой, всё на кости головы
    me = bpy.data.meshes.new("HairF")
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=14, radius=0.118,
                              matrix=Matrix.Translation((0, 0.012, 1.712)))
    drop = [f for f in bm.faces if (lambda c: c.y < -0.035 and c.z < 1.745)(f.calc_center_median())]
    bmesh.ops.delete(bm, geom=drop, context="FACES")
    roots = len(bm.faces)
    for i, (y, z, r) in enumerate(((0.13, 1.77, 0.045), (0.17, 1.72, 0.05), (0.19, 1.64, 0.046),
                                   (0.19, 1.56, 0.04), (0.18, 1.49, 0.03))):
        bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=8, radius=r,
                                  matrix=Matrix.Translation((0, y, z)) @ Matrix.Scale(1.0, 4))
    bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=0.028,
                              matrix=Matrix.Translation((0, 0.115, 1.775)))
    bm.to_mesh(me)
    bm.free()
    hair = bpy.data.objects.new("HairF", me)
    scene.collection.objects.link(hair)
    hair.data.materials.append(material("HairBlond", (0.95, 0.82, 0.55), 0.6))
    hair.data.materials.append(material("Scrunchie", (1.0, 0.1, 0.45), 0.5))
    for i, p in enumerate(hair.data.polygons):
        p.use_smooth = True
        p.material_index = 1 if p.center.z > 1.75 and p.center.y > 0.09 and p.center.y < 0.14 else 0
    vg = hair.vertex_groups.new(name="Head")
    vg.add(list(range(len(me.vertices))), 1.0, "REPLACE")
    hair.parent = rig
    mod = hair.modifiers.new("Armature", "ARMATURE")
    mod.object = rig


def material(name, color, rough=0.8):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = rough
    return m


def garment(name, keep_face, offset, mats, pick_mat=None):
    """Копия тела: оставляем нужные грани, раздуваем по нормалям. Веса костей сохраняются."""
    ob = body.copy()
    ob.data = body.data.copy()
    ob.name = name
    scene.collection.objects.link(ob)
    ob.data.materials.clear()
    for m in mats:
        ob.data.materials.append(m)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.normal_update()
    drop = [f for f in bm.faces if not keep_face(f.calc_center_median(), f.normal)]
    bmesh.ops.delete(bm, geom=drop, context="FACES")
    for v in bm.verts:
        v.co += v.normal * offset
    for f in bm.faces:
        f.material_index = pick_mat(f.calc_center_median(), f.normal) if pick_mat else 0
    bm.to_mesh(ob.data)
    bm.free()
    for p in ob.data.polygons:
        p.use_smooth = True
    print(name, len(ob.data.polygons), "faces")
    return ob


if FEMALE:
    feminize()
    top = garment("CropTop",
                  lambda c, n: 1.14 < c.z < 1.345 and abs(c.x) < 0.205,
                  0.008, [material("Top", (1.0, 0.18, 0.5), 0.5)])
    legs = garment("Leggings",
                   lambda c, n: 0.14 < c.z < 1.0 and abs(c.x) < 0.27,
                   0.006, [material("Leggings", (0.04, 0.04, 0.05), 0.35), material("LegStripe", (1.0, 0.18, 0.5), 0.5)],
                   lambda c, n: 1 if c.z < 0.95 and abs(c.x) > 0.07 and n.x * math.copysign(1, c.x) > 0.6
                   and abs(n.y) < 0.15 else 0)
    shoes = garment("Sneakers",
                    lambda c, n: c.z < 0.15,
                    0.012, [material("Shoes", (0.95, 0.95, 0.95), 0.5), material("Sole", (1.0, 0.18, 0.5), 0.6)],
                    lambda c, n: 1 if c.z < 0.03 else 0)
else:
    tank = garment("TankTop",
                   lambda c, n: (0.98 < c.z < 1.36 and abs(c.x) < 0.185
                                 and not (c.z > 1.29 and abs(c.x) < 0.065 and n.y < 0))  # вырез спереди
                   or (1.36 <= c.z < 1.47 and 0.06 < abs(c.x) < 0.12),  # лямки
                   0.009, [material("Tank", (0.86, 0.84, 0.74), 0.9)])
    pants = garment("TrackPants",
                    lambda c, n: 0.14 < c.z < 1.02 and abs(c.x) < 0.27,
                    0.013, [material("Pants", (0.05, 0.07, 0.2), 0.7), material("Stripe", (0.92, 0.92, 0.92), 0.6)],
                    lambda c, n: 1 if c.z < 0.97 and abs(c.x) > 0.07 and n.x * math.copysign(1, c.x) > 0.55
                    and abs(n.y) < 0.18 else 0)
    shoes = garment("Sneakers",
                    lambda c, n: c.z < 0.15,
                    0.012, [material("Shoes", (0.08, 0.08, 0.09), 0.5), material("Sole", (0.9, 0.9, 0.88), 0.6)],
                    lambda c, n: 1 if c.z < 0.03 else 0)
if shorts:
    bpy.data.objects.remove(shorts)

# ---------------- анимации ----------------
pb = rig.pose.bones
for b in pb:
    b.rotation_mode = "XYZ"
rig.animation_data_create()
scene.render.fps = 30
D = math.radians


def pose(**rot):
    for b in pb:
        b.rotation_euler = (0, 0, 0)
        b.location = (0, 0, 0)
    for name, v in rot.items():
        if name == "hips_loc":
            pb["Hips"].location = v
            continue
        pb[name].rotation_euler = tuple(D(a) for a in v)


def action(name, keys, loop=True):
    """keys: [(кадр, {кость: (x, y, z)})]"""
    act = bpy.data.actions.new(name)
    rig.animation_data.action = act
    for fr, rot in keys:
        pose(**rot)
        for b in pb:
            b.keyframe_insert("rotation_euler", frame=fr)
        pb["Hips"].keyframe_insert("location", frame=fr)
    act.use_fake_user = True
    rig.animation_data.action = None
    tr = rig.animation_data.nla_tracks.new()
    tr.name = name
    tr.strips.new(name, 1, act)
    tr.mute = True
    return act


def gait(swing, knee, arm, elbow, lean, bob):
    a = {"LeftUpperLeg": (-swing, 0, 0), "RightUpperLeg": (swing, 0, 0),
         "RightLowerLeg": (knee, 0, 0), "LeftLowerLeg": (knee * 0.2, 0, 0),
         "LeftUpperArm": (arm, 0, 0), "RightUpperArm": (-arm, 0, 0),
         "LeftLowerArm": (-elbow, 0, 0), "RightLowerArm": (-elbow, 0, 0),
         "Spine": (-lean, 0, 0), "hips_loc": (0, bob, 0)}
    b = {"LeftUpperLeg": (swing, 0, 0), "RightUpperLeg": (-swing, 0, 0),
         "LeftLowerLeg": (knee, 0, 0), "RightLowerLeg": (knee * 0.2, 0, 0),
         "LeftUpperArm": (-arm, 0, 0), "RightUpperArm": (arm, 0, 0),
         "LeftLowerArm": (-elbow, 0, 0), "RightLowerArm": (-elbow, 0, 0),
         "Spine": (-lean, 0, 0), "hips_loc": (0, bob, 0)}
    mid = {"LeftLowerLeg": (knee * 0.5, 0, 0), "RightLowerLeg": (knee * 0.5, 0, 0),
           "LeftLowerArm": (-elbow, 0, 0), "RightLowerArm": (-elbow, 0, 0), "Spine": (-lean, 0, 0),
           "hips_loc": (0, -bob, 0)}
    return a, mid, b


arms_down = {"LeftUpperArm": (0, 0, 0), "RightUpperArm": (0, 0, 0)}
a, m, b = gait(28, 40, 22, 15, 4, 0.02)
action("Walk", [(1, a), (7, m), (13, b), (19, m), (25, a)])
a, m, b = gait(42, 75, 45, 70, 12, 0.035)
action("Run", [(1, a), (5, m), (9, b), (13, m), (17, a)])
# удар сверху: замах, удар, возврат
action("Attack", [
    (1, {}),
    (6, {"RightUpperArm": (-160, 0, 0), "RightLowerArm": (-40, 0, 0), "Chest": (8, 18, 0), "LeftUpperArm": (-30, 0, 0)}),
    (10, {"RightUpperArm": (-40, 0, 0), "RightLowerArm": (-10, 0, 0), "Chest": (-15, -15, 0), "Spine": (-10, 0, 0),
          "LeftUpperLeg": (-20, 0, 0), "LeftLowerLeg": (20, 0, 0)}),
    (18, {}),
], loop=False)
action("Hit", [(1, {}), (4, {"Chest": (18, 0, 0), "Head": (20, 0, 8), "LeftUpperArm": (0, 0, -25),
                             "RightUpperArm": (0, 0, 25)}), (12, {})], loop=False)
action("Cast", [(1, {}), (7, {"LeftUpperArm": (-95, 0, -20), "RightUpperArm": (-95, 0, 20), "Chest": (10, 0, 0)}),
                (14, {"LeftUpperArm": (-70, 0, 0), "RightUpperArm": (-70, 0, 0), "Chest": (-12, 0, 0)}),
                (22, {})], loop=False)
crouch = {"LeftUpperLeg": (-70, 0, 0), "RightUpperLeg": (-70, 0, 0), "LeftLowerLeg": (110, 0, 0),
          "RightLowerLeg": (110, 0, 0), "Spine": (-35, 0, 0), "Chest": (-20, 0, 0), "hips_loc": (0, -0.35, 0),
          "LeftUpperArm": (-60, 0, 0), "RightUpperArm": (-60, 0, 0)}
action("Dodge", [(1, {}), (4, crouch), (10, crouch), (14, {})], loop=False)
bow = {"Spine": (-30, 0, 0), "Chest": (-25, 0, 0), "Head": (-15, 0, 0), "RightUpperArm": (-20, 0, 30),
       "RightLowerArm": (-80, 0, 0), "LeftUpperArm": (10, 0, 0)}
action("Bow", [(1, {}), (8, bow), (16, bow), (24, {})], loop=False)
flex = {"LeftUpperArm": (0, 0, -75), "RightUpperArm": (0, 0, 75), "LeftLowerArm": (0, 0, -100),
        "RightLowerArm": (0, 0, 100), "Chest": (6, 0, 0), "Head": (8, 0, 0)}
action("Flex", [(1, {}), (8, flex), (30, flex), (38, {})], loop=False)

# Idle из исходника тоже кладём в NLA, чтобы экспортер вывел все действия
for act in bpy.data.actions:
    if act.name.startswith("Idle"):
        act.name = "Idle"
        tr = rig.animation_data.nla_tracks.new()
        tr.name = "Idle"
        tr.strips.new("Idle", int(act.frame_range[0]), act)
        tr.mute = True
pose()

# ---------------- экспорт ----------------
bpy.ops.object.select_all(action="DESELECT")
for o in bpy.data.objects:
    if o.type in ("MESH", "ARMATURE"):
        o.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True,
                          export_animations=True, export_animation_mode="ACTIONS", export_skins=True,
                          export_apply=False)
print("exported", OUT, os.path.getsize(OUT))

# ---------------- проверочные рендеры ----------------
if RENDER:
    os.makedirs(RENDER, exist_ok=True)
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 12
    scene.cycles.device = "CPU"
    scene.cycles.use_denoising = False
    scene.render.resolution_x, scene.render.resolution_y = 360, 480
    world = bpy.data.worlds.new("w")
    world.color = (0.25, 0.25, 0.28)
    scene.world = world
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = 4
    sun.rotation_euler = (D(50), 0, D(30))
    scene.collection.objects.link(sun)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.location = (1.6, -3.4, 1.3)
    cam.rotation_euler = (D(84), 0, D(25))
    for name, frame in (("Idle", 1), ("Walk", 1), ("Run", 1), ("Attack", 6), ("Attack", 10), ("Dodge", 6),
                        ("Bow", 10), ("Flex", 15), ("Cast", 8), ("Hit", 4)):
        rig.animation_data.action = bpy.data.actions[name]
        scene.frame_set(frame)
        scene.render.filepath = os.path.join(RENDER, f"{name}_{frame}.png")
        bpy.ops.render.render(write_still=True)
