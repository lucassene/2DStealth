extends StateMachine

var enemy_controller

var is_player_hidden = false
var is_player_in_sight = false
var is_alerted = false setget set_is_alerted
var previous_air_state setget ,get_previous_air_state

func set_is_alerted(value):
	is_alerted = value

func get_is_alerted():
	return is_alerted

func get_previous_air_state():
	return previous_air_state

func _on_player_detected():
	is_player_in_sight = true
	if states[current_state].has_method("on_player_detected"):
		states[current_state].on_player_detected()

func _on_player_contact():
	is_player_in_sight = true
	if states[current_state].has_method("on_player_contact"):
		states[current_state].on_player_contact()

func _on_player_exited():
	is_player_in_sight = false
	if states[current_state].has_method("on_player_exited"):
		states[current_state].on_player_exited()

func _on_player_unhide():
	is_player_hidden = false
	if states[current_state].has_method("on_player_unhide"):
		states[current_state].on_player_unhide()

func _on_player_hide():
	is_player_hidden = true
	if states[current_state].has_method("on_player_hide"):
		states[current_state].on_player_hide()

func initialize(first_state):
	.initialize(first_state)
	connect_to_player()
	enemy_controller = actor.get_controller()
	enemy_controller.initialize(self,actor.get_reaction_time())

func set_air_state(state):
	previous_air_state = current_state
	set_state(state)

func back_from_air():
	set_state(previous_air_state)

func is_really_not_alerted():
	if next_state == "Shooting" or next_state == "Attacking" or next_state == "Jumping":
		return true
	else: return false

func set_fov_size():
	if states[current_state].has_method("set_fov_size"):
		states[current_state].set_fov_size(actor)
	else:
		actor.set_fov_size(Vector2.ONE)

func connect_to_player():
	Global.player.connect("on_hide",self,"_on_player_hide")
	Global.player.connect("on_unhide",self,"_on_player_unhide")
