extends Actor

var projectile = preload("res://src/actors/scenes/bullet.tscn")
onready var playerArea: Area2D = $playerArea
onready var castPoint = $castOrigin/castPoint
onready var castOrigin = $castOrigin
onready var meleeSprite = $meleeArea/meleeSlash
onready var meleeArea = $meleeArea
onready var animationPlayer = $AnimationPlayer
onready var jumpTimer = $jumpTimer
onready var tween = $Tween

onready var label = $Label

export var rate_of_fire = 0.5
export var attack_speed = 0.3

enum states {
	IDLE,
	RUNNING,
	WALKING,
	CROUCHED,
	CROUCH_WALK,
	JUMPING,
	FALLING,
	CLIMBING_UP,
	CLIMBING_DOWN,
	WALL_RUNNING,
	WALL_JUMPING
}

var can_jump = true
var can_climb = false
var can_wallrun = false
var can_shoot = true
var can_attack = true

var current_speed = run_speed
var current_up_speed = jump_speed
var is_running = true
var is_going_to_climb = false
var last_ladder
var last_wall
var starting_y = 0

var facing = Vector2.RIGHT

func _ready():
	set_state(states.IDLE,states.IDLE)
	jumpTimer.wait_time = jump_time

func _process(_delta):
	check_shoot_input()
	check_melee_input()
	check_vert_input()
	check_speed_input()
	check_crouch_input()
	match actualState:
		states.IDLE:
			label.text = "IDLE"
		states.WALKING:
			label.text = "WALKING"
		states.RUNNING:
			label.text = "RUNNING"
		states.CROUCHED:
			label.text = "CROUCHED"
		states.CROUCH_WALK:
			label.text = "CROUCH WALK"
		states.JUMPING:
			label.text = "JUMPING"
		states.FALLING:
			label.text = "FALLING"
		states.CLIMBING_UP:
			label.text = "CLIMBING UP"
		states.CLIMBING_DOWN:
			label.text = "CLIMBING DOWN"
		states.WALL_RUNNING:
			label.text = "WALL RUNNING"
		states.WALL_JUMPING:
			label.text = "WALL JUMPING"
	
func _on_PlayerArea_area_entered(area):
	if area.get_groups():
		match area.get_groups()[0]:
			"Climbable":
				can_climb = true
				last_ladder = area
			"ParkourWall":
				if is_on_floor(): 
					can_wallrun = true
					last_wall = area
			"Enemy":
				print("you're dead!")

func _on_playerArea_area_exited(area):
	if area.get_groups():
		match area.get_groups()[0]:
			"Climbable":
				can_climb = false
				enter_movement_state()
				#set_state(states.IDLE, actualState)
			"ParkourWall":
				can_wallrun = false
				set_state(states.IDLE, actualState)

func _on_meleeArea_body_entered(body):
	if body.is_in_group("Enemy"):
		body.on_hit()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "meleeSlash":
		can_attack = true

func _on_jumpTimer_timeout():
	can_jump = true

func _on_Tween_completed(_object, _key):
	is_going_to_climb = false

func _physics_process(delta):
	match(actualState):
		states.CLIMBING_UP:
			move_to_ladder()
			move(delta)
			exit_climb_state()
		states.CLIMBING_DOWN:
			move_to_ladder()
			move(delta)
			exit_climb_state()
		states.IDLE:
			move(delta)
			enter_movement_state()
		states.WALKING, states.RUNNING, states.CROUCHED, states.CROUCH_WALK:
			move(delta)
			enter_movement_state()
		states.JUMPING:
			move(delta)
			enter_movement_state()
		states.FALLING:
			move(delta)
			enter_movement_state()
		states.WALL_RUNNING:
			move(delta)
			exit_wallrun_state()

func enter_movement_state():
	if is_on_floor() and velocity == Vector2.ZERO and actualState != states.CLIMBING_DOWN and actualState != states.CLIMBING_UP and current_speed != crouch_speed:
		set_state(states.IDLE, actualState)
		return states.IDLE
	if is_on_floor() and velocity.x != 0 and velocity.y == 0 and current_speed == speed:
		set_state(states.WALKING, actualState)
		return states.WALKING
	if is_on_floor() and velocity.x != 0 and velocity.y == 0 and current_speed == run_speed:
		set_state(states.RUNNING, actualState)
		return states.RUNNING
	if is_on_floor() and velocity == Vector2.ZERO and current_speed == crouch_speed:
		set_state(states.CROUCHED, actualState)
		return states.CROUCHED
	if is_on_floor() and velocity.x != 0 and velocity.y == 0 and current_speed == crouch_speed:
		set_state(states.CROUCH_WALK, actualState)
		return states.CROUCH_WALK
	if !is_on_floor() and velocity.y < 0 and actualState != states.CLIMBING_DOWN and actualState != states.CLIMBING_UP:
		set_state(states.JUMPING, actualState)
		return states.JUMPING
	if !is_on_floor() and velocity.y > 0 and actualState != states.CLIMBING_DOWN and actualState != states.CLIMBING_UP:
		set_state(states.FALLING, actualState)
		return states.FALLING
	print("passou nos ifs")
	set_state(states.IDLE, actualState)
	return states.IDLE

