extends CharacterBody3D

# nodes
@onready var neck: Node3D = $Neck
@onready var head: Node3D = $Neck/Head
@onready var eyes: Node3D = $Neck/Head/Eyes
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var crouching_collision_shape: CollisionShape3D = $CrouchingCollisionShape
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var camera_3d: Camera3D = $Neck/Head/Eyes/Camera3D
@onready var eyes_anim: AnimationPlayer = $Neck/Head/Eyes/AnimationPlayer
@onready var slide_timer: Timer = $SlideTimer


# look constants
@export var MOUSE_SENS := 0.005
@export var FREE_LOOK_LERP := 10.0
@export var FREE_LOOK_TILT := PI/64

# movement constants and vars
@export var FLOOR_ACCELERATION := 0.5
@export var AIR_ACCELERATION := 0.2

@export var WALK_SPEED := 5.0
@export var SPRINT_SPEED := 8.0
@export var CROUCH_SPEED := 3.0
@export var JUMP_SPEED := 4.5

var prev_velocity : Vector3

# crouching constants
@export var CROUCH_DEPTH := -0.5
@export var CROUCH_LERP := 10.0

# slide constants and vars
@export var SLIDE_SPEED := 10.0
@export var SLIDE_TILT := PI/64
@export var SLIDE_TILT_LERP := 10.0
var slide_dir : Vector2

# head bob constants and vars
@export var HEAD_BOB_SPRINT_SPEED := 22.0
@export var HEAD_BOB_WALK_SPEED := 14.0
@export var HEAD_BOB_CROUCH_SPEED := 10.0

@export var HEAD_BOB_SPRINT_INTENSITY := 0.2
@export var HEAD_BOB_WALK_INTENSITY := 0.1
@export var HEAD_BOB_CROUCH_INTENSITY := 0.05

@export var HEAD_BOB_LERP := 10.0

var head_bob_vec := Vector2()
var head_bob_index := 0.0
var head_bob_curr_intensity := 0.0

# move states
enum MOVE_STATE {
	WALK, SPRINT, CROUCH, SLIDE
}
var move_state := MOVE_STATE.WALK
var free_looking := false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_look(event.relative)


func _handle_look(relative : Vector2) -> void:
	if free_looking:
		neck.rotate_y(-relative.x * MOUSE_SENS)
		neck.rotation.y = clamp(neck.rotation.y, -2*PI/3, 2*PI/3)
	else:
		rotate_y(-relative.x * MOUSE_SENS)
	
	head.rotate_x(-relative.y * MOUSE_SENS)
	head.rotation.x = clamp(head.rotation.x, -PI/2, PI/2)


func _physics_process(delta: float) -> void:
	_handle_move_state()
	
	_handle_head_bob(delta)
	_handle_free_looking(delta)
	_handle_crouching_height(delta)
	
	_handle_xz_movement()
	_handle_y_movement(delta)
	
	prev_velocity = velocity
	move_and_slide()


func _handle_move_state() -> void:
	if move_state == MOVE_STATE.SLIDE:
		return
	
	if Input.is_action_pressed("crouch"):
		if move_state == MOVE_STATE.SPRINT and _get_input_dir() != Vector2.ZERO:
			_start_slide()
		else:
			move_state = MOVE_STATE.CROUCH
		return
	
	# when existing crouch state, check for room above head
	if move_state == MOVE_STATE.CROUCH and ray_cast_3d.is_colliding():
		return
	
	if Input.is_action_pressed("sprint"):
		move_state = MOVE_STATE.SPRINT
		return
	
	move_state = MOVE_STATE.WALK


func _handle_head_bob(delta: float) -> void:
	if !is_on_floor() or move_state == MOVE_STATE.SLIDE or _get_input_dir() == Vector2.ZERO:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * HEAD_BOB_LERP)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta * HEAD_BOB_LERP)
		return
	
	match (move_state):
		MOVE_STATE.CROUCH:
			head_bob_curr_intensity = HEAD_BOB_CROUCH_INTENSITY
			head_bob_index += HEAD_BOB_CROUCH_SPEED * delta
		MOVE_STATE.SPRINT:
			head_bob_curr_intensity = HEAD_BOB_SPRINT_INTENSITY
			head_bob_index += HEAD_BOB_SPRINT_SPEED * delta
		_:
			head_bob_curr_intensity = HEAD_BOB_WALK_INTENSITY
			head_bob_index += HEAD_BOB_WALK_SPEED * delta
	
	head_bob_vec.y = sin(head_bob_index)
	head_bob_vec.x = sin(head_bob_index/2.0)+0.5
	
	eyes.position.y = lerp(eyes.position.y, head_bob_vec.y * (head_bob_curr_intensity/2.0), delta * HEAD_BOB_LERP)
	eyes.position.x = lerp(eyes.position.x, head_bob_vec.x * head_bob_curr_intensity, delta * HEAD_BOB_LERP)


func _handle_free_looking(delta: float) -> void:
	if Input.is_action_pressed("free_look") or move_state == MOVE_STATE.SLIDE:
		free_looking = true
		if move_state == MOVE_STATE.SLIDE:
			eyes.rotation.z = lerp(eyes.rotation.z, -SLIDE_TILT, delta * SLIDE_TILT_LERP)
		else:
			eyes.rotation.z = -neck.rotation.y * FREE_LOOK_TILT
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * FREE_LOOK_LERP)
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0, delta * FREE_LOOK_LERP)


func _start_slide() -> void:
	move_state = MOVE_STATE.SLIDE
	slide_dir = _get_input_dir()
	slide_timer.start()


func _handle_crouching_height(delta: float) -> void:
	if move_state == MOVE_STATE.CROUCH or move_state == MOVE_STATE.SLIDE:
		head.position.y = lerp(head.position.y, CROUCH_DEPTH, delta*CROUCH_LERP)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
	else:
		head.position.y = lerp(head.position.y, 0.0, delta*CROUCH_LERP)
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true


func _handle_xz_movement() -> void:
	var target := _target_xz_velocity()
	var diff := target - velocity
	
	var acceleration := FLOOR_ACCELERATION
	if !is_on_floor():
		acceleration = AIR_ACCELERATION
	
	if acceleration >= diff.length():
		velocity = target
	else:
		velocity += diff.normalized() * acceleration


func _handle_y_movement(delta: float) -> void:
	if !is_on_floor():
		velocity += get_gravity() * delta
		return
	
	# on_floor
	
	if prev_velocity.y < 0.0:
		eyes_anim.play("land")
	
	_handle_jump()


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and !ray_cast_3d.is_colliding():
		velocity.y = JUMP_SPEED
		eyes_anim.play("jump")
		_end_slide()


func _target_xz_velocity() -> Vector3:
	var speed : float
	match (move_state):
		MOVE_STATE.CROUCH:
			speed = CROUCH_SPEED
		MOVE_STATE.SPRINT:
			speed = SPRINT_SPEED
		MOVE_STATE.SLIDE:
			speed = SLIDE_SPEED
		_:
			speed = WALK_SPEED
	
	var input_dir : Vector2
	if move_state == MOVE_STATE.SLIDE:
		input_dir = slide_dir
	else:
		input_dir = _get_input_dir()
	
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	return Vector3(direction.x * speed, velocity.y, direction.z * speed)


func _get_input_dir() -> Vector2:
	return Input.get_vector("left", "right", "forward", "back")


func _on_slide_timer_timeout() -> void:
	_end_slide()


func _end_slide() -> void:
	if move_state != MOVE_STATE.SLIDE:
		return
		
	slide_timer.stop()
	move_state = MOVE_STATE.CROUCH
