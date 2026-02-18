extends Node

@onready var tabsNode = %TabsNode
@onready var realPlayersList := %RealPlayersList
@onready var presencePlayersList := %PresencePlayersList

@onready var lobbyLabelCheck: Label = %RealLobbyLabel
@onready var checkCodeLabel: Label = %CheckCodeLabel
@onready var find_button: Button = %FindButton

@onready var lobby_real: VBoxContainer = %LobbyReal

@onready var realElements = get_tree().get_nodes_in_group("realElements")
@onready var checkElements = get_tree().get_nodes_in_group("checkElements")

const LOBBY_OPTIONS_TEAMING: Array[String] = ["-", "FFA", "1v1", "TG"]


func _ready() -> void:
	for e in realElements:
		print(e)

func setText(element: Control, value) -> void:
	element.text = str(value)

func setTooltip(element: Control, value) -> void:
	element.tooltip_text = str(value)

func setBox(element: Button, value: bool) -> void:
	element.button_pressed = bool(value)

# func getCheckCodeFieldNames() -> Array[String]:
# 	var fields: Array[String] = []

# 	for key in checkLobbyElements.keys():
# 		if typeof(key) != TYPE_STRING:
# 			continue
# 		var field_name := str(key)
# 		if not (field_name.begins_with("F_") or field_name.begins_with("B_")):
# 			continue

# 		var element = checkLobbyElements.get(field_name)
# 		if element is OptionButton or element is CheckBox or element is LineEdit:
# 			fields.append(field_name)

# 	fields.sort()
# 	return fields


func onSettingsChanged(_value = null) -> void:
	call_deferred("refreshCheckCodeLabel")

func _on_check_code_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if checkCodeLabel.text != "":
			DisplayServer.clipboard_set(checkCodeLabel.text)

func getTeaming(lobby: LobbyClass) -> String:
	var team_counts := {}
	var player_count := 0

	for i in range(lobby.slots.size()):
		if lobby.slots[i] == null:
			continue
		player_count += 1
		var team := lobby.realTeams[i]
		team_counts[team] = int(team_counts.get(team, 0)) + 1

	if player_count < 2:
		return "-"
	if player_count == 2 and team_counts.size() == 2:
		return "1v1"

	for value in team_counts.values():
		if int(value) > 1:
			return "TG"

	if team_counts.size() >= 2:
		return "FFA"

	return "-"
	
func changeVictoryConditions(victory:String, condition:int = 0):
	var e: bool = false
	if (victory == "Time Limit"):
		e = true
		setText(realElements[2], Tables.LOBBY_CONDITION_TIME_TABLE[condition])
	elif (victory == "Score"):
		e = true
		setText(realElements[2], condition)
	if e:
		realElements[2].self_modulate = 0xffffffff
		realElements[2].mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		realElements[2].self_modulate = 0xffffff64
		realElements[2].mouse_filter = Control.MOUSE_FILTER_IGNORE
		setText(realElements[2], "-")

func fillrealElements(lobby: LobbyClass) -> void:
	# TODO: Replace each `0` with the correct index from `realElements`.
	setText(realElements[3], lobby.gameModeName)
	setText(realElements[4], lobby.map) #F_Location
	setText(realElements[5], lobby.size) #F_Size
	setText(realElements[6], lobby.AI_difficulty) #F_AI
	setText(realElements[7], lobby.resources) #F_Res
	setText(realElements[8], lobby.maxPop) #F_Pop
	setText(realElements[9], lobby.speed) #F_Speed
	setText(realElements[10], lobby.mapReveal) #F_Reveal
	setText(realElements[11], lobby.startIn) #F_StartIn
	setText(realElements[12], lobby.endIn) #F_EndIn
	setText(realElements[13], "[None]" if lobby.treaty == "0" else lobby.treaty) #F_Treaty
	setText(realElements[14], lobby.victory) #F_Victory
	changeVictoryConditions(lobby.victory, int(lobby.victoryCondition))

	setText(realElements[15], lobby.rankedType) #F_Type
	setText(realElements[16], "Public" if lobby.isVisible else "Private") #F_Visible
	setBox(realElements[17], lobby.isObservable) #B_Spec
	setText(realElements[18], str(lobby.observerDelay/60) + " min") #F_Delay
	setBox(realElements[19], lobby.isHideCivs) #B_HideCivs
	setText(realElements[20], lobby.server) #F_Server
	setText(realElements[21], lobby.dataModName) #F_Data
	setTooltip(realElements[21], lobby.dataModID) #F_Data

	setBox(realElements[22], lobby.isLockTeams) #B_LockTeams
	setBox(realElements[24], lobby.isTogether) #B_Together
	setBox(realElements[26], lobby.isTeamPosition) #B_TeamPos
	setBox(realElements[28], lobby.isSharedExploration) #B_SharedExp
	setBox(realElements[23], lobby.isLockSpeed) #B_LockSpeed
	setBox(realElements[25], lobby.isCheats) #B_Cheats
	setBox(realElements[27], lobby.isTurbo) #B_Turbo
	setBox(realElements[29], lobby.isFullTech) #B_FullTech
	setBox(realElements[30], lobby.isEW) #B_EW
	setBox(realElements[31], lobby.isSD) #B_SD
	setBox(realElements[32], lobby.isRegicide) #B_Regicide
	setBox(realElements[33], lobby.isAntiquity) #B_Antiquity

func refreshLobby():
	if not Storage.CURRENT_LOBBY:
		return

	var lobby:LobbyClass = Storage.CURRENT_LOBBY

	populateCheckLobby(lobby)
	fillrealElements(lobby)
	#refreshCheckCodeLabel()

func populateCheckLobby(lobby):
	realElements[0].text = lobby.title
	realPlayersList.changePlayersInSlots()
	realPlayersList.refreshAllNames()
	realPlayersList.showRealTeams()

func closeCurrentLobby():
	realElements[0].text = "no lobby"
	realPlayersList.reset()
