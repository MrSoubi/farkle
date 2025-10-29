extends Node

@export var scores : Array[Combination] = []

func calculate_score(dice_values: Array[int]) -> int:
    # Compute the maximal possible score by trying all combinations in any order.
    # Use recursion + memoization over the multiset of remaining dice values.
    var memo := {}
    return _max_score_for(dice_values.duplicate(), memo)


func _max_score_for(remaining_values: Array, memo: Dictionary) -> int:
    if remaining_values.size() == 0:
        return 0

    # Create a canonical key for memoization (sorted representation)
    var key_arr := remaining_values.duplicate()
    key_arr.sort()
    var key := str(key_arr)
    if memo.has(key):
        return memo[key]

    var best := 0

    # Try applying each combination (if it fits) and recurse on the leftover dice.
    for combination in scores:
        var comb_values := combination.values
        var temp := remaining_values.duplicate()
        var ok := true
        for v in comb_values:
            if v in temp:
                temp.erase(v)
            else:
                ok = false
                break
        if ok:
            var candidate := combination.base_score + _max_score_for(temp, memo)
            if candidate > best:
                best = candidate

    memo[key] = best
    return best