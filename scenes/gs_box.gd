extends GSRigidBase

func _on_gs_val_changed(val: float):
	var size := Vector3(val, val, val)
	
	mesh.material.uv1_scale = size
	mesh.material.uv1_offset = -size/2.0 + Vector3(0.5, 0.5, 0.5)


func is_grabable() -> bool:
	return gs_val < 0.8
