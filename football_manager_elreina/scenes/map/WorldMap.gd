extends Control

## World Map - Interactive map of Elreina
## Shows 16 regions with political coloring and pulsing tension

@onready var map_container: Control = $MapContainer
@onready var region_info_panel: PanelContainer = $RegionInfoPanel
@onready var region_name_label: Label = $RegionInfoPanel/VBoxContainer/RegionName
@onready var region_climate_label: Label = $RegionInfoPanel/VBoxContainer/RegionClimate
@onready var region_party_label: Label = $RegionInfoPanel/VBoxContainer/RegionParty
@onready var region_tension_label: Label = $RegionInfoPanel/VBoxContainer/RegionTension
@onready var region_style_label: Label = $RegionInfoPanel/VBoxContainer/RegionStyle
@onready var legend_container: VBoxContainer = $LegendContainer/VBoxContainer

var selected_region_id: int = -1
var pulse_time: float = 0.0


func _ready() -> void:
	_setup_map()
	_build_legend()


func _setup_map() -> void:
	# Draw all regions
	map_container.custom_minimum_size = Vector2(1600, 900)
	map_container.queue_redraw()
	
	# Connect to GameState for region data
	if GameState.regions.is_empty():
		WorldGenerator.generate_world()


func _build_legend() -> void:
	legend_container.clear()
	
	var title = Label.new()
	title.text = "Political Parties"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	legend_container.add_child(title)
	
	for party in GameState.political_parties:
		var hbox = HBoxContainer.new()
		
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(30, 20)
		color_rect.color = party.color
		hbox.add_child(color_rect)
		
		var label = Label.new()
		label.text = "%s - %s" % [party.short, party.name]
		label.add_theme_color_override("font_color", Color.WHITE)
		hbox.add_child(label)
		
		legend_container.add_child(hbox)


func _draw() -> void:
	_draw_regions()
	_draw_cities()


func _draw_regions() -> void:
	for region in GameState.regions:
		if region.has("polygon") and region.polygon.size() > 0:
			# Get party color
			var party_index = region.ruling_party
			var party_color = Color.WHITE
			if party_index >= 0 and party_index < GameState.political_parties.size():
				party_color = GameState.political_parties[party_index].color
			
			# Adjust opacity based on selection
			var alpha = 0.6 if selected_region_id != region.id else 0.9
			var draw_color = Color(party_color.r, party_color.g, party_color.b, alpha)
			
			# Draw polygon
			draw_colored_polygon(region.polygon, draw_color)
			
			# Draw border
			draw_polyline(region.polygon, Color.WHITE, 2)
			
			# Draw region name
			var center = _get_polygon_center(region.polygon)
			draw_string(ThemeDB.fallback_font, center, region.name, 
				HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
			
			# Pulse effect for high tension
			if region.tension > 70:
				_draw_tension_pulse(region, center)


func _draw_cities() -> void:
	for city in GameState.cities:
		var pos = Vector2(city.x, city.y)
		var radius = 8 if city.is_capital else 5
		var color = Color.YELLOW if city.is_capital else Color.WHITE
		
		draw_circle(pos, radius, color)
		
		# City name for capitals
		if city.is_capital:
			draw_string(ThemeDB.fallback_font, pos + Vector2(15, 5), 
				city.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func _draw_tension_pulse(region: Dictionary, center: Vector2) -> void:
	var tension_factor = region.tension / 100.0
	var pulse_radius = 20 + sin(pulse_time * 5) * 10 * tension_factor
	
	var points = PackedVector2Array()
	for i in range(16):
		var angle = (TAU / 16.0) * float(i)
		points.append(center + Vector2(cos(angle), sin(angle)) * pulse_radius)
	
	var pulse_color = Color.RED
	pulse_color.a = 0.3 * tension_factor
	draw_colored_polygon(points, pulse_color)


func _get_polygon_center(polygon: PackedVector2Array) -> Vector2:
	var sum = Vector2.ZERO
	for point in polygon:
		sum += point
	return sum / polygon.size()


func _process(delta: float) -> void:
	pulse_time += delta
	if is_instance_valid(map_container):
		map_container.queue_redraw()


func _on_MapContainer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_check_region_click(event.position)


func _check_region_click(pos: Vector2) -> void:
	for region in GameState.regions:
		if region.has("polygon") and _point_in_polygon(pos, region.polygon):
			selected_region_id = region.id
			_show_region_info(region)
			return


func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside = false
	var j = polygon.size() - 1
	
	for i in range(polygon.size()):
		var vi = polygon[i]
		var vj = polygon[j]
		
		if ((vi.y > point.y) != (vj.y > point.y)) and \
		   (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x):
			inside = !inside
		
		j = i
	
	return inside


func _show_region_info(region: Dictionary) -> void:
	region_info_panel.visible = true
	region_name_label.text = region.name
	
	var climate_names = {
		"northern": "Northern",
		"temperate": "Temperate",
		"southern": "Southern",
		"continental": "Continental"
	}
	region_climate_label.text = "Climate: " + climate_names.get(region.climate, "Unknown")
	
	var party_index = region.ruling_party
	if party_index >= 0 and party_index < GameState.political_parties.size():
		region_party_label.text = "Ruling Party: " + GameState.political_parties[party_index].name
	else:
		region_party_label.text = "Ruling Party: Unknown"
	
	var tension_color = Color.GREEN
	if region.tension > 70:
		tension_color = Color.RED
	elif region.tension > 40:
		tension_color = Color.ORANGE
	
	region_tension_label.text = "Tension: %d%%" % region.tension
	region_tension_label.add_theme_color_override("font_color", tension_color)
	
	var style_names = {
		"attacking": "Attacking",
		"defensive": "Defensive",
		"technical": "Technical",
		"physical": "Physical",
		"tactical": "Tactical"
	}
	region_style_label.text = "Football Style: " + style_names.get(region.football_style, "Unknown")
