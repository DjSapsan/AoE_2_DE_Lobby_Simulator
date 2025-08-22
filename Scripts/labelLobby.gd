extends Button

@onready var main = get_node("/root/Control")

func isLobby():
	return Storage.CURRENT_LOBBY

func _on_mouse_entered():
	if isLobby():
		modulate = 0x7ccbf2

func _on_mouse_exited():
	if isLobby():
		modulate = 0xffffffff
	
func _on_button_pressed(event):
	if isLobby() and event is InputEventMouseButton:
		if Input.is_physical_key_pressed(KEY_ALT):
			main.openAge(Storage.CURRENT_LOBBY)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			DisplayServer.clipboard_set(Storage.CURRENT_LOBBY.getRegularURL())
