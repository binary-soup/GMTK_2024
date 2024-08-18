extends RigidBody3D

@onready var gs_node: GSNode = $CollisionShape3D/GSNode
@onready var mesh: CSGBox3D = $CollisionShape3D/Mesh


func _on_gs_node_gs_val_changed(val: float) -> void:
	var size := Vector3(val, val, val)
	
	mass = val
	mesh.material.uv1_scale = size
	mesh.material.uv1_offset = -size/2.0 + Vector3(0.5, 0.5, 0.5)
