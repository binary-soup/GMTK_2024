extends CharacterBody3D

# nodes
@onready var neck: Node3D = $Neck
@onready var head: Node3D = $Neck/Head
@onready var eyes: Node3D = $Neck/Head/Eyes
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var crouching_collision_shape: CollisionShape3D = $CrouchingCollisionShape
@onready var crouch_ray_cast: RayCast3D = $CrouchRayCast
@onready var camera_3d: Camera3D = $Neck/Head/Eyes/Camera3D
@onready var eyes_anim: AnimationPlayer = $Neck/Head/Eyes/AnimationPlayer
@onready var slide_timer: Timer = $SlideTimer
@onready var grab_ray_cast: RayCast3D = $Neck/Head/GrabRayCast
@onready var hand: Node3D = $Neck/Head/Hand
@onready var ray_gun: Node3D = $Neck/Head/Eyes/RayGun

# sfx
@onready var slide_sfx: AudioStreamPlayer = $SoundFX/SlideSFX
@onready var step_sfx: AudioStreamPlayer = $SoundFX/StepSFX

# look constants
@export var MOUSE_SENS := 0.005

# movement constants and vars
@export var FLOOR_ACCELERATION := 0.5
@export var AIR_ACCELERATION := 0.2

@export var WALK_SPEED := 5.0
@export var SPRINT_SPEED := 8.0
@export var CROUCH_SPEED := 3.0
@export var JUMP_SPEED := 5.5

var prev_velocity : Vector3
var input_dir : Vector2

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
var foot_step_last_sign := 1.0

# ray gun constants and vars
@export var RAY_USAGE_DAMPENING := 0.3
var ray_gun_input : float

# throwing constants
@export var THROW_STRENGTH := 3.0

# move states
enum MOVE_STATE {
	WALK, SPRINT, CROUCH, SLIDE
}
var move_state := MOVE_STATE.WALK


func _ready() -> void:
	step_sfx.set_sounds([
		preload("res://assets/sfx/step_1.wav"),
		preload("res://assets/sfx/step_2.wav"),
		preload("res://assets/sfx/step_3.wav"),
		preload("res://assets/sfx/step_4.wav"),
	])


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_look(event.relative)


func _handle_look(relative : Vector2) -> void:
	var sens := MOUSE_SENS
	if ray_gun_input != 0.0:
		sens *= RAY_USAGE_DAMPENING
	
	if move_state == MOVE_STATE.SLIDE:
		neck.rotate_y(-relative.x * sens)
		neck.rotation.y = clamp(neck.rotation.y, -PI/2, PI/2)
	else:
		rotate_y(-relative.x * sens)
	
	head.rotate_x(-relative.y * sens)
	head.rotation.x = clamp(head.rotation.x, -PI/2, PI/2)


func _physics_process(delta: float) -> void:
	input_dir = Input.get_vector("left", "right", "forward", "back")
	ray_gun_input = Input.get_vector("shrink_ray", "grow_ray", "shrink_ray", "grow_ray").x
	
	_handle_move_state()
	
	_handle_head_bob(delta)
	_handle_slide_looking(delta)
	_handle_crouching_height(delta)
	
	_handle_xz_movement()
	_handle_y_movement(delta)
	
	_handle_grabing()
	_handle_throwing()
	_handle_ray_gun()
	
	prev_velocity = velocity
	move_and_slide()


func _handle_move_state() -> void:
	if move_state == MOVE_STATE.SLIDE:
		return
	
	if Input.is_action_pressed("crouch"):
		if move_state == MOVE_STATE.SPRINT and input_dir != Vector2.ZERO:
			_start_slide()
		else:
			move_state = MOVE_STATE.CROUCH
		return
	
	# when existing crouch state, check for room above head
	if move_state == MOVE_STATE.CROUCH and crouch_ray_cast.is_colliding():
		return
	
	if Input.is_action_pressed("sprint"):
		move_state = MOVE_STATE.SPRINT
		return
	
	move_state = MOVE_STATE.WALK


