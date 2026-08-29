extends Control

## Transfers Controller - Handles transfer market and free agents

@onready var players_list: VBoxContainer = $MarginContainer/VBoxContainer/PlayersListContainer/ScrollContainer/PlayersList
@onready var transfer_budget_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/TransferBudgetLabel
@onready var wage_budget_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/WageBudgetLabel
@onready var search_box: LineEdit = $MarginContainer/VBoxContainer/SearchPanel/SearchBox
@onready var position_filter: OptionButton = $MarginContainer/VBoxContainer/SearchPanel/PositionFilter
@onready var transfer_type_filter: OptionButton = $MarginContainer/VBoxContainer/SearchPanel/TransferTypeFilter

	var available_players: Array[Dictionary] = []
	var team_players: Array[Dictionary] = []
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


func _on_search_changed(_new_text: String) -> void:
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
	var club_id = GameState.player_club.get("id", -1)
	if club_id >= 0:
	team_players = WorldGenerator.get_team_squad(club_id)
	else:
	team_players = []


func generate_available_players() -> void:
	available_players.clear()

	var free_agents = WorldGenerator.get_free_agents()

	if free_agents.size() > 0:
	for j in range(min(15, free_agents.size())):
	var player = free_agents[j].duplicate(true)
	if not player.has("market_value"):
	player["market_value"] = player.overall * randi_range(10000, 100000)
	if not player.has("wage_demand"):
	player["wage_demand"] = player.contract.weekly_wage
	player["club_name"] = "Free Agent"
	player["contract_years"] = player.contract.years_remaining
	available_players.append(player)


func update_display() -> void:
	for child in players_list.get_children():
	child.queue_free()

	var filtered_players = get_filtered_players()

	for player in filtered_players:
	var player_card = create_transfer_card(player)
	players_list.add_child(player_card)


func get_filtered_players() -> Array:
	var result = []
	var source_array = available_players if current_transfer_type == "Buy" else team_players

	for player in source_array:
	if current_filter != "All":
	var player_pos = player.get("position", "")
	if current_filter == "GK" and player_pos != "GK":
	continue
	elif current_filter == "DEF" and player_pos not in ["LB", "CB", "RB", "LWB", "RWB", "DEF"]:
	if player_pos != "DEF":
	continue
	elif current_filter == "MID" and player_pos not in ["CM", "CDM", "CAM", "LM", "RM", "LAM", "RAM", "MID"]:
	if player_pos != "MID":
	continue
	elif current_filter == "FWD" and player_pos not in ["ST", "LW", "RW", "CF", "FWD"]:
	if player_pos != "FWD":
	continue

	var search_text = search_box.text.to_lower()
	if search_text.length() > 0:
	if search_text not in player.get("name", "").to_lower():
	continue

	result.append(player)

	return result


func create_transfer_card(player: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 120)

	var hbox = HBoxContainer.new()
	card.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = "%s (%s)" % [player.get("name", "Unknown"), player.get("position", "?")]
	name_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(name_label)

	var rating_label = Label.new()
	rating_label.text = "OVR: %d | Potential: %d" % [player.get("overall", 50), player.get("potential", 60)]
	info_vbox.add_child(rating_label)

	var age_label = Label.new()
	age_label.text = "Age: %d | Contract: %d years" % [player.get("age", 25), player.get("contract_years", 2)]
	info_vbox.add_child(age_label)

	var finance_vbox = VBoxContainer.new()
	finance_vbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_child(finance_vbox)

	if current_transfer_type == "Buy":
	var value_label = Label.new()
	value_label.text = "Value: £%.2fM" % (float(player.get("market_value", 0)) / 1000000.0)
	finance_vbox.add_child(value_label)

	var wage_label = Label.new()
	wage_label.text = "Wage: £%.1fK/wk" % (float(player.get("wage_demand", 0)) / 1000.0)
	finance_vbox.add_child(wage_label)
	else:
	var value_label = Label.new()
	value_label.text = "Market Value: £%.2fM" % (float(player.get("market_value", 500000)) / 1000000.0)
	finance_vbox.add_child(value_label)

	var button_vbox = VBoxContainer.new()
	button_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(button_vbox)

	if current_transfer_type == "Buy":
	var bid_btn = Button.new()
	bid_btn.text = "Make Bid"
	bid_btn.pressed.connect(_on_bid_pressed.bind(player))
	button_vbox.add_child(bid_btn)

	var scout_btn = Button.new()
	scout_btn.text = "Scout"
	button_vbox.add_child(scout_btn)
	else:
	var sell_btn = Button.new()
	sell_btn.text = "List for Sale"
	sell_btn.pressed.connect(_on_sell_pressed.bind(player))
	button_vbox.add_child(sell_btn)

	var renew_btn = Button.new()
	renew_btn.text = "Renew Contract"
	button_vbox.add_child(renew_btn)

	return card


func _on_bid_pressed(player: Dictionary) -> void:
	var bid_amount = float(player.get("market_value", 500000)) * 1.1

	var club_finances = GameState.club_data.get("finances", {"balance": 0})
	var current_balance = club_finances.get("balance", 0)

	if current_balance >= int(bid_amount):
	club_finances.balance = current_balance - int(bid_amount)
	GameState.club_data.finances = club_finances

	var club_id = GameState.player_club.get("id", -1)
	if club_id >= 0:
	player["team_id"] = club_id
	player["is_free_agent"] = false
	team_players.append(player)
	available_players.erase(player)

	GameState.add_prestige(5, "Transfer signing")
	GameState.add_notification("Signed " + player.get("name", "Player") + " for £%.2fM" % (bid_amount / 1000000.0))

	update_budget_labels()
	update_display()
	else:
	GameState.add_notification("Cannot afford bid for " + player.get("name", "Player"), "error")


func _on_sell_pressed(player: Dictionary) -> void:
	GameState.add_notification(player.get("name", "Player") + " listed for transfer", "info")


func update_budget_labels() -> void:
	var club_finances = GameState.club_data.get("finances", {"balance": 0, "weekly_income": 0})
	var balance = club_finances.get("balance", 0)
	var weekly_income = club_finances.get("weekly_income", 0)

	transfer_budget_label.text = "Club Balance: £%.2fM" % (float(balance) / 1000000.0)
	wage_budget_label.text = "Weekly Income: £%.1fK" % (float(weekly_income) / 1000.0)


func _on_back_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
	if err != OK:
	print("Error loading dashboard: ", err)
