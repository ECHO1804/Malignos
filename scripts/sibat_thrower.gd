extends StaticBody2D

var Bullet = preload("res://scenes/spear.tscn")
var bulletDamage = 2
var fire_rate = 1.0  # Shots per second
var shoot_delay = 1.0
var pathName
var currTargets = []

# Upgrade system
var upgrade_cost_damage = 75
var upgrade_cost_speed = 75
var damage_level = 1
var speed_level = 1
var is_selected = false
var MAX_LEVEL = 5

# Cost tracking
var total_gold_spent = 100
var base_tower_cost = 100

# Shooting variables
var shooting_timer = null
var can_shoot = true

# NEW: Sound effects for attacks
var spear_sounds = [
	preload("res://assets/SFX/1.mp3"),
	preload("res://assets/SFX/2.mp3"), 
	preload("res://assets/SFX/3.mp3")
]

# Animation variables
var attack_anim_speed_multiplier = 1.0  # Adjustable animation speed multiplier

func _ready():
	# Hide options initially
	$Upgrade/Options.hide()
	
	# Hide range panel initially
	if has_node("Range_panel"):
		$Range_panel.hide()
	
	# Scale the upgrade panel and buttons
	scale_upgrade_panel()
	
	# Set up shooting timer
	shooting_timer = Timer.new()
	shooting_timer.one_shot = true
	shooting_timer.timeout.connect(_on_shooting_timer_timeout)
	add_child(shooting_timer)
	
	# Connect upgrade buttons
	$Upgrade/Options/HBoxContainer/Damage.pressed.connect(_on_damage_button_pressed)
	$Upgrade/Options/HBoxContainer/Speed.pressed.connect(_on_speed_button_pressed)
	$Upgrade/Options/HBoxContainer/Sell.pressed.connect(_on_sell_button_pressed)
	
	# Initialize button texts
	update_button_texts()
	
	# Initialize shoot delay from fire rate
	shoot_delay = 1.0 / fire_rate
	
	# Make upgrade panel ignore mouse clicks (so it doesn't block tower clicks)
	if has_node("Upgrade/Options"):
		$Upgrade/Options.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Setup animation
	var attack_node = get_node_or_null("AnimatedSprite2D")
	if attack_node:
		attack_node.animation_finished.connect(_on_attack_animation_finished)
		# Set initial animation to idle/default
		if attack_node.sprite_frames.has_animation("default"):
			attack_node.play("default")
		elif attack_node.sprite_frames.has_animation("idle"):
			attack_node.play("idle")

func _on_attack_animation_finished():
	var attack_node = get_node_or_null("AnimatedSprite2D")
	if attack_node:
		# When attack animation finishes, check if we should continue attacking
		if currTargets.size() > 0 and can_shoot:
			# If enemies are still in range and we can shoot, prepare for next shot
			# Don't play idle yet - wait for shooting timer
			pass
		else:
			# No enemies or can't shoot, go back to idle/default
			_set_idle_animation()

func _set_idle_animation():
	var attack_node = get_node_or_null("AnimatedSprite2D")
	if attack_node:
		if attack_node.sprite_frames.has_animation("default"):
			attack_node.play("default")
		elif attack_node.sprite_frames.has_animation("idle"):
			attack_node.play("idle")
		else:
			# If no idle animation, stop and reset to first frame
			attack_node.stop()
			attack_node.frame = 0

func scale_upgrade_panel():
	var options_panel = $Upgrade/Options
	if options_panel:
		options_panel.scale = Vector2(0.5, 0.5)
		
		var damage_button = $Upgrade/Options/HBoxContainer/Damage
		var speed_button = $Upgrade/Options/HBoxContainer/Speed
		var sell_button = $Upgrade/Options/HBoxContainer/Sell
		
		if damage_button:
			damage_button.custom_minimum_size = Vector2(50, 20)
			damage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			damage_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		if speed_button:
			speed_button.custom_minimum_size = Vector2(50, 20)
			speed_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			speed_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		if sell_button:
			sell_button.custom_minimum_size = Vector2(50, 20)
			sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sell_button.size_flags_vertical = Control.SIZE_EXPAND_FILL

func update_button_texts():
	var damage_button = $Upgrade/Options/HBoxContainer/Damage
	var speed_button = $Upgrade/Options/HBoxContainer/Speed
	var sell_button = $Upgrade/Options/HBoxContainer/Sell
	
	if damage_button:
		if damage_level >= MAX_LEVEL:
			damage_button.text = "Damage\nMAX"
			damage_button.disabled = true
		else:
			damage_button.text = "Damage\nLvl " + str(damage_level) + "/" + str(MAX_LEVEL) + "\nP" + str(upgrade_cost_damage)
			damage_button.disabled = false
	
	if speed_button:
		if speed_level >= MAX_LEVEL:
			speed_button.text = "Speed\nMAX"
			speed_button.disabled = true
		else:
			speed_button.text = "Speed\nLvl " + str(speed_level) + "/" + str(MAX_LEVEL) + "\nP" + str(upgrade_cost_speed)
			speed_button.disabled = false
	
	if sell_button:
		var sell_value = int(total_gold_spent * 0.5)
		sell_button.text = "Sell\nP" + str(sell_value)

func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		var range_node = get_node("Range")
		if range_node:
			currTargets = range_node.get_overlapping_bodies()
			
			var enemies_in_range = []
			for enemy in currTargets:
				if enemy.is_in_group("enemy") and is_instance_valid(enemy):
					enemies_in_range.append(enemy)
			
			currTargets = enemies_in_range
			
			if currTargets.size() > 0 and can_shoot:
				call_deferred("shoot")

