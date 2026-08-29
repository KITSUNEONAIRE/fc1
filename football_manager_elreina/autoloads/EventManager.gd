extends Node

## Event Manager - Handles game events, notifications, and triggers
## Manages political events, fan incidents, media stories, etc.

# Signals
signal event_triggered(event_data: Dictionary)
signal notification_added(notification: Dictionary)

# Event categories
enum EventType {
	POLITICAL,
	FAN_INCIDENT,
	MEDIA_STORY,
	TRANSFER_RUMOR,
	INJURY,
	BOARD_MEETING,
	SPONSOR_OFFER,
	SCOUT_REPORT,
	WEATHER,
	SPECIAL
}

# Active events queue
var event_queue: Array = []
var active_events: Array = []
var event_history: Array = []

# Event templates
var event_templates: Dictionary = {}


func _ready() -> void:
	_load_event_templates()


func _load_event_templates() -> void:
	# Political events
	event_templates[EventType.POLITICAL] = [
		{
			"title": "Political Scandal",
			"description": "A major political scandal has erupted involving corruption allegations.",
			"impact": {"board_trust": -5, "state_relations": -10},
			"duration_weeks": 4
		},
		{
			"title": "Election Campaign",
			"description": "Political parties are campaigning heavily in your region.",
			"impact": {"fan_relations": 0},
			"duration_weeks": 6
		},
		{
			"title": "Government Investment",
			"description": "The government announces investment in sports infrastructure.",
			"impact": {"state_relations": 15, "club_finances": 50000},
			"duration_weeks": 0
		},
		{
			"title": "Policy Change",
			"description": "New regulations affect football clubs in the country.",
			"impact": {"board_trust": 0},
			"duration_weeks": 52
		}
	]
	
	# Fan incidents
	event_templates[EventType.FAN_INCIDENT] = [
		{
			"title": "Fan Clash",
			"description": "Violent clashes between fan groups outside the stadium.",
			"impact": {"fan_relations": -10, "reputation": -5, "fine": 10000},
			"duration_weeks": 2
		},
		{
			"title": "Stadium Vandalism",
			"description": "Fans have vandalized parts of the stadium.",
			"impact": {"fan_relations": -5, "club_finances": -5000},
			"duration_weeks": 1
		},
		{
			"title": "Peaceful Protest",
			"description": "Fans organize a peaceful protest about club direction.",
			"impact": {"fan_relations": -3, "board_trust": -2},
			"duration_weeks": 2
		},
		{
			"title": "Fan Celebration",
			"description": "Fans celebrate recent success with a parade.",
			"impact": {"fan_relations": 10, "morale": 5},
			"duration_weeks": 1
		}
	]
	
	# Media stories
	event_templates[EventType.MEDIA_STORY] = [
		{
			"title": "Positive Press",
			"description": "Media praises your management style and results.",
			"impact": {"media_relations": 10, "board_trust": 5},
			"duration_weeks": 2
		},
		{
			"title": "Transfer Speculation",
			"description": "Media speculates about major transfers.",
			"impact": {"fan_relations": 0},
			"duration_weeks": 1
		},
		{
			"title": "Criticism",
			"description": "Media criticizes recent team performance.",
			"impact": {"media_relations": -5, "board_trust": -3},
			"duration_weeks": 2
		}
	]
	
	# Transfer rumors
	event_templates[EventType.TRANSFER_RUMOR] = [
		{
			"title": "Star Player Linked",
			"description": "Your star player is being linked with a move abroad.",
			"impact": {"fan_relations": -5},
			"duration_weeks": 2
		},
		{
			"title": "New Signing Rumored",
			"description": "Media reports you're close to signing a top player.",
			"impact": {"fan_relations": 5},
			"duration_weeks": 1
		}
	]
	
	# Injury events
	event_templates[EventType.INJURY] = [
		{
			"title": "Key Player Injured",
			"description": "Your key player has suffered a serious injury.",
			"impact": {"team_strength": -10},
			"duration_weeks": 8
		},
		{
			"title": "Injury Crisis",
			"description": "Multiple players are injured, affecting squad depth.",
			"impact": {"team_strength": -15},
			"duration_weeks": 4
		}
	]
	
	# Board meetings
	event_templates[EventType.BOARD_MEETING] = [
		{
			"title": "Board Confidence Vote",
			"description": "The board discusses their confidence in your management.",
			"impact": {"board_trust": 0},
			"duration_weeks": 0
		},
		{
			"title": "Budget Review",
			"description": "Board reviews and adjusts the transfer budget.",
			"impact": {"transfer_budget": 0},
			"duration_weeks": 0
		}
	]
	
	# Sponsor offers
	event_templates[EventType.SPONSOR_OFFER] = [
		{
			"title": "New Sponsorship Deal",
			"description": "A company offers a lucrative sponsorship deal.",
			"impact": {"club_finances": 100000},
			"duration_weeks": 52
		},
		{
			"title": "Sponsor Withdrawal",
			"description": "A sponsor threatens to withdraw support.",
			"impact": {"club_finances": -50000},
			"duration_weeks": 4
		}
	]


