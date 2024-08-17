extends Node

var paused : bool :
	get:
		return paused
	set(val):
		paused = val
		get_tree().paused = val
		
		if val:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _ready() -> void:
	paused = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("pause"):
		paused = !paused
