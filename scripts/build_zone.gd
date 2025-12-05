extends Area2D

@onready var sprite = $Sprite2D
var is_occupied = false

func _ready():
	# Add to group
	add_to_group("build_zones")
	
	# Set initial color
	if sprite:
		sprite.modulate = Color(1, 1, 1, 0.3)
	
	print("Build zone ready: ", name, " at: ", global_position)
