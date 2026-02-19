extends Button

@onready var textureFalse: Texture2D = preload("res://img/checkbox_back.png")
@onready var textureTrue: Texture2D = preload("res://img/checkbox_mark.png")
@onready var textureAny: Texture2D = preload("res://img/checkbox_no.png")

var state: int = 0 # 0 = false, 1 = true, 2 = any

func _ready() -> void:
	state = 2

func setState(new_state: int) -> void:
	state = new_state
	match state:
		0:
			self.icon = textureFalse
		1:
			self.icon = textureTrue
		2:
			self.icon = textureAny

#cycles through the three states on click
#if the right mouse click the set to any
func _gui_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_RIGHT):
		state = 2
		self.icon = textureAny
		return
	elif Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_MIDDLE):
		state = 0
		self.icon = textureFalse
		return
	elif Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT):
		state = (state + 1) % 3
		match state:
			0:
				self.icon = textureFalse
			1:
				self.icon = textureTrue
			2:
				self.icon = textureAny
	
