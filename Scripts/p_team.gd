extends Button

@onready var parent: HBoxContainer = $"../.."
var balance_button: Button
var team_index: int = 0

func _ready() -> void:
	text = Global.TeamIndex[0]

func set_team(t:int=0):
	team_index = t
	text = Global.TeamIndex[team_index]

func next_team(plus:int=1):
	team_index = (team_index + plus) % Global.TeamIndex.size()
	text = Global.TeamIndex[team_index]

func _on_change_team(event):
	if (not parent.lockTeam) and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			next_team(1)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			next_team(-1)

		balance_button.manual_refresh_teams()
