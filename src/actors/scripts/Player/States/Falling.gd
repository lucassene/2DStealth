extends State

onready var player_controller = get_node("../PlayerController")

var jump_direction = 0.0
var force = 0.0

func enter(actor,delta = 0.0):
	actor.set_debug_text("FALLING")
	var movement = Vector2.ZERO
	if state_machine.get_previous_state() == "Jumping": 
		movement.x = get_x_movement()
		jump_direction = actor.states.Jumping.get_direction()
		force = actor.states.Jumping.get_force()
		movement = apply_force(movement)
	actor.move(delta,movement,Vector2.ZERO)

func handle_input(event):
	if player_controller.check_input_pressed(event,"climb_up","ladder_up"): return
	if player_controller.check_input_pressed(event,"climb_down","ladder_down"): return

func update(actor,delta):
	var movement = Vector2.ZERO
	if state_machine.get_previous_state() == "Jumping":
		movement = apply_force(movement)
	else:
		movement.x = get_x_movement()
	actor.move(delta,movement,Vector2.ZERO)
	if state_machine.ledge: state_machine.set_on_ledge_state()
	if actor.is_on_floor(): state_machine.set_state("Idle")

func exit(actor):
	actor.enable_ray_casts(actor.facing, false)

func apply_force(movement):
	var x_force = get_x_movement()
	movement.x = jump_direction + (force * x_force)
	return movement

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")