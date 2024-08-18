extends RigidBody3D

# nodes
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var gs_node: GSNode = $CollisionShape3D/GSNode
@onready var audio_player: AudioStreamPlayer3D = $CollisionShape3D/AudioStreamPlayer3D

# audio constants
var BASE_VOLUME : float
@export var VOLUME_CHANGE := 5.0


func _ready() -> void:
	BASE_VOLUME = audio_player.volume_db


func _on_gs_node_gs_val_changed(val: float):
	var size := Vector3(val, val, val)
	
	collision_shape.scale = size
	audio_player.volume_db = BASE_VOLUME + (val*VOLUME_CHANGE - VOLUME_CHANGE)
	audio_player.pitch_scale = 1/val


func is_grabable() -> bool:
	return gs_node.gs_val < 0.6
