extends Control

## Dashboard Controller
## Main game interface for managing the club

@onready var club_name_label: Label = $TopBar/HBoxContainer/ClubName
@onready var date_label: Label = $TopBar/HBoxContainer/DateLabel
@onready var week_label: Label = $TopBar/HBoxContainer/WeekLabel
@onready var prestige_label: Label = $TopBar/HBoxContainer/PrestigeLabel
@onready var money_label: Label = $TopBar/HBoxContainer/MoneyLabel

@onready var board_trust_value: Label = $ContentArea/MarginContainer/DashboardContent/GridContainer/BoardTrustValue
@onready var fan_relations_value: Label = $ContentArea/MarginContainer/DashboardContent/GridContainer/FanRelationsValue
@onready var media_relations_value: Label = $ContentArea/MarginContainer/DashboardContent/GridContainer/MediaRelationsValue
@onready var state_relations_value: Label = $ContentArea/MarginContainer/DashboardContent/GridContainer/StateRelationsValue
@onready var notifications_list: ItemList = $ContentArea/MarginContainer/DashboardContent/NotificationsList

@onready var advance_week_btn: Button = $NavPanel/VBoxContainer/AdvanceWeekBtn

const COLOR_BACKGROUND := Color(0.031, 0.047, 0.078)
const COLOR_PANEL := Color(0.102, 0.149, 0.2)
const COLOR_ACCENT_BLUE := Color(0.118, 0.565, 1.0)
const COLOR_ACCENT_GOLD := Color(1.0, 0.843, 0.0)
const COLOR_GREEN := Color(0.196, 0.804, 0.196)


func _ready() -> void:
	_setup_signals()
	_update_dashboard()


func _setup_signals() -> void:
	GameState.state_changed.connect(_on_game_state_changed)
	TimeSystem.week_advanced.connect(_on_week_advanced)
	advance_week_btn.pressed.connect(_on_advance_week_pressed)
	
	# Setup navigation buttons
	$NavPanel/VBoxContainer/TeamBtn.pressed.connect(_on_team_pressed)
	$NavPanel/VBoxContainer/MapBtn.pressed.connect(_on_map_pressed)
	$NavPanel/VBoxContainer/FinancesBtn.pressed.connect(_on_finances_pressed)
	$NavPanel/VBoxContainer/PoliticsBtn.pressed.connect(_on_politics_pressed)
	$NavPanel/VBoxContainer/FansBtn.pressed.connect(_on_fans_pressed)
	$NavPanel/VBoxContainer/ShopBtn.pressed.connect(_on_shop_pressed)
	$NavPanel/VBoxContainer/MenuBtn.pressed.connect(_on_menu_pressed)


func _update_dashboard() -> void:
	# Update top bar
	if GameState.player_club.has("name"):
		club_name_label.text = GameState.player_club.name
	else:
		club_name_label.text = "Your Club FC"
	
	date_label.text = TimeSystem.get_formatted_date()
	var week_info = TimeSystem.get_week_info()
	week_label.text = "Week %d/%d" % [week_info.week, week_info.total_weeks]
	
	prestige_label.text = "PP: %d" % GameState.prestige_points
	
	if GameState.club_data.has("finances"):
		money_label.text = "£%d" % GameState.club_data.finances.get("balance", 0)
	else:
		money_label.text = "£0"
	
	# Update relations
	board_trust_value.text = "%d%%" % int(GameState.board_trust)
	fan_relations_value.text = "%d%%" % int(GameState.fan_relations)
	media_relations_value.text = "%d%%" % int(GameState.media_relations)
	state_relations_value.text = "%d%%" % int(GameState.state_relations)
	
	# Color code relations
	_color_code_relation(board_trust_value, GameState.board_trust)
	_color_code_relation(fan_relations_value, GameState.fan_relations)
	_color_code_relation(media_relations_value, GameState.media_relations)
	_color_code_relation(state_relations_value, GameState.state_relations)
	
	# Update notifications
	_update_notifications()


func _color_code_relation(label: Label, value: float) -> void:
	if value >= 70:
		label.add_theme_color_override("font_color", COLOR_GREEN)
	elif value >= 40:
		label.add_theme_color_override("font_color", Color.WHITE)
	else:
		label.add_theme_color_override("font_color", Color.RED)


func _update_notifications() -> void:
	notifications_list.clear()
	var recent = GameState.get_recent_notifications(10)
	for notif in recent:
		var icon = "ℹ️"
		match notif.get("type", "info"):
			"success": icon = "✅"
			"warning": icon = "⚠️"
			"error": icon = "❌"
			"prestige": icon = "⭐"
		
		notifications_list.add_item("%s %s (Week %d)" % [icon, notif.message, notif.week])


func _on_game_state_changed() -> void:
	_update_dashboard()


func _on_week_advanced() -> void:
	_update_dashboard()
	_process_weekly_events()


func _process_weekly_events() -> void:
	# Random event chance (20% per week)
	if randf() < 0.2:
		EventManager.trigger_random_event()
	
	# Update active events
	EventManager.update_events()


func _on_advance_week_pressed() -> void:
	TimeSystem.advance_week()
	_update_dashboard()


func _on_team_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://scenes/team/Team.tscn")
	if err != OK:
		print("Error loading team scene: ", err)


func _on_map_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://scenes/map/WorldMap.tscn")
	if err != OK:
		print("Error loading map scene: ", err)


func _on_finances_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://scenes/finances/Finances.tscn")
	if err != OK:
		print("Error loading finances scene: ", err)


func _on_politics_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://scenes/politics/Politics.tscn")
	if err != OK:
		print("Error loading politics scene: ", err)


func _on_fans_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://scenes/fans/Fans.tscn")
	if err != OK:
		print("Error loading fans scene: ", err)


func _on_shop_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://scenes/shop/PrestigeShop.tscn")
	if err != OK:
		print("Error loading shop scene: ", err)


func _on_menu_pressed() -> void:
	_show_menu_popup()


func _show_menu_popup() -> void:
	# Create a simple popup menu for save/quit options
	var popup = PopupMenu.new()
	popup.add_item("Save Game")
	popup.add_item("Load Game")
	popup.add_item("Main Menu")
	popup.add_item("Quit to Desktop")
	
	popup.id_pressed.connect(_on_menu_item_selected)
	add_child(popup)
	popup.popup_centered()


func _on_menu_item_selected(id: int) -> void:
	match id:
		0:  # Save Game
			if GameState.save_game(0):
				print("Game saved successfully")
		1:  # Load Game
			if GameState.load_game(0):
				_update_dashboard()
		2:  # Main Menu
			var err = get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
			if err != OK:
				print("Error loading main menu: ", err)
		3:  # Quit
			get_tree().quit()
