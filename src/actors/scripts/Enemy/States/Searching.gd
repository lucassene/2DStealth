extends State

export var SPEED = 100
export var SEARCH_OFFSET = 200
export var ANIM_SPEED = 2.0
export var ALERT_DELAY = 1.0
export var SEARCH_TIME = 7.0
export var SIGHT_SIZE = Vector2(1.25,1.1)

var last_player_position = Vector2.ZERO
var is_player_in_sight = false
var timer = 0

func _on_player_detected(player):
	last_player_position = player.position
	is_player_in_sight = true

func _on_player_exited(player):
	last_player_position = player.position
	is_player_in_sight = false

func enter(actor,_delta = 0.0):
	actor.set_debug_text("SEARCHING")
	actor.set_anim_speed(ANIM_SPEED)
	actor.warningSprite.visible = true
	actor.dangerSprite.visible = false
	last_player_position = state_machine.get_player().position
	actor.set_fov_size(SIGHT_SIZE)
	timer = 0

func exit(actor):
	actor.set_anim_speed(1.0)
	actor.warningSprite.visible = false
	actor.dangerSprite.visible = false
	last_player_position = Vector2.ZERO
	timer = 0

func update(actor,delta):
	timer += delta
	if timer >= ALERT_DELAY and is_player_in_sight:
		state_machine.set_state("Alerted")
		return
	if timer >= SEARCH_TIME and !is_player_in_sight:
		state_machine.set_state("Patrolling")
		return
	var dir = 0
	
	var target_position = get_target_position_with_offset(actor,state_machine.get_player())
	if is_on_destination(actor,target_position,delta):
		actor.position = target_position
		return
	else:
		dir = actor.get_next_dir()
		actor.move(delta,dir,SPEED)

func get_target_position_with_offset(actor,player):
	var pos = last_player_position.x - (SEARCH_OFFSET * actor.facing.x)
	return Vector2(pos,player.position.y)

func is_on_destination(actor,target_position,delta):
	var motion = actor.facing * SPEED * delta
	var distance_to_target = actor.position.distance_to(target_position)
	return true if motion.length() > distance_to_target else false
