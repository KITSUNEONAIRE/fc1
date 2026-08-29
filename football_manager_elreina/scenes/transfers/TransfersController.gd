extends Control

@onready var players_list: VBoxContainer = $MarginContainer/VBoxContainer/PlayersListContainer/ScrollContainer/PlayersList
@onready var transfer_budget_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/TransferBudgetLabel
@onready var wage_budget_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/WageBudgetLabel
@onready var search_box: LineEdit = $MarginContainer/VBoxContainer/SearchPanel/SearchBox
@onready var position_filter: OptionButton = $MarginContainer/VBoxContainer/SearchPanel/PositionFilter
@onready var transfer_type_filter: OptionButton = $MarginContainer/VBoxContainer/SearchPanel/TransferTypeFilter

var available_players: Array[Dictionary] = []
var team_players: Array[Dictionary] = []
var transfer_targets: Array[Dictionary] = []
var current_filter: String = "All"
var current_transfer_type: String = "Buy"

func _ready() -> void:
	setup_filters()
	load_team_data()
	generate_available_players()
	update_display()
	update_budget_labels()

func setup_filters() -> void:
	position_filter.clear()
	position_filter.add_item("All Positions")
	position_filter.add_item("GK")
	position_filter.add_item("DEF")
	position_filter.add_item("MID")
	position_filter.add_item("FWD")
	
	transfer_type_filter.clear()
	transfer_type_filter.add_item("Buy Players")
	transfer_type_filter.add_item("Sell Players")
	transfer_type_filter.add_item("Contract Renewals")
	
	search_box.text_changed.connect(_on_search_changed)
	position_filter.item_selected.connect(_on_position_filter_selected)
	transfer_type_filter.item_selected.connect(_on_transfer_type_selected)

func _on_search_changed(new_text: String) -> void:
	update_display()

func _on_position_filter_selected(index: int) -> void:
	match index:
		0: current_filter = "All"
		1: current_filter = "GK"
		2: current_filter = "DEF"
		3: current_filter = "MID"
		4: current_filter = "FWD"
	update_display()

func _on_transfer_type_selected(index: int) -> void:
	match index:
		0: current_transfer_type = "Buy"
		1: current_transfer_type = "Sell"
		2: current_transfer_type = "Renew"
	update_display()

func load_team_data() -> void:
	if GameState.current_team_id >= 0 and GameState.current_team_id < GameState.teams.size():
		team_players = GameState.teams[GameState.current_team_id].get("players", [])

func generate_available_players() -> void:
	available_players.clear()
	var world_generator := WorldGenerator.new()
	
	for i in range(15):
		var player := world_generator.generate_player(randi_range(18, 32))
		player["market_value"] = randi_range(100000, 5000000)
		player["wage_demand"] = randi_range(5000, 50000)
		player["club_name"] = ["FC Northland", "United South", "Sporting West", "East City FC"][randi_range(0, 3)]
		player["contract_years"] = randi_range(1, 4)
		available_players.append(player)

func update_display() -> void:
	for child in players_list.get_children():
		child.queue_free()
	
	var filtered_players := get_filtered_players()
	
	for player in filtered_players:
		var player_card := create_transfer_card(player)
		players_list.add_child(player_card)

func get_filtered_players() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source_array := available_players if current_transfer_type == "Buy" else team_players
	
	for player in source_array:
		if current_filter != "All":
			var player_pos := player.get("position", "")
			if current_filter == "GK" and player_pos != "GK":
				continue
			elif current_filter == "DEF" and player_pos not in ["LB", "CB", "RB", "LWB", "RWB"]:
				continue
			elif current_filter == "MID" and player_pos not in ["CM", "CDM", "CAM", "LM", "RM", "LAM", "RAM"]:
				continue
			elif current_filter == "FWD" and player_pos not in ["ST", "LW", "RW", "CF"]:
				continue
		
		if search_box.text.length() > 0:
			if search_box.text.to_lower() not in player.get("name", "").to_lower():
				continue
		
		result.append(player)
	
	return result

