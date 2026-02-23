extends Node

#@onready var b_smurfs: CheckBox = %B_Smurfs
@onready var tabsNode = %TabsNode
@onready var lobbyPlayersList := %LobbyPlayersList
@onready var checkTab: PanelContainer = %Check

@onready var balanceButton = %BalanceButton
@onready var map_and_mode: Label = %MapAndMode
@onready var lobbyLabel: Label = %LobbyLabel
@onready var main = get_node("/root/Control")
@onready var find_button: Button = %FindButton
# Link back to the find button script for data requests
@export var find_button_path: NodePath

func closeCurrentLobby():
	lobbyLabel.text = "no lobby"
	main.removeTeamDisplay()
	lobbyPlayersList.reset()

func openSelectedLobby(selected):
	tabsNode.current_tab = 1
	if Storage.OPENED_LOBBY == selected:
		refreshLobby()
		return

	closeCurrentLobby()
	Storage.OPENED_LOBBY = selected
	populateLobby()
	if Global.ACTIVE_BROWSER_ID == 0:
		balanceButton.startBalancing()
	else:
		main.removeTeamDisplay()

func refreshLobby():
	if Storage.OPENED_LOBBY and (tabsNode.current_tab > 0):
		populateLobby()
		if Global.ACTIVE_BROWSER_ID == 0:
			balanceButton.startBalancing()

func populateLobby():
	var lobby = Storage.OPENED_LOBBY
	if not lobby:
		return

	if lobby.loadingLevel > 2:
		lobby.loadInternalDetails()

	lobbyLabel.text = "> " + lobby.title + " <"
	map_and_mode.text = lobby.map + " (" + lobby.gameModeName + ")"

	lobbyPlayersList.changePlayersInSlots()

	find_button.requestPlayersElo(lobby.slots)

	#b_smurfs.reset(lobby.isCheckSmurfs)
	lobbyPlayersList.refreshAllOtherInfo()
	lobbyPlayersList.refreshAllElo()
	#lobbyPlayersList.refreshAllSmurfs()

func populateSpecLobby():
	var lobby = Storage.OPENED_LOBBY
	if not lobby:
		return
	for slot in lobbyPlayersList.get_children():
		slot.changePlayer()

	for t in lobby.slot:
		for p in lobby.slot[t]:
			var player = {}
			var playerSlot = lobbyPlayersList.get_child(int(p.right(1)) - 1)
			var item = lobby.slot[t][p]
			player.alias = str(item.get("name"))
			player.color = int(item.get("color"))
			player.team = int(item.get("team"))
			player.civ = str(item.get("civ"))
			player.country = str(item.get("country"))
			playerSlot.changePlayer(player, 2)

func on_elo_updated():
	lobbyPlayersList.refreshAllElo()
	balanceButton.startBalancing()

#func on_smurfs_updated():
	#lobbyPlayersList.refreshAllSmurfs()
