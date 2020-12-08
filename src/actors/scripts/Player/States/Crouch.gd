extends State

var player_controller

func enter(actor,_delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("CROUCH")
	state_machine.set_x_speed(state_machine.states.Crouch_Walk.get_speed())

func handle_input(event):
	if player_controller.check_input_pressed(event,"crouch","exit_crouch"): return
	if player_controller.check_input_pressed(event,"jump","jump"): return
	if player_controller.check_input_pressed(event,"melee","set_melee_attack"): return
	if player_controller.check_input_pressed(event,"shoot","set_ranged_attack"): return
	if player_controller.check_input_pressed(event,"interact","enter_hide"): return

func update(_actor,_delta):
	if get_x_movement() != 0: 
		state_machine.set_state("Crouch_Walk")

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

func get_y_movement():
	return Input.get_action_strength("jump")

