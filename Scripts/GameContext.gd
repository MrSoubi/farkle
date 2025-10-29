extends Node

signal on_stored_value_changed(new_value : int)
var _current_stored_value : int = 0
var CurrentScoredValue : int :
    get:
        return _current_stored_value
    set(value):
        _current_stored_value = value
        emit_signal("on_stored_value_changed", _current_stored_value)

signal on_banked_value_changed(new_value : int)
var _banked_value : int = 0
var BankedValue : int :
    get:
        return _banked_value
    set(value):
        _banked_value = value
        on_banked_value_changed.emit(_banked_value)