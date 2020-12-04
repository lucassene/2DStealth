extends StateMachine

var player setget set_player,get_player
var enemy_controller

func set_player(body):
	player = body

func get_player():
	return player

func _on_player_detected():
	if states[current_state].has_method("on_player_detected"):
		states[current_state].on_player_detected(player)
	
func _on_player_contact():
	if states[current_state].has_method("on_player_contact"):
		states[current_state].on_player_contact(player)

func _on_player_exited():
	if states[current_state].has_method("on_player_exited"):
		states[current_state].on_player_exited(player)

func initialize(first_state):
	.initialize(first_state)
	set_player(actor.get_player())
	enemy_controller = actor.get_controller()
	enemy_controller.initialize(self,actor.get_reaction_time())

func set_searching_state(body):
	set_player(body)
	set_state("Searching")



