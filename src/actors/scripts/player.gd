extends Actor

var projectile = preload("res://src/actors/scenes/bullet.tscn")
onready var playerArea: Area2D = $playerArea
onready var castPoint = $castOrigin/castPoint
onready var castOrigin = $castOrigin
onready var meleeSprite = $meleeArea/meleeSlash
onready var meleeArea = $meleeArea
onready var animationPlayer = $AnimationPlayer
onready var jumpTimer: Timer = $jumpTimer
onready var tapTimer: Timer = $tapTimer
onready var tween = $Tween
onready var bottomRightRC: RayCast2D = $bottomRightRC
onready var bottomLeftRC: RayCast2D = $bottomLeftRC2
onready var topRightRC: RayCast2D = $topRightRC
onready var topLeftRC: RayCast2D = $topLeftRC

onready var label = $Label

export var jump_force = 0.25
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
	WALL_JUMPING,
	ON_LEDGE
}

var can_jump = true
var can_climb = false
var slide_down = false
var can_wallrun = false
var can_grab_ledge = false
var can_shoot = true
var can_attack = true

var current_speed = run_speed
var prior_speed = current_speed
var current_up_speed = jump_speed
var is_running = true
var prior_to_crouch_state
var is_going_to_climb = false
var last_ladder: Area2D 
var last_wall: Area2D

var jump_direction
var facing = Vector2.RIGHT

func _ready():
	set_state(states.IDLE,states.IDLE)
	jumpTimer.wait_time = jump_time

func _process(_delta):
	check_shoot_input()
	check_melee_input()
	check_climb_input()
	check_speed_input()
	check_crouch_input()
	if can_wallrun and last_wall: can_wallrun_check(last_wall)
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
		states.ON_LEDGE:
			label.text = "ON LEDGE"
	
func _on_PlayerArea_area_entered(area):
	if area.get_groups():
		match area.get_groups()[0]:
			"Climbable":
				can_climb = true
				last_ladder = area
			"ParkourWall":
				can_wallrun_check(area)
			"Ledge":
				can_grab_check(area)
			"Enemy":
				print("you're dead!")

func _on_playerArea_area_exited(area):
	if area.get_groups():
		match area.get_groups()[0]:
			"Climbable":
				can_climb = false
				match actualState:
					states.CROUCHED, states.CROUCH_WALK:
						enter_crouch_state()
						return
					states.JUMPING, states.FALLING:
						return
				enter_idle_state()
			"ParkourWall":
				can_wallrun = false
			"Ledge":
				can_grab_ledge = false

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
		states.CLIMBING_UP, states.CLIMBING_DOWN:
			move_to_ladder()
			move(delta)
			exit_climb_state()
		states.CROUCHED, states.CROUCH_WALK:
			move(delta)
			enter_crouch_state()
		states.IDLE, states.WALKING, states.RUNNING:
			move(delta)
			set_movement_state()
		states.JUMPING:
			move(delta)
			if is_on_ledge(): enter_on_ledge_state()
			exit_jump_state()
		states.FALLING:
			move(delta)
			if is_on_ledge(): enter_on_ledge_state()
			exit_falling_state()
		states.WALL_RUNNING:
			move(delta)
			exit_wallrun_state()
		states.WALL_JUMPING:
			move(delta)
			exit_wallrun_state()

func move(delta):
	velocity = calculate_move_velocity(velocity, get_move_direction(), current_up_speed, delta)
	set_facing()
	velocity = move_and_slide(velocity,FLOOR_NORMAL,true)

