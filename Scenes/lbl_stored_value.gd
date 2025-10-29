extends Label

func _ready() -> void:
    GameContext.on_stored_value_changed.connect(update_text)

func update_text(new_value: int) -> void:
    text = str(new_value)
