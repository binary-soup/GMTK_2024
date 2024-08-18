extends Node3D
class_name GSNode

signal gs_val_changed(val: float)

# gs constants
@export var GS_MAX_VAL := 2.0
@export var GS_MIN_VAL := 0.5
@export var GS_SPEED_MULTIPLIER := 1.0
@export var gs_disabled := false

# grabbable constants
@export var MAX_GRAB_SIZE := -1.0


var gs_val : float = 1.0 :
	get:
		return gs_val
	set(val):
		if gs_disabled:
			return
		
		gs_val = val
		_set_gs_val(val)


func shrink(speed: float) -> void:
	gs_val = lerp(gs_val, GS_MIN_VAL, speed * GS_SPEED_MULTIPLIER)


func grow(speed: float) -> void:
	gs_val = lerp(gs_val, GS_MAX_VAL, speed * GS_SPEED_MULTIPLIER)


func _set_gs_val(val: float):
	emit_signal("gs_val_changed", val)


func is_grabbable() -> bool:
	return gs_val < MAX_GRAB_SIZE
