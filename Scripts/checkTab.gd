extends Node

@onready var tabsNode = %TabsNode
@onready var realPlayersList := %RealPlayersList
@onready var presencePlayersList := %PresencePlayersList

@onready var lobbyLabelCheck: Label = %RealLobbyLabel
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

var toLoad = true
var realLobbyElements: Dictionary = {}
var checkLobbyElements: Dictionary = {}

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

func populateCheckLobby(lobby):
	lobbyLabelCheck.text = lobby.title
	lobbyLabelCheck.tooltip_text = lobby.title
	realPlayersList.changePlayersInSlots()
	realPlayersList.refreshAllNames()
	realPlayersList.showRealTeams()

func closeCurrentLobby():
	lobbyLabelCheck.text = "no lobby"
	realPlayersList.reset()
