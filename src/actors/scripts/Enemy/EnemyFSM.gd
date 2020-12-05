extends StateMachine

var enemy_controller

var is_player_hidden = false
var is_player_in_sight = false

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

func connect_to_player():
	Global.player.connect("on_hide",self,"_on_player_hide")
	Global.player.connect("on_unhide",self,"_on_player_unhide")
