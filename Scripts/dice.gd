class_name Die
extends RigidBody3D

@export var value_label : Label3D
@export var label_offset := 0.2

var values : Dictionary = {
    Vector3.UP : 1,
    Vector3.FORWARD : 5,
    Vector3.LEFT : 4,
    Vector3.RIGHT : 3,
    Vector3.BACK : 2,
    Vector3.DOWN : 6
}

func _ready() -> void:
    EventBus.throw_dice.connect(_on_throw_dice)
    value_label.visible = false

func _on_throw_dice() -> void:
    apply_impulse(Vector3.UP * 2)
    apply_torque_impulse(Vector3(randf(), randf(), randf()) * 5)

func _on_mouse_entered() -> void:
    value_label.global_position = global_position + Vector3.UP * label_offset
    value_label.text = str(get_top_value())
    value_label.visible = true

func _on_mouse_exited() -> void:
    value_label.visible = false

func get_top_value() -> int:
    var up = Vector3.UP
    var b = global_transform.basis

    # Dot products of local axes with world up
    var x_dot = b.x.dot(up)
    var y_dot = b.y.dot(up)
    var z_dot = b.z.dot(up)

    var abs_x = abs(x_dot)
    var abs_y = abs(y_dot)
    var abs_z = abs(z_dot)

    var max_abs = max(abs_x, abs_y, abs_z)
    var dir = Vector3.ZERO

    if max_abs == abs_x:
        if x_dot > 0:
            dir = Vector3.RIGHT
        else:
            dir = Vector3.LEFT
    elif max_abs == abs_y:
        if y_dot > 0:
            dir = Vector3.UP
        else:
            dir = Vector3.DOWN
    else:
        if z_dot > 0:
            dir = Vector3.BACK
        else:
            dir = Vector3.FORWARD

    if values.has(dir):
        return int(values[dir])

    return 0
