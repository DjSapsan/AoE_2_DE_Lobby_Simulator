extends PanelContainer

var associatedLobby

@onready var finder = get_node("/root/Control/MainContainer/Sections/TopElements/FindButton")
@onready var main = get_node("/root/Control")

func _on_pressed(event):
	
	if event is InputEventMouseButton and Input.is_physical_key_pressed(KEY_ALT):
		main.openAge(associatedLobby)
		
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		finder.openSelectedLobby(associatedLobby)


func _on_lobby_button_mouse_entered():
	modulate = 0x7aacffff

func _on_lobby_button_mouse_exited():
	modulate = 0xffffffff
	
