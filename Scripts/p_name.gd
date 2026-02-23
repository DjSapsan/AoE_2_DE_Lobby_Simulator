extends Label

var associatedPlayer: CorePlayerClass

@export var selectedStyle: StyleBox
@export var unselectedStyle: StyleBox

func getURL():
	return Global.URL_PLAYER_STATS + str(associatedPlayer.id)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and associatedPlayer and associatedPlayer.id > 0:
		OS.shell_open(getURL())
		accept_event()

func _on_mouse_entered() -> void:
	add_theme_stylebox_override("normal",selectedStyle)

func _on_mouse_exited() -> void:
	add_theme_stylebox_override("normal",unselectedStyle)
