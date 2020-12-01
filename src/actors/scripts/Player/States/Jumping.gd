extends State

var player_controller

export var SPEED = 1150.0 setget ,get_speed
export var FORCE = 0.4 setget ,get_force

var direction = 0.0 setget set_direction,get_direction
var can_wall_jump = false

func get_speed():
	return SPEED

func get_force():
	return FORCE

func set_direction(new_value):
	direction = new_value

func get_direction():
	return direction

func _on_Player_on_wall_jump_ready():
	can_wall_jump = true

func enter(actor, delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("JUMPING")
	var movement = Vector2(0.0,-1.0)
	if state_machine.get_previous_state() != "Wall_Run" and state_machine.get_previous_state() != "Jumping": 
		movement.x = get_x_movement()
	elif state_machine.wall:
		movement.x = state_machine.wall.get_enter_vector().x * -1.0
	elif state_machine.ledge:
		movement.x = state_machine.ledge.get_enter_vector().x * -1.0
	jump(actor,delta,movement)

func handle_input(event):
	if player_controller.check_input_pressed(event,"jump","jump"): return
	if player_controller.check_input_pressed(event,"climb_up","on_key_up"): return
	if player_controller.check_input_pressed(event,"climb_down","ladder_down"): return
	if player_controller.check_input_pressed(event,"melee","set_melee_attack"): return
	if player_controller.check_input_pressed(event,"shoot","set_ranged_attack"): return
	if player_controller.check_input_pressed(event,"dash","set_running_speed"): return
	if player_controller.check_input_released(event,"dash","set_walking_speed"): return

func update(actor,delta):
	var movement = Vector2.ZERO
	if !can_wall_jump:
		movement = apply_force(movement)
		var velocity = actor.move(delta,movement,Vector2.ZERO)
		if velocity.y > 0: state_machine.set_state("Falling")
		if state_machine.ledge: state_machine.set_on_ledge_state()
	elif state_machine.wall:
		movement.y = -1.0
		movement.x = state_machine.wall.get_enter_vector().x * -1.0
		jump(actor,delta,movement)
		can_wall_jump = false
		return

func jump(actor,delta,movement):
	direction = movement.x
	actor.set_current_y_speed(SPEED)
	actor.enable_ray_casts(movement if movement.x != 0 else actor.facing, true)
	movement = apply_force(movement)
	actor.move(delta,movement,Vector2.ZERO)

func apply_force(movement):
	var x_force = get_x_movement()
	movement.x = direction + (FORCE * x_force)
	return movement

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

