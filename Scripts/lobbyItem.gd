extends PanelContainer

var associatedLobby
var _base_self_modulate: Color = 0xffffffff
var _is_hovered := false

const HOVER_SELF_MODULATE: Color = 0x000020a0

@onready var finder = get_node("/root/Control/MainContainer/Sections/TopElements/FindButton")
@onready var main = get_node("/root/Control")

func _on_pressed(event):
	
	if event is InputEventMouseButton and Input.is_physical_key_pressed(KEY_ALT):
		main.openAge(associatedLobby)
		
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		finder.openSelectedLobby(associatedLobby)

func set_row_self_modulate(color: Color):
	_base_self_modulate = color
	if not _is_hovered:
		self_modulate = _base_self_modulate

func _on_lobby_button_mouse_entered():
	_is_hovered = true
	self_modulate = HOVER_SELF_MODULATE

func _on_lobby_button_mouse_exited():
	_is_hovered = false
	self_modulate = _base_self_modulate
	
