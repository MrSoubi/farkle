extends Node3D

@export var mesh_instance: MeshInstance3D
@export var base_material : StandardMaterial3D
@export var face_textures : Array[Texture2D]

func _ready() -> void:
    for i in face_textures.size():
        set_die_face_texture(i, face_textures[i])

func set_die_face_texture(surface_idx: int, tex: Texture2D) -> void:
    var mat = base_material.duplicate()
    mat.albedo_texture = tex
    mesh_instance.set_surface_override_material(surface_idx, mat)
