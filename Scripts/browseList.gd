extends Container

const lobbyItemScene: PackedScene = preload("res://scenes/lobbyItem.tscn")

@onready var searchField: LineEdit = %SearchField

@onready var lobbiesListNode = $LobbiesListNode
@onready var specListNode = $SpecListNode

var toContinue := false

func _ready() -> void:
	set_process(false) 

func clearAllLobbiesItems():
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
		lobbyItem = lobby.associatedNode
		if not lobbyItem:
			lobbyItem = lobbyItemScene.instantiate()
			lobbiesListNode.add_child(lobbyItem)
			lobbyItem.associatedLobby = lobby
			lobby.associatedNode = lobbyItem
			Storage.LOBBIES[id] = lobby
			lobbyItem.refreshUI()
			if not searchField.filterLobby(lobby):
				lobbyItem.visible = false
		else:
			pass
			#lobbyItem.refreshUI()
	applySort()

func applyFilter():
	searchField.applyFilter()

func applySort():
	searchField.applySort()

#braindead solution to load details over several frames
func _process(_delta: float) -> void:
	var lobby: LobbyClass
	toContinue = true
	for id in Storage.LOBBIES.keys():
		lobby = Storage.LOBBIES[id]
		if not lobby.fresh:
			Storage.LOBBIES.erase(id)
			lobby.associatedNode.queue_free()
		else:
			lobby.fresh = false
			if lobby.loadingLevel == 1:
				lobby.loadBasicDetails()
				continue
			elif lobby.loadingLevel == 2:
				lobby.loadAllDetails()
				toContinue = false
				continue
	set_process(toContinue)
