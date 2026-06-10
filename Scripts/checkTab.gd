extends Node

@onready var tabsNode = %TabsNode
@onready var realPlayersList := %RealPlayersList
@onready var presencePlayersList := %PresencePlayersList

@onready var lobbyLabelCheck: Label = %RealLobbyLabel
@onready var find_button: Button = %FindButton

@onready var lobby_real: VBoxContainer = %LobbyReal

@onready var realElements = get_tree().get_nodes_in_group("REAL_ELEMENTS")
@onready var checkElements = get_tree().get_nodes_in_group("CHECK_ELEMENTS")

# Official game option keys, same values as in LobbyClass.
const START_IN_KEY := 0
const ALLOW_CHEATS_KEY := 1
const END_IN_KEY := 4
const GAME_TYPE_KEY := 5
const MAP_SIZE_KEY := 8
const MAP_ID_KEY := 10
const MAX_POP_KEY := 28
const RESOURCES_KEY := 37
const GAME_SPEED_KEY := 41
const TREATY_KEY := 57
const DATA_MOD_ID_KEY := 59
const AI_DIFFICULTY_KEY := 61
const FULL_TECH_TREE_KEY := 62
const LOCK_SPEED_KEY := 65
const LOCK_TEAMS_KEY := 66
const SHARED_EXPLORATION_KEY := 76
const TURBO_MODE_KEY := 79
const VICTORY_CONDITION_KEY := 80
const VICTORY_KEY := 81
const MAP_REVEAL_KEY := 82
const HIDDEN_KEY := 85
const TEAM_POSITION_KEY := 86
const TEAM_TOGETHER_KEY := 87
const IS_EW_KEY := 89
const IS_SD_KEY := 90
const IS_REGICIDE_KEY := 91
const ANTIQUITY_KEY := 100

# Settings that are not part of the game's encoded options.
# They live in the 200+ range so they can never collide with official keys.
const RANKED_TYPE_KEY := 201
const VISIBLE_KEY := 202
const OBSERVER_DELAY_KEY := 203
const OBSERVABLE_KEY := 204
const SERVER_KEY := 205

# Every checkable setting in UI order; also defines the order of the share code parts.
const SETTING_KEYS: Array[int] = [
	GAME_TYPE_KEY, MAP_ID_KEY, MAP_SIZE_KEY, AI_DIFFICULTY_KEY, RESOURCES_KEY,
	MAX_POP_KEY, GAME_SPEED_KEY, MAP_REVEAL_KEY, START_IN_KEY, END_IN_KEY,
	TREATY_KEY, VICTORY_KEY, VICTORY_CONDITION_KEY,
	LOCK_SPEED_KEY, LOCK_TEAMS_KEY, ALLOW_CHEATS_KEY, TEAM_TOGETHER_KEY,
	TURBO_MODE_KEY, TEAM_POSITION_KEY, FULL_TECH_TREE_KEY, SHARED_EXPLORATION_KEY,
	IS_EW_KEY, IS_SD_KEY, IS_REGICIDE_KEY, ANTIQUITY_KEY,
	RANKED_TYPE_KEY, VISIBLE_KEY, OBSERVER_DELAY_KEY, OBSERVABLE_KEY, HIDDEN_KEY,
	SERVER_KEY, DATA_MOD_ID_KEY,
]

