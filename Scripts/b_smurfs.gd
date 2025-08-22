extends CheckBox

@onready var find_button: Button = %FindButton

func activate(e: InputEvent) -> void:
	if Storage.CURRENT_LOBBY.isCheckSmurfs == 0 and e is InputEventMouseButton and e.pressed:
		button_pressed = true
		disabled = true
		if Storage.CURRENT_LOBBY:
			Storage.CURRENT_LOBBY.isCheckSmurfs = 1
			find_button.requestPlayerSmurfs()

func reset(state:bool=false):
	disabled = state
	button_pressed = state
	modulate = Color.WHITE

var clock = 0
func _process(delta: float):
	clock = clock + delta
	if clock >= 0.5:
		clock = clock - 0.5

	if Storage.CURRENT_LOBBY:
		var status = Storage.CURRENT_LOBBY.isCheckSmurfs
		if status == 1:
			modulate.a = 0.5 + sin(TAU*clock)
		if status == 2:
			modulate = Color(0.25,1,0.5,1)
