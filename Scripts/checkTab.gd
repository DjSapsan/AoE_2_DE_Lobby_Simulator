extends Node

@onready var tabsNode = %TabsNode
@onready var realPlayersList := %RealPlayersList
@onready var presencePlayersList := %PresencePlayersList

@onready var lobbyLabelCheck: Label = %RealLobbyLabel
@onready var checkCodeLabel: Label = %CheckCodeLabel
@onready var find_button: Button = %FindButton

@onready var real_victory_conditions: Label = %F_Conditions

@onready var lobby_real: VBoxContainer = %LobbyReal
@onready var settings_real: VBoxContainer = %SettingsReal
@onready var settings_check: VBoxContainer = %SettingsCheck
@onready var lobby_check: VBoxContainer = %LobbyCheck
@onready var real_lobby_fields: GridContainer = %RealLobbyFields
@onready var real_lobby_boxes: GridContainer = %RealLobbyBoxes
@onready var check_lobby_fields: GridContainer = %CheckLobbyFields
@onready var check_lobby_boxes: GridContainer = %CheckLobbyBoxes

const CHECK_CODE_VERSION := 1
const LOBBY_OPTIONS_TEAMING: Array[String] = ["-", "FFA", "1v1", "TG"]

var toLoad = true
var checkCodeSignalsConnected := false
var realLobbyElements: Dictionary = {}
var checkLobbyElements: Dictionary = {}

func _ready() -> void:
	loading()

# loads only once
func loading() -> void:
	if not toLoad:
		return
	loadItemsFromParent(lobby_real, realLobbyElements)
	loadItemsFromParent(settings_real, realLobbyElements)
	loadItemsFromParent(real_lobby_fields, realLobbyElements)
	loadItemsFromParent(real_lobby_boxes, realLobbyElements)
	loadItemsFromParent(settings_check, checkLobbyElements)
	loadItemsFromParent(lobby_check, checkLobbyElements)
	loadItemsFromParent(check_lobby_fields, checkLobbyElements)
	loadItemsFromParent(check_lobby_boxes, checkLobbyElements)
	
	toLoad = false
	connectCheckCodeSignals()
	refreshCheckCodeLabel()

func loadItemsFromParent(parent: Node, add: Dictionary) -> Dictionary:
	var items = parent.get_children()
	for element in items:
		if element is Label or element is OptionButton or element is Button or element is LineEdit:
			add[element.name] = element
		elif element.get_child_count() > 0:
			loadItemsFromParent(element, add)
	return add

func setText(elements: Dictionary, name: String, value) -> void:
	var element = elements.get(name)
	element.text = str(value)

func setTooltip(elements: Dictionary, name: String, value) -> void:
	var element = elements.get(name)
	element.tooltip_text = str(value)

func setBox(elements: Dictionary, name: String, value: bool) -> void:
	var element = elements.get(name)
	element.button_pressed = bool(value)

func getCheckCodeFieldNames() -> Array[String]:
	var fields: Array[String] = []

	for key in checkLobbyElements.keys():
		if typeof(key) != TYPE_STRING:
			continue
		var field_name := str(key)
		if not (field_name.begins_with("F_") or field_name.begins_with("B_")):
			continue

		var element = checkLobbyElements.get(field_name)
		if element is OptionButton or element is CheckBox or element is LineEdit:
			fields.append(field_name)

	fields.sort()
	return fields

func connectCheckCodeSignals() -> void:
	if checkCodeSignalsConnected:
		return

	var on_change := Callable(self, "_on_check_setting_changed")
	for field_name in getCheckCodeFieldNames():
		var element = checkLobbyElements.get(field_name)
		if element is OptionButton:
			if not element.item_selected.is_connected(on_change):
				element.item_selected.connect(on_change)
		elif element is CheckBox:
			if not element.toggled.is_connected(on_change):
				element.toggled.connect(on_change)
		elif element is LineEdit:
			if not element.text_changed.is_connected(on_change):
				element.text_changed.connect(on_change)

	var on_code_click := Callable(self, "_on_check_code_label_gui_input")
	if not checkCodeLabel.gui_input.is_connected(on_code_click):
		checkCodeLabel.gui_input.connect(on_code_click)

	checkCodeSignalsConnected = true

func getOptionButtonText(button: OptionButton) -> String:
	if button.selected < 0 or button.selected >= button.item_count:
		return ""
	return button.get_item_text(button.selected)

func getLookupForField(field_name: String) -> Array:
	match field_name:
		"F_Mode":
			return Tables.LobbyOptions_Mode
		"F_Size":
			return Tables.LobbyOptions_MapSize
		"F_AI":
			return Tables.LobbyOptions_AI
		"F_Res":
			return Tables.LobbyOptions_Res
		"F_Pop":
			return Tables.LobbyOptions_Pop
		"F_Speed":
			return Tables.LobbyOptions_Speed
		"F_Reveal":
			return Tables.LobbyOptions_Reveal
		"F_StartIn":
			return Tables.LobbyOptions_StartIn
		"F_EndIn":
			return Tables.LobbyOptions_EndIn
		"F_Treaty":
			return Tables.LobbyOptions_Treaty
		"F_Victory":
			return Tables.LobbyOptions_Victory
		"F_Type":
			return Tables.LobbyOptions_TypeRanked
		"F_Visible":
			return Tables.LobbyOptions_VisibleLobby
		"F_Delay":
			return Tables.LobbyOptions_SpecDelay
		"F_Server":
			return Tables.LobbyOptions_Server
		"F_Teaming":
			return LOBBY_OPTIONS_TEAMING
		"F_CheckConditions":
			var victory_field = checkLobbyElements.get("F_Victory")
			if victory_field is OptionButton:
				var victory := getOptionButtonText(victory_field)
				if victory == "Time Limit":
					return Tables.LobbyOptions_TimeLimit_Conditions
				if victory == "Score":
					return Tables.LobbyOptions_Score_Conditions
	return []

