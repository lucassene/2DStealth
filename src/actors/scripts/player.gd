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
onready var positionTween = $PositionTween
onready var fadeTween = $FadeTween
onready var cameraTween = $CameraTween
onready var bottomRightRC: RayCast2D = $bottomRightRC
onready var bottomLeftRC: RayCast2D = $bottomLeftRC2
onready var topRightRC: RayCast2D = $topRightRC
onready var topLeftRC: RayCast2D = $topLeftRC
onready var sprite = $sprite
onready var camera = $Camera2D

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
	ON_LEDGE,
	CLIMBING_LEDGE,
	LEDGE_JUMP,
	HIDING
}

enum transition {
	IN,
	OUT
}

var can_jump = true
var jump_pressed = false
var can_climb = false
var slide_down = false
var can_wallrun = false
var can_grab_ledge = false
var can_hide = false
var can_change_layer = false
var change_layer_pressed = false
var can_shoot = true
var can_attack = true

var current_speed = run_speed
var prior_speed = current_speed
var current_up_speed = jump_speed

var is_running = true
var is_crouched = false
var is_going_to_climb = false
var is_going_to_ledge = false
var is_going_to_hide = false
var climbing_ledge = false
var is_camera_focusing = false
var prior_to_crouch_state

var last_ladder: Area2D 
var last_wall: Area2D
var last_ledge: Area2D
var last_hideout: Area2D
var actual_layer = 0
var last_layer: Area2D

var jump_direction
var facing = Vector2.RIGHT
var sprite_size

func _ready():
	sprite_size = sprite.get_texture().get_size().x
	set_state(states.IDLE,states.IDLE)
	jumpTimer.wait_time = jump_time

func _process(_delta):
	# DEV ONLY
	set_time_scale()
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
		states.CLIMBING_LEDGE:
			label.text = "CLIMBING LEDGE"
		states.LEDGE_JUMP:
			label.text = "LEDGE JUMP"
		states.HIDING:
			label.text = "HIDING"
	label.text = String(facing.x) + " | " + label.text
	
func set_time_scale():
	if Input.is_action_just_pressed("time_stop"):
		Engine.time_scale = 0.0
	if Input.is_action_just_pressed("slow-motion"):
		Engine.time_scale = 0.25
	if Input.is_action_just_pressed("normal_time"):
		Engine.time_scale = 1.0

func _on_PlayerArea_area_entered(area):
	if area.get_groups():
		match area.get_groups()[0]:
			"Climbable":
				last_ladder = area
				can_climb = true
			"TriggerArea":
				match area.get_area_type():
					area.type.PARKOUR_WALL:
						can_wallrun_check(area)
					area.type.HIDEOUT:
						last_hideout = area
						can_hide = true
					area.type.LAYER_CHANGE:
						can_change_layer = true
						last_layer = area
						exit_layer(last_layer.get_layer_bit())
			"Ledge":
				if actualState != states.LEDGE_JUMP: can_grab_check(area)
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
			"TriggerArea":
				match area.get_area_type():
					area.type.PARKOUR_WALL:
						can_wallrun = false
					area.type.HIDEOUT:
						if actualState == states.HIDING: exit_hiding_state()
						can_hide = false
					area.type.LAYER_CHANGE:
						can_change_layer = false
						if !change_layer_pressed: exit_layer(last_layer.get_layer_bit())
						change_layer_pressed = false
			"Ledge":
				can_grab_ledge = false

func _on_meleeArea_body_entered(body):
	if body.is_in_group("Enemy"):
		body.on_hit()

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"meleeSlash":
			can_attack = true
		"jump_to_hide":
			can_jump = true
			is_going_to_hide = false
			if actualState != states.HIDING:
				enter_hiding_state()
			else:
				exit_hiding_state()

func _on_jumpTimer_timeout():
	can_jump = true

