extends Node3D

# nodes
@onready var beam: Node3D = $Beam
@onready var ray_cast: RayCast3D = $Beam/RayCast3D
@onready var mesh: CSGCylinder3D = $Beam/Mesh

# materials
var grow_mat := preload("res://assets/materials/grow_mat.tres")
var shrink_mat := preload("res://assets/materials/shrink_mat.tres")

enum RAY_TYPE {
	GROW, SHRINK
}

func stop_ray() -> void:
	beam.visible = false


func fire_ray(ray_type: RAY_TYPE) -> void:
	if ray_type == RAY_TYPE.GROW:
		mesh.material = grow_mat
	else:
		mesh.material = shrink_mat
	
	beam.visible = true
	if not ray_cast.is_colliding():
		beam.scale.z = ray_cast.target_position.z
		return
	
	var hit := ray_cast.get_collision_point()
	beam.scale.z = (hit - beam.global_position).length()
	
	var gs_obj : GSNode = _get_gs_obj()
	if !gs_obj:
		return
	
	if ray_type == RAY_TYPE.GROW:
		gs_obj.grow(0.1)
	else:
		gs_obj.shrink(0.1)


func _get_gs_obj() -> GSNode:
	return ray_cast.get_collider().find_child("GSNode")
