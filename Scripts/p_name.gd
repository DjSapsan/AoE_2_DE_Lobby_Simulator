extends Label

var associatedPlayer: CorePlayerClass

func getURL():
	return Global.URL_PLAYER_STATS + str(associatedPlayer.id)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and associatedPlayer and associatedPlayer.id > 0:
		OS.shell_open(getURL())
		accept_event()
