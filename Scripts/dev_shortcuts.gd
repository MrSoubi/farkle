extends Node

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("dev_space"):
        EventBus.throw_dice.emit()