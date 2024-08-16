extends CharacterBody3D

# nodes
@onready var head: Node3D = $Head
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var crouching_collision_shape: CollisionShape3D = $CrouchingCollisionShape
@onready var ray_cast_3d: RayCast3D = $RayCast3D

# movement constants
@export var MOUSE_SENS := 0.005
@export var ACCELERATION := 0.5
@export var WALK_SPEED := 5.0
@export var SPRINT_SPEED := 8.0
@export var CROUCH_SPEED := 3.0

# crouching constants
@export var HEAD_HEIGHT := 1.8
@export var CROUCH_DEPTH := -0.5
@export var CROUCH_LERP := 10.0

const JUMP_VELOCITY := 4.5

# move state
enum MOVE_STATE {
	WALK, SPRINT, CROUCH
}
var move_state := MOVE_STATE.WALK


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotate_x(-event.relative.y * MOUSE_SENS)
		head.rotation.x = clamp(head.rotation.x, -PI/2, PI/2)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	_handle_move_state()
	_handle_crouching(delta)
	_handle_xz_movement()
	
	move_and_slide()


func _handle_move_state() -> void:
	if Input.is_action_pressed("crouch"):
		move_state = MOVE_STATE.CROUCH
		return
	
	if move_state == MOVE_STATE.CROUCH and ray_cast_3d.is_colliding():
		return
	
	if Input.is_action_pressed("sprint"):
		move_state = MOVE_STATE.SPRINT
		return
	
	move_state = MOVE_STATE.WALK


func _handle_crouching(delta: float) -> void:
	if move_state == MOVE_STATE.CROUCH:
		head.position.y = lerp(head.position.y, HEAD_HEIGHT + CROUCH_DEPTH, delta*CROUCH_LERP)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
	else:
		head.position.y = lerp(head.position.y, HEAD_HEIGHT, delta*CROUCH_LERP)
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true


func _handle_xz_movement() -> void:
	var target := _target_xz_velocity()
	var diff := target - velocity
	
	if ACCELERATION >= diff.length():
		velocity = target
	else:
		velocity += diff.normalized() * ACCELERATION


func _target_xz_velocity() -> Vector3:
	var speed : float
	match (move_state):
		MOVE_STATE.CROUCH:
			speed = CROUCH_SPEED
		MOVE_STATE.SPRINT:
			speed = SPRINT_SPEED
		_:
			speed = WALK_SPEED
	
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	return Vector3(direction.x * speed, velocity.y, direction.z * speed)
