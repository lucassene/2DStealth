extends Area2D

onready var platform: StaticBody2D = $OneWayPlatform
onready var collision: CollisionShape2D = $CollisionShape2D

signal on_player_entered(area)
signal on_player_exited()

func _on_Ladder_body_entered(body):
	if body.is_in_group("Player"):
		emit_signal("on_player_entered",self)

func _on_Ladder_body_exited(body):
	if body.is_in_group("Player"):
		emit_signal("on_player_exited")

func _ready():
	connect("on_player_entered",Global.player,"_on_ladder_area_entered")
	connect("on_player_exited",Global.player,"_on_ladder_area_exited")

func set_platform_collision(to_bool):
	platform.set_collision_mask_bit(0,to_bool)
	platform.set_collision_layer_bit(4,to_bool)
