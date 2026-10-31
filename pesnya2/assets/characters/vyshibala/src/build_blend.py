"""Blender (bpy) pipeline: high mesh -> low poly + bake (albedo/normal) -> rig -> glb + renders."""
import bpy, bmesh, sys, os, math
import numpy as np
from mathutils import Vector, Matrix, Euler

SRC = sys.argv[1]
OUTDIR = sys.argv[2]
QUICK = "--quick" in sys.argv
TEX = 1024 if QUICK else 2048
os.makedirs(OUTDIR, exist_ok=True)
d = np.load(SRC)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def srgb2lin(c):
    c = np.asarray(c, np.float32)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def make_mesh(name, v, f, col=None):
    me = bpy.data.meshes.new(name)
    me.vertices.add(len(v))
    me.vertices.foreach_set("co", v.ravel())
    me.loops.add(f.size)
    me.loops.foreach_set("vertex_index", f.ravel())
    me.polygons.add(len(f))
    me.polygons.foreach_set("loop_start", np.arange(0, f.size, 3))
    me.polygons.foreach_set("loop_total", np.full(len(f), 3))
    me.update(calc_edges=True)
    me.validate()
    if col is not None:
        ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
        rgba = np.c_[srgb2lin(col), np.ones(len(col), np.float32)]
        ca.data.foreach_set("color", rgba.ravel())
    ob = bpy.data.objects.new(name, me)
    scene.collection.objects.link(ob)
    me.shade_smooth()
    return ob


def select_only(*obs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in obs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = obs[-1]


def remesh(ob, voxel, tris=None):
    m = ob.modifiers.new("rem", "REMESH")
    m.mode = "VOXEL"; m.voxel_size = voxel; m.adaptivity = 0.0
    select_only(ob)
    bpy.ops.object.modifier_apply(modifier=m.name)
    ob.data.shade_smooth()
    if tris:
        decimate(ob, tris)
    print(ob.name, "remeshed", len(ob.data.polygons))


def decimate(ob, tris):
    cur = len(ob.data.polygons)
    m = ob.modifiers.new("dec", "DECIMATE")
    m.ratio = min(1.0, tris / cur)
    m.use_symmetry = True
    m.symmetry_axis = "X"
    select_only(ob)
    bpy.ops.object.modifier_apply(modifier=m.name)
    bm = bmesh.new(); bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-5)
    bm.to_mesh(ob.data); bm.free(); ob.data.validate()
    print(ob.name, cur, "->", len(ob.data.polygons))


def principled(name, color=(0.8, 0.8, 0.8), rough=0.5, vcol=False, sss=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*srgb2lin(color), 1)
    bsdf.inputs["Roughness"].default_value = rough
    if vcol:
        a = nt.nodes.new("ShaderNodeVertexColor")
        a.layer_name = "Col"
        nt.links.new(a.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


# ---------------- high-res source ----------------
body_hi = make_mesh("Body_high", d["bv"], d["bf"], d["bc"])
body_hi.data.materials.append(principled("BodyHigh", vcol=True))

# ---------------- low poly ----------------
body = make_mesh("Body", d["bv"], d["bf"])
remesh(body, 0.007, 7000 if QUICK else 16000)
shorts = make_mesh("Shorts", d["sv"], d["sf"])
remesh(shorts, 0.009, 3000)
hair = make_mesh("Hair", d["hv"], d["hf"])
remesh(hair, 0.0045, 3000)

# shorts: waistband as second material
m_sh = principled("Shorts", (0.36, 0.36, 0.37), 0.85)
m_band = principled("Waistband", (0.12, 0.12, 0.13), 0.7)
shorts.data.materials.append(m_sh)
shorts.data.materials.append(m_band)
zc = np.zeros(len(shorts.data.polygons) * 3, np.float32)
shorts.data.polygons.foreach_get("center", zc)
idx = (zc.reshape(-1, 3)[:, 2] > 0.957).astype(np.int32)
shorts.data.polygons.foreach_set("material_index", idx)
hair.data.materials.append(principled("Hair", (0.085, 0.065, 0.05), 0.6))

# eyes
eyes = []
m_scl = principled("EyeWhite", (0.72, 0.68, 0.64), 0.15)
m_iris = principled("EyeIris", (0.30, 0.36, 0.40), 0.1)
m_pup = principled("Pupil", (0.02, 0.02, 0.02), 0.05)
for i, c in enumerate(d["eyes"]):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=12, radius=0.0113)
    me = bpy.data.meshes.new("Eye%d" % i)
    bm.to_mesh(me); bm.free()
    for mt in (m_scl, m_iris, m_pup):
        me.materials.append(mt)
    for p in me.polygons:
        n = p.center.normalized()
        if n.y < -0.93:
            p.material_index = 2
        elif n.y < -0.70:
            p.material_index = 1
    me.shade_smooth()
    ob = bpy.data.objects.new("Eye%d" % i, me)
    ob.location = Vector(c) + Vector((0, 0.003, 0))
    scene.collection.objects.link(ob)
    eyes.append(ob)