func get_move_direction():
	var movement = Vector2.ZERO
	match actualState:
		states.IDLE, states.WALKING, states.RUNNING, states.CROUCHED, states.CROUCH_WALK:
			movement.x = get_x_movement()
			movement = check_jump_input(movement)
			return movement
		states.JUMPING:
			if jump_direction:
				var force = get_x_movement()
				movement.x = jump_direction + (jump_force * force)
			else: movement.x = 0
			return movement
		states.FALLING:
			if priorState == states.ON_LEDGE:
				movement.x = 0
			elif jump_direction:
				var force = get_x_movement()
				movement.x = jump_direction + (jump_force * force)
			elif priorState == states.JUMPING or priorState == states.WALL_RUNNING:
				movement.x = 0
			else: movement.x = get_x_movement()
			return movement
		states.CLIMBING_DOWN, states.CLIMBING_UP:
			movement.y = get_y_movement()
			current_up_speed = climb_speed
			can_jump = true
			movement = check_jump_input(movement)
			return movement
		states.WALL_RUNNING:
			movement.y = -1.0 if is_on_floor() and can_wallrun else 0.0
			current_up_speed = wall_speed
			can_jump = true
			movement = check_jump_input(movement)
			return movement
		states.WALL_JUMPING:
			current_up_speed = jump_speed
			movement.x = last_wall.get_climbable_vector().x
			return movement
	return Vector2.ZERO

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

func get_y_movement():
	return Input.get_action_strength("climb_down") - Input.get_action_strength("climb_up")

func calculate_move_velocity(linear_velocity, direction, up_speed, delta):
	var out = linear_velocity
	out.x = current_speed * direction.x
	out.y += gravity * delta
	if direction.y != 0:
		if !slide_down: out.y = up_speed * direction.y
	elif actualState == states.CLIMBING_DOWN or actualState == states.CLIMBING_UP:
		out.y = 0
	return out

func set_movement_state():
	if is_on_floor():
		if is_stationary():
			enter_idle_state()
			return
		else:
			match current_speed:
				speed:
					enter_walking_state()
				run_speed:
					enter_running_state()
	else:
		if velocity.y < 0: enter_jump_state(velocity)
		if velocity.y > 0: enter_falling_state()

func enter_idle_state():
	set_state(states.IDLE, actualState)

func enter_walking_state():
	set_state(states.WALKING, actualState)

func enter_running_state():
	set_state(states.RUNNING, actualState)

func enter_crouch_state():
	if velocity.x != 0: 
		set_state(states.CROUCH_WALK, actualState)
	else: set_state(states.CROUCHED, actualState)

func exit_crouch_state():
	if is_running:
		current_speed = run_speed
	else: 
		current_speed = speed
	set_movement_state()

func enter_on_ledge_state():
	set_state(states.ON_LEDGE, actualState)
	velocity = Vector2.ZERO

func enter_jump_state(movement):
	set_state(states.JUMPING, actualState)
	movement.x = get_x_movement()
	jump_direction = movement.x
	movement.y = - 1.0
	can_jump = false
	prior_speed = current_speed
	current_up_speed = jump_speed
	jumpTimer.start()
	enable_ray_casts(true)
	return movement

func exit_jump_state():
	if velocity.y > 0: enter_falling_state()

func enter_falling_state():
	set_state(states.FALLING, actualState)
	enable_ray_casts(true)

func exit_falling_state():
	if is_on_floor():
		current_speed = prior_speed
		jump_direction = null
		can_grab_ledge = false
		enter_idle_state()
		enable_ray_casts(false)
		if last_wall: can_wallrun_check(last_wall)

func enter_climb_state(state):
	current_up_speed = climb_speed
	set_state(state, actualState)
	is_going_to_climb = true
	last_ladder.set_platform_collision(false)

func exit_climb_state():
	if is_on_floor():
		slide_down = false
		set_state(states.IDLE, actualState)

func enter_wallrun_state():
	current_up_speed = wall_speed
	set_state(states.WALL_RUNNING, actualState)

func exit_wallrun_state():
	if velocity.y > 0: enter_falling_state()

func enter_wall_jump_state(movement):
	set_state(states.WALL_JUMPING, actualState)
	movement.x = last_wall.get_climbable_vector().x
	jump_direction = movement.x
	movement.y = - 1.0
	can_jump = false
	prior_speed = current_speed
	current_up_speed = wall_jump_speed
	jumpTimer.start()
	set_facing()
	return movement

func is_stationary():
	return true if velocity == Vector2.ZERO else false

