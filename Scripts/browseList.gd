extends Container

const lobbyItem: PackedScene = preload("res://scenes/lobbyItem.tscn")

@onready var searchField: LineEdit = %SearchField

@onready var lobbiesListNode = $LobbiesListNode
@onready var specListNode = $SpecListNode

func clearLobbiesList():
	for l in lobbiesListNode.get_children():
		l.queue_free()
				
func ammendLobbiesList(source: Array = []):
	var id:float = 0
	var lobby: LobbyClass
	for source_lobby in source:
		id = source_lobby.id
		lobby = Storage.LOBBIES[id]
		if not searchField.filterLobby(lobby):
			continue
		var lobbyNode = lobbyItem.instantiate()
		lobbyNode.associatedLobby = lobby
		lobby.associatedNode = lobbyNode
		setupLobbyItem(lobbyNode, lobby)
		lobbiesListNode.add_child(lobbyNode)

	applySort()

func removeAbsentLobbies(received_lobby_ids: Array):
	for lItem in lobbiesListNode.get_children():
		if lItem.associatedLobby.id not in received_lobby_ids:
			lItem.queue_free()
	applySort()

func setupLobbyItem(lItem, lobby):
	var obj = lItem.get_child(0)
	obj.get_child(0).text = lobby.title
	obj.get_child(1).text = "%d/%d" % [lobby.totalPlayers, lobby.maxPlayers]
	obj.get_child(2).text = lobby.map
	obj.get_child(3).text = lobby.gameModeName
	obj.get_child(4).text = "X" if lobby.password else ""

func applyFilter(_null = null):
	searchField.applyFilter()

func applySort():
	searchField.applySort()
