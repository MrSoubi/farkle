class_name Die
extends RigidBody3D

enum State {
    IN_HAND,
    ON_TABLE,
    SELECTED,
    MOVING
}

var state : State

var values : Dictionary = {
    Vector3.UP : 1,
    Vector3.FORWARD : 5,
    Vector3.LEFT : 4,
    Vector3.RIGHT : 3,
    Vector3.BACK : 2,
    Vector3.DOWN : 6
}

var last_position_on_table : Vector3

func _ready() -> void:
    state = State.ON_TABLE
    EventBus.throw_dice.connect(_on_throw_dice)

func _on_throw_dice() -> void:
    if state != State.ON_TABLE:
        return
    
    apply_impulse(Vector3.UP * 2)
    apply_torque_impulse(Vector3(randf(), randf(), randf()) * 5)
    state = State.MOVING

func _physics_process(delta):
    if state == State.MOVING:
        if linear_velocity.length() == 0 and angular_velocity.length() == 0:
            state = State.ON_TABLE

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

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
    if not event.is_action_pressed("click"):
        return

    if state == State.IN_HAND or state == State.MOVING:
        return
    
    if state == State.ON_TABLE:
        state = State.SELECTED
        last_position_on_table = global_position
        EventBus.store_die.emit(self)
    elif state == State.SELECTED:
        state = State.ON_TABLE
        EventBus.unstore_die.emit(self)