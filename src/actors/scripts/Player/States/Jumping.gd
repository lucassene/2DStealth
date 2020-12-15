extends State

var player_controller

export var FORCE = 0.3 setget ,get_force
export var MAX_HEIGHT_MODIFIER = 1.25 setget ,get_max_height
export var MIN_HEIGHT_MODIFIER = 0.50 setget ,get_min_height
export var JUMP_DURATION = 0.5
export var HEIGHT_THRESHOLD = 60

signal on_jump_pressed()
signal on_wall_jump_ocurred()

var direction = 0.0 setget set_direction,get_direction
var jump_pressed = false

var max_jump_speed
var min_jump_speed
var current_jump_speed

func get_force():
	return FORCE

func get_max_height():
	return MAX_HEIGHT_MODIFIER * Global.UNIT_HEIGHT

func get_min_height():
	return MIN_HEIGHT_MODIFIER * Global.UNIT_HEIGHT

func set_direction(new_value):
	direction = new_value

func get_direction():
	return direction
	
func _on_jump_released(actor):
	if actor.velocity.y < -min_jump_speed:
		state_machine.set_y_speed(min_jump_speed)
		actor.velocity.y = -min_jump_speed
		current_jump_speed = min_jump_speed

func enter(actor, delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("JUMPING")
	set_gravity(actor)
	actor.stop_coyote_time()
	actor.enable_ray_casts(true)
	jump_pressed = false
	var movement = Vector2(0.0,-1.0)
	if state_machine.wall and !actor.is_on_floor():
		movement.x = state_machine.wall.get_enter_vector().x * -1.0
	else:
		movement.x = get_x_movement()
	jump(actor,delta,movement)

func handle_input(event):
	if player_controller.check_input_pressed(event,"jump"): 
		jump_pressed = true
		emit_signal("on_jump_pressed")
		return
	if player_controller.check_input_pressed(event,"climb_up","on_key_up"): return
	if player_controller.check_input_pressed(event,"climb_down","ladder_down"): return
	if player_controller.check_input_pressed(event,"melee","set_melee_attack"): return
	if player_controller.check_input_pressed(event,"shoot","set_ranged_attack"): return
	if player_controller.check_input_pressed(event,"dash","set_running_speed"): return
	if player_controller.check_input_released(event,"jump","stop_jump"): return
	if player_controller.check_input_released(event,"dash","set_walking_speed"): return

func update(actor,delta):
	print(state_machine.wall)
	var movement = Vector2.ZERO
	movement = apply_force(movement)
	var velocity = actor.move(delta,movement,state_machine.get_x_speed(),current_jump_speed,Vector2.ZERO)
	if velocity.y > 0: 
		state_machine.set_state("Falling")
		return
	if state_machine.current_ledge: 
		state_machine.set_on_ledge_state()
		return
	if state_machine.wall and jump_pressed and actor.can_wall_jump(state_machine.wall) and is_above_height(actor):
		movement.y = -1.0
		movement.x = state_machine.wall.get_enter_vector().x * -1.0
		jump(actor,delta,movement)
		emit_signal("on_wall_jump_ocurred")
		return

func exit(actor):
	jump_pressed = false
	actor.enable_ray_casts(false)

func jump(actor,delta,movement):
	direction = movement.x
	movement = apply_force(movement)
	actor.move(delta,movement,state_machine.get_x_speed(),current_jump_speed,Vector2.ZERO)

func apply_force(movement):
	var x_force = get_x_movement()
	movement.x = direction + (FORCE * x_force)
	return movement

func is_above_height(actor):
	if actor.global_position.y < Global.FLOOR_HEIGHT - HEIGHT_THRESHOLD:
		return true
	return false

func set_gravity(actor):
	actor.set_gravity(2 * get_max_height() / pow(JUMP_DURATION,2))
	max_jump_speed = sqrt(2 * actor.get_gravity() * get_max_height())
	min_jump_speed = sqrt(2 * actor.get_gravity() * get_min_height())
	current_jump_speed = max_jump_speed

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
