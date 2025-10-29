extends Node3D

@export var dices : Array[Die] = []
@export var spacing : float = 0.15
@export var line_direction : Vector3 = Vector3(1, 0, 0)

var requested_store_dice : bool = false
var storing_positions : Array[Vector3] = []
var next_store_index : int = 0
var stored_dice : Array[Die] = []

func _ready() -> void:
    calculate_storing_positions()
    EventBus.store_die.connect(store_die)
    EventBus.unstore_die.connect(unstore_die)

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

func store_die(die: Die) -> void:
    var slot_index := stored_dice.size()

    # Placer le dé dans la première case libre (fin de stored_dice)
    var pos := storing_positions[slot_index]
    print("Storing single die at position (index", slot_index, "):", pos)
    die.freeze = true
    die.global_position = pos
    die.freeze = false

    # Marquer comme stocké et mettre à jour l'index
    stored_dice.append(die)
    next_store_index = stored_dice.size()

    GameContext.CurrentScoredValue = get_total_stored_value()


func unstore_die(die: Die) -> void:
    # Move the die back to the table
    var target := die.last_position_on_table
    print("Unstoring die to position:", target)
    die.freeze = true
    die.global_position = target
    die.freeze = false

    # Remove die from stored list and shift remaining stored dice to fill gaps
    var idx := stored_dice.find(die)
    stored_dice.remove_at(idx)

    for i in range(stored_dice.size()):
        if i >= storing_positions.size():
            break
        var d := stored_dice[i]
        var p := storing_positions[i]
        d.freeze = true
        d.global_position = p
        d.freeze = false

    # Update next_store_index to the current count of stored dice
    next_store_index = stored_dice.size()

    GameContext.CurrentScoredValue = get_total_stored_value()


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

func get_total_stored_value() -> int:
    var total := 0
    for die in stored_dice:
        total += die.get_top_value()
    return total
