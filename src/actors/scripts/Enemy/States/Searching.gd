extends State

export var SPEED = 100
export var SEARCH_OFFSET = 200
export var ANIM_SPEED = 2.0
export var ALERT_DELAY = 1.0
export var SEARCH_TIME = 7.0
export var SIGHT_SIZE = Vector2(1.25,1.1)

var enemy_controller

var last_player_position = Vector2.ZERO setget set_last_player_position
var is_player_in_sight = true
var timer = 0

func set_last_player_position(value):
	last_player_position = value

func enter(actor,_delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("SEARCHING")
	actor.set_anim_speed(ANIM_SPEED)
	actor.play_animation("patrol")
	actor.warningSprite.visible = true
	actor.dangerSprite.visible = false
	last_player_position = state_machine.get_player().position
	enemy_controller.set_facing(last_player_position,0)
	actor.set_fov_size(SIGHT_SIZE)
	if state_machine.get_previous_state() == "Alerted":
		is_player_in_sight = false
	timer = 0

func exit(actor):
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = false
	last_player_position = Vector2.ZERO
	timer = 0

func update(_actor,delta):
	timer += delta
	if timer >= ALERT_DELAY and is_player_in_sight:
		state_machine.set_state("Alerted")
		return
	if timer >= SEARCH_TIME and !is_player_in_sight:
		state_machine.set_state("Patrolling")
		return
	enemy_controller.update_movement(last_player_position,SPEED,delta,SEARCH_OFFSET)
	
func on_player_detected(player):
	last_player_position = player.position
	is_player_in_sight = true
	if state_machine.get_previous_state() == "Alerted":
		state_machine.set_state("Alerted")

func on_player_exited(player):
	last_player_position = player.position
	is_player_in_sight = false

func on_player_contact(player):
	last_player_position = player.position
	is_player_in_sight = true
