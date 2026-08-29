extends Control

@onready var groups_container: VBoxContainer = $MarginContainer/VBoxContainer/GroupsContainer/ScrollContainer/GroupsList
@onready var security_level_label: Label = $MarginContainer/VBoxContainer/SecurityPanel/SecurityLevelLabel
@onready var fan_morale_label: Label = $MarginContainer/VBoxContainer/MoralePanel/FanMoraleLabel
@onready var incidents_container: VBoxContainer = $MarginContainer/VBoxContainer/IncidentsContainer/ScrollContainer/IncidentsList

	var fan_groups: Array[Dictionary] = []
	var incidents: Array[Dictionary] = []
	var security_level: int = 2

func _ready() -> void:
	initialize_fan_groups()
	load_incidents()
	setup_security_buttons()
	update_display()
	update_fan_morale()

func initialize_fan_groups() -> void:
	fan_groups = [
	{"name": "Ultras Elite", "type": "Ultras", "aggression": 85, "size": 450, "mood": "Angry"},
	{"name": "Red Hooligans", "type": "Hooligans", "aggression": 95, "size": 120, "mood": "Violent"},
	{"name": "Family Stand", "type": "Moderates", "aggression": 20, "size": 2500, "mood": "Happy"},
	{"name": "Season Ticket Holders", "type": "Subscribers", "aggression": 30, "size": 1800, "mood": "Neutral"},
	{"name": "Youth Brigade", "type": "Youth", "aggression": 45, "size": 600, "mood": "Excited"}
	]

func load_incidents() -> void:
	incidents = [
	{"date": "Week 5", "type": "Vandalism", "severity": "Low", "description": "Graffiti on stadium walls"},
	{"date": "Week 8", "type": "Fighting", "severity": "Medium", "description": "Clash between rival fans"},
	{"date": "Week 12", "type": "Pitch Invasion", "severity": "High", "description": "Fan ran onto the pitch"}
	]

func setup_security_buttons() -> void:
	var security_buttons := $MarginContainer/VBoxContainer/SecurityPanel/SecurityButtons
	for i in range(5):
	var btn := Button.new()
	btn.text = "Level %d" % (i + 1)
	btn.pressed.connect(_on_security_level_pressed.bind(i + 1))
	if i == security_level - 1:
	btn.add_theme_stylebox_override("normal", get_stylebox("pressed", "Button"))
	security_buttons.add_child(btn)

func _on_security_level_pressed(level: int) -> void:
	security_level = level
	var costs := [0, 5000, 10000, 20000, 35000]
	GameState.money -= costs[level - 1]
	EventManager.queue_event("Security Updated", "Security level changed to Level %d. Weekly cost: £%d" % [level, costs[level - 1]], EventManager.EventType.INFO)
	GameState.save_game()
	setup_security_buttons()
	update_security_display()

func update_display() -> void:
	update_groups_display()
	update_incidents_display()
	update_security_display()

func update_groups_display() -> void:
	for child in groups_container.get_children():
	child.queue_free()

	for group in fan_groups:
	var group_card := create_group_card(group)
	groups_container.add_child(group_card)

func create_group_card(group: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 90)

	var hbox := HBoxContainer.new()
	hbox.set_columns(5)
	card.add_child(hbox)

# Group type icon
	var type_label := Label.new()
	type_label.text = get_type_icon(group.get("type", ""))
	type_label.add_theme_font_size_override("font_size", 24)
	type_label.custom_minimum_size = Vector2(50, 50)
	hbox.add_child(type_label)

# Group info
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = "%s (%s)" % [group.get("name", "Unknown"), group.get("type", "?")]
	name_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(name_label)

	var stats_label := Label.new()
	stats_label.text = "Size: %d | Aggression: %d%% | Mood: %s" % [
	group.get("size", 0),
	group.get("aggression", 50),
	group.get("mood", "Neutral")
	]
	info_vbox.add_child(stats_label)

# Risk indicator
	var risk_vbox := VBoxContainer.new()
	risk_vbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_child(risk_vbox)

	var risk_color := Color.GREEN if group.get("aggression", 50) < 40 else Color.YELLOW if group.get("aggression", 50) < 70 else Color.RED
	var risk_label := Label.new()
	risk_label.text = "Risk: %s" % ("Low" if group.get("aggression", 50) < 40 else "Medium" if group.get("aggression", 50) < 70 else "High")
	risk_label.add_theme_color_override("font_color", risk_color)
	risk_vbox.add_child(risk_label)

	return card

func get_type_icon(type_name: String) -> String:
	match type_name:
	"Ultras": return "🔥"
	"Hooligans": return "⚔️"
	"Moderates": return "👨‍👩‍👧‍👦"
	"Subscribers": return "🎫"
	"Youth": return "🎓"
	return "❓"

func update_incidents_display() -> void:
	for child in incidents_container.get_children():
	child.queue_free()

	for incident in incidents:
	var incident_label := Label.new()
	incident_label.text = "[%s] %s - %s: %s" % [
	incident.get("severity", "Low"),
	incident.get("date", "Unknown"),
	incident.get("type", "Unknown"),
	incident.get("description", "")
	]
	incident_label.add_theme_color_override("font_color", 
	Color.RED if incident.get("severity") == "High" else 
	Color.YELLOW if incident.get("severity") == "Medium" else 
	Color.WHITE)
	incidents_container.add_child(incident_label)

func update_security_display() -> void:
	var security_info := $MarginContainer/VBoxContainer/SecurityPanel/SecurityInfo
	if security_info:
	security_info.text = "Current Security Level: %d/5\nWeekly Cost: £%d" % [
	security_level,
	[0, 5000, 10000, 20000, 35000][security_level - 1]
	]

func update_fan_morale() -> void:
	var morale := GameState.fan_relations
	var morale_text := "Fan Morale: %d%%" % morale
	fan_morale_label.text = morale_text

	if morale > 75:
	fan_morale_label.add_theme_color_override("font_color", Color.GREEN)
	elif morale > 50:
	fan_morale_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
	fan_morale_label.add_theme_color_override("font_color", Color.RED)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
