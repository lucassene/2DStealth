extends State

export var SPEED_MODIFIER = 1.5 setget ,get_speed
export var TAP_TIME = 0.2
export var SLIDE_FACTOR = 3.0
export var ENTER_UP_DISTANCE = 30
export var ENTER_DOWN_DISTANCE = 100

var player_controller

var slide_down = false
var fall = false
var tap_timer = 0
var is_entering = true
var start_pos = Vector2.ZERO

func get_speed():
	return SPEED_MODIFIER * Global.UNIT_HEIGHT

func enter(actor,_delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("CLIMBING")
	start_pos = actor.global_position
	is_entering = true
	
func handle_input(event):
	if is_entering: return
	if player_controller.check_input_pressed(event,"jump","jump"): return
	if player_controller.check_input_pressed(event,"shoot","set_ranged_attack"): return
	if player_controller.check_input_pressed(event,"climb_up","set_ladder_collision",true): return
	if player_controller.check_input_pressed(event,"climb_down","set_ladder_collision",false):
		set_slide()
		return
	if player_controller.check_input_pressed(event,"move_right","update_facing",Vector2.RIGHT):
		set_fall()
		return
	if player_controller.check_input_pressed(event,"move_left","update_facing",Vector2.LEFT):
		set_fall()
		return

func update(actor,delta):
	tap_timer += delta
	var dir = Vector2.ZERO
	if is_entering:
		var new_pos = actor.global_position
		if state_machine.current_climb_dir == state_machine.CLIMB_DIR.DOWN:
			dir.y = 1.0
			if new_pos.y - ENTER_DOWN_DISTANCE > start_pos.y:
				is_entering = false
		else:
			dir.y = -1.0
			if new_pos.y + ENTER_UP_DISTANCE < start_pos.y:
				is_entering = false
	else:
		dir.y = get_y_movement()
	if slide_down: dir.y = SLIDE_FACTOR
	actor.move(delta,dir,state_machine.get_x_speed(),get_speed(),Vector2.ZERO)
	if fall: 
		state_machine.set_state("Falling")
		return
	if actor.is_on_floor(): state_machine.set_state("Idle")

func exit(_actor):
	slide_down = false
	fall = false

func get_y_movement():
	return Input.get_action_strength("climb_down") - Input.get_action_strength("climb_up")

func set_slide():
	if tap_timer > TAP_TIME: 
		slide_down = false
	else: 
		slide_down = true
	tap_timer = 0

func set_fall():
	if tap_timer > TAP_TIME:
		fall = false
	else:
		fall = true
	tap_timer = 0
