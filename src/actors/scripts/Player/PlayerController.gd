extends Node
class_name PlayerController

onready var actor = owner
onready var state_machine setget set_state_machine

func set_state_machine(new_value):
	state_machine = new_value

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
	actor.set_current_speed(actor.get_previous_speed())
	state_machine.set_state("Idle")

func jump(_param):
	state_machine.set_state("Jumping")

func set_running_speed(_param):
	state_machine.set_new_speed(state_machine.states.Running.get_speed())

func enter_running(_param):
	state_machine.set_state("Running")

func set_walking_speed(_param):
	state_machine.set_new_speed(state_machine.states.Walking.get_speed())

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

func set_melee_attack(_param):
	state_machine.set_melee_attack_state()

func set_ranged_attack(_param):
	state_machine.set_ranged_attack_state()

func focus_camera_right(_param):
	actor.tween_camera(actor.transition.OUT,Vector2.RIGHT)

func focus_camera_left(_param):
	actor.tween_camera(actor.transition.OUT,Vector2.LEFT)

func return_camera_position(_param):
	actor.tween_camera(actor.transition.IN)

