extends StaticBody2D

onready var collision_shape = $CollisionShape2D

func set_collision(to_bool):
	set_collision_mask_bit(0,to_bool)
	set_collision_layer_bit(4,to_bool)
