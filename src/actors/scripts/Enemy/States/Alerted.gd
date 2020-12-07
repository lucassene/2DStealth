extends State

export var SPEED = 600
export var CHASE_OFFSET = 1000
export var HIDDEN_OFFSET = 200
export var SIGHT_SIZE = Vector2(2.5,2.0)
export var ESCAPE_TIME = 5.0

var enemy_controller

var last_player_position = Vector2.ZERO
var timer = 0

func enter(actor,_delta = 0.0):
	enemy_controller = actor.get_controller()
	actor.set_debug_text("ALERTED")
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = true
	actor.stop_animation()
	actor.enter_alerted_state()
	actor.set_fov_size(SIGHT_SIZE)
	actor.rotate_sight()
	actor.on_alerted()
	last_player_position = Global.player.position
	timer = 0

func exit(actor):
	actor.on_not_alerted()
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = false
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
		enemy_controller.update_movement(last_player_position,SPEED,delta,HIDDEN_OFFSET)
	else:
		enemy_controller.update_movement(player_position,SPEED,delta,CHASE_OFFSET)
	
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


