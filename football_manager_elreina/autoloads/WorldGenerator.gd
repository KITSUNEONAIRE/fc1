extends Node

## World Generator - Procedural Generation System
## Generates regions, cities, teams, players, and political parties

# Signals
signal generation_started
signal generation_progress(progress: float, message: String)
signal generation_completed

# Region data structure
const REGION_NAMES := [
	"Northland", "Southmere", "Eastvale", "Westridge", "Centralia",
	"Highlands", "Lowlands", "Riverdale", "Coastal", "Mountainview",
	"Plainsburg", "Forestia", "Desertland", "Lakeland", "Hillcrest", "Valleytown"
]

# City name prefixes and suffixes
const CITY_PREFIXES := [
	"New", "Old", "Great", "Little", "Upper", "Lower", "North", "South", "East", "West",
	"Port", "Fort", "Mount", "Lake", "River", "Sea", "Bay", "Hill", "Valley", "Spring"
]

const CITY_SUFFIXES := [
	"ton", "ville", "burg", "field", "ford", "mouth", "port", "chester", "caster", "bridge",
	"worth", "haven", "pool", "stead", "wick", "ham", "bury", "shire", "land", "town"
]

# Ethnic groups with color palettes
const ETHNIC_GROUPS := {
	"nordic": {
		"skin_tones": [[255, 224, 209], [255, 213, 197], [255, 201, 186]],
		"hair_colors": [[255, 255, 255], [240, 230, 200], [200, 180, 150], [180, 150, 100]],
		"eye_colors": [[100, 150, 200], [150, 200, 230], [120, 180, 150]]
	},
	"western_european": {
		"skin_tones": [[255, 218, 200], [255, 206, 186], [255, 195, 173]],
		"hair_colors": [[200, 180, 150], [180, 150, 100], [150, 120, 80], [100, 80, 60]],
		"eye_colors": [[100, 150, 200], [120, 180, 150], [150, 120, 80]]
	},
	"central_european": {
		"skin_tones": [[255, 213, 197], [255, 201, 186], [255, 189, 173]],
		"hair_colors": [[180, 150, 100], [150, 120, 80], [100, 80, 60], [60, 50, 40]],
		"eye_colors": [[120, 180, 150], [150, 120, 80], [100, 100, 100]]
	},
	"southern_european": {
		"skin_tones": [[255, 201, 186], [255, 189, 173], [255, 178, 161]],
		"hair_colors": [[150, 120, 80], [100, 80, 60], [60, 50, 40], [40, 30, 20]],
		"eye_colors": [[150, 120, 80], [100, 100, 100], [80, 80, 60]]
	},
	"eastern_european": {
		"skin_tones": [[255, 206, 186], [255, 195, 173], [255, 184, 161]],
		"hair_colors": [[200, 180, 150], [180, 150, 100], [150, 120, 80], [100, 80, 60]],
		"eye_colors": [[100, 150, 200], [120, 180, 150], [150, 120, 80], [100, 100, 100]]
	}
}

# Political parties
const PARTY_DATA := [
	{"name": "National Front", "short": "NF", "color": Color(0.8, 0.2, 0.2), "icon": "🦁", "ideology": "nationalist"},
	{"name": "Democratic Union", "short": "DU", "color": Color(0.2, 0.4, 0.8), "icon": "🕊️", "ideology": "liberal"},
	{"name": "Labour Party", "short": "LP", "color": Color(0.8, 0.3, 0.3), "icon": "⚒️", "ideology": "socialist"},
	{"name": "Green Alliance", "short": "GA", "color": Color(0.2, 0.7, 0.2), "icon": "🌿", "ideology": "environmentalist"},
	{"name": "Conservative Party", "short": "CP", "color": Color(0.2, 0.2, 0.6), "icon": "🏛️", "ideology": "conservative"},
	{"name": "Regional Development", "short": "RD", "color": Color(0.8, 0.6, 0.2), "icon": "🗺️", "ideology": "regionalist"},
	{"name": "Trade Party", "short": "TP", "color": Color(0.6, 0.4, 0.8), "icon": "💰", "ideology": "mercantilist"}
]

# Football styles
const FOOTBALL_STYLES := ["attacking", "defensive", "technical", "physical", "tactical"]

# Climate types
const CLIMATE_TYPES := ["northern", "temperate", "southern", "continental"]


