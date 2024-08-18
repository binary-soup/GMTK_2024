extends RigidBody3D

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var gs_node: GSNode = $GSNode

@export var JUMP_BOOST := 3.0
var player : Player


func _physics_process(_delta: float) -> void:
	if player:
		player.set_jump_boost(JUMP_BOOST * gs_node.gs_val)
	

func _on_gs_node_gs_val_changed(val: float) -> void:
	var size := Vector3(val, val, val)
	
	mass = val
	collision_shape.scale = size


func _on_bounce_pad_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body


func _on_bounce_pad_body_exited(body: Node3D) -> void:
	if body is Player:
		player.set_jump_boost(0.0)
		player = null
