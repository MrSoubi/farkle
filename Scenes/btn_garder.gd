extends Button

func _ready() -> void:
    pressed.connect(_on_btn_garder_pressed)

func _on_btn_garder_pressed() -> void:
    EventBus.bank_dice.emit()