select_only(*eyes)
bpy.ops.object.transform_apply(location=True)
bpy.ops.object.join()
eyes = bpy.context.view_layer.objects.active
eyes.name = "Eyes"

# ---------------- UV + bake ----------------
select_only(body)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.004, area_weight=0.0)
bpy.ops.object.mode_set(mode="OBJECT")

scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 1

albedo = bpy.data.images.new("Vyshibala_albedo", TEX, TEX)
normal = bpy.data.images.new("Vyshibala_normal", TEX, TEX)
normal.colorspace_settings.name = "Non-Color"
mat = bpy.data.materials.new("Skin")
mat.use_nodes = True
nt = mat.node_tree
bsdf = nt.nodes["Principled BSDF"]
bsdf.inputs["Roughness"].default_value = 0.55
try:
    bsdf.inputs["Subsurface Weight"].default_value = 0.08
    bsdf.inputs["Subsurface Radius"].default_value = (0.012, 0.005, 0.003)
    bsdf.inputs["Subsurface Scale"].default_value = 1.0
except KeyError:
    pass
tA = nt.nodes.new("ShaderNodeTexImage"); tA.image = albedo
tN = nt.nodes.new("ShaderNodeTexImage"); tN.image = normal
nm = nt.nodes.new("ShaderNodeNormalMap")
body.data.materials.append(mat)

bake = scene.render.bake
bake.use_selected_to_active = True
bake.cage_extrusion = 0.02
bake.max_ray_distance = 0.06
bake.margin = 8
select_only(body_hi, body)

nt.nodes.active = tA
bake.use_pass_direct = False
bake.use_pass_indirect = False
bake.use_pass_color = True
bpy.ops.object.bake(type="DIFFUSE")
nt.nodes.active = tN
bpy.ops.object.bake(type="NORMAL")
for img in (albedo, normal):
    img.filepath_raw = os.path.join(OUTDIR, img.name + ".png")
    img.file_format = "PNG"
    img.save()
    img.pack()
nt.links.new(tA.outputs["Color"], bsdf.inputs["Base Color"])
nt.links.new(tN.outputs["Color"], nm.inputs["Color"])
nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
bpy.data.objects.remove(body_hi)

# ---------------- armature ----------------
S, E, W, H, K, A = [Vector(j) for j in d["joints"]]
arm_d = bpy.data.armatures.new("VyshibalaRig")
rig = bpy.data.objects.new("Vyshibala", arm_d)
scene.collection.objects.link(rig)
select_only(rig)
bpy.ops.object.mode_set(mode="EDIT")
eb = arm_d.edit_bones


def bone(name, head, tail, parent=None, roll=0.0):
    b = eb.new(name)
    b.head = Vector(head); b.tail = Vector(tail); b.roll = roll
    if parent:
        b.parent = eb[parent]
        b.use_connect = (b.parent.tail - b.head).length < 1e-4
    return b