# Node names shared by the CHECK_ELEMENTS and REAL_ELEMENTS groups.
# F_CheckConditions/F_Conditions are the check/lobby sides of the same setting.
const NODE_NAME_TO_KEY: Dictionary = {
	"F_Mode": GAME_TYPE_KEY,
	"F_Location": MAP_ID_KEY,
	"F_Size": MAP_SIZE_KEY,
	"F_AI": AI_DIFFICULTY_KEY,
	"F_Res": RESOURCES_KEY,
	"F_Pop": MAX_POP_KEY,
	"F_Speed": GAME_SPEED_KEY,
	"F_Reveal": MAP_REVEAL_KEY,
	"F_StartIn": START_IN_KEY,
	"F_EndIn": END_IN_KEY,
	"F_Treaty": TREATY_KEY,
	"F_Victory": VICTORY_KEY,
	"F_CheckConditions": VICTORY_CONDITION_KEY,
	"F_Conditions": VICTORY_CONDITION_KEY,
	"B_LockSpeed": LOCK_SPEED_KEY,
	"B_LockTeams": LOCK_TEAMS_KEY,
	"B_Cheats": ALLOW_CHEATS_KEY,
	"B_Together": TEAM_TOGETHER_KEY,
	"B_Turbo": TURBO_MODE_KEY,
	"B_TeamPos": TEAM_POSITION_KEY,
	"B_FullTech": FULL_TECH_TREE_KEY,
	"B_SharedExp": SHARED_EXPLORATION_KEY,
	"B_EW": IS_EW_KEY,
	"B_SD": IS_SD_KEY,
	"B_Regicide": IS_REGICIDE_KEY,
	"B_Antiquity": ANTIQUITY_KEY,
	"F_Type": RANKED_TYPE_KEY,
	"F_Visible": VISIBLE_KEY,
	"F_Delay": OBSERVER_DELAY_KEY,
	"B_Spec": OBSERVABLE_KEY,
	"B_HideCivs": HIDDEN_KEY,
	"F_Server": SERVER_KEY,
	"F_Data": DATA_MOD_ID_KEY,
}

# Settings that the game hides for the Scenario game mode. They get disabled,
# greyed out and ignored when generating/comparing the check code.
const SCENARIO_DISABLED_KEYS: Array[int] = [
	MAP_SIZE_KEY, TEAM_TOGETHER_KEY, TEAM_POSITION_KEY,
	IS_EW_KEY, IS_SD_KEY, IS_REGICIDE_KEY, VICTORY_KEY,
]

var checkByKey: Dictionary = {}	# setting key -> check input
var realByKey: Dictionary = {}	# setting key -> lobby display element
var checkCodeLabel: Label

# teaming of the opened lobby, detected on each refresh: "-", "FFA", "1v1" or "TG"
var detectedTeaming := "-"


func _ready() -> void:
	mapElementsByKey()
	connectChangeSignals()

func mapElementsByKey() -> void:
	for element in checkElements:
		var element_name := String(element.name)
		if element_name == "CheckCodeLabel":
			checkCodeLabel = element
		elif NODE_NAME_TO_KEY.has(element_name):
			checkByKey[NODE_NAME_TO_KEY[element_name]] = element

	for element in realElements:
		var element_name := String(element.name)
		if NODE_NAME_TO_KEY.has(element_name):
			realByKey[NODE_NAME_TO_KEY[element_name]] = element

func connectChangeSignals():
	for element in checkByKey.values():
		if element is OptionButton:
			element.connect("item_selected", onSettingsChanged)
		elif element is LineEdit:
			element.connect("text_changed", onSettingsChanged)
		elif element is Button:
			element.connect("state_changed", onSettingsChanged)

func setText(element: Control, value) -> void:
	element.text = str(value)

func setTooltip(element: Control, value) -> void:
	element.tooltip_text = str(value)

func setBox(element: Button, value: bool) -> void:
	element.button_pressed = bool(value)

func getTreatyText(treaty: String) -> String:
	return "[None]" if treaty == "0" else treaty + " Minutes"

func getObserverDelayText(delay_seconds: int) -> String:
	var delay_minutes := int(delay_seconds / 60.0)
	return "None" if delay_minutes <= 0 else str(delay_minutes) + " min"

func getOptionIndexByText(option: OptionButton, text: String) -> int:
	for i in range(option.item_count):
		if option.get_item_text(i) == text:
			return i
	return -1


func onSettingsChanged(_value = null) -> void:
	call_deferred("refreshCheckCodeLabel")

func isScenarioMode() -> bool:
	var mode := checkByKey[GAME_TYPE_KEY] as OptionButton
	return mode.selected >= 0 and mode.get_item_text(mode.selected) == "Scenario"

const OUTLINE_SIZE_ENABLED := 2
const OUTLINE_SIZE_DISABLED := 0

