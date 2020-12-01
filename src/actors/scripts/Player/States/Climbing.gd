extends State

export var SPEED = 250.0 setget ,get_speed
export var TAP_TIME = 0.2
export var SLIDE_FACTOR = 3.0

var player_controller

var slide_down = false
var tap_timer = 0

func get_speed():
	return SPEED

func enter(actor,_delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("CLIMBING")
	actor.set_current_y_speed(SPEED)
	
func handle_input(event):
	if player_controller.check_input_pressed(event,"jump","jump"): return
	if player_controller.check_input_pressed(event,"shoot","set_ranged_attack"): return
	if player_controller.check_input_pressed(event,"climb_up","set_ladder_collision",true): return
	if player_controller.check_input_pressed(event,"climb_down","set_ladder_collision",false):
		if tap_timer > TAP_TIME: 
			slide_down = false
		else: 
			slide_down = true
		tap_timer = 0
		return

func update(actor,delta):
	tap_timer += delta
	var dir = Vector2.ZERO
	dir.y = get_y_movement()
	dir.x = get_x_movement()
	if slide_down: dir.y = SLIDE_FACTOR
	actor.move(delta,dir,Vector2.ZERO)
	if dir.x != 0: state_machine.set_state("Falling")
	if actor.is_on_floor(): state_machine.set_state("Idle")

func exit(_actor):
	slide_down = false

func get_x_movement():
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

func get_y_movement():
	return Input.get_action_strength("climb_down") - Input.get_action_strength("climb_up")


