extends Area2D

export var enter_vector: Vector2 setget ,get_enter_vector

signal on_player_entered(area)
signal on_player_exited()

func get_enter_vector():
	return enter_vector

func _on_Ledge_body_entered(body):
	if body.is_in_group("Player"):
		if body.get_facing().x == enter_vector.x:
			emit_signal("on_player_entered",self)

func _on_Ledge_body_exited(body):
	if body.is_in_group("Player"):
		emit_signal("on_player_exited")

func _ready():
	connect("on_player_entered",Global.player,"_on_ledge_area_entered")
	connect("on_player_exited",Global.player,"_on_ledge_area_exited")
