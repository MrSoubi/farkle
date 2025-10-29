class_name Combination 
extends Resource

enum CombinationType {
    THREE_OF_A_KIND,
    FOUR_OF_A_KIND,
    FIVE_OF_A_KIND,
    SIX_OF_A_KIND,
    STRAIGHT,
    THREE_PAIRS,
    TWO_TRIPLETS,
    FOUR_AND_PAIR,
    FULL_HOUSE,
    SINGLE_ONES,
    SINGLE_FIVES
}

@export var values : Array[int] = []
@export var base_score : int = 0
@export var type : CombinationType
