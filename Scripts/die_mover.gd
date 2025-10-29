extends Node
class_name DieMover

# Utility that prepares a tween for moving a Die to a global position.
# The caller (a Node) is expected to await get_tree().physics_frame before calling
# this helper if they need that synchronization. This function sets freeze and
# zeroes velocities, then returns the created SceneTreeTween which the caller may await.
static func prepare_tween_for_die(die: Node, target: Vector3, duration: float = 0.12, trans_type: int = Tween.TRANS_QUAD, ease_type: int = Tween.EASE_OUT):
    if die == null:
        push_error("DieMover.prepare_tween_for_die: die is null")
        return null

    # Freeze and clear physics before animation
    die.freeze = true
    die.linear_velocity = Vector3.ZERO
    die.angular_velocity = Vector3.ZERO

    var tw := die.create_tween()
    var step := tw.tween_property(die, "global_position", target, duration)
    step.set_trans(trans_type).set_ease(ease_type)
    return tw
