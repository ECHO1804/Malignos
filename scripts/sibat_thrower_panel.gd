extends Panel

@onready var tower = preload("res://scenes/sibat_thrower.tscn")
@onready var towers_node = get_tree().get_root().get_node("Main/Towers")
@onready var camera = get_tree().get_root().get_node("Main/Camera2D")

var dragging_tower = null
var is_dragging = false
var tower_cost = 100
var is_valid_placement = true

func _process(delta):
	if is_dragging and dragging_tower and camera:
		# Get mouse position in world coordinates using camera
		var world_mouse_pos = camera.get_global_mouse_position()
		dragging_tower.global_position = world_mouse_pos
		check_placement_validity()  # <-- THIS LINE MUST BE HERE

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Check if player has enough gold and game is playing
			var main = get_tree().get_root().get_node("Main")
			if main and main.game_state == "playing" and main.gold >= tower_cost:
				# Create tower for dragging - add to towers_node directly for consistent coordinates
				dragging_tower = tower.instantiate()
				towers_node.add_child(dragging_tower)
				dragging_tower.process_mode = Node.PROCESS_MODE_DISABLED
				
				# Set initial position using camera for world coordinates
				if camera:
					dragging_tower.global_position = camera.get_global_mouse_position()
				
				# Disable collisions while dragging
				# Check for the correct collision shape name based on your hierarchy
				var range_node = dragging_tower.get_node("Range")
				if range_node:
					# Try to find any CollisionShape2D in the Range node
					for child in range_node.get_children():
						if child is CollisionShape2D:
							child.disabled = true
							break
				
				is_dragging = true
				update_drag_visual()
			elif main:
				if main.game_state != "playing":
					print("Cannot place towers during menu/game over!")
				else:
					print("Not enough gold! Need:", tower_cost, " Have:", main.gold)
			
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			# Left click released - place tower
			if is_dragging and dragging_tower:
				if is_valid_placement:
					# Enable tower functionality
					dragging_tower.process_mode = Node.PROCESS_MODE_INHERIT
					
					# Enable collisions when placed
					var range_node = dragging_tower.get_node("Range")
					if range_node:
						# Find and enable any CollisionShape2D in the Range node
						for child in range_node.get_children():
							if child is CollisionShape2D:
								child.disabled = false
								break
					
					dragging_tower.get_node("Range").show()
					dragging_tower.total_gold_spent = tower_cost
					dragging_tower.base_tower_cost = tower_cost
					
					# Hide the Range_panel
					var range_panel = dragging_tower.get_node("Range_panel")
					if range_panel:
						range_panel.hide()
						range_panel.modulate = Color.WHITE
					
					# Add to towers group for selection system
					dragging_tower.add_to_group("towers")
					
					# Deduct gold
					var main = get_tree().get_root().get_node("Main")
					if main:
						main.subtract_gold(tower_cost)
					
					# Reset
					dragging_tower = null
					is_dragging = false
					is_valid_placement = true
				else:
					# Invalid placement - cancel
					print("Cannot place tower here - position is blocked!")
					dragging_tower.queue_free()
					dragging_tower = null
					is_dragging = false
					is_valid_placement = true
		
		# RIGHT CLICK to cancel dragging
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_dragging and dragging_tower:
				# Cancel the drag
				dragging_tower.queue_free()
				dragging_tower = null
				is_dragging = false
				is_valid_placement = true

func check_placement_validity():
	if not dragging_tower:
		return
	
	var tower_position = dragging_tower.global_position
	
	# Check: Is it on Zone? (This is REQUIRED for placement)
	var zone_layer = get_tree().get_root().get_node("Main/Zone")
	var is_on_zone = false
	if zone_layer:
		var local_pos = zone_layer.to_local(tower_position)
		var tile_pos = zone_layer.local_to_map(local_pos)
		var tile_data = zone_layer.get_cell_tile_data(tile_pos)
		is_on_zone = tile_data != null
	
	# Check: Is it too close to other towers?
	var is_too_close = check_tower_overlap(tower_position)
	
	# Check: Is it outside the playable area?
	var is_out_of_bounds = check_out_of_bounds(tower_position)
	
	# Determine if placement is valid
	# MUST be on Zone, NOT too close to other towers, and NOT out of bounds
	is_valid_placement = is_on_zone and not is_too_close and not is_out_of_bounds
	
	# Update visual feedback
	update_drag_visual()
	
func check_tower_overlap(position: Vector2) -> bool:
	# Get all existing towers
	var towers = get_tree().get_nodes_in_group("towers")
	
	# Minimum distance between towers
	var min_distance = 60
	
	for tower in towers:
		# Skip the tower we're currently dragging
		if tower == dragging_tower:
			continue
		
		# Calculate distance between centers
		var distance = tower.global_position.distance_to(position)
		
		# Check if too close
		if distance < min_distance:
			return true
	
	return false

func check_out_of_bounds(position: Vector2) -> bool:
	if not camera:
		return false
	
	# Prevent placing towers outside the map
	# Get camera viewport in world coordinates
	var camera_rect = camera.get_viewport_rect()
	var camera_center = camera.global_position
	
	# Define bounds (adjust as needed)
	var bounds = Rect2(
		camera_center.x - camera_rect.size.x / 2,
		camera_center.y - camera_rect.size.y / 2,
		camera_rect.size.x,
		camera_rect.size.y
	)
	
	# Add some margin
	bounds = bounds.grow(-50)
	
	if not bounds.has_point(position):
		return true
	
	return false

func update_drag_visual():
	if dragging_tower:
		var range_panel = dragging_tower.get_node("Range_panel")
		if range_panel:
			# FIRST: Make sure the range panel is SHOWN when dragging
			range_panel.show()
			
			# THEN: Set the color based on placement validity
			if is_valid_placement:
				range_panel.modulate = Color(0, 1, 0, 0.7)  # Green, semi-transparent
			else:
				range_panel.modulate = Color(1, 0, 0, 0.7)  # Red, semi-transparent