# Text outline is removed while an element is disabled, restored when enabled.
func setOutline(element: Control, enabled: bool) -> void:
	element.add_theme_constant_override("outline_size", OUTLINE_SIZE_ENABLED if enabled else OUTLINE_SIZE_DISABLED)

# Greys out (or restores) a lobby-side display element to mirror a disabled check.
func setRealGreyed(element: Control, greyed: bool) -> void:
	element.self_modulate = 0xffffff64 if greyed else 0xffffffff
	element.mouse_filter = Control.MOUSE_FILTER_IGNORE if greyed else Control.MOUSE_FILTER_PASS
	setOutline(element, not greyed)

# Disables (or restores) a check-side input.
func setCheckDisabled(element: Button, disabled: bool) -> void:
	element.disabled = disabled
	element.mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
	setOutline(element, not disabled)

# Mirrors the game UI on the CHECK side: the check F_Mode dropdown decides
# which check inputs are fixed by Scenario mode, so they get disabled and ignored.
func applyCheckModeConstraints() -> void:
	var scenario := isScenarioMode()

	for key in SCENARIO_DISABLED_KEYS:
		setCheckDisabled(checkByKey[key], scenario)

	if scenario:
		setCheckDisabled(checkByKey[VICTORY_CONDITION_KEY], true)
	else:
		# Outside Scenario the conditions field follows the victory selection.
		setCheckDisabled(checkByKey[VICTORY_CONDITION_KEY], false)
		var victory := checkByKey[VICTORY_KEY] as OptionButton
		if victory.has_method("_on_item_selected"):
			victory._on_item_selected(victory.selected)

# Mirrors the game UI on the LOBBY side: the opened lobby's own game mode decides
# which lobby-side display fields are greyed out (Scenario fixes them).
func applyLobbyModeConstraints(lobby: LobbyClass) -> void:
	var scenario := lobby != null and lobby.gameModeName == "Scenario"

	for key in SCENARIO_DISABLED_KEYS:
		setRealGreyed(realByKey[key], scenario)

	# The conditions display follows the victory selection via changeVictoryConditions();
	# Scenario forces it greyed regardless.
	if scenario:
		setRealGreyed(realByKey[VICTORY_CONDITION_KEY], true)

func refreshCheckCodeLabel() -> void:
	applyCheckModeConstraints()
	checkCodeLabel.text = generateCheckShareCode()

	var check_element: Control
	var real_element: Control
	var selected := 0
	var text_value := ""

	for key in SETTING_KEYS:
		check_element = checkByKey[key]
		real_element = realByKey[key]
		real_element.modulate = 0xffffffff

		# Disabled checks (e.g. settings hidden in Scenario mode) are ignored.
		if check_element is Button and (check_element as Button).disabled:
			continue

		if check_element is OptionButton:
			selected = check_element.selected
			if check_element.item_count == 0 or selected < 0:
				continue
			if selected == 0 and check_element.get_item_text(0) == "-":
				continue
			if check_element.get_item_text(selected) != real_element.text:
				real_element.modulate = 0xff0000ff
		elif check_element is Button:
			if check_element.state == 2:
				continue
			if real_element is CheckBox and (check_element.state == 1) != real_element.button_pressed:
				real_element.modulate = 0xff0000ff
		elif check_element is LineEdit:
			text_value = check_element.text.strip_edges()
			if text_value == "" or text_value == "-":
				continue
			var real_value: String = real_element.tooltip_text if key == DATA_MOD_ID_KEY else real_element.text
			if text_value != real_value:
				real_element.modulate = 0xff0000ff

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
	var parts: PackedStringArray = []
	var element: Control
	var encoded_value := ""

	for key in SETTING_KEYS:
		element = checkByKey[key]
		encoded_value = ""

		# Disabled checks (e.g. settings hidden in Scenario mode) are ignored.
		if element is Button and (element as Button).disabled:
			continue

		if element is OptionButton:
			if element.item_count == 0 or element.selected <= 0:
				continue
			encoded_value = encodeAsString(str(element.selected))
		elif element is Button:
			if element.state == 2:
				continue
			encoded_value = encodeAsString(str(element.state))
		elif element is LineEdit and key == DATA_MOD_ID_KEY:
			encoded_value = encodeAsString(element.text.strip_edges())

		if encoded_value != "":
			parts.append(str(key) + encoded_value)

	# The location is base64, so it must stay the last part of the code:
	# it is decoded back as "everything after its key".
	var location_text: String = (checkByKey[MAP_ID_KEY] as LineEdit).text
	if location_text.length() > 1:
		parts.append(str(MAP_ID_KEY) + encodeLocationAsBase64(location_text))

	return "".join(parts)

