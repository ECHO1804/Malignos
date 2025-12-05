extends ProgressBar

@onready var enemy = get_parent()

func _ready() -> void:
	# Wait a frame to ensure enemy is fully initialized
	await get_tree().process_frame
	
	# Initialize health bar values
	if enemy and enemy.has_meta("Health"):
		# Try to get max_health from enemy
		if enemy.has_meta("max_health"):
			max_value = enemy.get_meta("max_health")
		else:
			max_value = enemy.get_meta("Health")
		
		value = enemy.get_meta("Health")

func update_health_display():
	if enemy and enemy.has_meta("Health"):
		value = enemy.get_meta("Health")
		
		# Update label if it exists
		if has_node("HealthLabel"):
			$HealthLabel.text = "%d/%d" % [value, max_value]
