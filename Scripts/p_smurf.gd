extends Label

@onready var f := preload("res://fonts/SpaceMono-Regular.ttf") 

func _make_custom_tooltip(s):
	var label = Label.new()
	label.add_theme_font_override("font", f)
	label.text = s
	return label

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var parent = get_parent()
		var player_id = parent.associatedPlayer.id
		var url = "https://smurf.new-chapter.eu/check_player?player_id=" + str(player_id)
		OS.shell_open(url)
		accept_event()
