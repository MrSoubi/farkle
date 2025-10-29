extends Node3D
@export var dices : Array[Die] = []
@export var spacing : float = 0.15
@export var line_direction : Vector3 = Vector3(1, 0, 0)
@export var bank_position : Node3D

const PositionCalculator = preload("res://Scripts/position_calculator.gd")
const DieMover = preload("res://Scripts/die_mover.gd")
const StorageModel = preload("res://Scripts/storage_model.gd")

var storing_positions : Array[Vector3] = []
var storage_model : StorageModel = null

func _ready() -> void:
    # Create and attach a storage model to keep lists in one place
    storage_model = StorageModel.new()
    add_child(storage_model)

    _recalculate_storing_positions()
    EventBus.store_die.connect(_on_store_die)
    EventBus.unstore_die.connect(_on_unstore_die)
    EventBus.bank_dice.connect(_on_bank_dice)

func _recalculate_storing_positions() -> void:
    storing_positions = PositionCalculator.calculate_storing_positions(dices.size(), spacing, line_direction, self)

func _on_store_die(die: Die) -> void:
    # Defensive: ignore invalid states
    if die == null:
        return
    if die.state == Die.State.MOVING or die.state == Die.State.BANKED:
        return

    var slot_index := storage_model.add_stored(die)
    _recalculate_storing_positions()
    var pos := Vector3.ZERO
    if slot_index < storing_positions.size():
        pos = storing_positions[slot_index]
    else:
        pos = to_global(Vector3.ZERO)

    GameContext.CurrentScoredValue = ScoreCalculator.calculate_score(storage_model.get_stored_values())

    # perform move during the next physics frame and await completion
    await get_tree().physics_frame
    var tw = DieMover.prepare_tween_for_die(die, pos)
    await tw.finished
    die.freeze = false

func _on_unstore_die(die: Die) -> void:
    if die == null:
        return
    # animate die back to its remembered table position
    var target := die.last_position_on_table
    await get_tree().physics_frame
    var tw = DieMover.prepare_tween_for_die(die, target)
    await tw.finished
    die.freeze = false

    storage_model.remove_stored(die)
    # shift remaining stored dice to fill slots
    _recalculate_storing_positions()
    for i in range(storage_model.stored_dice.size()):
        if i >= storing_positions.size():
            break
        var d: Die = storage_model.stored_dice[i]
        var p := storing_positions[i]
        await get_tree().physics_frame
        var tw2 = DieMover.prepare_tween_for_die(d, p)
        await tw2.finished
        d.freeze = false

    GameContext.CurrentScoredValue = ScoreCalculator.calculate_score(storage_model.get_stored_values())

func _on_bank_dice() -> void:
    # Move stored dice into banked positions and update GameContext
    if bank_position == null:
        push_error("bank_position is not set")
        return

    # accumulate authoritative banked list
    var current_banked := storage_model.collect_current_banked(dices)
    var moved := storage_model.clear_stored_to_banked()
    var total := current_banked.size() + moved.size()
    if total == 0:
        return

    var positions := PositionCalculator.calculate_bank_positions(total, spacing, line_direction, bank_position)

    # reposition already banked
    for i in range(current_banked.size()):
        if i >= positions.size():
            break
        await get_tree().physics_frame
        var tw = DieMover.prepare_tween_for_die(current_banked[i], positions[i])
        await tw.finished
        current_banked[i].freeze = false

    # place newly banked
    var start_idx := current_banked.size()
    for j in range(moved.size()):
        var d: Die = moved[j]
        var pos_idx := start_idx + j
        if pos_idx >= positions.size():
            break
        await get_tree().physics_frame
        var tw2 = DieMover.prepare_tween_for_die(d, positions[pos_idx])
        await tw2.finished
        d.state = Die.State.BANKED
        d.freeze = false

    GameContext.BankedValue += GameContext.CurrentScoredValue
    GameContext.CurrentScoredValue = 0

