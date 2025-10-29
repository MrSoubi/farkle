extends Node3D

@export var speed: float = 200.0

func _process(delta: float) -> void:
    rotate_y(deg_to_rad(speed) * delta)