# Team values are Global.TeamIndex indexes: 0 = no team, 1-4 = teams, 5 = random ("?").
func getTeaming(lobby: LobbyClass) -> String:
	var team_counts := {}	# declared team (1-4) -> player count
	var player_count := 0
	var solo_count := 0		# players with no team
	var random_count := 0	# players with a random ("?") team

	for i in range(lobby.slots.size()):
		if lobby.slots[i] == null:
			continue
		player_count += 1
		var team := lobby.realTeams[i]
		if team == 0:
			solo_count += 1
		elif team == 5:
			random_count += 1
		else:
			team_counts[team] = int(team_counts.get(team, 0)) + 1

	if player_count < 2:
		return "-"

	# 1v1: exactly 2 players on different teams (no team counts as a team of its own)
	if player_count == 2 and random_count != 2 and not team_counts.values().has(2):
		return "1v1"

	# TG: everyone on a random team, or only declared teams of equal size (4v4, 2v2v2v2...)
	if random_count == player_count:
		return "TG"
	if solo_count == 0 and random_count == 0:
		var sizes: Array = team_counts.values()
		if sizes[0] >= 2 and sizes.min() == sizes.max():
			return "TG"

	return "FFA"

func changeVictoryConditions(victory:String, condition:int = 0):
	var conditions := realByKey[VICTORY_CONDITION_KEY] as Control
	var enabled := victory == "Time Limit" or victory == "Score"

	if victory == "Time Limit":
		setText(conditions, Tables.LOBBY_CONDITION_TIME_TABLE[condition])
	elif victory == "Score":
		setText(conditions, condition)
	else:
		setText(conditions, "-")

	setRealGreyed(conditions, not enabled)

func fillrealElements(lobby: LobbyClass) -> void:
	setText(realByKey[GAME_TYPE_KEY], lobby.gameModeName)
	setText(realByKey[MAP_ID_KEY], lobby.map)
	setText(realByKey[MAP_SIZE_KEY], lobby.size)
	setText(realByKey[AI_DIFFICULTY_KEY], lobby.AI_difficulty)
	setText(realByKey[RESOURCES_KEY], lobby.resources)
	setText(realByKey[MAX_POP_KEY], lobby.maxPop)
	setText(realByKey[GAME_SPEED_KEY], lobby.speed)
	setText(realByKey[MAP_REVEAL_KEY], lobby.mapReveal)
	setText(realByKey[START_IN_KEY], lobby.startIn)
	setText(realByKey[END_IN_KEY], lobby.endIn)
	setText(realByKey[TREATY_KEY], getTreatyText(lobby.treaty))
	setText(realByKey[VICTORY_KEY], lobby.victory)
	changeVictoryConditions(lobby.victory, int(lobby.victoryCondition))

	setText(realByKey[RANKED_TYPE_KEY], lobby.rankedType)
	setText(realByKey[VISIBLE_KEY], "Public" if lobby.isVisible else "Private")
	setBox(realByKey[OBSERVABLE_KEY], lobby.isObservable)
	setText(realByKey[OBSERVER_DELAY_KEY], getObserverDelayText(lobby.observerDelay))
	setBox(realByKey[HIDDEN_KEY], lobby.isHideCivs)
	setText(realByKey[SERVER_KEY], lobby.server)
	setText(realByKey[DATA_MOD_ID_KEY], lobby.dataModName)
	setTooltip(realByKey[DATA_MOD_ID_KEY], lobby.dataModID)

	setBox(realByKey[LOCK_TEAMS_KEY], lobby.isLockTeams)
	setBox(realByKey[LOCK_SPEED_KEY], lobby.isLockSpeed)
	setBox(realByKey[TEAM_TOGETHER_KEY], lobby.isTogether)
	setBox(realByKey[ALLOW_CHEATS_KEY], lobby.isCheats)
	setBox(realByKey[TEAM_POSITION_KEY], lobby.isTeamPosition)
	setBox(realByKey[TURBO_MODE_KEY], lobby.isTurbo)
	setBox(realByKey[SHARED_EXPLORATION_KEY], lobby.isSharedExploration)
	setBox(realByKey[FULL_TECH_TREE_KEY], lobby.isFullTech)
	setBox(realByKey[IS_EW_KEY], lobby.isEW)
	setBox(realByKey[IS_SD_KEY], lobby.isSD)
	setBox(realByKey[IS_REGICIDE_KEY], lobby.isRegicide)
	setBox(realByKey[ANTIQUITY_KEY], lobby.isAntiquity)

	applyLobbyModeConstraints(lobby)

