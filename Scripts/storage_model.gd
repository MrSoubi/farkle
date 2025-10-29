extends Node

var stored_dice: Array[Die] = []
var banked_dice: Array[Die] = []

func add_stored(die: Die) -> int:
    var idx: int = stored_dice.find(die)
    if idx != -1:
        return idx
    stored_dice.append(die)
    return stored_dice.size() - 1

func remove_stored(die: Die) -> void:
    var idx: int = stored_dice.find(die)
    if idx != -1:
        stored_dice.remove_at(idx)

func clear_stored_to_banked() -> Array[Die]:
    var moved: Array[Die] = stored_dice.duplicate()
    for d in moved:
        banked_dice.append(d)
    stored_dice.clear()
    return moved

func get_stored_values() -> Array[int]:
    var vals: Array[int] = []
    for d in stored_dice:
        vals.append(int(d.get_top_value()))
    return vals

func collect_current_banked(all_dices: Array) -> Array[Die]:
    var out: Array[Die] = banked_dice.duplicate()
    for d in all_dices:
        if d.state == Die.State.BANKED and out.find(d) == -1:
            out.append(d)
    return out
