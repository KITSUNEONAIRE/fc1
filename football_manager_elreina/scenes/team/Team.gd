extends Control

## Team Scene Controller
## Displays team squad with player information and pixel portraits

@onready var player_list: ItemList = $PlayerList
@onready var title_label: Label = $TitleLabel

const COLOR_BACKGROUND := Color(0.031, 0.047, 0.078)


func _ready() -> void:
	_setup_team_view()


func _setup_team_view() -> void:
	player_list.clear()
	
	# Get players for the current club (or all players if no club assigned)
	var squad = GameState.players.filter(func(p): return p.team_id == -1 or p.team_id == GameState.player_club.get("id", -1))
	
	# Sort by overall rating
	squad.sort_custom(func(a, b): return a.overall > b.overall)
	
	for player in squad:
		var position_icon = _get_position_icon(player.position)
		var player_text = "%s %s - OVR: %d - Age: %d - Value: £%dK" % [
			position_icon,
			player.name,
			player.overall,
			player.age,
			player.contract.weekly_wage / 1000
		]
		
		player_list.add_item(player_text)
		
		# Set custom metadata for player ID
		var idx = player_list.item_count - 1
		player_list.set_item_metadata(idx, player.id)
		
		# Color code by position
		var position_color = _get_position_color(player.position)
		player_list.set_item_icon_modulate(idx, position_color)


func _get_position_icon(position: String) -> String:
	match position:
		"GK": return "🧤"
		"DEF": return "🛡️"
		"MID": return "⚙️"
		"FWD": return "⚽"
		_: return "👤"


func _get_position_color(position: String) -> Color:
	match position:
		"GK": return Color(1.0, 0.843, 0.0)  # Gold
		"DEF": return Color(0.2, 0.4, 0.8)   # Blue
		"MID": return Color(0.2, 0.7, 0.2)   # Green
		"FWD": return Color(0.8, 0.2, 0.2)   # Red
		_: return Color.WHITE


func _on_back_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
	if err != OK:
		print("Error loading dashboard: ", err)