func encodeCheckField(field_name: String):
	var element = checkLobbyElements.get(field_name)

	if element is CheckBox:
		return int(element.button_pressed)
	if element is LineEdit:
		return str(element.text).strip_edges()
	if element is OptionButton:
		var value := getOptionButtonText(element)
		var lookup := getLookupForField(field_name)
		if lookup.is_empty():
			return value

		var lookup_id := lookup.find(value)
		return lookup_id if lookup_id >= 0 else value

	return ""

func encodeCheckCodePayload(payload: Dictionary) -> String:
	var payload_text := JSON.stringify(payload)
	if payload_text.is_empty():
		return ""

	var payload_bytes := payload_text.to_utf8_buffer()
	var compressed := payload_bytes.compress(FileAccess.COMPRESSION_DEFLATE)
	if compressed.is_empty():
		return ""

	return Marshalls.raw_to_base64(compressed)

func refreshCheckCodeLabel() -> void:
	if checkLobbyElements.is_empty():
		return

	var fields := getCheckCodeFieldNames()
	var values: Array = []
	for field_name in fields:
		values.append(encodeCheckField(field_name))

	var payload := {
		"v": CHECK_CODE_VERSION,
		"f": fields,
		"d": values,
	}

	checkCodeLabel.text = encodeCheckCodePayload(payload)
	checkCodeLabel.tooltip_text = "RBM to copy code to clipboard"

func _on_check_setting_changed(_value = null) -> void:
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
		setText(realLobbyElements, "F_Conditions",Tables.LOBBY_CONDITION_TIME_TABLE[condition])
	elif (victory == "Score"):
		e = true
		setText(realLobbyElements, "F_Conditions",condition)
	if e:
		real_victory_conditions.self_modulate = 0xffffffff
		real_victory_conditions.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		real_victory_conditions.self_modulate = 0xffffff64
		real_victory_conditions.mouse_filter = Control.MOUSE_FILTER_IGNORE
		setText(realLobbyElements, "F_Conditions","")

func fillRealLobbyElements(lobby: LobbyClass) -> void:
	setText(realLobbyElements, "F_Mode", lobby.gameModeName)
	setText(realLobbyElements, "F_Location", lobby.map)
	setText(realLobbyElements, "F_Size", lobby.size)
	setText(realLobbyElements, "F_AI", lobby.AI_difficulty)
	setText(realLobbyElements, "F_Res", lobby.resources)
	setText(realLobbyElements, "F_Pop", lobby.maxPop)
	setText(realLobbyElements, "F_Speed", lobby.speed)
	setText(realLobbyElements, "F_Reveal", lobby.mapReveal)
	setText(realLobbyElements, "F_StartIn", lobby.startIn)
	setText(realLobbyElements, "F_EndIn", lobby.endIn)
	setText(realLobbyElements, "F_Treaty", "[None]" if lobby.treaty == "0" else lobby.treaty)
	setText(realLobbyElements, "F_Victory", lobby.victory)
	changeVictoryConditions(lobby.victory, int(lobby.victoryCondition))

	setText(realLobbyElements, "F_Type", lobby.rankedType)
	setText(realLobbyElements, "F_Visible", "Public" if lobby.isVisible else "Private")
	setBox(realLobbyElements,  "B_Spec", lobby.isObservable)
	setText(realLobbyElements, "F_Delay", str(lobby.observerDelay/60) + " min")
	setBox(realLobbyElements,  "B_HideCivs", lobby.isHideCivs)
	setText(realLobbyElements, "F_Server", lobby.server)
	setText(realLobbyElements, "F_Data", lobby.dataModName)
	setTooltip(realLobbyElements, "F_Data", lobby.dataModID)

	setBox(realLobbyElements, "B_LockTeams", lobby.isLockTeams)
	setBox(realLobbyElements, "B_Together", lobby.isTogether)
	setBox(realLobbyElements, "B_TeamPos", lobby.isTeamPosition)
	setBox(realLobbyElements, "B_SharedExp", lobby.isSharedExploration)
	setBox(realLobbyElements, "B_LockSpeed", lobby.isLockSpeed)
	setBox(realLobbyElements, "B_Cheats", lobby.isCheats)
	setBox(realLobbyElements, "B_Turbo", lobby.isTurbo)
	setBox(realLobbyElements, "B_FullTech", lobby.isFullTech)
	setBox(realLobbyElements, "B_EW", lobby.isEW)
	setBox(realLobbyElements, "B_SD", lobby.isSD)
	setBox(realLobbyElements, "B_Regicide", lobby.isRegicide)
	setBox(realLobbyElements, "B_Antiquity", lobby.isAntiquity)

func refreshLobby():
	if not Storage.CURRENT_LOBBY:
		return

	if realLobbyElements.is_empty():
		loading()

	var lobby:LobbyClass = Storage.CURRENT_LOBBY

	populateCheckLobby(lobby)
	fillRealLobbyElements(lobby)
	refreshCheckCodeLabel()

func populateCheckLobby(lobby):
	lobbyLabelCheck.text = lobby.title
	lobbyLabelCheck.tooltip_text = lobby.title
	realPlayersList.changePlayersInSlots()
	realPlayersList.refreshAllNames()
	realPlayersList.showRealTeams()

func closeCurrentLobby():
	lobbyLabelCheck.text = "no lobby"
	realPlayersList.reset()
