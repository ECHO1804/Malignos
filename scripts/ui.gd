extends CanvasLayer

# Music streams
var title_music = preload("res://assets/musics/Airline - Geographer.mp3")   # Adjust path
var gameplay_music = preload("res://assets/musics/Castlevania - Density & Time.mp3")
var result_music = preload("res://assets/musics/I give up, I remove melody cause it sucks (100 bpm).mp3")

# Reference to UI elements
@onready var title_label = $TITLE
@onready var menu_panel = $Menu
@onready var message_label = $Menu/Message
@onready var gold_label = $Gold
@onready var lives_label = $Lives
@onready var waves_label = $Waves
@onready var start_button = $StartButton
@onready var tower_slot = $Panel
@onready var exit_button = $ExitButton
@onready var pause_button = $PauseButton
@onready var wave_message_label = $WaveMessage
@onready var music_player = $MusicPlayer   # Make sure you have this node

signal start_button_pressed
signal restart_button_pressed

func _ready() -> void:
	# Set UI to process even when game is paused
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	# Connect all button signals
	start_button.pressed.connect(_on_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	
	# Show menu initially
	show_menu()
	print("UI initialized")
	
	# DEBUG: Check if music player exists
	if music_player:
		print("MusicPlayer found and ready")
	else:
		print("ERROR: No MusicPlayer node found!")

# NEW: Handle ESC key input
func _input(event):
	if event.is_action_pressed("pause"):
		print("ESC key pressed - toggling pause")
		_on_pause_button_pressed()
		get_viewport().set_input_as_handled()

func _on_exit_button_pressed():
	if get_tree().paused:
		print("Restart button pressed from pause menu")
		restart_button_pressed.emit()
	else:
		print("Exit button pressed - closing game")
		get_tree().quit()

# --- MUSIC FUNCTIONS ---
func play_title_music():
	if music_player and title_music:
		music_player.stream = title_music
		music_player.play()
		print("Playing title music")

func play_gameplay_music():
	if music_player and gameplay_music:
		music_player.stream = gameplay_music
		music_player.play()
		print("Playing gameplay music")

func play_result_music():
	if music_player and result_music:
		music_player.stream = result_music
		music_player.play()
		print("Playing result music")

func stop_music():
	if music_player:
		music_player.stop()
		print("Music stopped")
# --- END MUSIC FUNCTIONS ---

func _on_pause_button_pressed():
	print("Pause button pressed")
	var is_paused = get_tree().paused
	
	if not is_paused:
		# Pause the game AND music
		get_tree().paused = true
		if music_player:
			music_player.stream_paused = true  # Pause the music
		print("Game paused")
		
		# Get current game stats from main
		var main = get_tree().get_root().get_node("Main")
		if main:
			print("Showing pause menu with stats from Main")
			show_pause_menu(main.gold, main.lives, main.current_wave, main.total_kills)
		else:
			print("ERROR: Main node not found!")
	else:
		# Resume the game AND music
		get_tree().paused = false
		if music_player:
			music_player.stream_paused = false  # Unpause the music
		print("Game resumed")
		show_game_ui()  # Return to normal game UI

func show_pause_menu(current_gold, current_lives, current_wave, total_kills):
	print("Showing pause menu")
	
	# Hide game UI elements
	gold_label.hide()
	lives_label.hide()
	waves_label.hide()
	wave_message_label.hide()
	tower_slot.hide()
	pause_button.hide()
	
	# Show pause menu elements - Show the PANEL
	title_label.hide()
	menu_panel.show()  # Changed: Show the panel, not the label
	start_button.show()
	exit_button.show()
	
	# Set pause message on the LABEL
	message_label.text = "GAME PAUSED\n\n" \
		+ "Current Wave: " + str(current_wave) + "/20\n" \
		+ "Gold: " + str(current_gold) + "\n" \
		+ "Lives: " + str(current_lives) + "\n" \
		+ "Total Kills: " + str(total_kills) + "\n\n" \
		+ "Click RESUME to continue"
	
	# Change button text for resume and restart
	start_button.text = "RESUME"
	exit_button.text = "RETURN"

func show_menu():
	print("Showing main menu")
	title_label.show()
	menu_panel.hide()  # Changed: Hide the panel, not the label
	
	# Hide game UI
	gold_label.hide()
	lives_label.hide()
	waves_label.hide()
	wave_message_label.hide()
	tower_slot.hide()
	pause_button.hide()
	
	# Show menu buttons
	start_button.text = "START"
	start_button.show()
	exit_button.text = "EXIT"
	exit_button.show()
	
	# --- ADDED: Play title music when showing menu ---
	play_title_music()

func show_game_ui():
	print("Showing game UI")
	# Hide menu elements
	title_label.hide()
	menu_panel.hide()  # Changed: Hide the panel
	start_button.hide()
	exit_button.hide()
	
	# Show game UI
	gold_label.show()
	lives_label.show()
	waves_label.show()
	wave_message_label.show()
	tower_slot.show()
	pause_button.show()
	
	# --- ADDED: Switch to gameplay music ---
	play_gameplay_music()
	
	print("Game UI shown")

func update_gold(amount: int):
	if gold_label:
		gold_label.text = str(amount)

func update_lives(amount: int):
	if lives_label:
		lives_label.text =  str(amount)

func update_waves(current: int, total: int = 20):
	if waves_label:
		waves_label.text = "Wave: " + str(current) + "/" + str(total)

func update_wave_message(wave: int, health: float, speed: float):
	if wave_message_label:
		# Show difficulty info for current wave
		var difficulty = ""
		if wave <= 5:
			difficulty = "Easy"
		elif wave <= 10:
			difficulty = "Medium"
		elif wave <= 15:
			difficulty = "Hard"
		else:
			difficulty = "EXTREME"
		
		wave_message_label.text = "Wave " + str(wave) + " (" + difficulty + ")\n" \
			+ "Enemy HP: " + str(health) + " | Speed: " + str(speed) + "%"
		
		# Flash the message
		wave_message_label.modulate = Color(1, 1, 1, 1)
		var tween = get_tree().create_tween()
		tween.tween_property(wave_message_label, "modulate", Color(1, 1, 1, 0.3), 3.0)

func show_game_over(total_kills, waves_survived, stars):
	print("Showing game over screen")
	title_label.hide()
	menu_panel.show()  # Changed: Show the panel
	wave_message_label.hide()
	tower_slot.hide()
	pause_button.hide()
	
	var stars_text = "⭐".repeat(stars)
	message_label.text = "DEFEATED\n\n" \
		+ "Waves Survived: " + str(waves_survived) + "/20\n" \
		+ "Enemies Killed: " + str(total_kills) + "\n" \
		+ "Final Score: " + stars_text + ""
	
	gold_label.hide()
	lives_label.hide()
	waves_label.hide()
	
	start_button.text = "RETURN"
	start_button.show()
	exit_button.text = "EXIT"
	exit_button.show()
	
	# --- ADDED: Play result music for game over ---
	play_result_music()

func show_victory(total_kills, waves_completed, stars):
	print("Showing victory screen")
	title_label.hide()
	menu_panel.show()  # Changed: Show the panel
	wave_message_label.hide()
	tower_slot.hide()
	pause_button.hide()
	
	var stars_text = "⭐⭐⭐"
	message_label.text = "VICTORY! 🎉\n\n" \
		+ "You completed all " + str(waves_completed) + " waves!\n" \
		+ "Enemies Killed: " + str(total_kills) + "\n" \
		+ "Rating: " + stars_text + "\n\n" \
		+ "Click RETURN to go back to title screen!"
	
	gold_label.hide()
	lives_label.hide()
	waves_label.hide()
	
	start_button.text = "RETURN"
	start_button.show()
	exit_button.text = "EXIT"
	exit_button.show()
	
	# --- ADDED: Play result music for victory ---
	play_result_music()

func _on_button_pressed():
	print("Start/Resume button pressed")
	
	# Handle different button functions based on game state
	if get_tree().paused:
		# Resume game if paused
		print("Resuming game from pause")
		get_tree().paused = false
		if music_player:
			music_player.stream_paused = false  # Unpause music
		show_game_ui()
	
	# Emit signal for main.gd to handle
	print("Emitting start_button_pressed signal")
	start_button_pressed.emit()
