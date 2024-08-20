extends Node3D

@onready var respawn: Node3D = $ThrowDemo/Respawn
@onready var audio_stream_player: AudioStreamPlayer = $Commentary/AudioStreamPlayer
@onready var collision_shape: CollisionShape3D = $Commentary/CommentarryTrigger/CollisionShape3D



func _on_throw_death_plane_body_entered(body: Node3D) -> void:
	body.position = respawn.position
	
	if body is RigidBody3D:
		body.freeze = true
		body.freeze = false


func _on_commentarry_trigger_body_entered(body: Node3D) -> void:
	audio_stream_player.play()
	collision_shape.set_deferred("disabled", true)
