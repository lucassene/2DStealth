extends State

onready var player_controller = get_node("../PlayerController")

func enter(actor,_delta = 0.0):
	actor.set_debug_text("CROUCH")

func handle_input(event):
	if player_controller.check_input_pressed(event,"crouch","exit_crouch"): return
	if player_controller.check_input_pressed(event,"jump","jump"): return
	if player_controller.check_input_pressed(event,"interact","enter_hide"): return

func update(_actor,_delta):
	if get_x_movement() != 0: 
		state_machine.set_state("Crouch_Walk")

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

func get_y_movement():
	return Input.get_action_strength("jump")

