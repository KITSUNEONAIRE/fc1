extends Control

@onready var news_container: VBoxContainer = $MarginContainer/VBoxContainer/NewsContainer/ScrollContainer/NewsList
@onready var journalists_container: VBoxContainer = $MarginContainer/VBoxContainer/JournalistsContainer/ScrollContainer/JournalistsList
@onready var press_response_container: VBoxContainer = $MarginContainer/VBoxContainer/PressConferencePanel/ResponseOptions

	var news_articles: Array[Dictionary] = []
	var journalists: Array[Dictionary] = []
	var current_question: Dictionary = {}

func _ready() -> void:
	load_news()
	load_journalists()
	update_display()

func load_news() -> void:
	news_articles = [
	{"source": "The Sports Times", "headline": "Local Club Struggles in Mid-Table", "sentiment": "Negative", "impact": -5, "date": "Week 15"},
	{"source": "Daily Football", "headline": "Young Star Shows Promise in Training", "sentiment": "Positive", "impact": 3, "date": "Week 14"},
	{"source": "The Tabloid", "headline": "Manager Under Pressure After Poor Run", "sentiment": "Negative", "impact": -8, "date": "Week 13"},
	{"source": "Football Analytics", "headline": "Tactical Analysis: New Formation Working Well", "sentiment": "Positive", "impact": 5, "date": "Week 12"},
	{"source": "Goal Weekly", "headline": "Transfer Rumors: Club Eyes Striker", "sentiment": "Neutral", "impact": 0, "date": "Week 11"}
	]

	journalists = [
	{"name": "James Richardson", "outlet": "The Sports Times", "credibility": 85, "bias": "Critical"},
	{"name": "Sarah Mitchell", "outlet": "Daily Football", "credibility": 78, "bias": "Friendly"},
	{"name": "Tom Parker", "outlet": "The Tabloid", "credibility": 45, "bias": "Sensationalist"},
	{"name": "Dr. Emily Watson", "outlet": "Football Analytics", "credibility": 92, "bias": "Analytical"},
	{"name": "Mike Stevens", "outlet": "Goal Weekly", "credibility": 70, "bias": "Neutral"}
	]

func update_display() -> void:
	update_news_display()
	update_journalists_display()

func update_news_display() -> void:
	for child in news_container.get_children():
	child.queue_free()

	for article in news_articles:
	var card := create_news_card(article)
	news_container.add_child(card)

func create_news_card(article: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)

	var hbox := HBoxContainer.new()
	hbox.set_columns(4)
	card.add_child(hbox)

# Sentiment indicator
	var sentiment_icon := Label.new()
	sentiment_icon.text = "📉" if article.get("sentiment") == "Negative" else "📈" if article.get("sentiment") == "Positive" else "➡️"
	sentiment_icon.add_theme_font_size_override("font_size", 24)
	sentiment_icon.custom_minimum_size = Vector2(40, 40)
	hbox.add_child(sentiment_icon)

# Article info
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var headline_label := Label.new()
	headline_label.text = article.get("headline", "No Headline")
	headline_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(headline_label)

	var source_label := Label.new()
	source_label.text = "%s - %s (Impact: %+d)" % [article.get("source", "Unknown"), article.get("date", ""), article.get("impact", 0)]
	info_vbox.add_child(source_label)

# Response button
	var respond_btn := Button.new()
	respond_btn.text = "Respond"
	respond_btn.pressed.connect(_on_respond_pressed.bind(article))
	hbox.add_child(respond_btn)

	return card

func update_journalists_display() -> void:
	for child in journalists_container.get_children():
	child.queue_free()

	for journalist in journalists:
	var card := create_journalist_card(journalist)
	journalists_container.add_child(card)

func create_journalist_card(journalist: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 60)

	var hbox := HBoxContainer.new()
	hbox.set_columns(4)
	card.add_child(hbox)

	var name_label := Label.new()
	name_label.text = "%s (%s)" % [journalist.get("name", "Unknown"), journalist.get("outlet", "?")]
	name_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_label)

	var stats_label := Label.new()
	stats_label.text = "Credibility: %d | Bias: %s" % [journalist.get("credibility", 50), journalist.get("bias", "Neutral")]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_label.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(stats_label)

	return card

func _on_respond_pressed(article: Dictionary) -> void:
	current_question = article

	var response_options := press_response_container
	for child in response_options.get_children():
	child.queue_free()

	var responses := [
	{"text": "No Comment", "effect": 0},
	{"text": "Defend Position", "effect": -3},
	{"text": "Acknowledge Issue", "effect": 2},
	{"text": "Attack Criticism", "effect": -5},
	{"text": "Promise Improvement", "effect": 1}
	]

	for response in responses:
	var btn := Button.new()
	btn.text = response.text
	btn.pressed.connect(_on_response_selected.bind(response, article))
	response_options.add_child(btn)

func _on_response_selected(response: Dictionary, article: Dictionary) -> void:
	var impact := response.get("effect", 0)
	GameState.media_relations = clamp(GameState.media_relations + impact, 0, 100)

	EventManager.queue_event("Press Response", 
	"You chose: %s\nMedia Relations: %s%d%%" % [
	response.get("text", ""),
	"+" if impact > 0 else "" if impact == 0 else "",
	GameState.media_relations
	], 
	EventManager.EventType.INFO)

	GameState.save_game()

	for child in press_response_container.get_children():
	child.queue_free()

	var status_label := Label.new()
	status_label.text = "Response recorded."
	press_response_container.add_child(status_label)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
