extends Node3D

# nodes
@onready var beam: Node3D = $Beam
@onready var ray_cast: RayCast3D = $Beam/RayCast3D
@onready var mesh: CSGCylinder3D = $Beam/Mesh

# materials
var grow_mat := preload("res://assets/materials/grow_mat.tres")
var shrink_mat := preload("res://assets/materials/shrink_mat.tres")


func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("shrink_ray", "grow_ray", "shrink_ray", "grow_ray").x
	if input == 0.0:
		beam.visible = false
		return
	
	if input < 0.0:
		mesh.material = shrink_mat
	else:
		mesh.material = grow_mat
	
	beam.visible = true
	if not ray_cast.is_colliding():
		beam.scale.z = ray_cast.target_position.z
		return
	
	var hit := ray_cast.get_collision_point()
	var origin := beam.global_position
	
	beam.scale.z = (hit - origin).length()
	
	var obj := ray_cast.get_collider()
	if not "gs_val" in obj:
		return
	
	if input < 0.0:
		obj.gs_shrink(0.1)
	else:
		obj.gs_grow(0.1)
	
