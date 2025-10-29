extends Node3D

@export var dices : Array[Die] = []
@export var spacing : float = 0.15
@export var line_direction : Vector3 = Vector3(1, 0, 0)
@export var bank_position : Node3D

var requested_store_dice : bool = false
var storing_positions : Array[Vector3] = []
var next_store_index : int = 0
var stored_dice : Array[Die] = []
var banked_dice : Array[Die] = []
# We perform requested movements during the next physics frame using `await get_tree().physics_frame`.
# No pending dict is needed with this approach.

func _ready() -> void:
    calculate_storing_positions()
    EventBus.store_die.connect(store_die)
    EventBus.unstore_die.connect(unstore_die)
    EventBus.bank_dice.connect(bank_stored_dice)
    # Initialize tracked banked dice from existing dice (if any were banked before)
    banked_dice = _collect_current_banked()

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
    # Mark as stored immediately, but perform the actual move in the next physics frame
    stored_dice.append(die)
    next_store_index = stored_dice.size()
    GameContext.CurrentScoredValue = get_total_stored_value()

    # Animate move to storage slot during the next physics frame
    await _move_die_to(die, pos)


func unstore_die(die: Die) -> void:
    # Move the die back to the table
    var target := die.last_position_on_table
    print("Unstoring die to position:", target)
    # Animate move back to table on next physics frame
    await _move_die_to(die, target)

    # Remove die from stored list and shift remaining stored dice to fill gaps
    var idx := stored_dice.find(die)
    stored_dice.remove_at(idx)

    # Shift remaining stored dice into their slots (sequential)
    for i in range(stored_dice.size()):
        if i >= storing_positions.size():
            break
        var d := stored_dice[i]
        var p := storing_positions[i]
        # perform sequential moves so they shift one after another
        await _move_die_to(d, p)

    # Update next_store_index to the current count of stored dice
    next_store_index = stored_dice.size()

    GameContext.CurrentScoredValue = get_total_stored_value()


func _physics_process(_delta: float) -> void:
    # Handle requested store-dice operation (visual update in physics frame)
    if requested_store_dice:
        requested_store_dice = false
        var index = 0
        for die in dices:
            if index >= storing_positions.size():
                break
            var store_position = storing_positions[index]
            # Start a tweened move in the physics frame (don't await so many run in parallel)
            _move_die_to(die, store_position)
            index += 1

func get_total_stored_value() -> int:
    var values : Array[int] = []
    for die in stored_dice:
        values.append(die.get_top_value())
    
    var total : int = ScoreCalculator.calculate_score(values)
    return total

func bank_stored_dice() -> void:
    # Clear stored dice and reset index
    GameContext.BankedValue += GameContext.CurrentScoredValue
    GameContext.CurrentScoredValue = 0
    bank_dice()
    
func bank_dice() -> void:
    if bank_position == null:
        push_error("bank_position is not set")
        return
    # Compose authoritative list of already-banked dice (tracked + any Die with state BANKED)
    var current_banked: Array[Die] = _collect_current_banked()

    # Compute target positions for all banked dice after this operation
    var total := current_banked.size() + stored_dice.size()
    if total == 0:
        return

    var positions := _calculate_bank_positions(total)

    # Debug: print counts
    print("bank_dice: currently tracked banked=", current_banked.size(), ", stored=", stored_dice.size(), ", total positions=", positions.size())
    # Debug: list computed bank positions
    for i in range(positions.size()):
        print("bank position[", i, "] =", positions[i])

    # Re-position already banked dice (sequentially)
    for i in range(current_banked.size()):
        var d: Die = current_banked[i]
        if i >= positions.size():
            break
        await _position_die(d, positions[i])

    # Place stored dice into the next positions and mark them BANKED, then add to current_banked
    var start_idx := current_banked.size()
    for j in range(stored_dice.size()):
        var d: Die = stored_dice[j]
        var pos_idx := start_idx + j
        if pos_idx >= positions.size():
            break
        print("bank_dice: positioning stored die", d.name, "to index", pos_idx, "pos", positions[pos_idx])
        await _position_die(d, positions[pos_idx])
        d.state = Die.State.BANKED
        current_banked.append(d)

    # Update authoritative list and clear stored
    banked_dice = current_banked
    stored_dice.clear()
    next_store_index = 0


func _collect_current_banked() -> Array[Die]:
    # Return a typed array containing all dice that are currently BANKED.
    var out: Array[Die] = []
    # Add tracked ones first (avoid duplicates later)
    for d in banked_dice:
        out.append(d)
    # Add any dice in `dices` that have BANKED state but aren't in the tracked list
    for d in dices:
        if d.state == Die.State.BANKED and out.find(d) == -1:
            out.append(d)
    return out


func _position_die(die: Die, target: Vector3) -> void:
    # Small helper to consistently move a die to a global position while
    # disabling its physics/controls via `freeze`.
    var old_pos := die.global_position
    print("_position_die: die=", die.name, "old=", old_pos, "new=", target, "state=", die.state)
    # Delegate to the tween-based mover which will run during the next physics frame.
    await _move_die_to(die, target)


func _move_die_to(die: Die, target: Vector3, duration: float = 0.12, trans_type: int = Tween.TRANS_QUAD, ease_type: int = Tween.EASE_OUT) -> void:
    # Wait a physics frame so we call physics APIs at the right time.
    await get_tree().physics_frame
    die.freeze = true
    die.linear_velocity = Vector3.ZERO
    die.angular_velocity = Vector3.ZERO
    # Use a SceneTreeTween to animate global_position smoothly.
    var tw = die.create_tween()
    var step = tw.tween_property(die, "global_position", target, duration)
    # Configure easing/transition for the tweened step
    step.set_trans(trans_type).set_ease(ease_type)
    # Wait until the tween finishes
    await tw.finished
    die.freeze = false
    print("_move_die_to: die=", die.name, "-> now=", die.global_position)


func _calculate_bank_positions(total_count: int) -> Array:
    print("Calculating bank positions for total count:", total_count)
    var out := []
    if total_count <= 0:
        return out

    var dir := line_direction
    if dir.length() == 0:
        dir = Vector3(1, 0, 0)
    dir = dir.normalized()

    var start_offset := -((total_count - 1) * spacing) / 2.0

    for i in range(total_count):
        var local_pos := dir * (start_offset + i * spacing)
        # bank_position is the origin for banked dice
        var global_pos := bank_position.to_global(local_pos)
        out.append(global_pos)

    return out
