extends Area2D

onready var collision_shape: CollisionShape2D = $CollisionShape2D

enum layer {
	BACKGROUND,
	FOREGROUND
}

enum physics_layer {
	WORLD_LAYER_0 = 2,
	WORLD_LAYER_1 = 5,
	WORLD_LAYER_2 = 6
}

enum type {
	PARKOUR_WALL,
	HIDEOUT,
	LAYER_CHANGE
}

enum traffic {
	ENTRANCE,
	EXIT
}

export var enter_side = Vector2.ZERO
export(layer) var z_layer = layer.BACKGROUND 
export(type) var area_type = type.PARKOUR_WALL
export(traffic) var traffic_type = traffic.ENTRANCE
export(physics_layer) var world_layer = physics_layer.WORLD_LAYER_0
export var can_move = true

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

func can_enter_layer():
	return true if traffic_type == traffic.ENTRANCE else false

func can_exit_layer():
	return true if traffic_type == traffic.EXIT else false
		
