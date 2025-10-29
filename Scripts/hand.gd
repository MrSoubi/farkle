extends Node3D

@export var dices : Array[Die] = []
@export var spacing : float = 0.15
@export var line_direction : Vector3 = Vector3(1, 0, 0)

var requested_store_dice : bool = false
var storing_positions : Array[Vector3] = []
var next_store_index : int = 0
var stored_dice : Array[Die] = []

func _ready() -> void:
    # Calculer les positions locales centrées autour de ce node
    calculate_storing_positions()
    EventBus.store_die.connect(store_die)
    EventBus.unstore_die.connect(unstore_die)

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
    # Clamp next_store_index pour rester dans les bornes [0, storing_positions.size()]
    if next_store_index < 0:
        next_store_index = 0
    if next_store_index > storing_positions.size():
        next_store_index = storing_positions.size()

func store_dice() -> void:
    # Recalculer les positions au moment du stockage au cas où la liste a changé
    calculate_storing_positions()
    if storing_positions.size() == 0:
        print("No storing positions available (no dice)")
        return

    # Lors d'un stockage massif, on repart de l'index 0
    next_store_index = 0
    print("Storing dice...")
    requested_store_dice = true


func store_die(die: Die) -> void:
    # Stocke un seul dé en utilisant un index séquentiel (next_store_index).
    if die == null:
        push_warning("store_die called with null die")
        return

    # Recalculer les positions au cas où la liste a changé
    calculate_storing_positions()

    if storing_positions.size() == 0:
        print("No storing positions available (no dice)")
        return

    # Eviter de stocker deux fois le même dé
    if stored_dice.find(die) != -1:
        print("Die is already stored")
        return

    # Vérifier qu'il reste un emplacement
    var slot_index := stored_dice.size()
    if slot_index >= storing_positions.size():
        print("No storing position available for die; slot_index >= storing_positions.size()", slot_index)
        return

    # Placer le dé dans la première case libre (fin de stored_dice)
    var pos := storing_positions[slot_index]
    print("Storing single die at position (index", slot_index, "):", pos)
    die.freeze = true
    die.global_position = pos
    die.freeze = false

    # Marquer comme stocké et mettre à jour l'index
    stored_dice.append(die)
    next_store_index = stored_dice.size()


func unstore_die(die: Die) -> void:
    # Replace a die back to its last known position on the table and compact stored slots.
    if die == null:
        push_warning("unstore_die called with null die")
        return

    # If the die is not currently stored, just move it back and exit
    var idx := stored_dice.find(die)
    if idx == -1:
        var target_simple := die.last_position_on_table
        print("Unstoring die (was not tracked as stored) to position:", target_simple)
        die.freeze = true
        die.global_position = target_simple
        die.freeze = false
        return

    # Move the die back to the table
    var target := die.last_position_on_table
    print("Unstoring die to position:", target)
    die.freeze = true
    die.global_position = target
    die.freeze = false

    # Remove die from stored list and shift remaining stored dice to fill gaps
    stored_dice.remove_at(idx)

    # Recompute positions and move remaining stored dice to the first slots
    calculate_storing_positions()
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


func _physics_process(_delta: float) -> void:
    if not requested_store_dice:
        return
    requested_store_dice = false

    # Recalculate positions in case the list changed since request
    calculate_storing_positions()

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

    # Après un stockage massif, considérer tous les dés comme stockés (en ordre)
    stored_dice = dices.duplicate()
    next_store_index = stored_dice.size()
