extends Node
class_name PlayerController

onready var actor = owner
onready var state_machine = get_parent()

func check_input_pressed(event,input,method = null,param = null):
	if event.is_action_pressed(input):
		call_deferred(method,param)
		return true
	return false

func check_input_released(event,input,method = null,param = null):
	if event.is_action_released(input):
		call_deferred(method,param)
		return true
	return false

func enter_crouch(_param):
	state_machine.set_state("Crouch")

func enter_crouch_walk(_param):
	state_machine.set_state("Crouch_Walk")

func exit_crouch(_param):
	state_machine.set_state("Idle")

func jump(_param):
	state_machine.set_state("Jumping")

func set_running_speed(_param):
	actor.set_current_speed(actor.states.Running.get_speed())

func enter_running(_param):
	state_machine.set_state("Running")

func set_walking_speed(_param):
	actor.set_current_speed(actor.states.Walking.get_speed())

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
	if state_machine.hideout:
		state_machine.set_hiding_state()

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
	if state_machine.ladder and !state_machine.is_player_on_ladder_top():
		state_machine.set_climb_state(state_machine.CLIMB_DIR.UP)
		return
	if state_machine.wall:
		state_machine.set_wall_run_state()
		return
	if actor.can_change_layer:
		actor.change_layer()

