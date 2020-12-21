extends Node2D

onready var sprite: AnimatedSprite = $AnimatedSprite
onready var switch_area: Area2D = $SwitchArea
onready var light = get_node(light_path)

export var light_path = NodePath()

var activated = true

signal on_player_entered(switch)
signal on_player_exited()

func _ready():
	connect("on_player_entered",Global.player,"_on_player_can_switch")
	connect("on_player_exited",Global.player,"_on_player_cannot_switch")

func toggle_switch():
	activated = !activated
	if activated:
		sprite.animation = "on"
		light.deactivate(false)
	else:
		sprite.animation = "off"
		light.deactivate(true)

func _on_SwitchArea_body_entered(_body):
	emit_signal("on_player_entered",self)

func _on_SwitchArea_body_exited(_body):
	emit_signal("on_player_exited")
