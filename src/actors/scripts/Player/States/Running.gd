extends State

onready var player_controller = get_node("../PlayerController")

export var SPEED = 1000.0 setget ,get_speed

func get_speed():
	return SPEED

func enter(actor,_delta = 0.0):
	actor.set_debug_text("RUNNING")
	actor.set_current_speed(SPEED)

func handle_input(event):
	if player_controller.check_input_pressed(event,"crouch","enter_crouch_walk"): return
	if player_controller.check_input_pressed(event,"jump","jump"): return
	if player_controller.check_input_pressed(event,"climb_up","on_key_up"): return
	if player_controller.check_input_pressed(event,"climb_down","ladder_down"): return
	if player_controller.check_input_pressed(event,"interact","enter_hide"): return
	if player_controller.check_input_released(event,"dash","enter_walking"): return

func update(actor,delta):
	var dir = Vector2.ZERO
	dir.x = get_x_movement()
	if dir.x == 0.0:
		state_machine.set_state("Idle")
	else:
		var velocity = actor.move(delta,dir)
		if velocity.y > 0.0: state_machine.set_state("Falling")

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

