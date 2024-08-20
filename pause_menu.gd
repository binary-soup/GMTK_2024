extends Control

var paused : bool :
	get:
		return paused
	set(val):
		paused = val
		get_tree().paused = val
		
		if val:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			visible = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			visible = false


func _ready() -> void:
	paused = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		paused = !paused


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_resume_button_pressed() -> void:
	paused = false
