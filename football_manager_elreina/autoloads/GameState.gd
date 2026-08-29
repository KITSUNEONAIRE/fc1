extends Node

## Global Game State Manager
## Handles game state, save/load, and global variables

# Signals
signal game_loaded
signal game_saved
signal state_changed

# Constants
const MAX_SAVE_SLOTS := 6
const SAVE_DIR := "user://saves/"

# Game state variables
var is_game_started: bool = false
var current_save_slot: int = -1
var player_manager: Dictionary = {}
var player_club: Dictionary = {}
var is_employed: bool = true

# World data
var world_data: Dictionary = {}
var regions: Array = []
var cities: Array = []
var teams: Array = []
var players: Array = []
var political_parties: Array = []

# Club data
var club_data: Dictionary = {}
var club_finances: Dictionary = {}
var club_staff: Dictionary = {}
var club_squad: Array = []

# League data
var league_table: Array = []
var league_stats: Dictionary = {}

# Time tracking
var current_date: Dictionary = {}
var current_week: int = 1
var current_season: int = 1

# Prestige Points
var prestige_points: int = 0
var total_prestige_earned: int = 0

# Relationships
var fan_relations: float = 50.0
var board_trust: float = 50.0
var media_relations: float = 50.0
var state_relations: float = 50.0

# Active effects
var active_effects: Array = []
var notifications: Array = []

# Shop purchases
var shop_upgrades: Dictionary = {}


func _ready() -> void:
	_create_save_directory()


func _create_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			dir.make_dir("saves")


func start_new_game(manager_name: String, club_name: String, region_id: int) -> void:
	is_game_started = true
	current_date = {"year": 1997, "month": 8, "day": 1}
	current_week = 1
	current_season = 1
	
	player_manager = {
		"name": manager_name,
		"age": 35,
		"nationality": "Elreinian",
		"style": "balanced",
		"experience": 0
	}
	
	prestige_points = 0
	total_prestige_earned = 0
	fan_relations = 50.0
	board_trust = 50.0
	media_relations = 50.0
	state_relations = 50.0
	
	shop_upgrades.clear()
	active_effects.clear()
	notifications.clear()
	
	state_changed.emit()


func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
	
	var save_data = {
		"version": "1.0",
		"slot": slot,
		"timestamp": Time.get_datetime_dict_from_system(),
		"game_state": {
			"is_started": is_game_started,
			"current_date": current_date,
			"current_week": current_week,
			"current_season": current_season,
			"prestige_points": prestige_points,
			"total_prestige_earned": total_prestige_earned
		},
		"player": {
			"manager": player_manager,
			"club": player_club,
			"is_employed": is_employed
		},
		"world": {
			"regions": regions,
			"cities": cities,
			"teams": teams,
			"players": players,
			"parties": political_parties
		},
		"club": {
			"data": club_data,
			"finances": club_finances,
			"staff": club_staff,
			"squad": club_squad
		},
		"league": {
			"table": league_table,
			"stats": league_stats
		},
		"relations": {
			"fans": fan_relations,
			"board": board_trust,
			"media": media_relations,
			"state": state_relations
		},
		"effects": active_effects,
		"shop": shop_upgrades
	}
	
	var file = FileAccess.open(SAVE_DIR + "save_%d.save" % slot, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		current_save_slot = slot
		game_saved.emit()
		return true
	
	return false


func load_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
	
	var file = FileAccess.open(SAVE_DIR + "save_%d.save" % slot, FileAccess.READ)
	if not file:
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return false
	
	var save_data = json.data
	
	is_game_started = save_data.get("game_state", {}).get("is_started", false)
	current_date = save_data.get("game_state", {}).get("current_date", {})
	current_week = save_data.get("game_state", {}).get("current_week", 1)
	current_season = save_data.get("game_state", {}).get("current_season", 1)
	prestige_points = save_data.get("game_state", {}).get("prestige_points", 0)
	total_prestige_earned = save_data.get("game_state", {}).get("total_prestige_earned", 0)
	
	player_manager = save_data.get("player", {}).get("manager", {})
	player_club = save_data.get("player", {}).get("club", {})
	is_employed = save_data.get("player", {}).get("is_employed", true)
	
	regions = save_data.get("world", {}).get("regions", [])
	cities = save_data.get("world", {}).get("cities", [])
	teams = save_data.get("world", {}).get("teams", [])
	players = save_data.get("world", {}).get("players", [])
	political_parties = save_data.get("world", {}).get("parties", [])
	
	club_data = save_data.get("club", {}).get("data", {})
	club_finances = save_data.get("club", {}).get("finances", {})
	club_staff = save_data.get("club", {}).get("staff", {})
	club_squad = save_data.get("club", {}).get("squad", [])
	
	league_table = save_data.get("league", {}).get("table", [])
	league_stats = save_data.get("league", {}).get("stats", {})
	
	fan_relations = save_data.get("relations", {}).get("fans", 50.0)
	board_trust = save_data.get("relations", {}).get("board", 50.0)
	media_relations = save_data.get("relations", {}).get("media", 50.0)
	state_relations = save_data.get("relations", {}).get("state", 50.0)
	
	active_effects = save_data.get("effects", [])
	shop_upgrades = save_data.get("shop", {})
	
	current_save_slot = slot
	game_loaded.emit()
	state_changed.emit()
	
	return true


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(SAVE_DIR + "save_%d.save" % slot)


func get_save_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	
	var file = FileAccess.open(SAVE_DIR + "save_%d.save" % slot, FileAccess.READ)
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}
	
	return json.data.get("timestamp", {})


func add_prestige(amount: int, reason: String = "") -> void:
	prestige_points += amount
	total_prestige_earned += amount
	if reason:
		add_notification("Prestige: +%d (%s)" % [amount, reason])


func spend_prestige(amount: int) -> bool:
	if prestige_points >= amount:
		prestige_points -= amount
		return true
	return false


func add_notification(message: String, type: String = "info") -> void:
	notifications.append({
		"message": message,
		"type": type,
		"week": current_week,
		"season": current_season
	})
	# Keep only last 50 notifications
	if notifications.size() > 50:
		notifications.remove_at(0)


func get_recent_notifications(count: int = 10) -> Array:
	var result = []
	for i in range(max(0, notifications.size() - count), notifications.size()):
		result.append(notifications[i])
	return result


func advance_week() -> void:
	current_week += 1
	if current_week > 38:
		end_season()


func end_season() -> void:
	current_season += 1
	current_week = 1
	# Age players, reset stats, etc.
	state_changed.emit()


func get_player_club() -> Dictionary:
	return player_club


func set_player_club(club: Dictionary) -> void:
	player_club = club
	state_changed.emit()


func get_team_by_id(team_id: int) -> Dictionary:
	for team in teams:
		if team.get("id", -1) == team_id:
			return team.duplicate()
	return {}


func get_all_teams() -> Array:
	return teams.duplicate()


func get_players_by_team(team_id: int) -> Array:
	return WorldGenerator.get_team_squad(team_id)


func get_available_free_agents() -> Array:
	return WorldGenerator.get_free_agents()
