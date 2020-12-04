extends State

export var SPEED = 600
export var CHASE_OFFSET = 1000
export var SIGHT_SIZE = Vector2(2.5,2.0)
export var ESCAPE_TIME = 2.0

var enemy_controller

var last_player_position = Vector2.ZERO
var is_player_in_sight = true

var timer = 0

func enter(actor,_delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("ALERTED")
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = true
	actor.stop_animation()
	actor.set_fov_size(SIGHT_SIZE)
	last_player_position = state_machine.get_player().position
	is_player_in_sight = true
	timer = 0

func exit(actor):
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = false
	last_player_position = Vector2.ZERO
	timer = 0

func update(_actor,delta):
	if !is_player_in_sight: timer += delta
	if timer >= ESCAPE_TIME:
		state_machine.set_state("Searching")
		return
	var player_position = state_machine.get_player().position
	enemy_controller.update_movement(player_position,SPEED,delta,CHASE_OFFSET)

func on_player_detected(player):
	last_player_position = player.position
	is_player_in_sight = true
	timer = 0

func on_player_exited(player):
	last_player_position = player.position
	is_player_in_sight = false
	timer = 0

