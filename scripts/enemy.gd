extends CharacterBody2D

@export var speed = 20
var Health = 10
var max_health = 50
@onready var health_bar = $enemy_health
@onready var sprite = $Range_panel/AnimatedSprite2D

var last_position = Vector2.ZERO
var current_direction = 1

func _ready():
	# Store initial position
	last_position = global_position
	
	# Initialize health values
	max_health = Health
	
	# Initialize health bar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = Health

func _process(delta):
	# Store current position before moving
	var previous_position = global_position
	
	# Move along path - THIS IS WHERE SPEED IS USED
	get_parent().progress += speed * delta
	
	# Get current position after moving
	var current_position = global_position
	
	# Calculate movement direction
	if current_position.x < previous_position.x:
		# Moving left
		current_direction = -1
		flip_sprite(true)
	elif current_position.x > previous_position.x:
		# Moving right
		current_direction = 1
		flip_sprite(false)
	
	# Check if dead
	if Health <= 0:
		die()

func flip_sprite(flip_left: bool):
	if sprite:
		sprite.flip_h = flip_left
	else:
		find_and_flip_sprite(flip_left)

func find_and_flip_sprite(flip_left: bool):
	var found_sprite = find_sprite_node(self)
	if found_sprite:
		found_sprite.flip_h = flip_left

func find_sprite_node(node: Node):
	for child in node.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			return child
		var result = find_sprite_node(child)
		if result:
			return result
	return null

func take_damage(amount):
	Health -= amount
	Health = max(0, Health)
	
	# Update health bar after taking damage
	if health_bar:
		health_bar.value = Health
		if health_bar.has_method("update_health_display"):
			health_bar.update_health_display()
	
	if Health <= 0:
		die()

func die():
	# Give gold reward when enemy dies
	var main = get_tree().get_root().get_node("Main")
	if main and main.has_method("enemy_killed"):
		main.enemy_killed()
	
	queue_free()
