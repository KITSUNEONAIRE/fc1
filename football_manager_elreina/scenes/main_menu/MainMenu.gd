extends Control

## Main Menu Controller
## Handles main menu interactions and navigation

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var load_game_button: Button = $VBoxContainer/LoadGameButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var credits_button: Button = $VBoxContainer/CreditsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

# Color scheme from design document
const COLOR_BACKGROUND := Color(0.031, 0.047, 0.078)  # #080C14
const COLOR_PANEL := Color(0.102, 0.149, 0.2)  # #1A2633
const COLOR_ACCENT_BLUE := Color(0.118, 0.565, 1.0)  # #1E90FF
const COLOR_ACCENT_GOLD := Color(1.0, 0.843, 0.0)  # #FFD700
const COLOR_TEXT := Color(1.0, 1.0, 1.0)  # #FFFFFF


func _ready() -> void:
	_setup_buttons()
	_apply_theme()


func _setup_buttons() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _apply_theme() -> void:
	# Apply background color
	$Background.color = COLOR_BACKGROUND
	
	# Set button styles
	var buttons = [new_game_button, load_game_button, settings_button, credits_button, quit_button]
	for btn in buttons:
		btn.add_theme_color_override("font_color", COLOR_TEXT)
		btn.add_theme_color_override("font_hover_color", COLOR_ACCENT_BLUE)


func _on_new_game_pressed() -> void:
	# Start world generation
	WorldGenerator.generation_progress.connect(_on_generation_progress)
	WorldGenerator.generation_completed.connect(_on_world_generated)
	WorldGenerator.generate_world()


func _on_generation_progress(progress: float, message: String) -> void:
	print("Generation: ", progress * 100, "% - ", message)


func _on_world_generated() -> void:
	# Initialize game state
	GameState.start_new_game("Manager", "Player Club", 0)
	TimeSystem.start_game()
	
	# Switch to dashboard scene
	var err = get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
	if err != OK:
		print("Error loading dashboard: ", err)


func _on_load_game_pressed() -> void:
	# Check for available saves
	var has_saves = false
	for i in range(GameState.MAX_SAVE_SLOTS):
		if GameState.has_save(i):
			has_saves = true
			break
	
	if has_saves:
		# Load most recent save (slot 0 for now)
		if GameState.load_game(0):
			TimeSystem.start_game()
			var err = get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
			if err != OK:
				print("Error loading dashboard: ", err)
		else:
			print("Failed to load save")
	else:
		print("No saves found")


func _on_quit_pressed() -> void:
	get_tree().quit()
