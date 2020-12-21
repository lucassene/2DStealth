extends Node2D

onready var sprite: Sprite = $Sprite
onready var light_area: Area2D = $LightArea

signal on_player_entered()
signal on_player_exited()

func _ready():
	connect("on_player_entered",Global.player,"_on_player_in_light")
	connect("on_player_exited",Global.player,"_on_player_out_of_light")

func deactivate(value):
	sprite.visible = !value
	light_area.visible = !value
	light_area.monitoring = !value

func _on_LightArea_body_entered(_body):
	emit_signal("on_player_entered")

func _on_LightArea_body_exited(_body):
	emit_signal("on_player_exited")
