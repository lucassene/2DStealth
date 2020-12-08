extends State

var player_controller

func enter(actor,_delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("IDLE")
	state_machine.reset_gravity()

func handle_input(event):
	if player_controller.check_input_pressed(event,"crouch","enter_crouch"): return
	if player_controller.check_input_pressed(event,"jump","jump"): return
	if player_controller.check_input_pressed(event,"climb_up","on_key_up"): return
	if player_controller.check_input_pressed(event,"climb_down","ladder_down"): return
	if player_controller.check_input_pressed(event,"interact","enter_hide"): return
	if player_controller.check_input_pressed(event,"melee","set_melee_attack"): return
	if player_controller.check_input_pressed(event,"shoot","set_ranged_attack"): return
	if player_controller.check_input_pressed(event,"dash","set_running_speed"): return
	if player_controller.check_input_released(event,"dash","set_walking_speed"): return

func update(actor,delta):
	var dir = Vector2.ZERO
	actor.move(delta,dir,state_machine.get_x_speed())
	if get_x_movement() != 0: state_machine.set_movement_state()
	if actor.velocity.y > 0: state_machine.set_state("Falling")

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
