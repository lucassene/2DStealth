extends StateMachine

var player setget set_player,get_player

func set_player(body):
	player = body

func get_player():
	return player

func set_searching_state(body):
	set_player(body)
	set_state("Searching")