func create_transfer_card(player: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 120)
	
	var hbox := HBoxContainer.new()
	hbox.set_columns(6)
	card.add_child(hbox)
	
	# Player info
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label := Label.new()
	name_label.text = "%s (%s)" % [player.get("name", "Unknown"), player.get("position", "?")]
	name_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(name_label)
	
	var rating_label := Label.new()
	rating_label.text = "OVR: %d | Potential: %d" % [player.get("overall", 50), player.get("potential", 60)]
	info_vbox.add_child(rating_label)
	
	var age_label := Label.new()
	age_label.text = "Age: %d | Contract: %d years" % [player.get("age", 25), player.get("contract_years", 2)]
	info_vbox.add_child(age_label)
	
	# Financial info
	var finance_vbox := VBoxContainer.new()
	finance_vbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_child(finance_vbox)
	
	if current_transfer_type == "Buy":
		var value_label := Label.new()
		value_label.text = "Value: £%sM" % str(player.get("market_value", 0) / 1000000.0).pad_decimals(2)
		finance_vbox.add_child(value_label)
		
		var wage_label := Label.new()
		wage_label.text = "Wage: £%sK/wk" % str(player.get("wage_demand", 0) / 1000.0).pad_decimals(1)
		finance_vbox.add_child(wage_label)
	else:
		var value_label := Label.new()
		value_label.text = "Market Value: £%sM" % str(player.get("market_value", 500000) / 1000000.0).pad_decimals(2)
		finance_vbox.add_child(value_label)
	
	# Action buttons
	var button_vbox := VBoxContainer.new()
	button_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(button_vbox)
	
	if current_transfer_type == "Buy":
		var bid_btn := Button.new()
		bid_btn.text = "Make Bid"
		bid_btn.pressed.connect(_on_bid_pressed.bind(player))
		button_vbox.add_child(bid_btn)
		
		var scout_btn := Button.new()
		scout_btn.text = "Scout"
		button_vbox.add_child(scout_btn)
	else:
		var sell_btn := Button.new()
		sell_btn.text = "List for Sale"
		sell_btn.pressed.connect(_on_sell_pressed.bind(player))
		button_vbox.add_child(sell_btn)
		
		var renew_btn := Button.new()
		renew_btn.text = "Renew Contract"
		button_vbox.add_child(renew_btn)
	
	return card

func _on_bid_pressed(player: Dictionary) -> void:
	var bid_amount := player.get("market_value", 500000) * 1.1
	if GameState.money >= bid_amount:
		GameState.money -= int(bid_amount)
		transfer_targets.append(player)
		EventManager.queue_event("Transfer Bid", "Bid of £%sM accepted for %s" % [str(bid_amount / 1000000.0).pad_decimals(2), player.get("name", "Player")], EventManager.EventType.INFO)
		GameState.save_game()
		update_budget_labels()
		update_display()
	else:
		EventManager.queue_event("Insufficient Funds", "Cannot afford £%sM bid" % str(bid_amount / 1000000.0).pad_decimals(2), EventManager.EventType.ERROR)

func _on_sell_pressed(player: Dictionary) -> void:
	EventManager.queue_event("Player Listed", "%s has been listed for transfer" % player.get("name", "Player"), EventManager.EventType.INFO)

func update_budget_labels() -> void:
	if GameState.current_team_id >= 0 and GameState.current_team_id < GameState.teams.size():
		var team := GameState.teams[GameState.current_team_id]
		var budget := team.get("transfer_budget", 1000000)
		var wage_budget := team.get("wage_budget", 200000)
		
		transfer_budget_label.text = "Transfer Budget: £%sM" % str(budget / 1000000.0).pad_decimals(2)
		wage_budget_label.text = "Weekly Wage Budget: £%sK" % str(wage_budget / 1000.0).pad_decimals(1)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
