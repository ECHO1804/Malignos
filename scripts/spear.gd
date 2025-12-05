extends CharacterBody2D

var target = null
var speed = 300
var bulletDamage = 0
var tower = null  # Reference to the tower that shot this bullet
var target_position = Vector2.ZERO  # Last known position of target

func _ready():
	# Set a timer to automatically destroy the bullet if it doesn't hit anything
	var destroy_timer = Timer.new()
	destroy_timer.wait_time = 5.0  # Destroy after 5 seconds
	destroy_timer.timeout.connect(_on_destroy_timer_timeout)
	add_child(destroy_timer)
	destroy_timer.start()

func set_target(enemy):
	target = enemy
	if is_instance_valid(target):
		target_position = target.global_position
	else:
		target = null

func _physics_process(delta: float) -> void:
	# Update target position if target still exists
	if is_instance_valid(target):
		target_position = target.global_position
	
	# If we have no target or target position, queue free
	if target_position == Vector2.ZERO:
		queue_free()
		return
	
	# Move towards the target position
	var direction = global_position.direction_to(target_position)
	velocity = direction * speed
	
	# Look at the target
	look_at(target_position)
	
	# Move and check for collisions
	move_and_slide()
	
	# Check if we're close to the target position
	if global_position.distance_to(target_position) < 10:
		# We've reached the target position, check for enemies
		check_for_enemies()
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Check if we hit an enemy
	if body.is_in_group("enemy"):
		# Damage the enemy
		if body.has_method("take_damage"):
			body.take_damage(bulletDamage)
		
		# Destroy the bullet
		queue_free()

func check_for_enemies():
	# Check for enemies near the impact point
	var area = $Area2D  # Make sure your bullet has an Area2D
	if area:
		var overlapping_bodies = area.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body.is_in_group("enemy") and body.has_method("take_damage"):
				body.take_damage(bulletDamage)
				break  # Only hit one enemy

func _on_destroy_timer_timeout():
	# Destroy bullet after timeout
	queue_free()
