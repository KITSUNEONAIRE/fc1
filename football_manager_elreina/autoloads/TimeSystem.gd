extends Node

## Time System - Manages game time progression
## Handles weeks, seasons, dates, and time speed

# Signals
signal week_advanced
signal season_started
signal season_ended
signal time_updated

# Constants
const SEASON_START_MONTH := 8  # August
const SEASON_START_DAY := 1
const WEEKS_PER_SEASON := 38
const SEASON_END_MONTH := 5  # May

# Time state
var current_year: int = 1997
var current_month: int = 8
var current_day: int = 1
var current_week: int = 1
var current_season: int = 1
var day_of_week: int = 0  # 0 = Monday, 6 = Sunday

# Time speed
var time_speed: int = 1  # 1 = normal, 2 = x2, 5 = x5
var is_paused: bool = false
var is_running: bool = false

# Season state
var is_season_active: bool = false
var matches_played_this_week: int = 0
var total_matches_this_week: int = 0


func _ready() -> void:
	reset_time()


func reset_time() -> void:
	current_year = 1997
	current_month = SEASON_START_MONTH
	current_day = SEASON_START_DAY
	current_week = 1
	current_season = 1
	day_of_week = 0
	time_speed = 1
	is_paused = false
	is_running = false
	is_season_active = false


func start_game() -> void:
	is_running = true
	is_season_active = true
	season_started.emit()


func pause_time() -> void:
	is_paused = true


func resume_time() -> void:
	is_paused = false


func set_time_speed(speed: int) -> void:
	if speed in [1, 2, 5]:
		time_speed = speed


func toggle_pause() -> void:
	is_paused = !is_paused


func advance_time(delta: float) -> void:
	if not is_running or is_paused:
		return
	
	# Time advancement logic based on speed
	# For simplicity, we advance by weeks rather than real-time
	pass


func advance_week() -> void:
	if not is_running or is_paused:
		return
	
	current_week += 1
	
	if current_week > WEEKS_PER_SEASON:
		end_season()
	else:
		# Update date
		_update_date()
		week_advanced.emit()
		time_updated.emit()


func _update_date() -> void:
	# Simple date progression (7 days per week)
	current_day += 7
	
	var days_in_month = _get_days_in_month(current_month, current_year)
	
	if current_day > days_in_month:
		current_day -= days_in_month
		current_month += 1
		
		if current_month > 12:
			current_month = 1
			current_year += 1
	
	day_of_week = (day_of_week + 7) % 7


func _get_days_in_month(month: int, year: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			# Check for leap year
			if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
				return 29
			else:
				return 28
	return 30


func end_season() -> void:
	is_season_active = false
	season_ended.emit()
	
	# Reset for new season
	current_season += 1
	current_week = 1
	current_month = SEASON_START_MONTH
	current_day = SEASON_START_DAY
	
	# Start new season after a break
	start_new_season()


func start_new_season() -> void:
	is_season_active = true
	season_started.emit()
	time_updated.emit()


func skip_weeks(count: int) -> void:
	for i in range(count):
		advance_week()
		if not is_season_active:
			break


func get_formatted_date() -> String:
	var month_names = [
		"January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"
	]
	
	var day_suffix = "th"
	if current_day % 10 == 1 and current_day != 11:
		day_suffix = "st"
	elif current_day % 10 == 2 and current_day != 12:
		day_suffix = "nd"
	elif current_day % 10 == 3 and current_day != 13:
		day_suffix = "rd"
	
	return "%d%s %s %d" % [current_day, day_suffix, month_names[current_month - 1], current_year]


func get_week_info() -> Dictionary:
	return {
		"week": current_week,
		"total_weeks": WEEKS_PER_SEASON,
		"season": current_season,
		"is_active": is_season_active,
		"date": get_formatted_date()
	}


func is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)


func get_season_progress() -> float:
	return float(current_week) / float(WEEKS_PER_SEASON)