func _on_PositionTween_completed(_object, _key):
	is_going_to_climb = false
	if can_wallrun_check(last_wall):
		enter_wallrun_state()
		return	
	if is_going_to_ledge:
		enter_on_ledge_state()
		is_going_to_ledge = false
		return
	if actualState == states.CLIMBING_LEDGE and climbing_ledge:
		tween_position(Vector2(position.x + sprite_size * 1.25 * facing.x,position.y),0.25)
		climbing_ledge = false
		return
	elif actualState == states.CLIMBING_LEDGE and !climbing_ledge:
		exit_climb_ledge_state()
		return
	if can_hide and actualState != states.HIDING:
		is_going_to_hide = true
		enter_hiding_state()
		return

func _physics_process(delta):
	match(actualState):
		states.CLIMBING_UP, states.CLIMBING_DOWN:
			move(delta, Vector2.ZERO)
			exit_climb_state()
		states.CROUCHED:
			move(delta, snap_vector if !jump_pressed else Vector2.ZERO)
			exit_crouch_state()
		states.CROUCH_WALK:
			move(delta, snap_vector if !jump_pressed else Vector2.ZERO)
			exit_crouch_walk_state()
		states.IDLE, states.WALKING, states.RUNNING:
			if !is_going_to_hide: move(delta, snap_vector if !jump_pressed else Vector2.ZERO)
			set_movement_state()
		states.JUMPING:
			move(delta, Vector2.ZERO)
			move_to_ledge()
			exit_jump_state()
		states.FALLING:
			move(delta)
			move_to_ledge()
			exit_falling_state()
		states.WALL_RUNNING:
			move(delta, Vector2.ZERO)
			exit_wallrun_state()
		states.WALL_JUMPING:
			move(delta, Vector2.ZERO)
			move_to_ledge()
			exit_wallrun_state()
		states.ON_LEDGE:
			check_jump_input(Vector2.ZERO)
		states.LEDGE_JUMP:
			move(delta, Vector2.ZERO)
			exit_ledge_jump_state()
		states.HIDING:
			if !is_going_to_hide and !is_camera_focusing and last_hideout.can_move: move(delta, snap_vector if !jump_pressed else Vector2.ZERO)
			if z_index == 0: exit_hiding_state()

func move(delta, vector = snap_vector):
	velocity = calculate_move_velocity(velocity, get_move_direction(), current_up_speed, delta)
	set_facing()
	velocity = move_and_slide_with_snap(velocity, vector, FLOOR_NORMAL, true, 4, SLOPE_THRESHOLD)

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
			movement.y = -1.0 if is_on_floor() else 0.0
			current_up_speed = wall_speed
			can_jump = true
			movement = check_jump_input(movement)
			return movement
		states.WALL_JUMPING:
			current_up_speed = jump_speed
			movement.x = last_wall.get_enter_vector().x * -1.0
			return movement
		states.LEDGE_JUMP:
			if jump_pressed: movement.y = - 1.0
			jump_pressed = false
			current_up_speed = jump_speed
			movement.x = last_ledge.get_enter_vector().x * - 1.0
			return movement
		states.HIDING:
			movement.x = get_x_movement()
			movement = check_jump_input(movement)
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
	set_speed(crouch_speed)
	is_crouched = true
	if velocity.x != 0: 
		set_state(states.CROUCH_WALK, actualState)
	else: set_state(states.CROUCHED, actualState)

func exit_crouch_state(crouch_pressed = false):
	if actualState == states.CROUCHED and velocity.x != 0:
		enter_crouch_walk_state()
	if crouch_pressed:
		if is_running:
			set_speed(run_speed)
		else: 
			set_speed(speed)
		set_movement_state()
		is_crouched = false

func enter_crouch_walk_state():
	set_state(states.CROUCH_WALK, actualState)

func exit_crouch_walk_state():
	if actualState == states.CROUCH_WALK and velocity.x == 0:
		enter_crouch_state()

func enter_on_ledge_state():
	can_jump = true
	jump_pressed = false
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
	enable_ray_casts(movement if movement.x != 0 else facing, true)
	return movement

func exit_jump_state():
	if velocity.y > 0: 
		enter_falling_state()
		jump_pressed = false

func enter_falling_state():
	set_state(states.FALLING, actualState)
	enable_ray_casts(facing, true)

