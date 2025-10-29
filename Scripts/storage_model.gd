extends Node
class_name StorageModel

var stored_dice : Array = []
var banked_dice : Array = []

func add_stored(die) -> int:
    var idx := stored_dice.find(die)
    if idx != -1:
        return idx
    stored_dice.append(die)
    return stored_dice.size() - 1

func remove_stored(die) -> void:
    var idx := stored_dice.find(die)
    if idx != -1:
        stored_dice.remove_at(idx)

func clear_stored_to_banked() -> Array:
    var moved := stored_dice.duplicate()
    for d in moved:
        banked_dice.append(d)
    stored_dice.clear()
    return moved

func get_stored_values() -> Array:
    var vals := []
    for d in stored_dice:
        vals.append(d.get_top_value())
    return vals

func collect_current_banked(all_dices: Array) -> Array:
    var out := banked_dice.duplicate()
    for d in all_dices:
        if d.state == Die.State.BANKED and out.find(d) == -1:
            out.append(d)
    return out
