extends LineEdit

@onready var playerNode = $".."
@onready var balancer = get_node("/root/Control/MainContainer/Sections/TopElements/BalanceButton")
@onready var player_node: HBoxContainer = $".."

var regex = RegEx.new()
var oldtext = ""

func _ready():
	regex.compile("^[0-9]*$")

func _on_text_changed(new_text):
	if regex.search(new_text):
		text = new_text   
		oldtext = text
	else:
		text = oldtext
	
	set_caret_column(text.length())

func get_value():
	return(int(text))

func _on_text_submitted(new_text):
	player_node.overrideElo(int(new_text))
	playerNode.showElo()
	balancer.startBalancing()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		player_node.overrideElo()
		playerNode.showElo()
		balancer.startBalancing()
		accept_event()
