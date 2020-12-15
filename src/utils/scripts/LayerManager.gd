extends TileMap

export var layer_bit = 1

func _on_change_layer():
	print("called")
	set_collision_layer_bit(layer_bit,true)
	print(get_collision_layer_bit(layer_bit))

func _ready():
	Global.player.connect("on_change_layer",self,"_on_change_layer")