func refreshLobby():
	var lobby:LobbyClass = Storage.OPENED_LOBBY

	if not lobby:
		return

	if lobby.loadingLevel > 2:
		lobby.loadInternalDetails()

	detectedTeaming = getTeaming(lobby)
	populateCheckLobby(lobby)
	fillrealElements(lobby)
	refreshCheckCodeLabel()

func populateCheckLobby(lobby: LobbyClass):
	lobbyLabelCheck.text = lobby.title
	realPlayersList.changePlayersInSlots()
	realPlayersList.refreshAllNames()
	realPlayersList.showRealTeams()

func closeCurrentLobby():
	lobbyLabelCheck.text = "no lobby"
	detectedTeaming = "-"
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
	for element in checkByKey.values():
		if element is LineEdit:
			element.text = ""
		elif element is OptionButton:
			element.select(0)
		elif element is Button:
			element.setState(2)

	var victory := checkByKey[VICTORY_KEY] as OptionButton
	if victory.has_method("_on_item_selected"):
		victory._on_item_selected(0)

	refreshCheckCodeLabel()

func copyLobby():
	if not Storage.OPENED_LOBBY:
		return

	var index := -1
	for key in SETTING_KEYS:
		var check = checkByKey[key]
		var real = realByKey[key]

		if check is OptionButton:
			index = getOptionIndexByText(check, real.text)
			if index != -1:
				check.select(index)
			# repopulates the conditions dropdown before VICTORY_CONDITION_KEY is copied
			if key == VICTORY_KEY and check.has_method("_on_item_selected"):
				check._on_item_selected(check.selected)
		elif check is LineEdit:
			check.text = real.tooltip_text if key == DATA_MOD_ID_KEY else real.text
		elif check is Button and real is CheckBox:
			check.setState(1 if real.button_pressed else 0)

	refreshCheckCodeLabel()


func onCodeInserted(new_text: String) -> void:
	resetSettings()

	var code := new_text.strip_edges()
	var pos := 0

	while pos < code.length():
		var key_text := ""
		while pos < code.length() and code.substr(pos, 1).is_valid_int():
			key_text += code.substr(pos, 1)
			pos += 1

		var key := int(key_text)

		if key == MAP_ID_KEY:
			var raw: PackedByteArray = Marshalls.base64_to_raw(code.substr(pos))
			(checkByKey[MAP_ID_KEY] as LineEdit).text = raw.get_string_from_utf8()
			break

		var encoded_value := ""
		while pos < code.length() and not code.substr(pos, 1).is_valid_int():
			encoded_value += code.substr(pos, 1)
			pos += 1

		# unknown keys (e.g. an old-format code) are skipped
		var element = checkByKey.get(key)

		if element is OptionButton:
			var decoded_index := int(decodeFromString(encoded_value))
			element.select(decoded_index)
			if key == VICTORY_KEY:
				element._on_item_selected(decoded_index)
		elif element is LineEdit:
			element.text = decodeFromString(encoded_value)
		elif element is Button:
			element.setState(int(decodeFromString(encoded_value)))

	refreshCheckCodeLabel()
