extends State

export var SPEED_MODIFIER = 4 setget ,get_max_speed
export var ACCELERATION = 30

var player_controller
var current_speed
var previous_dir = Vector2.ZERO

func get_max_speed():
	return SPEED_MODIFIER * Global.UNIT_SIZE

func enter(actor,_delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("WALKING")
	set_current_speed()
	previous_dir = Vector2.ZERO
	state_machine.set_x_speed(get_max_speed())

func handle_input(event):
	if player_controller.check_input_pressed(event,"dash","enter_running"): return
	if player_controller.check_input_pressed(event,"crouch","enter_crouch_walk"): return
	if player_controller.check_input_pressed(event,"jump","jump"): return
	if player_controller.check_input_pressed(event,"climb_up","on_key_up"): return
	if player_controller.check_input_pressed(event,"climb_down","ladder_down"): return
	if player_controller.check_input_pressed(event,"melee","set_melee_attack"): return
	if player_controller.check_input_pressed(event,"shoot","set_ranged_attack"): return
	if player_controller.check_input_pressed(event,"interact","enter_hide"): return

func update(actor,delta):
	var velocity = Vector2.ZERO
	var was_on_floor = actor.is_on_floor()
	var dir = Vector2.ZERO
	dir.x = get_x_movement()
	if dir.x == 0.0:
		velocity = actor.move(delta,previous_dir,get_slowing_speed(0.0))
		if velocity.x == 0.0:
			state_machine.set_state("Idle")
			return
	elif current_speed > get_max_speed():
		velocity = actor.move(delta,dir,get_slowing_speed(get_max_speed()))
	else:
		velocity = actor.move(delta,dir,get_current_speed())
	if !actor.is_on_floor() and was_on_floor:
		actor.start_coyote_time()
	elif velocity.y > 0.0 and !actor.is_on_floor(): state_machine.set_state("Falling")

func get_x_movement():
	var new_dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if new_dir != previous_dir.x and new_dir != 0.0:
		previous_dir.x = new_dir
	return new_dir

func set_current_speed():
	if state_machine.get_x_speed() != get_max_speed():
		current_speed = state_machine.get_x_speed()
	else:
		current_speed = 0

func get_current_speed():
	current_speed += ACCELERATION
	current_speed = min(current_speed,get_max_speed())
	return current_speed

func get_slowing_speed(speed):
	current_speed = lerp(current_speed,speed,0.25)
	return current_speed

