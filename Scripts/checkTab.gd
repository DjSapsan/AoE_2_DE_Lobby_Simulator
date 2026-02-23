extends Node

@onready var tabsNode = %TabsNode
@onready var realPlayersList := %RealPlayersList
@onready var presencePlayersList := %PresencePlayersList

@onready var lobbyLabelCheck: Label = %RealLobbyLabel
@onready var find_button: Button = %FindButton

@onready var lobby_real: VBoxContainer = %LobbyReal

@onready var realElements = get_tree().get_nodes_in_group("REAL_ELEMENTS")
@onready var checkElements = get_tree().get_nodes_in_group("CHECK_ELEMENTS")

const LOBBY_OPTIONS_TEAMING: Array[String] = ["-", "FFA", "1v1", "TG"]
const CHECK_LOCATION_INDEX := 2
const CHECK_DATA_INDEX := 32


func _ready() -> void:
	connectChangeSignals()
	pass
	# for e in checkElements:
	# 	print(e)

func connectChangeSignals():
	for element in checkElements:
		if element is OptionButton:
			element.connect("item_selected", onSettingsChanged)
		elif element is CheckBox:
			element.connect("toggled", onSettingsChanged)
		elif element is Button:
			element.connect("state_changed", onSettingsChanged)
		elif element is LineEdit:
			element.connect("text_changed", onSettingsChanged)

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

func refreshCheckCodeLabel() -> void:
	checkElements[0].text = generateCheckShareCode()

# Encodes integer digits as letters (0->a, 1->b, ..., 9->j).
func encodeAsString(value:String) -> String:
	var code := ""
	if value.is_valid_int():
		for c in value:
			code += char(97+int(c))
	return code

func encodeLocationAsBase64(value: String) -> String:
	if value == "":
		return ""
	return Marshalls.raw_to_base64(value.to_utf8_buffer())

func decodeFromString(value: String) -> String:
	var decoded := ""

	for c in value:
		var unicode := c.unicode_at(0)
		if unicode < 97 or unicode > 106:
			return ""
		decoded += str(unicode - 97)

	return decoded

func generateCheckShareCode() -> String:
	var encoded_parts := {}
	var element: Control
	var encoded_value := ""
	var tri_state: int = 0
	var selected_index: int = 0

	for i in range(1, checkElements.size()):
		element = checkElements[i]
		encoded_value = ""

		if i == CHECK_LOCATION_INDEX or i == CHECK_DATA_INDEX:
			continue

		if element is OptionButton:
			selected_index = element.selected
			if (element.item_count == 0 or selected_index == 0):
				continue
			encoded_value = encodeAsString(str(selected_index))
		elif element is CheckBox:
			encoded_value = "y" if element.pressed else "n"
		elif element is Button:
			tri_state = element.state
			if tri_state == 2:
				continue
			encoded_value = encodeAsString(str(tri_state))
		elif element is LineEdit:
			continue
		else:
			continue

		if encoded_value != "":
			encoded_parts[i] = encoded_value

	var data_edit := checkElements[CHECK_DATA_INDEX] as LineEdit
	var data_text := data_edit.text.strip_edges()
	if (data_text != ""):
		encoded_parts[CHECK_DATA_INDEX] = encodeAsString(data_text)

	var location_edit := checkElements[CHECK_LOCATION_INDEX] as LineEdit
	if location_edit.text.length()>1:
		encoded_parts[CHECK_LOCATION_INDEX] = encodeLocationAsBase64(location_edit.text)

	var parts: PackedStringArray = []
	#for key and value in encoded_parts:
	for i in encoded_parts.keys():
		parts.append(str(i) + encoded_parts[i])

	return "".join(parts)

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
	setText(realElements[13], "[None]" if lobby.treaty == "0" else lobby.treaty + " Minutes") #F_Treaty
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

