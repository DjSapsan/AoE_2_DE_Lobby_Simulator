extends TextureButton

@export_range(0,5) var team_index = 0
var locked = false		# Locks when loaded
var teamLabel: Label

func _ready():
	teamLabel = $P_label
	teamLabel.text = Global.TeamIndex[0]

func next_team(plus:int=1):
	team_index = (team_index + 1*plus) % Global.TeamIndex.size()
	teamLabel.text = Global.TeamIndex[team_index]

func change_team(index: int):
	teamLabel.text = Global.TeamIndex[index]

func onClick(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			next_team(1)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			next_team(-1)
