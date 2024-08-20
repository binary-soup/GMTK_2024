extends Node3D

@onready var respawn: Node3D = $Respawn


func _on_death_plane_body_entered(body: Node3D) -> void:
	body.position = respawn.position
	
	if body is RigidBody3D:
		body.freeze = true
		body.freeze = false
