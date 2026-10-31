"""Общий набор для моделей из коробок: Builder копит примитивы в один меш с материалами.

Импортируется скриптами tools/blender/*.py (sys.path дополняется папкой скрипта).
Палитра: имя -> ((r, g, b) в sRGB, сила свечения, шероховатость).
"""
import bpy, os, math

PALETTE = {}

class Builder:
    """Копит коробки и цилиндры в один меш с индексами материалов."""

    def __init__(self, name):
        self.name = name
        self.verts, self.faces, self.mats = [], [], []
        self.mat_names = []

    def _m(self, name):
        if name not in self.mat_names:
            self.mat_names.append(name)
        return self.mat_names.index(name)

    def box(self, c, s, mat, rot_z=0.0):
        mi = self._m(mat)
        hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
        cz, sz = math.cos(rot_z), math.sin(rot_z)
        base = len(self.verts)
        for dx, dy, dz in [(-1, -1, -1), (1, -1, -1), (1, 1, -1), (-1, 1, -1),
                           (-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1)]:
            x, y = dx * hx, dy * hy
            self.verts.append((c[0] + x * cz - y * sz, c[1] + x * sz + y * cz, c[2] + dz * hz))
        for f in [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]:
            self.faces.append(tuple(base + i for i in f))
            self.mats.append(mi)

    def cyl(self, c, r, h, mat, axis="z", segs=12, r2=None):
        """Цилиндр (или конус, если задан r2) вдоль оси x/y/z, c — центр."""
        mi = self._m(mat)
        r2 = r if r2 is None else r2
        base = len(self.verts)
        for k, rad in ((-1, r), (1, r2)):
            for i in range(segs):
                a = 2 * math.pi * i / segs
                u, v, w = math.cos(a) * rad, math.sin(a) * rad, k * h / 2
                p = {"z": (u, v, w), "x": (w, u, v), "y": (u, w, v)}[axis]
                self.verts.append((c[0] + p[0], c[1] + p[1], c[2] + p[2]))
        bot = tuple(base + i for i in range(segs))
        top = tuple(base + segs + i for i in range(segs))
        self.faces.append(tuple(reversed(bot)))
        self.mats.append(mi)
        self.faces.append(top)
        self.mats.append(mi)
        for i in range(segs):
            j = (i + 1) % segs
            self.faces.append((base + i, base + j, base + segs + j, base + segs + i))
            self.mats.append(mi)

    def sphere(self, c, r, mat, segs=10, rings=6, scale=(1, 1, 1)):
        """Шар (сплюснутый через scale) — мешки, головы, комки."""
        mi = self._m(mat)
        base = len(self.verts)
        self.verts.append((c[0], c[1], c[2] - r * scale[2]))
        for j in range(1, rings):
            phi = math.pi * j / rings - math.pi / 2
            for i in range(segs):
                th = 2 * math.pi * i / segs
                self.verts.append((c[0] + math.cos(phi) * math.cos(th) * r * scale[0],
                                   c[1] + math.cos(phi) * math.sin(th) * r * scale[1],
                                   c[2] + math.sin(phi) * r * scale[2]))
        self.verts.append((c[0], c[1], c[2] + r * scale[2]))
        top = len(self.verts) - 1
        for i in range(segs):
            j = (i + 1) % segs
            self.faces.append((base, base + 1 + j, base + 1 + i))
            self.mats.append(mi)
        for ring in range(rings - 2):
            r0 = base + 1 + ring * segs
            r1 = r0 + segs
            for i in range(segs):
                j = (i + 1) % segs
                self.faces.append((r0 + i, r0 + j, r1 + j, r1 + i))
                self.mats.append(mi)
        last = base + 1 + (rings - 2) * segs
        for i in range(segs):
            j = (i + 1) % segs
            self.faces.append((last + i, last + j, top))
            self.mats.append(mi)

    def build(self):
        me = bpy.data.meshes.new(self.name)
        me.from_pydata(self.verts, [], self.faces)
        for n in self.mat_names:
            me.materials.append(material(n))
        for p, m in zip(me.polygons, self.mats):
            p.material_index = m
        me.validate()
        me.update()
        ob = bpy.data.objects.new(self.name, me)
        bpy.context.scene.collection.objects.link(ob)
        return ob


_mats = {}


def material(name):
    """Материал из PALETTE (заполняет вызывающий скрипт)."""
    if name in _mats:
        return _mats[name]
    srgb, emit, rough = PALETTE[name]
    # палитра записана в sRGB (как цвета в Godot), Blender и glTF ждут линейные значения
    col = tuple(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb)
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*col, 1)
    b.inputs["Roughness"].default_value = rough
    if "chrome" in name:
        b.inputs["Metallic"].default_value = 1.0
    if emit:
        b.inputs["Emission Color"].default_value = (*col, 1)
        b.inputs["Emission Strength"].default_value = emit
    _mats[name] = m
    return m


def export(ob, name, out):
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    path = os.path.join(out, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=True, export_animations=False)
    print("exported", path, os.path.getsize(path), "bytes,", len(ob.data.polygons), "faces")


