extends Button

func _ready() -> void:
    pressed.connect(_on_btn_relancer_pressed)

func _on_btn_relancer_pressed() -> void:
    EventBus.throw_dice_request.emit()