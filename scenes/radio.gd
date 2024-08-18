extends GSRigidBase

# nodes
@onready var audio_player: AudioStreamPlayer3D = $Mesh/AudioStreamPlayer3D

# audio constants
var BASE_VOLUME : float
@export var VOLUME_CHANGE := 5.0


func _ready() -> void:
	BASE_VOLUME = audio_player.volume_db


func _on_gs_val_changed(val: float):
	audio_player.volume_db = BASE_VOLUME + (val*VOLUME_CHANGE - VOLUME_CHANGE)
	audio_player.pitch_scale = 1/val


func is_grabable() -> bool:
	return gs_val < 0.6
