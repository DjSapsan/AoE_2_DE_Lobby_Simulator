extends HBoxContainer

var associatedPlayer : CorePlayerClass

@onready var colorSquare = $pColor
@onready var eloField = $pElo
#@onready var smurfLabel = $pSmurf
@onready var wrateLabel = $pWrate
@onready var teamSquare = $pTeam
@onready var flagIcon = $pFlag
@onready var nameLabel = $pName
@onready var emptyLabel = $pEmpty
@onready var teamLabel = $pTeam/P_label
@onready var eloSelector = %L_elo
@onready var estimate_elo_setts: CheckBox = %EstimateEloSetts
@onready var short_names_setts: HSlider = %ShortNamesSetts
@onready var p_civ: Label = $pCiv
@onready var balance_button: Button = %BalanceButton

var lockTeam = false		# Locks when loaded
var color_index = 0
var team_index = 0

func _ready():
	#flagIcon.tooltip_text = ""
	#colorSquare.color = Global.ColorIndex[color_index]
	pass

func set_team(t:int=0):
	team_index = t
	teamLabel.text = Global.TeamIndex[team_index]

func showName():
	if associatedPlayer:
		nameLabel.text = associatedPlayer.getName(short_names_setts.value)
	else:
		nameLabel.text = "..."
