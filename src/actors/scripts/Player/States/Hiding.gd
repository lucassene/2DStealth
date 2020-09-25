extends State

onready var player_controller = get_node("../PlayerController")

func enter(actor, _delta=0):
	actor.set_debug_text("HIDING")
	actor.set_current_speed(actor.states.Crouch_Walk.SPEED)

func handle_input(event):
	if player_controller.check_input_pressed(event,"dash","enter_running"): return
	if player_controller.check_input_pressed(event,"interact","exit_hide"): return
	if player_controller.check_input_pressed(event,"climb_up","enter_wall_run"): return

func update(actor,delta):
	var dir = Vector2.ZERO
	dir.x = get_x_movement()
	actor.move(delta,dir)
	if state_machine.hideout and !state_machine.hideout.can_move and get_x_movement() != 0:
		state_machine.set_movement_state()

func exit(actor):
	actor.exit_hiding_state()

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