func exit_falling_state():
	if is_on_floor():
		if is_crouched: 
			enter_crouch_state()
		else:
			set_speed(prior_speed)
			jump_direction = null
			enter_idle_state()
		enable_ray_casts(facing, false)

func enter_climb_state(state):
	current_up_speed = climb_speed
	set_state(state, actualState)
	is_going_to_climb = true
	last_ladder.set_platform_collision(false)
	move_to_ladder()

func exit_climb_state():
	if is_on_floor():
		slide_down = false
		last_ladder.set_platform_collision(true)
		set_state(states.IDLE, actualState)

func enter_wallrun_state():
	current_up_speed = wall_speed
	set_state(states.WALL_RUNNING, actualState)

func exit_wallrun_state():
	if velocity.y > 0: enter_falling_state()

func enter_climb_ledge_state():
	set_state(states.CLIMBING_LEDGE, actualState)

func exit_climb_ledge_state():
	enter_idle_state()

func enter_ledge_jump_state(movement):
	set_state(states.LEDGE_JUMP, actualState)
	movement.x = last_ledge.get_enter_vector().x * -1.0
	jump_direction = movement.x
	movement.y = - 1.0
	can_jump = false
	prior_speed = current_speed
	current_up_speed = jump_speed
	jumpTimer.start()
	set_facing()
	enable_ray_casts(movement,true)
	return movement

func exit_ledge_jump_state():
	if velocity.y > 0:
		enter_falling_state()

func enter_wall_jump_state(movement):
	set_state(states.WALL_JUMPING, actualState)
	movement.x = last_wall.get_enter_vector().x * -1.0
	jump_direction = movement.x
	movement.y = - 1.0
	can_jump = false
	jump_pressed = false
	prior_speed = current_speed
	current_up_speed = wall_jump_speed
	jumpTimer.start()
	set_facing()
	enable_ray_casts(movement, true)
	return movement

func enter_hiding_state():
	is_going_to_hide = false
	can_hide = false
	set_speed(crouch_speed)
	set_collision_mask_bit(1,false)
	set_state(states.HIDING, actualState)

func exit_hiding_state():
	tween_fade(transition.IN)
	can_hide = true
	z_index = 1
	set_collision_mask_bit(1,true)
	if priorState == states.CROUCHED or priorState == states.CROUCH_WALK:
		enter_crouch_state()
	else: 
		if is_running:
			set_speed(run_speed)
		else: 
			set_speed(speed)
		set_movement_state()

func is_stationary():
	return true if velocity == Vector2.ZERO else false

func is_on_ledge():
	if can_grab_ledge and bottomLeftRC.is_colliding() and !topLeftRC.is_colliding():
		is_going_to_ledge = true
		return true
	if can_grab_ledge and bottomRightRC.is_colliding() and !topRightRC.is_colliding():
		is_going_to_ledge = true
		return true
	return false

func move_to_ledge():
	if is_on_ledge() and can_grab_ledge and is_going_to_ledge:
		can_grab_ledge = false
		tween_position(Vector2(get_area_offset_position(last_ledge,sprite_size/2),position.y),0.1)

func get_area_offset_position(area, offset = 0):
	return area.get_global_position().x + (offset * facing.x * -1)

func move_to_wall():
	tween_position(Vector2(get_area_offset_position(last_wall),position.y),0.1)

func move_to_ladder():
	if is_going_to_climb and position.x != last_ladder.position.x:
		tween_position(Vector2(last_ladder.position.x,position.y),0.2)
	else: is_going_to_climb = false

func move_over_ledge():
	enter_climb_ledge_state()
	tween_position(Vector2(position.x,last_ledge.get_global_position().y),0.3)

