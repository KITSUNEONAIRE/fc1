extends Control

@onready var formation_buttons: VBoxContainer = $MarginContainer/VBoxContainer/FormationButtons
@onready var style_buttons: VBoxContainer = $MarginContainer/VBoxContainer/StyleButtons
@onready var lineup_container: GridContainer = $MarginContainer/VBoxContainer/LineupContainer
@onready var tactics_info: Label = $MarginContainer/VBoxContainer/TacticsInfo

var current_formation: String = "4-4-2"
var current_style: String = "Balanced"
var formations: Array[String] = ["4-4-2", "4-3-3", "3-5-2", "4-2-3-1", "5-3-2"]
var styles: Array[String] = ["Attacking", "Defensive", "Balanced", "Counter", "Possession"]

var team_data: Array[Dictionary] = []

func _ready() -> void:
	setup_formation_buttons()
	setup_style_buttons()
	load_team_data()
	update_lineup_display()
	update_tactics_info()

func setup_formation_buttons() -> void:
	for button in formation_buttons.get_children():
		button.queue_free()
	
	for formation in formations:
		var btn := Button.new()
		btn.text = formation
		btn.custom_minimum_size = Vector2(150, 40)
		btn.pressed.connect(_on_formation_pressed.bind(formation))
		if formation == current_formation:
			btn.add_theme_stylebox_override("normal", get_stylebox("pressed", "Button"))
		formation_buttons.add_child(btn)

func setup_style_buttons() -> void:
	for button in style_buttons.get_children():
		button.queue_free()
	
	for style in styles:
		var btn := Button.new()
		btn.text = style
		btn.custom_minimum_size = Vector2(150, 40)
		btn.pressed.connect(_on_style_pressed.bind(style))
		if style == current_style:
			btn.add_theme_stylebox_override("normal", get_stylebox("pressed", "Button"))
		style_buttons.add_child(btn)

func _on_formation_pressed(formation: String) -> void:
	current_formation = formation
	GameState.save_game()
	setup_formation_buttons()
	update_lineup_display()
	update_tactics_info()

func _on_style_pressed(style: String) -> void:
	current_style = style
	GameState.save_game()
	setup_style_buttons()
	update_tactics_info()

func load_team_data() -> void:
	if GameState.current_team_id >= 0 and GameState.current_team_id < GameState.teams.size():
		team_data = GameState.teams[GameState.current_team_id].get("players", [])

func update_lineup_display() -> void:
	for child in lineup_container.get_children():
		child.queue_free()
	
	var positions := get_positions_for_formation(current_formation)
	var max_players = min(positions.size(), team_data.size())
	
	for i in range(max_players):
		var player_card := create_player_card(team_data[i], positions[i])
		lineup_container.add_child(player_card)

func get_positions_for_formation(formation: String) -> Array[String]:
	match formation:
		"4-4-2":
			return ["GK", "LB", "CB", "CB", "RB", "LM", "CM", "CM", "RM", "ST", "ST"]
		"4-3-3":
			return ["GK", "LB", "CB", "CB", "RB", "CDM", "CM", "CM", "LW", "ST", "RW"]
		"3-5-2":
			return ["GK", "CB", "CB", "CB", "LM", "CM", "CDM", "CM", "RM", "ST", "ST"]
		"4-2-3-1":
			return ["GK", "LB", "CB", "CB", "RB", "CDM", "CDM", "LAM", "CAM", "RAM", "ST"]
		"5-3-2":
			return ["GK", "LWB", "CB", "CB", "CB", "RWB", "CM", "CM", "CM", "ST", "ST"]
	return []

func create_player_card(player: Dictionary, position: String) -> Control:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(100, 140)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)
	
	var pos_label := Label.new()
	pos_label.text = position
	pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pos_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(pos_label)
	
	var name_label := Label.new()
	name_label.text = player.get("name", "Unknown")[:12]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)
	
	var rating_label := Label.new()
	rating_label.text = "OVR: " + str(player.get("overall", 50))
	rating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rating_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(rating_label)
	
	return card

func update_lineup_display() -> void:
	for child in lineup_container.get_children():
		child.queue_free()
	
	var positions := get_positions_for_formation(current_formation)
	var max_players = min(positions.size(), team_data.size())
	
	for i in range(max_players):
		var player_card := create_player_card(team_data[i], positions[i])
		lineup_container.add_child(player_card)

func update_tactics_info() -> void:
	tactics_info.text = "Formation: %s | Style: %s\nTeam Chemistry: %d%%" % [
		current_formation, 
		current_style,
		calculate_chemistry()
	]

func calculate_chemistry() -> int:
	if team_data.is_empty():
		return 50
	var avg_morale := 0
	for player in team_data:
		avg_morale += player.get("morale", 50)
	return clamp(avg_morale / team_data.size(), 0, 100)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
