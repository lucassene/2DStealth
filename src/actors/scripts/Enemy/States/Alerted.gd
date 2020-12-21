extends State

export var SPEED_MODIFIER = 8 setget ,get_max_speed
export var ACCELERATION = 30
export var CHASE_OFFSET = 1000
export var HIDDEN_OFFSET = 200
export var SIGHT_SIZE = Vector2(2.5,2.0)
export var ESCAPE_TIME = 5.0

var enemy_controller

var last_player_position = Vector2.ZERO
var timer = 0
var current_speed

func get_max_speed():
	return SPEED_MODIFIER * Global.UNIT_SIZE

func enter(actor,_delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("ALERTED")
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = true
	actor.stop_animation()
	actor.enter_alerted_state()
	actor.set_fov_size(SIGHT_SIZE)
	actor.rotate_sight()
	current_speed = enemy_controller.get_x_speed()
	enemy_controller.set_x_speed(get_max_speed())
	last_player_position = Global.player.position
	timer = 0

func exit(actor):
	if !state_machine.is_really_not_alerted(): 
		actor.exit_alerted_state()
	last_player_position = Vector2.ZERO
	timer = 0

func update(actor,delta):
	actor.rotate_sight()
	if !state_machine.is_player_in_sight or state_machine.is_player_hidden: timer += delta
	if timer >= ESCAPE_TIME:
		state_machine.set_state("Searching")
		return
	var player_position = Global.player.position
	if state_machine.is_player_hidden:
		enemy_controller.update_movement(last_player_position,get_current_speed(),delta,HIDDEN_OFFSET)
	else:
		enemy_controller.update_movement(player_position,get_current_speed(),delta,CHASE_OFFSET)

func get_current_speed():
	current_speed += ACCELERATION
	current_speed = min(current_speed,get_max_speed())
	return current_speed

func set_fov_size(actor):
	actor.set_fov_size(SIGHT_SIZE)

func on_player_detected():
	last_player_position = Global.player.position
	timer = 0

func on_player_exited():
	last_player_position = Global.player.position
	timer = 0

func on_player_hide():
	last_player_position = Global.player.position
	timer = 0

func on_player_unhide():
	if state_machine.is_player_in_sight: timer = 0


