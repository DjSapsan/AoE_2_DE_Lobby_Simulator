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
@onready var teamButton: Button = $pTeam/B_team
@onready var eloSelector = %L_elo
@onready var estimate_elo_setts: CheckBox = %EstimateEloSetts
@onready var short_names_setts: HSlider = %ShortNamesSetts
@onready var p_civ: Label = $pCiv
@onready var balance_button: Button = %BalanceButton

var lockTeam = false		# Locks when loaded
var color_index = 0
var team_index = 0

func _ready():
	flagIcon.tooltip_text = ""
	colorSquare.color = Global.ColorIndex[color_index]
	nameLabel.associatedPlayer = null
	teamButton.balance_button = balance_button

func getFlag():
	return associatedPlayer.country.to_upper()
	#var code = associatedPlayer.country.to_upper()
	#var flag = ""
	#for letter in code:
		## Calculate the Unicode value of the regional indicator symbol
		#var offset = letter.unicode_at(0) - 65 + 0x1F1E6
		## Append the Unicode character to the flag string
		#flag += char(offset)
	#return flag

func changePlayer(player:CorePlayerClass = null, levelOfDetails:int = 0):
	associatedPlayer = player
	nameLabel.associatedPlayer = player
	showName()

	if !player:
		showDetails(0)
		nameLabel.associatedPlayer = null
		change_color(0)
		set_team(0)
		return

	showDetails(levelOfDetails)

	flagIcon.texture = load("res://fonts/png/" + associatedPlayer.flag + ".png")
	flagIcon.tooltip_text = getFlag()

#0 = empty, 1 = minimal, 2 = full
func showDetails(level:int = 0):
	match level:
		0:
			colorSquare.visible = false
			eloField.visible = false
			wrateLabel.visible = false
			teamSquare.visible = false
			flagIcon.visible = false
			nameLabel.visible = false
			p_civ.visible = false
			#smurfLabel.visible = false
			#smurfLabel.tooltip_text = ""
			lockTeam = true
			emptyLabel.visible = true

		1:
			colorSquare.visible = false
			eloField.visible = false
			wrateLabel.visible = false
			teamSquare.visible = true
			lockTeam = true
			flagIcon.visible = false
			nameLabel.visible = true
			p_civ.visible = false
			#smurfLabel.visible = false
			#smurfLabel.tooltip_text = ""
			lockTeam = true
			emptyLabel.visible = false

		2:
			colorSquare.visible = true
			eloField.visible = true
			wrateLabel.visible = true
			teamSquare.visible = true
			lockTeam = false
			flagIcon.visible = true
			nameLabel.visible = true
			p_civ.visible = true
			#smurfLabel.visible = true
			lockTeam = false
			emptyLabel.visible = false
			#showSmurf()
			showElo()

func change_color(index: int):
	if Global.ColorIndex.has(index):
		colorSquare.color = Global.ColorIndex[index]
	else:
		colorSquare.color = Global.ColorIndex[4294967295]

func set_team(t:int=0):
	teamButton.set_team(t)
	
func getElo(LB_ID= null):
	if not associatedPlayer:
		return
	var LB = LB_ID if LB_ID else eloSelector.get_selected_id()
	if associatedPlayer.overridenElo:
		return associatedPlayer.overridenElo
	if estimate_elo_setts.button_pressed:
		return associatedPlayer.estimateElo(LB)
	if associatedPlayer.notRanked:
		return Global.ELO_ZERO
	else:
		return associatedPlayer.getElo(LB)

	#return Global.ELO_ZERO

func getTeam() -> int:
	return teamButton.team_index

func overrideElo(e=null):
	if associatedPlayer:
		associatedPlayer.overridenElo = e

func showElo(LB_ID= null):
	if not associatedPlayer:
		return

	var LB = LB_ID if LB_ID else eloSelector.get_selected_id()
	var wr: String = "50"
	
	var g = associatedPlayer.getStatProperty(LB,"games")
	
	if associatedPlayer.overridenElo:
		get_child(1).add_theme_color_override("font_color", Color.WEB_PURPLE)
	elif estimate_elo_setts.button_pressed:
		if g == 0:
			get_child(1).add_theme_color_override("font_color", Color(0.3,0.3,0.3))
		else:
			get_child(1).add_theme_color_override("font_color", Color(0,0,0.4))
			wr = "%d" % [0.5 + 100 * associatedPlayer.getWR(LB)]
	elif g > 0:
		get_child(1).add_theme_color_override("font_color", Color.BLACK)
		wr = "%d" % [0.5 + 100 * associatedPlayer.getWR(LB)]
	else:
		get_child(1).add_theme_color_override("font_color", Color(0.3,0.3,0.3))

	get_child(1).text = str(int(getElo(LB_ID)))
	get_child(2).text = wr + "%"

# outputs true if smurf is relatively better than the main ac
#func compareSmurf(s):
	#if s.id == associatedPlayer.id:
		#return false
	#var e:int = 0
	#if (s.stat).has(3) and (associatedPlayer.stat).has(3):
		#e = s.stat[3].rating + s.stat[3].rating * ( (associatedPlayer.stat[3].wr / s.stat[3].wr) -1 )*0.1
		#if e > associatedPlayer.stat[3].rating:
			#return true
	#if (s.stat).has(4) and (associatedPlayer.stat).has(4):
		#e = s.stat[4].rating + s.stat[4].rating * ( (associatedPlayer.stat[4].wr / s.stat[4].wr) -1 )*0.1
		#if e > associatedPlayer.stat[4].rating:
			#return true
	#return false
#
#func showSmurf():
	#if associatedPlayer and associatedPlayer.hasSmurfs():
		#var smurfs = associatedPlayer.smurfs
		#var result = ""
#
		#for s in smurfs:
			#if not associatedPlayer.significantSmurfs:
				#associatedPlayer.significantSmurfs = compareSmurf(s)
			#result += s.getShortStat() + "\n"
#
		#if associatedPlayer.significantSmurfs:
			#var txt:String = result.strip_edges()
			#smurfLabel.tooltip_text = txt
			#smurfLabel.visible = true
	#else:
		#smurfLabel.visible = false
		#smurfLabel.tooltip_text = ""
#

func showName():
	if associatedPlayer:
		nameLabel.text = associatedPlayer.getName(short_names_setts.value)
	else:
		nameLabel.text = "..."

func showOtherInfo(civID, colorID, team):
	var civ = Tables.CIVS_TABLE.get(civID,"other")
	p_civ.text = civ

	#if ready == 1:
		#nameLabel.add_theme_color_override("font_color", Color.DARK_GREEN)
	#else:
		#nameLabel.add_theme_color_override("font_color", Color.BLACK)

	change_color(colorID)
	set_team(team)

func showRealTeam(realTeam):
	teamButton.set_team(realTeam)