####### CHECK ELEMENTS: #######
#0 = CheckCodeLabel
#1 = F_Mode
#2 = F_Location
#3 = F_Size
#4 = F_AI
#5 = F_Res
#6 = F_Pop
#7 = F_Speed
#8 = F_Reveal
#9 = F_StartIn
#10 = F_EndIn
#11 = F_Treaty
#12 = F_Victory
#13 = F_CheckConditions
#14 = B_LockSpeed
#15 = B_LockTeams
#16 = B_Cheats
#17 = B_Together
#18 = B_Turbo
#19 = B_TeamPos
#20 = B_FullTech
#21 = B_SharedExp
#22 = B_EW
#23 = B_SD
#24 = B_Regicide
#25 = B_Antiquity
#26 = F_Type
#27 = F_Visible
#28 = F_Delay
#29 = B_Spec
#30 = B_HideCivs
#31 = F_Server
#32 = F_Data

func refreshLobby():
	var lobby:LobbyClass = Storage.OPENED_LOBBY

	if not lobby:
		return

	if lobby.loadingLevel > 2:
		lobby.loadInternalDetails()

	populateCheckLobby(lobby)
	fillrealElements(lobby)
	#refreshCheckCodeLabel()

func populateCheckLobby(lobby: LobbyClass):
	realElements[0].text = lobby.title
	realPlayersList.changePlayersInSlots()
	realPlayersList.refreshAllNames()
	realPlayersList.showRealTeams()

func closeCurrentLobby():
	realElements[0].text = "no lobby"
	realPlayersList.reset()


func onModOpenInput(event: InputEvent) -> void:
	if not Storage.OPENED_LOBBY:
		return
	if (event is InputEventMouseButton and event.is_pressed()):
		var mod_id := Storage.OPENED_LOBBY.dataModID
		if mod_id == 0:
			return
			
		OS.shell_open(Global.URL_MODS + str(mod_id))

func resetSettings():
	for i in range(1, checkElements.size()):
		var element = checkElements[i]

		if element is LineEdit:
			element.text = ""
		elif element is OptionButton:
			element.select(0)
		elif element is CheckBox:
			element.button_pressed = false
		elif element is Button:
			element.setState(2)

	var victory_option = checkElements[12]
	if victory_option and victory_option.has_method("_on_item_selected"):
		victory_option._on_item_selected(0)

	refreshCheckCodeLabel()

