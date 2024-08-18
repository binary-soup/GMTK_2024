extends RigidBody3D
class_name GSRigidBase

# nodes
@onready var mesh: CSGBox3D = $Mesh
@onready var collision: CollisionShape3D = $CollisionShape3D

# gs constants
@export var GS_MAX_VAL := 2.0
@export var GS_MIN_VAL := 0.5
@export var GS_SPEED_MULTIPLIER := 1.0


var gs_val : float = 1.0 :
	get:
		return gs_val
	set(val):
		gs_val = val
		_set_gs_val(val)


func gs_shrink(speed: float) -> void:
	gs_val = lerp(gs_val, GS_MIN_VAL, speed * GS_SPEED_MULTIPLIER)


func gs_grow(speed: float) -> void:
	gs_val = lerp(gs_val, GS_MAX_VAL, speed * GS_SPEED_MULTIPLIER)


func _set_gs_val(val: float):
	var size := Vector3(val, val, val)
	mass = val
	
	collision.scale = size
	mesh.scale = size
	
	_on_gs_val_changed(val)


func _on_gs_val_changed(val: float) -> void:
	pass