bone("Hips", (0, 0.01, 0.95), (0, 0.01, 1.04))
bone("Spine", (0, 0.01, 1.04), (0, 0.02, 1.14), "Hips")
bone("Chest", (0, 0.02, 1.14), (0, 0.02, 1.26), "Spine")
bone("UpperChest", (0, 0.02, 1.26), (0, 0.01, 1.43), "Chest")
bone("Neck", (0, 0.01, 1.43), (0, -0.0, 1.56), "UpperChest")
bone("Head", (0, -0.0, 1.56), (0, -0.0, 1.78), "Neck")
for side, sx in (("Left", 1), ("Right", -1)):
    m = lambda v: Vector((v[0] * sx, v[1], v[2]))
    W2 = W + (W - E).normalized() * 0.1
    bone(side + "Shoulder", m((0.03, 0.0, 1.42)), m(S), "UpperChest")
    bone(side + "UpperArm", m(S), m(E), side + "Shoulder")
    bone(side + "LowerArm", m(E), m(W), side + "UpperArm")
    bone(side + "Hand", m(W), m(W2), side + "LowerArm")
    bone(side + "Fingers", m(W2), m(W2 + (W - E).normalized() * 0.08), side + "Hand")
    bone(side + "UpperLeg", m(H), m(K), "Hips")
    bone(side + "LowerLeg", m(K), m(A), side + "UpperLeg")
    bone(side + "Foot", m(A), m(A + Vector((0.0, -0.11, -0.065))), side + "LowerLeg")
    bone(side + "Toes", m(A + Vector((0.0, -0.11, -0.065))), m(A + Vector((0.0, -0.17, -0.07))), side + "Foot")
bpy.ops.armature.select_all(action="SELECT")
bpy.ops.armature.calculate_roll(type="GLOBAL_POS_Y")
bpy.ops.object.mode_set(mode="OBJECT")

# skin
select_only(body, rig)
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
ok = sum(1 for g in body.vertex_groups)
print("body vgroups", ok)
# shorts: copy skin weights from the body so cloth follows skin exactly
dt = shorts.modifiers.new("wt", "DATA_TRANSFER")
dt.object = body
dt.use_vert_data = True
dt.data_types_verts = {"VGROUP_WEIGHTS"}
dt.vert_mapping = "POLYINTERP_NEAREST"
dt.layers_vgroup_select_src = "ALL"
dt.layers_vgroup_select_dst = "NAME"
select_only(shorts)
bpy.ops.object.datalayout_transfer(modifier=dt.name)
bpy.ops.object.modifier_apply(modifier=dt.name)
shorts.parent = rig
am = shorts.modifiers.new("Armature", "ARMATURE"); am.object = rig
print("shorts vgroups", len(shorts.vertex_groups))
for ob in (hair, eyes):
    vg = ob.vertex_groups.new(name="Head")
    vg.add(list(range(len(ob.data.vertices))), 1.0, "REPLACE")
    ob.parent = rig
    mod = ob.modifiers.new("Armature", "ARMATURE")
    mod.object = rig

# ---------------- idle animation ----------------
pb = rig.pose.bones
for b in pb:
    b.rotation_mode = "XYZ"
act = bpy.data.actions.new("Idle")
rig.animation_data_create()
rig.animation_data.action = act
scene.render.fps = 30
for fr, k in ((1, 0.0), (31, 1.0), (61, 0.0)):
    pb["Chest"].rotation_euler = (math.radians(-1.5 * k), 0, 0)
    pb["UpperChest"].rotation_euler = (math.radians(-1.0 * k), 0, 0)
    pb["Head"].rotation_euler = (math.radians(1.5 * k), 0, 0)
    for s in ("Left", "Right"):
        pb[s + "UpperArm"].rotation_euler = (0, 0, math.radians(1.5 * k * (1 if s == "Left" else -1)))
    for n in ("Chest", "UpperChest", "Head", "LeftUpperArm", "RightUpperArm"):
        pb[n].keyframe_insert("rotation_euler", frame=fr)
scene.frame_start, scene.frame_end = 1, 60

# reset to rest for export base
scene.frame_set(1)

# ---------------- export ----------------
select_only(rig, body, shorts, hair, eyes)
glb = os.path.join(OUTDIR, "vyshibala.glb")
kw = dict(filepath=glb, export_format="GLB", use_selection=True, export_yup=True,
          export_animations=True, export_skins=True, export_apply=False)
try:
    bpy.ops.export_scene.gltf(**kw, export_vertex_color="NONE")
except TypeError:
    bpy.ops.export_scene.gltf(**kw)
print("exported", glb, os.path.getsize(glb))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTDIR, "vyshibala.blend"))
