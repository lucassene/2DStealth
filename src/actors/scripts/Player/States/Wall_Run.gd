extends State

export var SPEED_MODIFIER = 6 setget ,get_speed
export var SLIDE_DOWN_MODIFIER = 3.0 setget ,get_slide_speed
export var MIN_HEIGHT_MODIFIER = 0.50 setget ,get_min_height

var player_controller
var start_y_pos
var can_cancel = false
var current_speed
var is_entering = true

func get_speed():
	return SPEED_MODIFIER * Global.UNIT_HEIGHT

func get_slide_speed():
	return SLIDE_DOWN_MODIFIER * Global.UNIT_HEIGHT

func get_min_height():
	return MIN_HEIGHT_MODIFIER * Global.UNIT_HEIGHT

func _on_wallrun_released(actor):
	var pos_difference = start_y_pos - actor.position.y
	if pos_difference < get_min_height():
		current_speed = get_slide_speed()
		can_cancel = true

func _on_player_arrived(actor,delta):
	var movement = Vector2(0.0,-1.0)
	actor.move(delta,movement,state_machine.get_x_speed(),current_speed,Vector2.ZERO)

func enter(actor, delta = 0.0):
	player_controller = actor.get_player_controller()
	actor.set_debug_text("WALL RUN")
	start_y_pos = actor.position.y
	can_cancel = false
	current_speed = get_speed()
	actor.connect("on_arrived_to_target",self,"_on_player_arrived",[actor,delta])

func handle_input(event):
	if player_controller.check_input_pressed(event,"jump","jump"): return
	if player_controller.check_input_released(event,"climb_up","stop_wall_run"): return

func update(actor,delta):
	var pos_difference = start_y_pos - actor.position.y
	if can_cancel and pos_difference > get_min_height():
		actor.velocity.y = -get_slide_speed()
		state_machine.set_state("Wall_Slide")
		return
	var movement = Vector2.ZERO
	var velocity = actor.move(delta,movement,state_machine.get_x_speed(),current_speed,Vector2.ZERO)
	if velocity.y > 0: 
		state_machine.set_state("Wall_Slide")
		return
	if actor.is_on_floor():
		state_machine.set_state("Idle")
		return

func exit(actor):
	actor.disconnect("on_arrived_to_target",self,"_on_player_arrived")



