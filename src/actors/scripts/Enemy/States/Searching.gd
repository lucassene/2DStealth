extends State

export var SPEED_MODIFIER = 1 setget ,get_max_speed
export var ACCELERATION = 15
export var SEARCH_OFFSET = 200
export var ANIM_SPEED = 2.0
export var ALERT_DELAY = 1.0
export var SEARCH_TIME = 7.0
export var SIGHT_SIZE = Vector2(1.25,1.1)

var enemy_controller
var current_speed

var last_player_position = Vector2.ZERO setget set_last_player_position
var timer = 0

func get_max_speed():
	return SPEED_MODIFIER * Global.UNIT_SIZE

func set_last_player_position(value):
	last_player_position = value

func enter(actor,_delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("SEARCHING")
	actor.set_anim_speed(ANIM_SPEED)
	actor.play_animation("patrol")
	set_current_speed()
	actor.warningSprite.visible = true
	actor.dangerSprite.visible = false
	last_player_position = Global.player.position
	enemy_controller.set_facing(last_player_position,0)
	enemy_controller.set_x_speed(get_max_speed())
	if !actor.is_player_visible:
		actor.set_fov_size(SIGHT_SIZE)
	timer = 0

func exit(_actor):
	last_player_position = Vector2.ZERO
	timer = 0

func update(_actor,delta):
	timer += delta
	if timer >= ALERT_DELAY and state_machine.is_player_in_sight and !state_machine.is_player_hidden:
		state_machine.set_state("Alerted")
		return
	if timer >= SEARCH_TIME and !state_machine.is_player_in_sight or timer >= SEARCH_TIME and state_machine.is_player_hidden:
		state_machine.set_state("Patrolling")
		return
	if current_speed > get_max_speed():
		enemy_controller.update_movement(last_player_position,get_slowing_speed(get_max_speed()),delta,SEARCH_OFFSET)
	else:
		enemy_controller.update_movement(last_player_position,get_current_speed(),delta,SEARCH_OFFSET)

func set_current_speed():
	if enemy_controller.get_x_speed() != get_max_speed():
		current_speed = enemy_controller.get_x_speed()
	else:
		current_speed = 0

func get_current_speed():
	current_speed += ACCELERATION
	current_speed = min(current_speed,get_max_speed())
	return current_speed

func get_slowing_speed(speed):
	current_speed = lerp(current_speed,speed,0.15)
	return current_speed

func set_fov_size(actor):
	actor.set_fov_size(SIGHT_SIZE)

func on_player_detected():
	last_player_position = Global.player.position
	if state_machine.get_previous_state() == "Alerted" and !state_machine.is_player_hidden:
		state_machine.set_state("Alerted")

func on_player_exited():
	if !state_machine.is_player_hidden: 
		last_player_position = Global.player.position

func on_player_contact():
	if !state_machine.is_player_hidden: 
		last_player_position = Global.player.position

func on_player_hide():
	if state_machine.is_player_in_sight:
		last_player_position = Global.player.position

func on_player_unhide():
	if state_machine.is_player_in_sight:
		last_player_position = Global.player.position

