extends State

export var SPEED_MODIFIER = 4 setget ,get_speed

var player_controller

func get_speed():
	return SPEED_MODIFIER * Global.UNIT_SIZE

func enter(actor,_delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("WALKING")
	state_machine.set_x_speed(get_speed())

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
	var was_on_floor = actor.is_on_floor()
	var dir = Vector2.ZERO
	dir.x = get_x_movement()
	if dir.x == 0.0:
		state_machine.set_state("Idle")
	else:
		var velocity = actor.move(delta,dir,get_speed())
		if !actor.is_on_floor() and was_on_floor:
			actor.start_coyote_time()
		elif velocity.y > 0.0 and !actor.is_on_floor(): state_machine.set_state("Falling")

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")