func _on_range_body_exited(_body: Node2D) -> void:
	var range_node = get_node("Range")
	if range_node:
		currTargets = range_node.get_overlapping_bodies()
		
		var enemies_in_range = []
		for enemy in currTargets:
			if enemy.is_in_group("enemy") and is_instance_valid(enemy):
				enemies_in_range.append(enemy)
		
		currTargets = enemies_in_range
		
		# If no enemies left, set to idle
		if currTargets.size() == 0:
			_set_idle_animation()

func shoot():
	if currTargets.size() == 0:
		return
	
	var target = get_valid_target()
	if not target:
		return
	
	# Play attack animation and sound
	play_attack_animation()
	play_random_spear_sound()
	
	# Create bullet
	var tempBullet = Bullet.instantiate()
	tempBullet.bulletDamage = bulletDamage
	tempBullet.tower = self
	tempBullet.global_position = $Aim.global_position
	
	if is_instance_valid(target):
		tempBullet.set_target(target)
	
	get_tree().current_scene.call_deferred("add_child", tempBullet)
	
	can_shoot = false
	shooting_timer.wait_time = shoot_delay
	shooting_timer.start()

func play_attack_animation():
	var attack_node = get_node_or_null("AnimatedSprite2D")
	if attack_node:
		# Set animation speed based on fire rate
		# The higher the fire rate, the faster the animation should play
		# attack_anim_speed_multiplier allows you to adjust this relationship
		var animation_speed = fire_rate * attack_anim_speed_multiplier
		attack_node.speed_scale = animation_speed
		
		# Play attack animation
		if attack_node.sprite_frames.has_animation("attack"):
			attack_node.play("attack")
		else:
			print("Warning: No 'attack' animation found")

func play_random_spear_sound():
	if spear_sounds.size() > 0:
		var random_index = randi() % spear_sounds.size()
		
		var sfx_player = get_node_or_null("SFXPlayer")
		if sfx_player and spear_sounds[random_index]:
			sfx_player.stream = spear_sounds[random_index]
			sfx_player.play()
		else:
			print("Warning: No SFXPlayer found or sound not loaded")

func get_valid_target():
	for target in currTargets:
		if is_instance_valid(target):
			return target
	
	currTargets = []
	return null

func _on_shooting_timer_timeout():
	can_shoot = true
	cleanup_targets()
	
	# Check if we should continue attacking
	if currTargets.size() > 0:
		call_deferred("shoot")
	else:
		# No enemies, set to idle
		_set_idle_animation()

func cleanup_targets():
	var valid_targets = []
	for target in currTargets:
		if is_instance_valid(target):
			valid_targets.append(target)
	currTargets = valid_targets
	
	# If no valid targets, set to idle
	if currTargets.size() == 0:
		_set_idle_animation()

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			var distance = global_position.distance_to(mouse_pos)
			
			if distance < 40:
				toggle_selection()
				get_viewport().set_input_as_handled()
			elif distance > 60 and is_selected:
				deselect()

func toggle_selection():
	deselect_all_towers()
	
	is_selected = not is_selected
	
	if is_selected:
		$Upgrade/Options.show()
		if has_node("Range_panel"):
			$Range_panel.show()
			$Range_panel.modulate = Color(1, 1, 1, 0.5)
		
		position_upgrade_panel()
	else:
		$Upgrade/Options.hide()
		if has_node("Range_panel"):
			$Range_panel.hide()

func position_upgrade_panel():
	var options_panel = $Upgrade/Options
	
	var tower_height = 10
	var panel_x = global_position.x - (options_panel.size.x * options_panel.scale.x) / 2
	var panel_y = global_position.y + tower_height + 20
	
	options_panel.global_position = Vector2(panel_x, panel_y)

func deselect():
	is_selected = false
	$Upgrade/Options.hide()
	if has_node("Range_panel"):
		$Range_panel.hide()

func _on_damage_button_pressed():
	if damage_level >= MAX_LEVEL:
		return
	
	var main = get_tree().get_root().get_node("Main")
	if main and not main.subtract_gold(upgrade_cost_damage):
		print("Not enough gold for damage upgrade!")
		return
	
	if damage_level == 1:
		bulletDamage = 3
	elif damage_level == 2:
		bulletDamage = 5
	elif damage_level == 3:
		bulletDamage = 8
	elif damage_level == 4:
		bulletDamage = 10
	
	damage_level += 1
	total_gold_spent += upgrade_cost_damage
	upgrade_cost_damage += 50
	
	update_button_texts()
	print("Damage upgraded to: ", bulletDamage)

func _on_speed_button_pressed():
	if speed_level >= MAX_LEVEL:
		return
	
	var main = get_tree().get_root().get_node("Main")
	if main and not main.subtract_gold(upgrade_cost_speed):
		print("Not enough gold for speed upgrade!")
		return
	
	if speed_level == 1:
		fire_rate = 1.2
	elif speed_level == 2:
		fire_rate = 1.5
	elif speed_level == 3:
		fire_rate = 1.8
	elif speed_level == 4:
		fire_rate = 2.2
	
	speed_level += 1
	total_gold_spent += upgrade_cost_speed
	shoot_delay = 1.0 / fire_rate
	upgrade_cost_speed += 50
	
	update_button_texts()
	print("Fire rate upgraded to: ", fire_rate)

func _on_sell_button_pressed():
	var refund_amount = int(total_gold_spent * 0.5)
	
	var main = get_tree().get_root().get_node("Main")
	if main:
		main.add_gold(refund_amount)
		print("Refunded $", refund_amount, " to player")
	
	queue_free()

func deselect_all_towers():
	var towers = get_tree().get_nodes_in_group("towers")
	for tower in towers:
		if tower != self and tower.has_method("deselect"):
			tower.deselect()
