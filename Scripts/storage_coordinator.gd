extends Node3D
class_name StorageCoordinator
@export var dice : Array[Die] = []
@export var spacing : float = 0.15
@export var line_direction : Vector3 = Vector3(1, 0, 0)
@export var bank_position : Node3D

# PositionCalculator, DieMover and StorageModel are available by their class_name
# PositionCalculator: pure functions for computing positions (no instance needed)
# DieMover: autoloaded helper (provides prepare_tween_for_die)
# StorageModel: a Node we instantiate locally

var storing_positions : Array[Vector3] = []
# StorageModel is provided as an autoload singleton. Use it directly.
var storage_model = null
var event_queue: Array = []
var processing_queue: bool = false

func _ready() -> void:
    # StorageModel is an autoload (singleton). Use the global directly.
    storage_model = StorageModel if typeof(StorageModel) != TYPE_NIL else null

    if storage_model == null:
        push_error("StorageCoordinator: StorageModel autoload not found. Please add res://Scripts/storage_model.gd as an autoload named StorageModel.")

    _recalculate_storing_positions()
    EventBus.store_die.connect(_on_store_die)
    EventBus.unstore_die.connect(_on_unstore_die)
    EventBus.bank_dice.connect(_on_bank_dice)
    # Coordinate throw requests so we only emit the actual throw when all dice are idle
    EventBus.throw_dice_request.connect(_on_throw_request)

func _recalculate_storing_positions() -> void:
    storing_positions = PositionCalculator.calculate_storing_positions(dice.size(), spacing, line_direction, self)

func _on_store_die(die: Die) -> void:
    # enqueue store requests to avoid overlapping animations
    if die == null:
        return
    event_queue.append({"type": "store", "die": die})
    if not processing_queue:
        _process_queue()

func _handle_store_die(die: Die) -> void:
    # Defensive: ignore invalid states
    if die == null:
        return
    if die.state == Die.State.MOVING or die.state == Die.State.BANKED:
        return

    var slot_index: int = storage_model.add_stored(die)
    _recalculate_storing_positions()
    var pos: Vector3 = Vector3.ZERO
    if slot_index < storing_positions.size():
        pos = storing_positions[slot_index]
    else:
        pos = to_global(Vector3.ZERO)

    GameContext.current_scored_value = ScoreCalculator.calculate_score(storage_model.get_stored_values())

    # perform move during the next physics frame and await completion
    die.begin_animation() # sets MOVING, locked, freeze and clears velocities
    await get_tree().physics_frame
    var tw = DieMover.prepare_tween_for_die(die, pos)
    await tw.finished
    die.end_animation(Die.State.IN_HAND)

func _on_unstore_die(die: Die) -> void:
    # enqueue unstore requests
    if die == null:
        return
    event_queue.append({"type": "unstore", "die": die})
    if not processing_queue:
        _process_queue()

func _handle_unstore_die(die: Die) -> void:
    if die == null:
        return
    # animate die back to its remembered table position
    var target: Vector3 = die.last_position_on_table
    die.begin_animation()
    await get_tree().physics_frame
    var tw = DieMover.prepare_tween_for_die(die, target)
    await tw.finished
    die.end_animation(Die.State.ON_TABLE)
    
    storage_model.remove_stored(die)
    # shift remaining stored dice to fill slots
    _recalculate_storing_positions()
    # work on a snapshot to avoid index errors if the underlying array changes during awaits
    var snapshot: Array[Die] = storage_model.stored_dice.duplicate()
    var limit: int = min(snapshot.size(), storing_positions.size())

    for i in range (limit):
        var d: Die = snapshot[i]
        d.begin_animation()
    
    for j in range(limit):
        var d: Die = snapshot[j]
        var p: Vector3 = storing_positions[j]
        await get_tree().physics_frame
        var tw2 = DieMover.prepare_tween_for_die(d, p)
        await tw2.finished
        d.end_animation(Die.State.IN_HAND)

    GameContext.current_scored_value = ScoreCalculator.calculate_score(storage_model.get_stored_values())

func _on_bank_dice() -> void:
    # enqueue bank requests
    event_queue.append({"type": "bank"})
    if not processing_queue:
        _process_queue()

func _handle_bank_dice() -> void:
    # Move stored dice into banked positions and update GameContext
    if bank_position == null:
        push_error("bank_position is not set")
        return

    # accumulate authoritative banked list
    var current_banked: Array[Die] = storage_model.collect_current_banked(dice)
    var moved: Array[Die] = storage_model.clear_stored_to_banked()
    var total: int = current_banked.size() + moved.size()
    if total == 0:
        return

    var positions: Array[Vector3] = PositionCalculator.calculate_bank_positions(total, spacing, line_direction, bank_position)

    for d in dice:
        d.begin_animation()  # prevent interaction during bank animation
    
    # reposition already banked
    for i in range(current_banked.size()):
        if i >= positions.size():
            break
        # Use the centralized animation lifecycle on Die so input/state locking is consistent.
        var d: Die = current_banked[i]
        d.begin_animation()
        await get_tree().physics_frame
        var tw = DieMover.prepare_tween_for_die(d, positions[i])
        await tw.finished

    for d in dice:
        d.end_animation()  # re-enable interaction
    
    # place newly banked
    var start_idx: int = current_banked.size()
    for j in range(moved.size()):
        var d: Die = moved[j]
        var pos_idx: int = start_idx + j
        if pos_idx >= positions.size():
            break
        # Use Die's begin/end helpers so we keep consistent locking/freeze behavior.
        d.begin_animation()
        await get_tree().physics_frame
        var tw2 = DieMover.prepare_tween_for_die(d, positions[pos_idx])
        await tw2.finished
        # Set explicit final state to BANKED
        d.end_animation(Die.State.BANKED)

    GameContext.banked_value += GameContext.current_scored_value
    GameContext.current_scored_value = 0

func _on_throw_request() -> void:
    # If any die is still moving, ignore the throw request entirely for this game.
    for d in dice:
        if d == null:
            continue
        if d.state == Die.State.MOVING:
            # ignore request while any die is moving
            return

    # All dice are settled — emit the real throw signal that each Die listens to
    EventBus.throw_dice.emit()

func _process_queue() -> void:
    processing_queue = true
    while event_queue.size() > 0:
        var item: Dictionary = event_queue.pop_front()
        match item.get("type", ""):
            "store":
                await _handle_store_die(item.get("die"))
            "unstore":
                await _handle_unstore_die(item.get("die"))
            "bank":
                await _handle_bank_dice()
            _:
                # unknown event, ignore
                pass
    processing_queue = false