func is_on_ledge():
	if can_grab_ledge and bottomLeftRC.is_colliding() and !topLeftRC.is_colliding():
		print("Ledge à esquerda")
		return true

	if can_grab_ledge and bottomRightRC.is_colliding() and !topRightRC.is_colliding():
		print("Ledge à direita")
		return true
	
	return false

func move_to_ladder():
	if is_going_to_climb and position.x != last_ladder.position.x:
		tween.interpolate_property(self,"position",Vector2(position.x,position.y),Vector2(last_ladder.position.x,position.y),0.1,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		tween.start()
	else: is_going_to_climb = false

func check_jump_input(movement = Vector2.ZERO):
	if Input.is_action_pressed("jump") and can_jump:
		if actualState == states.WALL_RUNNING:
			movement = enter_wall_jump_state(movement)
		else:
			movement = enter_jump_state(movement)
	return movement

func check_climb_input():
	if can_climb and Input.is_action_just_pressed("climb_up"):
		enter_climb_state(states.CLIMBING_UP)
		last_ladder.set_platform_collision(true)
	elif can_climb and Input.is_action_just_pressed("climb_down"):
		if actualState == states.CLIMBING_DOWN and !tapTimer.is_stopped(): slide_down = true
		tapTimer.start()
		enter_climb_state(states.CLIMBING_DOWN)
	elif can_wallrun and Input.is_action_just_pressed("climb_up"):
		enter_wallrun_state()
	elif actualState == states.ON_LEDGE and Input.is_action_just_pressed("climb_down"):
		can_grab_ledge = false
		enter_falling_state()

func check_speed_input():
	if Input.is_action_just_pressed("dash") and is_on_floor() and actualState != states.CROUCHED:
		if actualState == states.CROUCH_WALK:
			exit_crouch_state()
		else:
			if is_running:
				is_running = false
				current_speed = speed
				set_movement_state()
			else:
				is_running = true
				current_speed = run_speed
				set_movement_state()

func check_crouch_input():
	if Input.is_action_just_pressed("crouch") and is_on_floor() and actualState != states.JUMPING and actualState != states.FALLING and actualState != states.CLIMBING_DOWN and actualState != states.CLIMBING_UP and actualState != states.WALL_JUMPING and actualState != states.WALL_RUNNING:
		if actualState == states.CROUCHED or actualState == states.CROUCH_WALK:
			exit_crouch_state()
		else: 
			current_speed = crouch_speed
			enter_crouch_state()

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

func can_wallrun_check(area):
	can_wallrun = false
	if is_on_floor() and facing == Vector2.LEFT and area.get_climbable_vector() == Vector2.RIGHT and position.x >= area.get_global_position().x:
			can_wallrun = true
			last_wall = area
	if is_on_floor() and facing == Vector2.RIGHT and area.get_climbable_vector() == Vector2.LEFT and position.x <= area.get_global_position().x:
			can_wallrun = true
			last_wall = area

func can_grab_check(area):
	can_grab_ledge = false
	if facing == Vector2.LEFT and area.get_climbable_vector() == Vector2.RIGHT and position.x >= area.get_global_position().x:
			can_grab_ledge = true
	if facing == Vector2.RIGHT and area.get_climbable_vector() == Vector2.LEFT and position.x <= area.get_global_position().x:
			can_grab_ledge = true

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

func set_facing():
	if velocity.x < 0:
		facing = Vector2.LEFT
	elif velocity.x > 0: 
		facing = Vector2.RIGHT
	set_cast_point_side()

func enable_ray_casts(value):
	if value:
		if facing == Vector2.LEFT:
			bottomLeftRC.enabled = value
			topLeftRC.enabled = value
		elif facing == Vector2.RIGHT:
			bottomRightRC.enabled = value
			topRightRC.enabled = value
	else:
		bottomLeftRC.enabled = value
		topLeftRC.enabled = value
		bottomRightRC.enabled = value
		topRightRC.enabled = value

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
		states.WALL_RUNNING:
			print("WALL_RUNNING")
		states.WALL_JUMPING:
			print("WALL_JUMPING")
		states.ON_LEDGE:
			print("ON_LEDGE")