func copyLobby():
	if not Storage.OPENED_LOBBY:
		return

	var index := -1
	index = Tables.LobbyOptions_Mode.find(realElements[3].text); if index != -1: (checkElements[1] as OptionButton).select(index)
	(checkElements[2] as LineEdit).text = realElements[4].text
	index = Tables.LobbyOptions_MapSize.find(realElements[5].text); if index != -1: (checkElements[3] as OptionButton).select(index)
	index = Tables.LobbyOptions_AI.find(realElements[6].text); if index != -1: (checkElements[4] as OptionButton).select(index)
	index = Tables.LobbyOptions_Res.find(realElements[7].text); if index != -1: (checkElements[5] as OptionButton).select(index)
	index = Tables.LobbyOptions_Pop.find(realElements[8].text); if index != -1: (checkElements[6] as OptionButton).select(index)
	index = Tables.LobbyOptions_Speed.find(realElements[9].text); if index != -1: (checkElements[7] as OptionButton).select(index)
	index = Tables.LobbyOptions_Reveal.find(realElements[10].text); if index != -1: (checkElements[8] as OptionButton).select(index)
	index = Tables.LobbyOptions_StartIn.find(realElements[11].text); if index != -1: (checkElements[9] as OptionButton).select(index)
	index = Tables.LobbyOptions_EndIn.find(realElements[12].text); if index != -1: (checkElements[10] as OptionButton).select(index)
	index = Tables.LobbyOptions_Treaty.find(realElements[13].text); if index != -1: (checkElements[11] as OptionButton).select(index)
	index = Tables.LobbyOptions_Victory.find(realElements[14].text); if index != -1: (checkElements[12] as OptionButton).select(index)
	if index != -1 and checkElements[12].has_method("_on_item_selected"): checkElements[12]._on_item_selected(index)
	if realElements[14].text == "Time Limit": index = Tables.LobbyOptions_TimeLimit_Conditions.find(realElements[2].text); if index != -1: (checkElements[13] as OptionButton).select(index)
	elif realElements[14].text == "Score": index = Tables.LobbyOptions_Score_Conditions.find(realElements[2].text); if index != -1: (checkElements[13] as OptionButton).select(index)
	(checkElements[14] as Button).setState(1 if (realElements[23] as CheckBox).button_pressed else 0)
	(checkElements[15] as Button).setState(1 if (realElements[22] as CheckBox).button_pressed else 0)
	(checkElements[16] as Button).setState(1 if (realElements[25] as CheckBox).button_pressed else 0)
	(checkElements[17] as Button).setState(1 if (realElements[24] as CheckBox).button_pressed else 0)
	(checkElements[18] as Button).setState(1 if (realElements[27] as CheckBox).button_pressed else 0)
	(checkElements[19] as Button).setState(1 if (realElements[26] as CheckBox).button_pressed else 0)
	(checkElements[20] as Button).setState(1 if (realElements[29] as CheckBox).button_pressed else 0)
	(checkElements[21] as Button).setState(1 if (realElements[28] as CheckBox).button_pressed else 0)
	(checkElements[22] as Button).setState(1 if (realElements[30] as CheckBox).button_pressed else 0)
	(checkElements[23] as Button).setState(1 if (realElements[31] as CheckBox).button_pressed else 0)
	(checkElements[24] as Button).setState(1 if (realElements[32] as CheckBox).button_pressed else 0)
	(checkElements[25] as Button).setState(1 if (realElements[33] as CheckBox).button_pressed else 0)
	index = Tables.LobbyOptions_TypeRanked.find(realElements[15].text); if index != -1: (checkElements[26] as OptionButton).select(index)
	index = Tables.LobbyOptions_VisibleLobby.find(realElements[16].text); if index != -1: (checkElements[27] as OptionButton).select(index)
	index = Tables.LobbyOptions_SpecDelay.find(realElements[18].text); if index != -1: (checkElements[28] as OptionButton).select(index)
	(checkElements[29] as Button).setState(1 if (realElements[17] as CheckBox).button_pressed else 0)
	(checkElements[30] as Button).setState(1 if (realElements[19] as CheckBox).button_pressed else 0)
	index = Tables.LobbyOptions_Server.find(realElements[20].text); if index != -1: (checkElements[31] as OptionButton).select(index)
	(checkElements[32] as LineEdit).text = realElements[21].tooltip_text
	refreshCheckCodeLabel()


func onCodeInserted(new_text: String) -> void:
	resetSettings()

	var code := new_text.strip_edges()
	if code == "":
		return

	var pos := 0
	while pos < code.length():
		var index_text := ""
		while pos < code.length() and code.substr(pos, 1).is_valid_int():
			index_text += code.substr(pos, 1)
			pos += 1

		var index := int(index_text)

		if index == CHECK_LOCATION_INDEX:
			var raw: PackedByteArray = Marshalls.base64_to_raw(code.substr(pos))
			(checkElements[index] as LineEdit).text = raw.get_string_from_utf8()
			break

		var encoded_value := ""
		while pos < code.length() and not code.substr(pos, 1).is_valid_int():
			encoded_value += code.substr(pos, 1)
			pos += 1

		var element = checkElements[index]

		if element is OptionButton:
			var decoded_index := int(decodeFromString(encoded_value))
			element.select(decoded_index)
			if index == 12:
				element._on_item_selected(decoded_index)
		elif element is CheckBox:
			element.button_pressed = encoded_value == "y"
		elif element is Button:
			element.setState(int(decodeFromString(encoded_value)))
		elif element is LineEdit:
			element.text = decodeFromString(encoded_value)

	refreshCheckCodeLabel()
