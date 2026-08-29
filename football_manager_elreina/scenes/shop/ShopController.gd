extends Control

@onready var pp_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/PPLabel
@onready var items_container: VBoxContainer = $MarginContainer/VBoxContainer/ItemsContainer/ScrollContainer/ItemsList

	var shop_items: Array[Dictionary] = []

func _ready() -> void:
	initialize_shop_items()
	update_display()
	update_pp_label()

func initialize_shop_items() -> void:
	shop_items = [
	{"name": "Player Development Boost", "description": "Instantly improve a young player's development", "cost": 50, "icon": "⭐", "category": "Development"},
	{"name": "Facility Upgrade (Training)", "description": "Upgrade training facilities for better player growth", "cost": 150, "icon": "🏋️", "category": "Infrastructure"},
	{"name": "Facility Upgrade (Youth)", "description": "Improve youth academy recruitment", "cost": 200, "icon": "🎓", "category": "Infrastructure"},
	{"name": "Political Influence", "description": "Gain favor with government officials", "cost": 100, "icon": "🏛️", "category": "Politics"},
	{"name": "Media Campaign", "description": "Improve media relations significantly", "cost": 80, "icon": "📰", "category": "Media"},
	{"name": "Fan Morale Boost", "description": "Organize fan event to boost morale", "cost": 60, "icon": "🎉", "category": "Fans"},
	{"name": "Scout Network Expansion", "description": "Unlock more regions for scouting", "cost": 120, "icon": "🔍", "category": "Scouting"},
	{"name": "Medical Equipment Upgrade", "description": "Better injury recovery rates", "cost": 90, "icon": "🏥", "category": "Medical"},
	{"name": "Security Enhancement", "description": "Reduce fan incident risks", "cost": 70, "icon": "👮", "category": "Security"},
	{"name": "Sponsor Attraction", "description": "Attract better sponsorship deals", "cost": 110, "icon": "💼", "category": "Finance"}
	]

func update_display() -> void:
	for child in items_container.get_children():
	child.queue_free()

	for item in shop_items:
	var card := create_shop_card(item)
	items_container.add_child(card)

func create_shop_card(item: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)

	var hbox := HBoxContainer.new()
	hbox.set_columns(5)
	card.add_child(hbox)

# Icon
	var icon_label := Label.new()
	icon_label.text = item.get("icon", "❓")
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.custom_minimum_size = Vector2(60, 60)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)

# Item info
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = item.get("name", "Unknown Item")
	name_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = item.get("description", "No description")
	desc_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(desc_label)

	var category_label := Label.new()
	category_label.text = "Category: %s" % item.get("category", "General")
	info_vbox.add_child(category_label)

# Cost and buy button
	var right_vbox := VBoxContainer.new()
	right_vbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_child(right_vbox)

	var cost_label := Label.new()
	cost_label.text = "%d PP" % item.get("cost", 0)
	cost_label.add_theme_font_size_override("font_size", 20)
	cost_label.add_theme_color_override("font_color", Color(1, 0.84, 0))  # Gold
	right_vbox.add_child(cost_label)

	var buy_btn := Button.new()
	buy_btn.text = "Purchase"
	buy_btn.pressed.connect(_on_buy_pressed.bind(item))
	right_vbox.add_child(buy_btn)

	return card

func update_pp_label() -> void:
	pp_label.text = "Prestige Points: %d" % GameState.prestige_points

func _on_buy_pressed(item: Dictionary) -> void:
	var cost := item.get("cost", 0)

	if GameState.prestige_points >= cost:
	GameState.prestige_points -= cost
	apply_item_effect(item)
	EventManager.queue_event("Purchase Successful", 
	"Purchased: %s\nRemaining PP: %d" % [item.get("name", "Item"), GameState.prestige_points], 
	EventManager.EventType.SUCCESS)
	GameState.save_game()
	update_pp_label()
	else:
	EventManager.queue_event("Insufficient PP", 
	"Need %d PP for %s. You have %d PP." % [cost, item.get("name", "Item"), GameState.prestige_points], 
	EventManager.EventType.ERROR)

func apply_item_effect(item: Dictionary) -> void:
	match item.get("name", ""):
	"Player Development Boost":
	EventManager.queue_event("Effect Applied", "Player development boosted! Check your squad.", EventManager.EventType.INFO)
	"Facility Upgrade (Training)":
	EventManager.queue_event("Effect Applied", "Training facilities upgraded!", EventManager.EventType.INFO)
	"Facility Upgrade (Youth)":
	EventManager.queue_event("Effect Applied", "Youth academy improved!", EventManager.EventType.INFO)
	"Political Influence":
	GameState.state_relations = clamp(GameState.state_relations + 15, 0, 100)
	"Media Campaign":
	GameState.media_relations = clamp(GameState.media_relations + 20, 0, 100)
	"Fan Morale Boost":
	GameState.fan_relations = clamp(GameState.fan_relations + 15, 0, 100)
	_:
	EventManager.queue_event("Effect Applied", "%s effect activated!" % item.get("name", "Item"), EventManager.EventType.INFO)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
