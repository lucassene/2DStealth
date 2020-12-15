extends State

export var JUMP_BUFFER = 0.1
export var HEIGHT_THRESHOLD = 100

var player_controller

var jump_direction = 0.0
var force = 0.0
var timer = 0
var jump_pressed = false

func _on_jump_pressed():
	jump_pressed = true

func _on_wall_jump_ocurred():
	jump_pressed = false

func enter(actor,delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("FALLING")
	actor.enable_ray_casts(true)
	var movement = Vector2.ZERO
	if state_machine.get_previous_state() == "Jumping" or state_machine.get_previous_state() == "Climbing": 
		movement.x = get_x_movement()
		jump_direction = movement.x
		if state_machine.get_previous_state() == "Jumping":
			jump_direction = state_machine.states.Jumping.get_direction()
		force = state_machine.states.Jumping.get_force()
		movement = apply_force(movement)
	actor.move(delta,movement,state_machine.get_x_speed(),state_machine.get_y_speed(),Vector2.ZERO)

func handle_input(event):
	if player_controller.check_input_pressed(event,"jump"): 
		timer = 0
		jump_pressed = true
		return
	if player_controller.check_input_pressed(event,"climb_up","on_key_up"): return
	if player_controller.check_input_pressed(event,"climb_down","ladder_down"): return
	if player_controller.check_input_pressed(event,"melee","set_melee_attack"): return
	if player_controller.check_input_pressed(event,"shoot","set_ranged_attack"): return
	if player_controller.check_input_pressed(event,"dash","set_running_speed"): return
	if player_controller.check_input_released(event,"dash","set_walking_speed"): return

func update(actor,delta):
	timer += delta
	var movement = Vector2.ZERO
	if state_machine.get_previous_state() == "Jumping" or state_machine.get_previous_state() == "Climbing":
		movement = apply_force(movement)
	else:
		movement.x = get_x_movement()
	actor.move(delta,movement,state_machine.get_x_speed(),state_machine.get_y_speed(),Vector2.ZERO)
	if state_machine.current_ledge:
		state_machine.set_on_ledge_state()
		return
	if state_machine.wall and jump_pressed and actor.can_wall_jump(state_machine.wall) and is_above_height(actor):
		state_machine.set_state("Jumping")
		return
	if jump_pressed and actor.is_on_floor():
		if timer < JUMP_BUFFER:
			state_machine.set_state("Jumping")
			return
		else: state_machine.set_state("Idle")
	elif actor.is_on_floor(): 
		state_machine.set_state("Idle")

func exit(actor):
	timer = 0
	jump_pressed = false
	actor.enable_ray_casts(false)

func is_above_height(actor):
	if actor.global_position.y < Global.FLOOR_HEIGHT - HEIGHT_THRESHOLD:
		return true
	return false

func apply_force(movement):
	var x_force = get_x_movement()
	movement.x = jump_direction + (force * x_force)
	return movement

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