func move_to_hide():
	z_index = last_hideout.get_area_z_index()
	is_going_to_hide = true
	if !last_hideout.can_move:
		tween_position(Vector2(last_hideout.position.x,position.y),0.2)
		tween_fade(transition.OUT)
	elif position.x < last_hideout.get_left_point():
		tween_position(Vector2(last_hideout.get_left_point() + sprite_size/1.5,position.y),0.2)
		tween_fade(transition.OUT)
	elif position.x > last_hideout.get_right_point():
		tween_position(Vector2(last_hideout.get_right_point() - sprite_size/1.5,position.y),0.2)
		tween_fade(transition.OUT)
	else:
		tween_fade(transition.OUT)
		can_jump = false
		animationPlayer.play("jump_to_hide")

func _unhandled_input(event):
	check_shoot_input(event)
	check_melee_input(event)
	check_climb_input(event)
	check_speed_input(event)
	check_crouch_input(event)
	check_interact_input(event)
	check_camera_input(event)
	check_move_input(event)

func check_interact_input(event):
	if event.is_action_pressed("interact"):
		if actualState == states.HIDING:
			if last_hideout.can_move:
				animationPlayer.play_backwards("jump_to_hide")
			else:
				exit_hiding_state()
			return
		if can_hide: 
			move_to_hide()

func check_jump_input(movement = Vector2.ZERO):
	if Input.is_action_pressed("jump") and can_jump:
		if actualState == states.WALL_RUNNING:
			movement = enter_wall_jump_state(movement)
		elif actualState == states.ON_LEDGE:
			movement = enter_ledge_jump_state(movement)
		elif is_on_floor() and actualState == states.HIDING:
			set_speed(prior_speed)
			movement = enter_jump_state(movement)
		elif is_on_floor() or actualState == states.CLIMBING_DOWN or actualState == states.CLIMBING_UP: 
				movement = enter_jump_state(movement)
		jump_pressed = true
	return movement

func check_climb_input(event):
	if event.is_action_pressed("climb_up"):
		if can_climb:
			enter_climb_state(states.CLIMBING_UP)
			last_ladder.set_platform_collision(true)
			return
		if actualState == states.ON_LEDGE:
			climbing_ledge = true
			move_over_ledge()
			return
		if can_wallrun_check(last_wall):
			is_going_to_climb = true
			move_to_wall()
			return
		if can_change_layer:
			change_layer_pressed = true
			enter_layer(last_layer.get_layer_bit())
			return
	
	if event.is_action_pressed("climb_down"):
		if can_climb:
			if actualState == states.CLIMBING_DOWN and !tapTimer.is_stopped(): slide_down = true
			tapTimer.start()
			enter_climb_state(states.CLIMBING_DOWN)
		elif actualState == states.ON_LEDGE:
			can_grab_ledge = false
			enter_falling_state()

func check_speed_input(event):
	if event.is_action_pressed("dash") and is_on_floor() and actualState != states.CROUCHED:
		if actualState == states.CROUCH_WALK:
			exit_crouch_state()
		else:
			if is_running:
				is_running = false
				current_speed = speed
				set_movement_state()
				return
			else:
				is_running = true
				current_speed = run_speed
				set_movement_state()

func check_crouch_input(event):
	if event.is_action_pressed("crouch") and is_on_floor() and actualState != states.JUMPING and actualState != states.FALLING and actualState != states.CLIMBING_DOWN and actualState != states.CLIMBING_UP and actualState != states.WALL_JUMPING and actualState != states.WALL_RUNNING and actualState != states.HIDING:
		if actualState == states.CROUCHED or actualState == states.CROUCH_WALK:
			exit_crouch_state(true)
		else: 
			enter_crouch_state()

func check_shoot_input(event):
	if event.is_action_pressed("shoot") and can_shoot:
		can_shoot = false
		var projectile_instance = projectile.instance()
		projectile_instance.position = castPoint.get_global_transform().get_origin()
		projectile_instance.shoot(castOrigin.rotation_degrees)
		projectile_instance.origin = "Player"
		get_parent().add_child(projectile_instance)
		yield(get_tree().create_timer(rate_of_fire),"timeout")
		can_shoot = true

func check_melee_input(event):
	if event.is_action_pressed("slash") and can_attack:
		can_attack = false
		animationPlayer.play("meleeSlash")