func _handle_head_bob(delta: float) -> void:
	if !is_on_floor() or move_state == MOVE_STATE.SLIDE or input_dir == Vector2.ZERO:
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
	
	var s : float = sign(cos(head_bob_index/2.0)/2.0)
	if s != foot_step_last_sign:
		foot_step_last_sign = s
		step_sfx.play_rand()


func _handle_slide_looking(delta: float) -> void:
	if move_state == MOVE_STATE.SLIDE:
		eyes.rotation.z = lerp(eyes.rotation.z, -SLIDE_TILT, delta * SLIDE_TILT_LERP)
	else:
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * SLIDE_TILT_LERP)
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0, delta * SLIDE_TILT_LERP)


func _start_slide() -> void:
	move_state = MOVE_STATE.SLIDE
	slide_dir = input_dir
	slide_timer.start()
	slide_sfx.play()


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
	if Input.is_action_just_pressed("jump") and !crouch_ray_cast.is_colliding():
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
	
	var input : Vector2
	if move_state == MOVE_STATE.SLIDE:
		input = slide_dir
	else:
		input = input_dir
	
	var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	
	return Vector3(direction.x * speed, velocity.y, direction.z * speed)


func _on_slide_timer_timeout() -> void:
	_end_slide()


func _end_slide() -> void:
	if move_state != MOVE_STATE.SLIDE:
		return
		
	slide_timer.stop()
	move_state = MOVE_STATE.CROUCH


func _handle_grabing() -> void:
	if not Input.is_action_just_pressed("grab"):
		return
	
	if _object_in_hand():
		_drop_object()
		return
	
	if not grab_ray_cast.is_colliding():
		return
	
	var obj : RigidBody3D = grab_ray_cast.get_collider()
	if obj.is_grabable():
		_grab_object(obj)


func _handle_throwing() -> void:
	if !_object_in_hand() or !Input.is_action_just_pressed("throw"):
		return
	
	var obj := _drop_object()
	obj.apply_impulse(Vector3.FORWARD * hand.global_basis.inverse() * THROW_STRENGTH)


func _grab_object(obj : RigidBody3D) -> void:
	obj.get_parent().remove_child(obj)
	hand.add_child(obj)
	
	obj.freeze = true
	obj.position = Vector3()
	obj.set_collision_layer_value(2, false)


func _drop_object() -> RigidBody3D:
	# TODO: only drop if object is in bounds
	
	var obj : RigidBody3D = hand.get_child(0)
	hand.remove_child(obj)
	
	var parent := get_parent()
	
	obj.freeze = false
	obj.set_collision_layer_value(2, true)
	
	parent.add_child(obj)
	obj.position = parent.to_local(hand.global_position)
	return obj


func _object_in_hand() -> bool:
	return hand.get_child_count() > 0


func _handle_ray_gun() -> void:
	if _object_in_hand():
		return
	
	if ray_gun_input < 0.0:
		ray_gun.fire_ray(ray_gun.RAY_TYPE.SHRINK)
	elif ray_gun_input > 0.0:
		ray_gun.fire_ray(ray_gun.RAY_TYPE.GROW)
	else:
		ray_gun.stop_ray()


#func _on_weapon_hit(obj: Node3D, point: Vector3, delta : float) -> void:
	#var pt1 := neck.to_local(obj.global_position)
	#var pt2 := neck.to_local(point)
	#
	#var y := Vector2(pt1.x, pt1.z).angle_to(Vector2(pt2.x, pt2.z))
	#rotation.y = lerp(rotation.y, rotation.y + y, delta * 20.0)
	#
	#var pt3 := head.to_local(obj.global_position)
	#var pt4 := head.to_local(point)
	#
	#var x := Vector2(pt3.z, pt3.y).angle_to(Vector2(pt4.z, pt4.y))
	#head.rotation.x = lerp(head.rotation.x, head.rotation.x + x, delta * 20.0)
