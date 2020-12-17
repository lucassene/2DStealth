extends Node
class_name PlayerController

onready var actor = owner
onready var state_machine setget set_state_machine
onready var action_state_machine setget set_action_state_machine

signal on_jump_released(actor)
signal on_wallrun_released(actor)

func set_state_machine(new_value):
	state_machine = new_value
	
func set_action_state_machine(new_value):
	action_state_machine = new_value

func check_input_pressed(event,input,method = null,param = null):
	if event.is_action_pressed(input):
		if method: call_deferred(method,param)
		return true
	return false

func check_input_released(event,input,method = null,param = null):
	if event.is_action_released(input):
		if method: call_deferred(method,param)
		return true
	return false

func enter_crouch(_param):
	state_machine.set_state("Crouch")

func enter_crouch_walk(_param):
	state_machine.set_state("Crouch_Walk")

func exit_crouch(_param):
	state_machine.set_x_speed(state_machine.states.Walking.get_max_speed())
	state_machine.set_state("Idle")

func jump(_param):
	if actor.is_on_floor() or actor.is_on_coyote_time() or state_machine.ladder:
		state_machine.set_state("Jumping")
		return
	elif state_machine.get_wall_to_run():
		state_machine.set_state("Jumping")

func wall_jump(_param):
	if state_machine.wall and actor.check_pos_to_wall(state_machine.wall):
		state_machine.set_state("Jumping")
		actor.move_to_area(state_machine.wall)

func stop_jump(_param):
	emit_signal("on_jump_released",actor)

func set_running_speed(_param):
	state_machine.set_x_speed(state_machine.states.Running.get_max_speed())

func enter_running(_param):
	state_machine.set_state("Running")

func set_walking_speed(_param):
	state_machine.set_x_speed(state_machine.states.Walking.get_max_speed())

func enter_walking(_param):
	state_machine.set_state("Walking")

func ladder_up(_param):
	if state_machine.ladder and !state_machine.is_player_on_ladder_top():
		state_machine.set_climb_state(state_machine.CLIMB_DIR.UP)

func ladder_down(_param):
	if state_machine.ladder:
		state_machine.set_climb_state(state_machine.CLIMB_DIR.DOWN)

func set_ladder_collision(param):
	state_machine.ladder.set_platform_collision(param)

func enter_hide(_param):
	if state_machine.hideout and actor.can_hide():
		actor.enter_hiding_state()

func exit_hide(_param):
	if state_machine.hideout.can_player_move():
		actor.animation_player.play_backwards("jump_to_hide")
		return
	else:
		state_machine.set_state("Idle")

func enter_wall_run(_param):
	state_machine.set_wall_run_state()

func move_over_ledge(_param):
	state_machine.move_over_ledge()

func enter_falling(_param):
	state_machine.set_state("Falling")

func on_key_up(_param):
	if state_machine.ladder:
		if !state_machine.is_player_on_ladder_top():
			state_machine.set_climb_state(state_machine.CLIMB_DIR.UP)
			return
	var wall = state_machine.get_wall_to_run()
	if wall:
		state_machine.set_wall_run_state(wall)
		return
	if actor.can_change_layer:
		actor.set_change_layer_pressed(true)
		actor.change_layer(true)

func stop_wall_run(_param):
	emit_signal("on_wallrun_released",actor)

func set_melee_attack(_param):
	action_state_machine.set_melee_attack_state()

func set_ranged_attack(_param):
	action_state_machine.set_ranged_attack_state()

func focus_camera_right(_param):
	actor.tween_camera(actor.transition.OUT,Vector2.RIGHT)

func focus_camera_left(_param):
	actor.tween_camera(actor.transition.OUT,Vector2.LEFT)

func return_camera_position(_param):
	actor.tween_camera(actor.transition.IN)
	
func update_facing(param):
	actor.set_facing(param)

