extends Area2D

onready var platform: StaticBody2D = $OneWayPlatform

func set_platform_collision(to_bool):
	platform.set_collision_mask_bit(0,to_bool)
	platform.set_collision_layer_bit(4,to_bool)