func trigger_random_event(event_type: EventType = -1) -> void:
	var type = event_type
	if type == -1:
		type = randi() % EventType.size()
	
	var templates = event_templates.get(type, [])
	if templates.is_empty():
		return
	
	var template = templates[randi() % templates.size()]
	var event = template.duplicate(true)
	event["type"] = type
	event["week_created"] = GameState.current_week
	event["season_created"] = GameState.current_season
	
	queue_event(event)


func queue_event(event: Dictionary) -> void:
	event_queue.append(event)
	process_event_queue()


func process_event_queue() -> void:
	while not event_queue.is_empty():
		var event = event_queue.pop_front()
		activate_event(event)


func activate_event(event: Dictionary) -> void:
	active_events.append(event)
	event_triggered.emit(event)
	
	# Apply immediate impacts
	_apply_event_impacts(event)
	
	# Add notification
	var notification = {
		"title": event.title,
		"description": event.description,
		"type": _get_event_type_name(event.type),
		"week": GameState.current_week
	}
	notification_added.emit(notification)
	GameState.add_notification(event.title + ": " + event.description)


func _apply_event_impacts(event: Dictionary) -> void:
	var impact = event.get("impact", {})
	
	for key in impact:
		match key:
			"board_trust":
				GameState.board_trust = clamp(GameState.board_trust + impact[key], 0, 100)
			"fan_relations":
				GameState.fan_relations = clamp(GameState.fan_relations + impact[key], 0, 100)
			"media_relations":
				GameState.media_relations = clamp(GameState.media_relations + impact[key], 0, 100)
			"state_relations":
				GameState.state_relations = clamp(GameState.state_relations + impact[key], 0, 100)
			"club_finances":
				if GameState.club_data.has("finances"):
					GameState.club_data.finances.balance += impact[key]
			"fine":
				if GameState.club_data.has("finances"):
					GameState.club_data.finances.balance -= impact[key]
			"reputation":
				if GameState.club_data.has("reputation"):
					GameState.club_data.reputation = clamp(GameState.club_data.reputation + impact[key], 0, 100)


func _get_event_type_name(type: EventType) -> String:
	match type:
		EventType.POLITICAL: return "Political"
		EventType.FAN_INCIDENT: return "Fan Incident"
		EventType.MEDIA_STORY: return "Media"
		EventType.TRANSFER_RUMOR: return "Transfer"
		EventType.INJURY: return "Injury"
		EventType.BOARD_MEETING: return "Board"
		EventType.SPONSOR_OFFER: return "Sponsor"
		_: return "Event"


func update_events() -> void:
	# Check for expired events
	var i = active_events.size() - 1
	while i >= 0:
		var event = active_events[i]
		var duration = event.get("duration_weeks", 0)
		
		if duration > 0:
			var weeks_active = GameState.current_week - event.week_created
			if weeks_active >= duration:
				expire_event(event)
				active_events.remove_at(i)
		i -= 1


func expire_event(event: Dictionary) -> void:
	event_history.append(event)
	if event_history.size() > 100:
		event_history.pop_front()


func get_active_events_by_type(type: EventType) -> Array:
	var result = []
	for event in active_events:
		if event.type == type:
			result.append(event)
	return result


func has_active_event(type: EventType) -> bool:
	for event in active_events:
		if event.type == type:
			return true
	return false


func clear_all_events() -> void:
	event_queue.clear()
	active_events.clear()
	event_history.clear()
