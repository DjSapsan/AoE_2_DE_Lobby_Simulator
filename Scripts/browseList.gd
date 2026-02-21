extends Container

const lobbyItemScene: PackedScene = preload("res://scenes/lobbyItem.tscn")

@onready var searchField: LineEdit = %SearchField

@onready var lobbiesListNode = $LobbiesListNode
@onready var specListNode = $SpecListNode

func clearLobbiesItems():
	for l in lobbiesListNode.get_children():
		l.queue_free()

func getLobbiesItems():
	return lobbiesListNode.get_children()

func ammendLobbiesList(source: Array = []):
	var id: int
	var lobby: LobbyClass
	var lobbyItem: Control
	for source_lobby in source:
		id = int(source_lobby.id)
		lobby = Storage.LOBBIES[id]
		lobbyItem = Storage.LIVE_LOBBIES.get(lobby)
		if lobbyItem:
			lobbyItem.refreshUI()
			continue

		lobbyItem = lobbyItemScene.instantiate()
		lobbiesListNode.add_child(lobbyItem)
		lobbyItem.associatedLobby = lobby
		lobby.associatedNode = lobbyItem
		Storage.LIVE_LOBBIES[lobby] = lobbyItem
		lobbyItem.refreshUI()
		if not searchField.filterLobby(lobby):
			lobbyItem.visible = false

	#applySort()

func removeAbsentLobbies(received_lobby_ids: Array):
	for lItem in lobbiesListNode.get_children():
		if lItem.associatedLobby.id not in received_lobby_ids:
			lItem.queue_free()
	applySort()

func applyFilter():
	searchField.applyFilter()

func applySort():
	searchField.applySort()
