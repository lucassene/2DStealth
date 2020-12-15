extends Area2D

onready var collision: CollisionShape2D = $CollisionShape2D
onready var platform = get_node(platform_path)

export var platform_path = NodePath()
export var DISTANCE_THRESHOLD = 16

signal on_player_entered(area)
signal on_player_exited()

func _on_Ladder_area_entered(area):
	if area.is_in_group("PlayerArea"):
		emit_signal("on_player_entered",self)

func _on_Ladder_area_exited(area):
	if area.is_in_group("PlayerArea"):
		emit_signal("on_player_exited")

func _ready():
	connect("on_player_entered",Global.player,"_on_ladder_area_entered")
	connect("on_player_exited",Global.player,"_on_ladder_area_exited")

func set_platform_collision(to_bool):
	platform.set_collision(to_bool)

func get_top_position():
	return position.y - (scale.y * Global.UNIT_SIZE) + DISTANCE_THRESHOLD

