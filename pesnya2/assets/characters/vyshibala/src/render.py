"""Render turnaround previews from vyshibala.blend with Cycles (CPU)."""
import bpy, sys, os, math
from mathutils import Vector

BLEND, OUTDIR = sys.argv[1], sys.argv[2]
SAMPLES = int(sys.argv[3]) if len(sys.argv) > 3 else 48
POSE = "--pose" in sys.argv
bpy.ops.wm.open_mainfile(filepath=BLEND)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = SAMPLES
try:
    scene.cycles.use_denoising = True
except Exception:
    pass
scene.render.resolution_x, scene.render.resolution_y = 640, 1100
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "AgX - Medium High Contrast" if "AgX - Medium High Contrast" in [i.identifier for i in scene.view_settings.bl_rna.properties["look"].enum_items] else "None"

world = bpy.data.worlds.new("W"); scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.02, 0.02, 0.022, 1)

# backdrop
bpy.ops.mesh.primitive_plane_add(size=12, location=(0, 0, 0))
floor = bpy.context.object
fm = bpy.data.materials.new("Floor"); fm.use_nodes = True
fm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.012, 0.012, 0.014, 1)
fm.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.6
floor.data.materials.append(fm)


def area(name, loc, energy, size, color=(1, 1, 1)):
    l = bpy.data.lights.new(name, "AREA"); l.energy = energy; l.size = size; l.color = color
    o = bpy.data.objects.new(name, l); scene.collection.objects.link(o)
    o.location = loc
    d = Vector((0, 0, 1.1)) - Vector(loc)
    o.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    return o

rig_lights = bpy.data.objects.new("LightRig", None); scene.collection.objects.link(rig_lights)
for l in (area("Key", (-1.8, -2.4, 2.6), 260, 1.8, (1, 0.95, 0.9)),
          area("Fill", (2.4, -1.8, 1.4), 70, 2.5, (0.85, 0.9, 1)),
          area("Rim", (1.2, 2.6, 2.4), 260, 1.2, (1, 0.97, 0.95)),
          area("Rim2", (-1.6, 2.2, 1.8), 150, 1.2)):
    l.parent = rig_lights

cam_d = bpy.data.cameras.new("Cam"); cam_d.lens = 85
cam = bpy.data.objects.new("Cam", cam_d); scene.collection.objects.link(cam)
scene.camera = cam

rig = bpy.data.objects["Vyshibala"]
if POSE:
    pb = rig.pose.bones
    for b in pb:
        b.rotation_mode = "XYZ"
    from mathutils import Matrix
    rig.animation_data.action = None
    def rot(name, axis, deg):
        p = pb[name]
        h = p.head.copy()
        R = Matrix.Translation(h) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-h)
        p.matrix = R @ p.matrix
        bpy.context.view_layer.update()
    # fighting stance (world-space rotations, parents first)
    rot("Hips", "Z", 15)
    rot("Spine", "X", 5); rot("Chest", "Z", -8)
    for s, sg in (("Left", 1), ("Right", -1)):
        lead = 1.0 if s == "Left" else 0.75
        rot(s + "UpperArm", "X", -45 * lead)
        rot(s + "UpperArm", "Y", 12 * sg)
        rot(s + "LowerArm", "X", -105)
        rot(s + "LowerArm", "Y", 25 * sg)
    rot("Head", "X", 6)
    rot("LeftUpperLeg", "X", -12); rot("LeftLowerLeg", "X", 14)
    rot("RightUpperLeg", "X", 10); rot("RightLowerLeg", "X", 12)
    rig.animation_data.action = None

views = [("front", 0), ("side", 90), ("back", 180), ("side2", 270), ("q34", -35)] if not POSE else [("pose", -30)]
for name, yaw in views:
    rig.rotation_euler = (0, 0, math.radians(yaw))
    dist = 7.2
    cam.location = (0, -dist, 0.95)
    cam.rotation_euler = (math.radians(90), 0, 0)
    scene.render.filepath = os.path.join(OUTDIR, "r_%s.png" % name)
    bpy.ops.render.render(write_still=True)
    print("rendered", name)

# head close-ups
if not POSE:
    scene.render.resolution_x, scene.render.resolution_y = 600, 700
    cam_d.lens = 85
    for name, yaw in (("head_front", 0), ("head_34", -40), ("head_side", 90), ("head_back", 180)):
        rig.rotation_euler = (0, 0, math.radians(yaw))
        cam.location = (0, -1.75, 1.665)
        cam.rotation_euler = (math.radians(90), 0, 0)
        scene.render.filepath = os.path.join(OUTDIR, "r_%s.png" % name)
        bpy.ops.render.render(write_still=True)
