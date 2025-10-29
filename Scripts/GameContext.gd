extends Node

signal on_stored_value_changed(new_value : int)
var _current_scored_value : int = 0
var current_scored_value : int :
    get:
        return _current_scored_value
    set(value):
        _current_scored_value = value
        emit_signal("on_stored_value_changed", _current_scored_value)

signal on_banked_value_changed(new_value : int)
var _banked_value : int = 0
var banked_value : int :
    get:
        return _banked_value
    set(value):
        _banked_value = value
        emit_signal("on_banked_value_changed", _banked_value)