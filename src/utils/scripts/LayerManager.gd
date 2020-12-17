extends TileMap

export var layer_bit = 1

func _on_change_layer(value,bit):
	if bit == layer_bit:
		set_collision_layer_bit(layer_bit,value)

func _ready():
	Global.player.connect("on_change_layer",self,"_on_change_layer")

