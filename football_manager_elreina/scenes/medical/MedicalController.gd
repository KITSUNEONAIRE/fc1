extends Control

@onready var injured_players_container: VBoxContainer = $MarginContainer/VBoxContainer/InjuredPlayersContainer/ScrollContainer/InjuredList
@onready var medical_staff_container: VBoxContainer = $MarginContainer/VBoxContainer/MedicalStaffContainer/ScrollContainer/StaffList
@onready var treatment_options_container: VBoxContainer = $MarginContainer/VBoxContainer/TreatmentPanel/TreatmentOptions

var injured_players: Array[Dictionary] = []
var medical_staff: Array[Dictionary] = []

func _ready() -> void:
load_injured_players()
load_medical_staff()
update_display()

func load_injured_players() -> void:
injured_players = [
{"name": "John Smith", "position": "ST", "injury_type": "Hamstring Strain", "severity": "Medium", "weeks_out": 3, "recovery_progress": 45},
{"name": "Mike Johnson", "position": "CB", "injury_type": "Ankle Sprain", "severity": "Low", "weeks_out": 1, "recovery_progress": 80},
{"name": "David Lee", "position": "CM", "injury_type": "ACL Tear", "severity": "High", "weeks_out": 24, "recovery_progress": 15},
{"name": "Tom Wilson", "position": "GK", "injury_type": "Shoulder Dislocation", "severity": "Medium", "weeks_out": 6, "recovery_progress": 30}
]

medical_staff = [
{"name": "Dr. Sarah Brown", "role": "Head Physician", "skill": 85, "specialization": "General"},
{"name": "James Miller", "role": "Physiotherapist", "skill": 78, "specialization": "Rehabilitation"},
{"name": "Dr. Emily Chen", "role": "Surgeon", "skill": 92, "specialization": "Orthopedic"},
{"name": "Mark Davis", "role": "Sports Psychologist", "skill": 70, "specialization": "Mental Health"}
]

func update_display() -> void:
update_injured_display()
update_staff_display()

func update_injured_display() -> void:
for child in injured_players_container.get_children():
child.queue_free()

for player in injured_players:
var card := create_injury_card(player)
injured_players_container.add_child(card)

func create_injury_card(player: Dictionary) -> PanelContainer:
var card := PanelContainer.new()
card.custom_minimum_size = Vector2(0, 100)

var hbox := HBoxContainer.new()
hbox.set_columns(5)
card.add_child(hbox)

# Severity indicator
var severity_rect := ColorRect.new()
severity_rect.custom_minimum_size = Vector2(10, 60)
severity_rect.color = Color.RED if player.get("severity") == "High" else Color.YELLOW if player.get("severity") == "Medium" else Color.GREEN
hbox.add_child(severity_rect)

# Player info
var info_vbox := VBoxContainer.new()
info_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
hbox.add_child(info_vbox)

var name_label := Label.new()
name_label.text = "%s (%s)" % [player.get("name", "Unknown"), player.get("position", "?")]
name_label.add_theme_font_size_override("font_size", 18)
info_vbox.add_child(name_label)

var injury_label := Label.new()
injury_label.text = "Injury: %s" % player.get("injury_type", "Unknown")
info_vbox.add_child(injury_label)

var weeks_label := Label.new()
weeks_label.text = "Weeks Out: %d | Recovery: %d%%" % [player.get("weeks_out", 0), player.get("recovery_progress", 0)]
info_vbox.add_child(weeks_label)

# Progress bar
var progress_bar := ProgressBar.new()
progress_bar.custom_minimum_size = Vector2(150, 20)
progress_bar.max_value = 100
progress_bar.value = player.get("recovery_progress", 0)
hbox.add_child(progress_bar)

# Treatment button
var treat_btn := Button.new()
treat_btn.text = "Treat"
treat_btn.pressed.connect(_on_treat_pressed.bind(player))
hbox.add_child(treat_btn)

return card

func update_staff_display() -> void:
for child in medical_staff_container.get_children():
child.queue_free()

for staff in medical_staff:
var card := create_staff_card(staff)
medical_staff_container.add_child(card)

func create_staff_card(staff: Dictionary) -> PanelContainer:
var card := PanelContainer.new()
card.custom_minimum_size = Vector2(0, 70)

var hbox := HBoxContainer.new()
hbox.set_columns(4)
card.add_child(hbox)

var role_label := Label.new()
role_label.text = get_role_icon(staff.get("role", ""))
role_label.add_theme_font_size_override("font_size", 24)
role_label.custom_minimum_size = Vector2(50, 50)
hbox.add_child(role_label)

var info_vbox := VBoxContainer.new()
info_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
hbox.add_child(info_vbox)

var name_label := Label.new()
name_label.text = "%s - %s" % [staff.get("name", "Unknown"), staff.get("role", "?")]
name_label.add_theme_font_size_override("font_size", 16)
info_vbox.add_child(name_label)

var skill_label := Label.new()
skill_label.text = "Skill: %d | Specialization: %s" % [staff.get("skill", 50), staff.get("specialization", "General")]
info_vbox.add_child(skill_label)

return card

func get_role_icon(role: String) -> String:
match role:
"Head Physician": return "👨‍⚕️"
"Physiotherapist": return "💆"
"Surgeon": return "🔪"
"Sports Psychologist": return "🧠"
return "❓"

func _on_treat_pressed(player: Dictionary) -> void:
var treatment_cost := 5000 if player.get("severity") == "High" else 2000 if player.get("severity") == "Medium" else 500

if GameState.money >= treatment_cost:
GameState.money -= treatment_cost
player["recovery_progress"] = min(100, player.get("recovery_progress", 0) + 20)

if player.get("recovery_progress", 0) >= 100:
EventManager.queue_event("Player Recovered", "%s has fully recovered from %s!" % [player.get("name", "Player"), player.get("injury_type", "injury")], EventManager.EventType.SUCCESS)
injured_players.erase(player)
else:
EventManager.queue_event("Treatment Applied", "Treatment applied to %s. Recovery: %d%%" % [player.get("name", "Player"), player.get("recovery_progress", 0)], EventManager.EventType.INFO)

GameState.save_game()
update_injured_display()
else:
EventManager.queue_event("Insufficient Funds", "Cannot afford £%d treatment" % treatment_cost, EventManager.EventType.ERROR)

func _on_back_pressed() -> void:
get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
