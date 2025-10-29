class_name Die
extends RigidBody3D

@export var value_label : Label3D
@export var label_offset := 0.2

func _ready() -> void:
    EventBus.throw_dice.connect(_on_throw_dice)
    value_label.visible = false

func _on_throw_dice() -> void:
    apply_impulse(Vector3.UP * 2)
    apply_torque_impulse(Vector3(randf(), randf(), randf()) * 5)

func _on_mouse_entered() -> void:
    value_label.global_position = global_position + Vector3.UP * label_offset
    value_label.visible = true

func _on_mouse_exited() -> void:
    value_label.visible = false