func check_camera_input(event):
	if event.is_action_pressed("camera_focus") and actualState == states.HIDING:
		tween_camera(transition.OUT)
		return
	if event.is_action_released("camera_focus") and actualState == states.HIDING:
		tween_camera(transition.IN)
		return

func check_move_input(event):
	if actualState == states.HIDING and last_hideout and !last_hideout.can_move and !is_camera_focusing:
		if event.is_action_pressed("move_right"):
			facing = Vector2.RIGHT
		if event.is_action_pressed("move_left"):
			facing = Vector2.LEFT
		set_cast_point_side()

func can_wallrun_check(area):
	can_wallrun = false
	if area:
		if is_on_floor() and facing == Vector2.LEFT and area.get_enter_vector() == Vector2.LEFT and position.x >= get_area_offset_position(area):
				can_wallrun = true
				last_wall = area
		if is_on_floor() and facing == Vector2.RIGHT and area.get_enter_vector() == Vector2.RIGHT and position.x <= get_area_offset_position(area):
				can_wallrun = true
				last_wall = area
	return can_wallrun

func can_grab_check(area):
	can_grab_ledge = false
	if facing == Vector2.LEFT and area.get_enter_vector() == Vector2.LEFT and position.x >= get_area_offset_position(area,sprite_size/2):
			can_grab_ledge = true
	if facing == Vector2.RIGHT and area.get_enter_vector() == Vector2.RIGHT and position.x <= get_area_offset_position(area,sprite_size/2):
			can_grab_ledge = true
	last_ledge = area

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

func tween_position(new_position,time):
	positionTween.interpolate_property(self,"position",Vector2(position.x,position.y),new_position,time,positionTween.TRANS_LINEAR,positionTween.EASE_IN_OUT)
	positionTween.start()

func tween_fade(fade):
	var fade_in = Color(1.0,1.0,1.0,1.0)
	var fade_out = Color(0.33,0.33,0.33,1.0)
	if fade == transition.IN:
		fadeTween.interpolate_property(self,"modulate",fade_out,fade_in,0.3,positionTween.TRANS_LINEAR,positionTween.EASE_IN_OUT)
	else:
		fadeTween.interpolate_property(self,"modulate",fade_in,fade_out,0.3,positionTween.TRANS_LINEAR,positionTween.EASE_IN_OUT)
	fadeTween.start()

func tween_camera(trans):
	var cam_offset = Vector2.ZERO
	if trans == transition.OUT:
		if facing == Vector2.LEFT:
			cam_offset = Vector2(-400,0)
		else: 
			cam_offset = Vector2(400,0)
		is_camera_focusing = true
	else:
		is_camera_focusing = false
	cameraTween.interpolate_property(camera,"offset",camera.offset,cam_offset,0.4,cameraTween.TRANS_LINEAR,cameraTween.EASE_OUT_IN)
	cameraTween.start()

func on_hit():
	print("Foi atingido!")

func is_hidden():
	return true if actualState == states.HIDING else false

func set_facing():
	if velocity.x < 0:
		facing = Vector2.LEFT
	elif velocity.x > 0: 
		facing = Vector2.RIGHT
	set_cast_point_side()

func set_speed(new_speed):
	prior_speed = current_speed
	current_speed = new_speed

func enter_layer(layer_bit):
	if last_layer.can_enter_layer():
		actual_layer = layer_bit
		set_collision_mask_bit(layer_bit,true)

func exit_layer(layer_bit):
	var can_exit = false
	if last_layer.can_exit_layer() and !is_on_floor():
		can_exit = true
	elif last_layer.can_enter_layer():
		can_exit = true
	if can_exit:
		actual_layer = 0
		set_collision_mask_bit(layer_bit,false)

func enable_ray_casts(dir, value):
	if value:
		if dir.x < 0:
			bottomLeftRC.enabled = value
			topLeftRC.enabled = value
		elif dir.x > 0:
			bottomRightRC.enabled = value
			topRightRC.enabled = value
	else:
		bottomLeftRC.enabled = value
		topLeftRC.enabled = value
		bottomRightRC.enabled = value
		topRightRC.enabled = value

# DEV ONLY
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
