extends State

var player_controller

export var SPEED = 1150.0 setget ,get_speed
export var FORCE = 0.25 setget ,get_force

var direction = 0.0 setget set_direction,get_direction

func get_speed():
	return SPEED

func get_force():
	return FORCE

func set_direction(new_value):
	direction = new_value

func get_direction():
	return direction

func enter(actor, delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("JUMPING")
	var movement = Vector2(0.0,-1.0)
	if state_machine.get_previous_state() != "Wall_Run": 
		movement.x = get_x_movement()
	elif state_machine.wall:
		movement.x = state_machine.wall.get_enter_vector().x * -1.0
	elif state_machine.ledge:
		movement.x = state_machine.ledge.get_enter_vector().x * -1.0
	direction = movement.x
	actor.set_current_y_speed(SPEED)
	actor.enable_ray_casts(movement if movement.x != 0 else actor.facing, true)
	movement = apply_force(movement)
	actor.move(delta,movement,Vector2.ZERO)

func handle_input(event):
	if player_controller.check_input_pressed(event,"climb_up","ladder_up"): return
	if player_controller.check_input_pressed(event,"climb_down","ladder_down"): return
	if player_controller.check_input_pressed(event,"dash","set_running_speed"): return
	if player_controller.check_input_released(event,"dash","set_walking_speed"): return

func update(actor,delta):
	var movement = Vector2.ZERO
	movement = apply_force(movement)
	var velocity = actor.move(delta,movement,Vector2.ZERO)
	if velocity.y > 0: state_machine.set_state("Falling")
	if state_machine.ledge: state_machine.set_on_ledge_state()

func apply_force(movement):
	var x_force = get_x_movement()
	movement.x = direction + (FORCE * x_force)
	return movement

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

