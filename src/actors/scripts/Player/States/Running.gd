extends State

export var SPEED_MODIFIER = 8 setget ,get_max_speed
export var ACCELERATION = 30
export var INTERACT_SIZE = 1.5

var player_controller
var current_speed
var previous_dir = Vector2.ZERO

func get_max_speed():
	return SPEED_MODIFIER * Global.UNIT_SIZE

func enter(actor,_delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("RUNNING")
	actor.update_interact_area(INTERACT_SIZE)
	current_speed = state_machine.get_x_speed()
	previous_dir = Vector2.ZERO
	state_machine.set_x_speed(get_max_speed())

func handle_input(event):
	if player_controller.check_input_pressed(event,"crouch","enter_crouch_walk"): return
	if player_controller.check_input_pressed(event,"jump","jump"): return
	if player_controller.check_input_pressed(event,"climb_up","on_key_up"): return
	if player_controller.check_input_pressed(event,"climb_down","ladder_down"): return
	if player_controller.check_input_pressed(event,"melee","set_melee_attack"): return
	if player_controller.check_input_pressed(event,"shoot","set_ranged_attack"): return
	if player_controller.check_input_pressed(event,"interact","interact"): return
	if player_controller.check_input_released(event,"dash","enter_walking"): return

func update(actor,delta):
	var was_on_floor = actor.is_on_floor()
	var dir = Vector2.ZERO
	dir.x = get_x_movement()
	if dir.x == 0.0:
		var velocity = actor.move(delta,previous_dir,get_stopping_speed())
		if velocity.x == 0.0:
			state_machine.set_state("Idle")
	else:
		var velocity = actor.move(delta,dir,get_current_speed())
		if !actor.is_on_floor() and was_on_floor:
			actor.start_coyote_time()
		elif velocity.y > 0.0 and !actor.is_on_floor(): state_machine.set_state("Falling")

func get_x_movement():
	var new_dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if new_dir != previous_dir.x and new_dir != 0.0:
		previous_dir.x = new_dir
	return new_dir

func get_current_speed():
	current_speed += ACCELERATION
	current_speed = min(current_speed,get_max_speed())
	return current_speed

func get_stopping_speed():
	current_speed = lerp(current_speed,0.0,0.1)
	return current_speed
