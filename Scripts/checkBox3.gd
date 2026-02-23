extends Button

@onready var textureFalse: Texture2D = preload("res://img/checkbox_back.png")
@onready var textureTrue: Texture2D = preload("res://img/checkbox_mark.png")
@onready var textureAny: Texture2D = preload("res://img/checkbox_no.png")

signal state_changed(new_state: int)

var state: int = 2 # 0 = false, 1 = true, 2 = any

func _ready() -> void:
	setState(2)

func setState(new_state: int, emit_change: bool = false) -> void:
	state = clampi(new_state, 0, 2)
	match state:
		0:
			icon = textureFalse
		1:
			icon = textureTrue
		2:
			icon = textureAny
	if emit_change:
		state_changed.emit(state)

#cycles through the three states on click
#if the right mouse click the set to any
func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return

	match (event as InputEventMouseButton).button_index:
		MouseButton.MOUSE_BUTTON_LEFT:
			setState((state + 1) % 3, true)
		MouseButton.MOUSE_BUTTON_RIGHT:
			setState(2, true)
		MouseButton.MOUSE_BUTTON_MIDDLE:
			setState(0, true)
		_:
			return

	accept_event()
