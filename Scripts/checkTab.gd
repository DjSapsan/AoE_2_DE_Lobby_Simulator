extends Node

@onready var tabsNode = %TabsNode
@onready var lobbyPlayersList := %LobbyPlayersList
@onready var checkPlayersList := %CheckPlayersList

@onready var lobbyLabelCheck: Label = %LobbyLabelCheck
@onready var find_button: Button = %FindButton
# Link back to the find button script for data requests
@export var find_button_path: NodePath

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
