extends Label

func _ready() -> void:
    GameContext.on_banked_value_changed.connect(update_text)
    update_text(GameContext.banked_value)

func update_text(new_value: int) -> void:
    text = str(new_value)