func exit_climb_state():
	if is_on_floor():
		enter_movement_state()

func exit_wallrun_state():
	if velocity.y > 0:
		enter_movement_state()

func move_to_ladder():
	if is_going_to_climb and position.x != last_ladder.position.x:
		tween.interpolate_property(self,"position",Vector2(position.x,position.y),Vector2(last_ladder.position.x,position.y),0.1,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		tween.start()
	else: is_going_to_climb = false

func move(delta):
	velocity = calculate_move_velocity(velocity, get_move_direction(), current_up_speed, delta)
	velocity = move_and_slide(velocity,FLOOR_NORMAL,true)

func get_move_direction():
	if Input.is_action_pressed("move_right"):
		facing = Vector2.RIGHT
		set_cast_point_side()
	if Input.is_action_pressed("move_left"):
		facing = Vector2.LEFT
		set_cast_point_side()
	var movement = Vector2.ZERO
	movement.x = 0
	match actualState:
		states.CLIMBING_DOWN, states.CLIMBING_UP:
			movement.y = Input.get_action_strength("climb_down") - Input.get_action_strength("climb_up")
			current_up_speed = climb_speed
			return movement
		states.WALL_RUNNING:
			movement.y = -1.0 if is_on_floor() and can_wallrun else 0.0
			current_up_speed = wall_speed
			return movement
	movement.x = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))
	movement.y = -1.0 if Input.get_action_strength("jump") and is_on_floor() and can_jump else 0.0
	if movement.y < 0: 
		can_jump = false
		current_up_speed = jump_speed
		set_state(states.JUMPING, priorState)
		jumpTimer.start()
	elif movement.y > 0 and is_on_floor():
		movement.y = 0
	return movement

func calculate_move_velocity(linear_velocity, direction, up_speed, delta):
	var out = linear_velocity
	out.x = current_speed * direction.x
	out.y += gravity * delta
	if direction.y == -1.0:
		out.y = up_speed * direction.y
	elif direction.y == 1.0:
		out.y = 0
	return out

func check_vert_input():
	if can_climb and Input.is_action_just_pressed("climb_up"):
		set_state(states.CLIMBING_UP, priorState)
		current_up_speed = climb_speed
		is_going_to_climb = true
		last_ladder.set_platform_collision(true)
	elif can_climb and Input.is_action_just_pressed("climb_down"):
		set_state(states.CLIMBING_DOWN, priorState)
		current_up_speed = climb_speed
		is_going_to_climb = true
		last_ladder.set_platform_collision(false)
	elif can_wallrun and Input.is_action_just_pressed("climb_up"):
		current_up_speed = wall_speed
		starting_y = position.y
		set_state(states.WALL_RUNNING, priorState)

func check_speed_input():
	if Input.is_action_just_pressed("dash") and is_on_floor():
		if is_running:
			is_running = false
			current_speed = speed
			enter_movement_state()
		else:
			is_running = true
			current_speed = run_speed
			enter_movement_state()

func check_crouch_input():
	if Input.is_action_just_pressed("crouch") and is_on_floor() and actualState != states.JUMPING and actualState != states.FALLING and actualState != states.CLIMBING_DOWN and actualState != states.CLIMBING_UP:
		if actualState == states.CROUCHED or actualState == states.CROUCH_WALK:
			print_state(priorState)
			current_speed = get_state_speed(priorState)
			set_state(priorState,actualState)
		else:
			current_speed = crouch_speed
			set_state(states.CROUCHED, priorState)

func check_shoot_input():
	if Input.is_action_just_pressed("shoot") and can_shoot:
		can_shoot = false
		var projectile_instance = projectile.instance()
		projectile_instance.position = castPoint.get_global_transform().get_origin()
		projectile_instance.shoot(castOrigin.rotation_degrees)
		projectile_instance.origin = "Player"
		get_parent().add_child(projectile_instance)
		yield(get_tree().create_timer(rate_of_fire),"timeout")
		can_shoot = true

func check_melee_input():
	if Input.is_action_just_pressed("slash") and can_attack:
		can_attack = false
		animationPlayer.play("meleeSlash")
		
func set_cast_point_side():
	if facing == Vector2.RIGHT:
		castOrigin.rotation_degrees = 0
		meleeArea.transform.origin.x = 96
		meleeSprite.flip_h = false
		meleeSprite.flip_v = false
	else: 
		castOrigin.rotation_degrees = 180
		meleeArea.transform.origin.x = -96
		meleeSprite.flip_h = true
		meleeSprite.flip_v = true

func on_hit():
	print("Foi atingido!")

func get_state_speed(state):
	if state == states.RUNNING:
		return run_speed
	else: return speed

func print_state(state):
	match state:
		states.IDLE:
			print("IDLE")
		states.WALKING:
			print("WALKING")
		states.RUNNING:
			print("RUNNING")
		states.CROUCHED:
			print("CROUCHED")
		states.CROUCH_WALK:
			print("CROUCH_WALK")
		states.JUMPING:
			print("JUMPING")
		states.FALLING:
			print("FALLING")
		states.CLIMBING_UP:
			print("CLIMBING_UP")
		states.CLIMBING_DOWN:
			print("CLIMBING_DOWN")
