extends State

export var TAP_TIME = 0.2

var player_controller
var current_speed
var tap_timer = 0
var is_leaving = false

func enter(actor, _delta=0):
	player_controller = actor.get_player_controller()
	actor.set_collision_mask_bit(1,false)
	actor.set_debug_text("HIDING")
	is_leaving = false
	current_speed = state_machine.states.Crouch_Walk.get_max_speed()
	state_machine.set_x_speed(current_speed)

func handle_input(event):
	if player_controller.check_input_pressed(event,"dash","enter_running"): return
	if player_controller.check_input_pressed(event,"move_right"):
		set_leaving()
		return
	if player_controller.check_input_pressed(event,"move_left"):
		set_leaving()
		return
	if player_controller.check_input_pressed(event,"jump","jump"): return
	if player_controller.check_input_pressed(event,"interact","exit_hide"): return
	if player_controller.check_input_pressed(event,"climb_up","enter_wall_run"): return
	if player_controller.check_input_pressed(event,"camera_focus_right","focus_camera_right"): return
	if player_controller.check_input_pressed(event,"camera_focus_left","focus_camera_left"): return
	if player_controller.check_input_released(event,"camera_focus_right","return_camera_position"): return
	if player_controller.check_input_released(event,"camera_focus_left","return_camera_position"): return

func update(actor,delta):
	tap_timer += delta
	if is_leaving and !state_machine.hideout.can_move:
		state_machine.set_state("Walking")
		return
	elif state_machine.hideout.can_move:
		var dir = Vector2.ZERO
		dir.x = get_x_movement()
		actor.move(delta,dir,current_speed)

func exit(actor):
	state_machine.reset_x_speed()
	actor.set_collision_mask_bit(1,true)
	actor.exit_hiding_state()

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

func set_leaving():
	if tap_timer > TAP_TIME: 
		is_leaving = false
	else: 
		is_leaving = true
	tap_timer = 0

