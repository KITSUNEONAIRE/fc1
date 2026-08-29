extends Control

@onready var parties_container: VBoxContainer = $MarginContainer/VBoxContainer/PartiesContainer/ScrollContainer/PartiesList
@onready var regions_container: GridContainer = $MarginContainer/VBoxContainer/RegionsMapContainer/RegionsGrid
@onready var tension_slider: HSlider = $MarginContainer/VBoxContainer/TensionPanel/TensionSlider
@onready var tension_value_label: Label = $MarginContainer/VBoxContainer/TensionPanel/TensionValueLabel
@onready var election_info: Label = $MarginContainer/VBoxContainer/ElectionPanel/ElectionInfoLabel

var parties: Array[Dictionary] = []
var regions_data: Array[Dictionary] = []
var selected_party_index: int = -1

func _ready() -> void:
load_political_data()
setup_tension_slider()
update_parties_display()
update_regions_display()
update_election_info()

func load_political_data() -> void:
parties = GameState.political_parties.duplicate(true)
regions_data = GameState.regions.duplicate(true)

func setup_tension_slider() -> void:
tension_slider.min_value = 0
tension_slider.max_value = 100
tension_slider.step = 1
tension_slider.value = 50
tension_slider.value_changed.connect(_on_tension_changed)

func _on_tension_changed(value: float) -> void:
tension_value_label.text = "Current National Tension: %d%%" % int(value)
if value > 75:
tension_value_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
elif value > 50:
tension_value_label.add_theme_color_override("font_color", Color(1, 0.65, 0))
else:
tension_value_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))

func update_parties_display() -> void:
for child in parties_container.get_children():
child.queue_free()

for i in range(parties.size()):
var party := parties[i]
var party_card := create_party_card(party, i)
parties_container.add_child(party_card)

func create_party_card(party: Dictionary, index: int) -> PanelContainer:
var card := PanelContainer.new()
card.custom_minimum_size = Vector2(0, 100)

var hbox := HBoxContainer.new()
hbox.set_columns(5)
card.add_child(hbox)

# Party icon/color
var color_rect := ColorRect.new()
color_rect.custom_minimum_size = Vector2(60, 60)
color_rect.color = party.get("color", Color.WHITE)
hbox.add_child(color_rect)

# Party info
var info_vbox := VBoxContainer.new()
info_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
hbox.add_child(info_vbox)

var name_label := Label.new()
name_label.text = "%s (%s)" % [party.get("name", "Unknown"), party.get("short_name", "???")]
name_label.add_theme_font_size_override("font_size", 18)
info_vbox.add_child(name_label)

var ideology_label := Label.new()
ideology_label.text = "Ideology: %s" % party.get("ideology", "Unknown")
info_vbox.add_child(ideology_label)

var regions_label := Label.new()
var controlled_regions := get_controlled_regions_count(index)
regions_label.text = "Controlled Regions: %d/16" % controlled_regions
info_vbox.add_child(regions_label)

# Support level
var support_vbox := VBoxContainer.new()
support_vbox.alignment = BoxContainer.ALIGNMENT_END
hbox.add_child(support_vbox)

var support_label := Label.new()
support_label.text = "National Support: %d%%" % party.get("support", 15)
support_label.add_theme_font_size_override("font_size", 16)
support_vbox.add_child(support_label)

var leader_label := Label.new()
leader_label.text = "Leader: %s" % party.get("leader", "Unknown")
support_vbox.add_child(leader_label)

# Action button
var action_btn := Button.new()
action_btn.text = "View Details"
action_btn.pressed.connect(_on_party_details_pressed.bind(party))
hbox.add_child(action_btn)

return card

func get_controlled_regions_count(party_index: int) -> int:
var count := 0
for region in regions_data:
if region.get("ruling_party", 0) == party_index:
count += 1
return count

func update_regions_display() -> void:
for child in regions_container.get_children():
child.queue_free()

for region in regions_data:
var region_btn := create_region_button(region)
regions_container.add_child(region_btn)

func create_region_button(region: Dictionary) -> Button:
var btn := Button.new()
btn.custom_minimum_size = Vector2(140, 60)

var party_index := region.get("ruling_party", 0)
var party_color := Color.WHITE
if party_index >= 0 and party_index < parties.size():
party_color = parties[party_index].get("color", Color.WHITE)

var tension := region.get("tension", 0)

btn.text = "%s\nTension: %d%%" % [region.get("name", "Unknown"), tension]
btn.add_theme_color_override("font_color", Color.WHITE if tension < 50 else Color.YELLOW if tension < 75 else Color.RED)

btn.pressed.connect(_on_region_pressed.bind(region))

return btn

func _on_region_pressed(region: Dictionary) -> void:
EventManager.queue_event("Region Details", 
"%s (Capital: %s)\nRuling Party: %s\nTension: %d%%\nPopulation: %sM" % [
region.get("name", "Unknown"),
region.get("capital", "Unknown"),
parties[region.get("ruling_party", 0)].get("name", "Unknown") if region.get("ruling_party", 0) >= 0 else "None",
region.get("tension", 0),
str(region.get("population", 1.0) / 1000000.0).pad_decimals(1)
], 
EventManager.EventType.INFO)

func _on_party_details_pressed(party: Dictionary) -> void:
var policies := party.get("policies", ["Tax Reform", "Infrastructure", "Youth Development"])
var policy_text := ""
for policy in policies:
policy_text += "• " + policy + "\n"

EventManager.queue_event(party.get("name", "Party"), 
"Ideology: %s\nLeader: %s\n\nKey Policies:\n%s" % [
party.get("ideology", "Unknown"),
party.get("leader", "Unknown"),
policy_text
], 
EventManager.EventType.INFO)

func update_election_info() -> void:
var next_presidential := TimeSystem.get_weeks_until_next_election("presidential")
var next_parliamentary := TimeSystem.get_weeks_until_next_election("parliamentary")

election_info.text = "Next Presidential Election: %d weeks\nNext Parliamentary Election: %d weeks" % [
next_presidential,
next_parliamentary
]

func _on_back_pressed() -> void:
get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
