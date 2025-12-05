extends Node2D

@onready var path = preload("res://scenes/level_1.tscn")
@onready var timer = $Timer

var current_wave = 0
var enemies_to_spawn = 0
var enemies_spawned = 0
var enemy_health = 10
var enemy_speed = 20
var spawn_interval = 2.0
var is_spawning = false

func _on_timer_timeout():
	if is_spawning and enemies_spawned < enemies_to_spawn:
		spawn_enemy()
		enemies_spawned += 1
		
		if enemies_spawned >= enemies_to_spawn:
			stop_spawning()
			print("Wave ", current_wave, " spawning complete")

func spawn_enemy():
	var tempPath = path.instantiate()
	add_child(tempPath)
	
	# Set enemy stats based on wave difficulty
	var enemy = tempPath.get_node("Enemy")
	if enemy:
		# DEBUG: Print the speed being set
		print("Setting enemy speed to: ", enemy_speed)
		
		# Set speed directly
		enemy.speed = enemy_speed
		
		# Set health values
		enemy.Health = enemy_health
		enemy.max_health = enemy_health
		
		# Update health bar if exists
		var health_bar = enemy.get_node("enemy_health")
		if health_bar:
			health_bar.max_value = enemy.max_health
			health_bar.value = enemy.Health
			if health_bar.has_method("update_health_display"):
				health_bar.update_health_display()
	
	# Notify main that enemy spawned
	var main = get_tree().get_root().get_node("Main")
	if main and main.has_method("enemy_spawned"):
		main.enemy_spawned()

func start_wave(wave_number, enemy_count, health, speed, spawn_rate):
	current_wave = wave_number
	enemies_to_spawn = enemy_count
	enemies_spawned = 0
	enemy_health = health
	enemy_speed = speed
	spawn_interval = spawn_rate
	is_spawning = true
	
	# DEBUG: Print wave info
	print("Wave ", wave_number, " starting. Speed: ", speed, ", Health: ", health)
	
	# Set the timer with the calculated spawn rate
	timer.wait_time = spawn_interval
	timer.start()
	
	print("Spawning: ", enemy_count, " enemies every ", spawn_rate, " seconds")

func stop_spawning():
	is_spawning = false
	timer.stop()

func is_wave_complete():
	return enemies_spawned >= enemies_to_spawn

func get_remaining_enemies():
	return enemies_to_spawn - enemies_spawned
