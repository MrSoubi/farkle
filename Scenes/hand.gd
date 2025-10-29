extends Node3D

@export var dices : Array[Die] = []
@export var spacing : float = 0.15
@export var line_direction : Vector3 = Vector3(1, 0, 0)

var requested_store_dice : bool = false
var storing_positions : Array[Vector3] = []

func _ready() -> void:
    # Calculer les positions locales centrées autour de ce node
    calculate_storing_positions()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("dev_R"):
        store_dice()

func calculate_storing_positions() -> void:
    storing_positions.clear()
    var count := dices.size()
    if count == 0:
        return

    var dir = line_direction
    if dir.length() == 0:
        dir = Vector3(1, 0, 0)
    dir = dir.normalized()

    # offset de départ pour centrer la ligne sur l'origine locale
    var start_offset = -((count - 1) * spacing) / 2.0

    for i in range(count):
        var local_pos = dir * (start_offset + i * spacing)
        var global_pos = to_global(local_pos)
        storing_positions.append(global_pos)

func store_dice() -> void:
    # Recalculer les positions au moment du stockage au cas où la liste a changé
    calculate_storing_positions()
    if storing_positions.size() == 0:
        print("No storing positions available (no dice)")
        return

    print("Storing dice...")
    requested_store_dice = true

func _physics_process(_delta: float) -> void:
    if not requested_store_dice:
        return
    requested_store_dice = false

    var index = 0
    for die in dices:
        if index >= storing_positions.size():
            break
        var store_position = storing_positions[index]
        print("Storing die at position:", store_position)
        # Si l'objet Die a des propriétés spécifiques (freeze), on les conserve
        die.freeze = true
        die.global_position = store_position
        index += 1
        die.freeze = false
