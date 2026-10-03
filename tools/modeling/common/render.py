"""Cycles CPU preview / turntable rendering helpers (headless)."""
import math
import bpy
from mathutils import Vector


def setup_cycles(res=(768, 1024), samples=32, transparent=True):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = False
    sc.cycles.max_bounces = 4
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = transparent
    sc.view_settings.view_transform = "Standard"
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    if sc.world is None:
        sc.world = bpy.data.worlds.new("World")
    sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes.get("Background")
    bg.inputs[0].default_value = (0.55, 0.52, 0.5, 1)
    bg.inputs[1].default_value = 0.6
    return sc


def add_lights(key_dir=(-0.6, -1.0, 1.2), key=3.0, rim=2.0):
    def sun(name, d, e, col=(1, 1, 1)):
        l = bpy.data.lights.new(name, "SUN")
        l.energy = e
        l.color = col
        l.angle = math.radians(8)
        o = bpy.data.objects.new(name, l)
        bpy.context.scene.collection.objects.link(o)
        o.rotation_euler = Vector(d).normalized().to_track_quat("Z", "Y").to_euler()
        return o
    k = sun("Key", key_dir, key, (1.0, 0.95, 0.88))
    r = sun("Rim", (0.7, 1.0, 0.6), rim, (0.85, 0.9, 1.0))
    return k, r


def camera(name="Cam", ortho_scale=2.7, target=(0, 0, 1.2), yaw_deg=0.0, pitch_deg=0.0, dist=8.0, ortho=True, lens=50):
    cam = bpy.data.cameras.new(name)
    cam.type = "ORTHO" if ortho else "PERSP"
    cam.ortho_scale = ortho_scale
    cam.lens = lens
    cam.clip_end = 100
    o = bpy.data.objects.new(name, cam)
    bpy.context.scene.collection.objects.link(o)
    place_camera(o, target, yaw_deg, pitch_deg, dist)
    bpy.context.scene.camera = o
    return o


def place_camera(o, target, yaw_deg, pitch_deg, dist):
    """yaw 0 = camera in front of the character (character faces -Y, camera at -Y)."""
    t = Vector(target)
    y, p = math.radians(yaw_deg), math.radians(pitch_deg)
    d = Vector((math.sin(y) * math.cos(p), -math.cos(y) * math.cos(p), math.sin(p)))
    o.location = t + d * dist
    o.rotation_euler = (t - o.location).to_track_quat("-Z", "Y").to_euler()


def render(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
