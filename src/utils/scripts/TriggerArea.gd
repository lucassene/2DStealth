extends Area2D

onready var collision_shape: CollisionShape2D = $CollisionShape2D

enum layer {
	BACKGROUND,
	FOREGROUND
}

enum physics_layer {
	WORLD_LAYER_0 = 6,
	WORLD_LAYER_1 = 7
}

enum type {
	PARKOUR_WALL,
	HIDEOUT,
	LAYER_CHANGE,
}

export var enter_side = Vector2.ZERO
export(layer) var z_layer = layer.BACKGROUND 
export(type) var area_type = type.PARKOUR_WALL
export(physics_layer) var world_layer = physics_layer.WORLD_LAYER_0
export var can_move = true setget ,can_player_move
export var auto_change = false setget ,is_auto_change

signal on_player_entered(area)
signal on_player_exited(area)
signal on_can_change_layer()
signal on_player_body_exited(area)

func is_auto_change():
	return auto_change

func _on_TriggerArea_area_entered(area):
	if area.is_in_group("PlayerArea"):
		emit_signal("on_player_entered",self)

func _on_TriggerArea_area_exited(area):
	if area.is_in_group("PlayerArea"):
		emit_signal("on_player_exited",self)

func _on_TriggerArea_body_entered(body):
	if body.is_in_group("Player") and is_layer_area():
		emit_signal("on_can_change_layer")
		return

func _on_TriggerArea_body_exited(body):
	if body.is_in_group("Player"):
		emit_signal("on_player_body_exited",self)
		return

func _ready():
	connect("on_player_entered",Global.player,"_on_trigger_area_entered")
	connect("on_player_exited",Global.player,"_on_trigger_area_exited")
	connect("on_can_change_layer",Global.player,"_on_can_change_layer")
	connect("on_player_body_exited",Global.player,"_on_area_body_exited")
	
func can_player_move():
	return can_move

func get_enter_vector():
	return enter_side

func get_area_z_index():
	match z_layer:
		layer.BACKGROUND:
			return -1
		layer.FOREGROUND:
			return 3
	return 0
	
func get_area_type():
	return area_type
	
func get_area_size():
	return collision_shape.shape.get_extents().x * get_transform().get_scale().x * 2
	
func get_left_point():
	return position.x - (collision_shape.shape.get_extents().x * get_transform().get_scale().x)

func get_right_point():
	return position.x + (collision_shape.shape.get_extents().x * get_transform().get_scale().x)

func get_layer_bit():
	return world_layer

func is_layer_area():
	return true if area_type == type.LAYER_CHANGE else false