func generate_world() -> void:
	generation_started.emit()
	
	# Generate regions
	generate_regions()
	emit_progress(0.2, "Generated 16 regions")
	
	# Generate cities
	generate_cities()
	emit_progress(0.4, "Generated 40+ cities")
	
	# Generate political parties
	generate_political_parties()
	emit_progress(0.6, "Generated 7 political parties")
	
	# Generate teams
	generate_teams()
	emit_progress(0.8, "Generated teams")
	
	# Generate players
	generate_players()
	emit_progress(1.0, "World generation complete")
	
	generation_completed.emit()


func emit_progress(progress: float, message: String) -> void:
	generation_progress.emit(progress, message)


func generate_regions() -> void:
	GameState.regions.clear()
	
	for i in range(16):
		var region = generate_single_region(i)
		GameState.regions.append(region)


func generate_single_region(index: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = index
	
	var ethnic_keys = ETHNIC_GROUPS.keys()
	var ethnic_group = ethnic_keys[rng.randi() % ethnic_keys.size()]
	
	var climate = CLIMATE_TYPES[rng.randi() % CLIMATE_TYPES.size()]
	var football_style = FOOTBALL_STYLES[rng.randi() % FOOTBALL_STYLES.size()]
	
	# Generate polygon points for the region
	var polygon = generate_region_polygon(index, rng)
	
	# Assign political party
	var party_index = rng.randi() % PARTY_DATA.size()
	
	return {
		"id": index,
		"name": REGION_NAMES[index],
		"polygon": polygon,
		"climate": climate,
		"ethnic_group": ethnic_group,
		"football_style": football_style,
		"ruling_party": party_index,
		"tension": rng.randi_range(0, 100),
		"talent_modifier": randf_range(0.5, 2.0),
		"reputation": rng.randi_range(0, 100),
		"population": rng.randi_range(1000000, 12000000)
	}


func generate_region_polygon(index: int, rng: RandomNumberGenerator) -> PackedVector2Array:
	var polygon = PackedVector2Array()
	var center_x = (index % 4) * 400 + 200
	var center_y = (index / 4) * 300 + 150
	
	var num_points = rng.randi_range(4, 8)
	var radius = rng.randi_range(80, 120)
	
	for i in range(num_points):
		var angle = (TWO_PI / num_points) * i + rng.randf() * 0.3
		var r = radius * (0.8 + rng.randf() * 0.4)
		var x = center_x + cos(angle) * r
		var y = center_y + sin(angle) * r
		polygon.append(Vector2(x, y))
	
	return polygon


func generate_cities() -> void:
	GameState.cities.clear()
	
	var city_count = 40 + randi() % 10
	
	for i in range(city_count):
		var city = generate_single_city(i)
		GameState.cities.append(city)


func generate_single_city(index: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = index + 100
	
	var region_index = rng.randi() % GameState.regions.size()
	var region = GameState.regions[region_index]
	
	var is_capital = (index == 0)
	
	var name = generate_city_name(rng)
	
	return {
		"id": index,
		"name": name,
		"region_id": region_index,
		"is_capital": is_capital,
		"population": rng.randi_range(50000, 2000000) if not is_capital else rng.randi_range(2000000, 5000000),
		"x": rng.randi_range(100, 1700),
		"y": rng.randi_range(100, 900)
	}


func generate_city_name(rng: RandomNumberGenerator) -> String:
	var prefix = CITY_PREFIXES[rng.randi() % CITY_PREFIXES.size()]
	var suffix = CITY_SUFFIXES[rng.randi() % CITY_SUFFIXES.size()]
	return prefix + suffix


func generate_political_parties() -> void:
	GameState.political_parties.clear()
	
	for i in range(PARTY_DATA.size()):
		var party = PARTY_DATA[i].duplicate()
		party["id"] = i
		party["support"] = randf_range(0.1, 0.3)
		party["regions_controlled"] = []
		GameState.political_parties.append(party)


func generate_teams() -> void:
	GameState.teams.clear()
	
	# Generate 1-2 teams per region
	for region in GameState.regions:
		var team_count = 1 if randf() < 0.5 else 2
		for i in range(team_count):
			var team = generate_team(region)
			GameState.teams.append(team)


func generate_team(region: Dictionary) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = region.id * 1000 + randi()
	
	var team_name = generate_team_name(region, rng)
	var short_name = team_name.substr(0, 3).to_upper()
	
	# Generate logo configuration
	var logo_config = generate_logo_config(rng)
	
	return {
		"id": GameState.teams.size(),
		"name": team_name,
		"short_name": short_name,
		"region_id": region.id,
		"founded": rng.randi_range(1890, 1995),
		"stadium": generate_stadium_name(rng),
		"stadium_capacity": rng.randi_range(10000, 80000),
		"logo_config": logo_config,
		"finances": {
			"balance": rng.randi_range(1000000, 50000000),
			"weekly_income": rng.randi_range(50000, 500000),
			"weekly_expenses": rng.randi_range(40000, 400000)
		},
		"reputation": rng.randi_range(30, 95),
		"league_position": 0,
		"points": 0,
		"played": 0,
		"wins": 0,
		"draws": 0,
		"losses": 0,
		"goals_for": 0,
		"goals_against": 0
	}


func generate_team_name(region: Dictionary, rng: RandomNumberGenerator) -> String:
	var prefixes = ["FC", "United", "City", "Athletic", "Real", "Sporting", "Inter", "Dynamo"]
	var suffixes = ["Football Club", "FC", "United", "City", "Athletic", "Rovers", "Wanderers"]
	
	var prefix = prefixes[rng.randi() % prefixes.size()]
	var suffix = suffixes[rng.randi() % suffixes.size()]
	var region_name = region.name
	
	var pattern = rng.randi() % 3
	match pattern:
		0: return "%s %s" % [prefix, region_name]
		1: return "%s %s %s" % [prefix, region_name, suffix]
		2: return "FC %s" % region_name
	
	return "FC " + region_name


func generate_stadium_name(rng: RandomNumberGenerator) -> String:
	var names = ["Stadium", "Arena", "Park", "Field", "Ground", "Bowl", "Coliseum"]
	var adjectives = ["Central", "Grand", "Royal", "National", "City", "United", "Memorial"]
	
	return adjectives[rng.randi() % adjectives.size()] + " " + names[rng.randi() % names.size()]


func generate_logo_config(rng: RandomNumberGenerator) -> Dictionary:
	const SHAPES = ["shield", "circle", "star", "hexagon", "diamond"]
	const EMBLEMS = ["ball", "lightning", "crown", "wings", "flame", "none"]
	const COLORS = ["red", "blue", "green", "black", "purple", "orange", "maroon", "sky"]
	
	return {
		"shape": SHAPES[rng.randi() % SHAPES.size()],
		"emblem": EMBLEMS[rng.randi() % EMBLEMS.size()],
		"color_scheme": COLORS[rng.randi() % COLORS.size()],
		"border_thickness": rng.randi_range(1, 3),
		"text": ""
	}


func generate_players() -> void:
	GameState.players.clear()
	
	# Generate 500-800 players
	var player_count = 500 + randi() % 301
	
	for i in range(player_count):
		var player = generate_single_player(i)
		GameState.players.append(player)


func generate_single_player(index: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = index + 5000
	
	var region_index = rng.randi() % GameState.regions.size()
	var region = GameState.regions[region_index]
	
	var age = rng.randi_range(17, 36)
	var position = get_random_position(rng)
	
	# Generate skills based on region's football style
	var skills = generate_skills(rng, region, age, position)
	
	# Get ethnic group from region
	var ethnic_group = region.ethnic_group
	
	# Generate portrait seed for deterministic generation
	var portrait_seed = index * 12345
	
	return {
		"id": index,
		"name": generate_player_name(region, rng),
		"age": age,
		"position": position,
		"region_id": region_index,
		"skills": skills,
		"overall": calculate_overall(skills),
		"potential": calculate_potential(age, skills),
		"ethnic_group": ethnic_group,
		"portrait_seed": portrait_seed,
		"morale": rng.randi_range(60, 100),
		"form": rng.randi_range(60, 100),
		"fitness": rng.randi_range(80, 100),
		"injured": false,
		"injury_type": "",
		"injury_weeks": 0,
		"contract": {
			"weekly_wage": rng.randi_range(1000, 100000),
			"years_remaining": rng.randi_range(1, 5),
			"release_clause": rng.randi_range(1000000, 50000000)
		},
		"team_id": -1,  # Will be assigned later
		"stats": {
			"appearances": 0,
			"goals": 0,
			"assists": 0,
			"yellow_cards": 0,
			"red_cards": 0
		},
		"advanced_stats": {
			"xG": 0.0,
			"xA": 0.0,
			"PPDA": 0.0
		}
	}


func generate_player_name(region: Dictionary, rng: RandomNumberGenerator) -> String:
	var first_names = get_first_names_for_ethnicity(region.ethnic_group)
	var last_names = get_last_names_for_ethnicity(region.ethnic_group)
	
	var first = first_names[rng.randi() % first_names.size()]
	var last = last_names[rng.randi() % last_names.size()]
	
	return first + " " + last


func get_first_names_for_ethnicity(ethnicity: String) -> Array:
	var names_db = {
		"nordic": ["Erik", "Lars", "Anders", "Nils", "Sven", "Bjorn", "Magnus", "Olaf"],
		"western_european": ["James", "John", "Robert", "Michael", "William", "David", "Richard"],
		"central_european": ["Thomas", "Michael", "Andreas", "Stefan", "Markus", "Daniel"],
		"southern_european": ["Marco", "Alessandro", "Giuseppe", "Antonio", "Francesco"],
		"eastern_european": ["Alexander", "Dmitri", "Viktor", "Andrei", "Nikolai", "Sergei"]
	}
	return names_db.get(ethnicity, names_db.western_european)


func get_last_names_for_ethnicity(ethnicity: String) -> Array:
	var names_db = {
		"nordic": ["Anderson", "Johansson", "Karlsson", "Nilsson", "Eriksson", "Larsson"],
		"western_european": ["Smith", "Johnson", "Williams", "Brown", "Jones", "Taylor"],
		"central_european": ["Mueller", "Schmidt", "Schneider", "Fischer", "Weber"],
		"southern_european": ["Rossi", "Russo", "Ferrari", "Esposito", "Bianchi"],
		"eastern_european": ["Ivanov", "Petrov", "Sokolov", "Lebedev", "Kozlov"]
	}
	return names_db.get(ethnicity, names_db.western_european)


func get_random_position(rng: RandomNumberGenerator) -> String:
	var positions = ["GK", "DEF", "DEF", "DEF", "MID", "MID", "MID", "FWD", "FWD"]
	return positions[rng.randi() % positions.size()]


func generate_skills(rng: RandomNumberGenerator, region: Dictionary, age: int, position: String) -> Dictionary:
	var base = 40 + rng.randi_range(0, 40)
	var style_bonus = get_style_bonus(region.football_style, position)
	
	var skills = {
		"attacking": clamp(base + rng.randi_range(-10, 20) + style_bonus.attack, 1, 99),
		"defending": clamp(base + rng.randi_range(-10, 20) + style_bonus.defense, 1, 99),
		"pace": clamp(base + rng.randi_range(-10, 20), 1, 99),
		"passing": clamp(base + rng.randi_range(-10, 20) + style_bonus.passing, 1, 99),
		"shooting": clamp(base + rng.randi_range(-10, 20) + style_bonus.shooting, 1, 99),
		"dribbling": clamp(base + rng.randi_range(-10, 20), 1, 99),
		"physical": clamp(base + rng.randi_range(-10, 20) + style_bonus.physical, 1, 99),
		"goalkeeping": 0
	}
	
	if position == "GK":
		skills.goalkeeping = clamp(50 + rng.randi_range(0, 40), 1, 99)
		skills.attacking = 10 + rng.randi_range(0, 20)
	
	return skills


func get_style_bonus(style: String, position: String) -> Dictionary:
	var bonuses = {
		"attacking": {"attack": 10, "defense": -5, "passing": 5, "shooting": 10, "physical": 0},
		"defensive": {"attack": -5, "defense": 10, "passing": 0, "shooting": -5, "physical": 5},
		"technical": {"attack": 5, "defense": 0, "passing": 10, "shooting": 5, "physical": -5},
		"physical": {"attack": 0, "defense": 5, "passing": -5, "shooting": 5, "physical": 10},
		"tactical": {"attack": 5, "defense": 5, "passing": 5, "shooting": 0, "physical": 0}
	}
	return bonuses.get(style, bonuses.tactical)


func calculate_overall(skills: Dictionary) -> int:
	var values = skills.values()
	var sum = 0
	for v in values:
		sum += v
	return int(sum / values.size())


func calculate_potential(age: int, skills: Dictionary) -> int:
	var overall = calculate_overall(skills)
	if age < 23:
		return min(99, overall + randi_range(5, 20))
	elif age < 28:
		return min(99, overall + randi_range(0, 10))
	else:
		return overall
