extends State

onready var player_controller = get_node("../PlayerController")

export var SPEED = 200 setget ,get_speed

func get_speed():
	return SPEED

func enter(actor,_delta = 0.0):
	actor.set_debug_text("CROUCH WALK")
	actor.set_current_speed(SPEED)

func handle_input(event):
	if player_controller.check_input_pressed(event,"dash","enter_running"): return
	if player_controller.check_input_pressed(event,"crouch","enter_walking"): return
	if player_controller.check_input_pressed(event,"jump","jump"): return
	if player_controller.check_input_pressed(event,"interact","enter_hide"): return

func update(actor,delta):
	var dir = Vector2.ZERO
	dir.x = get_x_movement()
	if dir.x == 0.0:
		state_machine.set_state("Crouch")
	else:
		actor.move(delta,dir)

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

