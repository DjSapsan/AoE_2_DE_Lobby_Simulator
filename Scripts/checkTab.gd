extends Node

@onready var tabsNode = %TabsNode
@onready var lobbyPlayersList := %LobbyPlayersList
@onready var checkPlayersList := %CheckPlayersList

@onready var lobbyLabelCheck: Label = %LobbyLabelCheck
@onready var find_button: Button = %FindButton

@onready var lobby_real: VBoxContainer = %LobbyReal
@onready var settings_real: VBoxContainer = %SettingsReal
@onready var settings_check: VBoxContainer = %SettingsCheck
@onready var lobby_check: VBoxContainer = %LobbyCheck

var realLobbyElements: Dictionary = {}
var checkLobbyElements: Dictionary = {}

func load_check_menu_elements() -> void:
	loadItemsFromParent(lobby_real,		realLobbyElements)
	loadItemsFromParent(settings_real,	realLobbyElements)
	loadItemsFromParent(settings_check,	checkLobbyElements)
	loadItemsFromParent(lobby_check,	checkLobbyElements)


func loadItemsFromParent(parent: Node, add: Dictionary) -> Dictionary:
	var items = parent.get_children()
	for element in items:
		if element is Label or element is OptionButton or element is Button:
			add[element.name] = element
		elif element.get_child_count() > 0:
			loadItemsFromParent(element, add)
	return add

func trySet(element: Control, field, value):
	if element.has(field):
		element.set(field, value)

func fillRealLobbyElements():
	var lobby:LobbyClass = Storage.CURRENT_LOBBY
	if not lobby:
		return

	#var element: Control
	realLobbyElements["B_Spec"].trySet("pressed", lobby.isVisible)
	realLobbyElements["F_Delay"].trySet("text", lobby.observerDelay)
	realLobbyElements["F_Server"].trySet("text", lobby.server)
	

func closeCurrentLobby():
	lobbyLabelCheck.text = "no lobby"
	checkPlayersList.reset()

func refreshLobby():
	if Storage.CURRENT_LOBBY and (tabsNode.current_tab > 0):
		populateLobby()

func populateLobby():
	var lobby = Storage.CURRENT_LOBBY
	if not lobby:
		return
	lobbyLabelCheck.text = lobby.title
	lobbyLabelCheck.tooltip_text = lobby.title

	checkPlayersList.changePlayersInSlots()
	checkPlayersList.refreshAllNames()
	checkPlayersList.showRealTeams()
