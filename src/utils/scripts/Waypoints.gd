extends Node2D

var active_point_index = 0

func get_start_position():
	return get_child(0).global_position

func get_current_point_position():
	return get_child(active_point_index).global_position

func get_current_index():
	var index = active_point_index  - 1
	if index < 0: return get_child_count() - 1
	else: return index
	
func set_current_index(value):
	active_point_index = value

func get_next_index():
	return active_point_index

func get_next_point_position():
	active_point_index += 1
	if active_point_index > get_child_count() - 1:
		active_point_index = 0
	return get_current_point_position()
