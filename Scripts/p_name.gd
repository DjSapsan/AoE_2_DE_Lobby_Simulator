extends Label

var associatedPlayer: CorePlayerClass

var _default_font_color: Color

func _ready() -> void:
	_default_font_color = get_theme_color("font_color")

func getURL():
	return Global.URL_PLAYER_STATS + str(associatedPlayer.id)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and associatedPlayer and associatedPlayer.id > 0:
		OS.shell_open(getURL())
		accept_event()

func _on_mouse_entered() -> void:
	add_theme_color_override("font_color", 0xfafcffff)

func _on_mouse_exited() -> void:
	add_theme_color_override("font_color", _default_font_color)
