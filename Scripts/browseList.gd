extends Container

const lobbyItemScene: PackedScene = preload("res://scenes/lobbyItem.tscn")

@onready var searchField: LineEdit = %SearchField
@onready var findButton = %FindButton

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
	applySort()

func applyFilter():
	searchField.applyFilter()

func applySort():
	searchField.applySort()

#braindead solution to load details over several frames
func _process(_delta: float) -> void:
	var lobby: LobbyClass
	var openedLobby: LobbyClass = Storage.OPENED_LOBBY
	var refreshOpenedLobby := false
	var refreshBrowseList := false
	toContinue = false
	for id in Storage.LOBBIES.keys():
		lobby = Storage.LOBBIES[id]
		if not lobby.fresh:
			Storage.LOBBIES.erase(id)
			lobby.associatedNode.queue_free()
			refreshBrowseList = true
		else:
			if lobby.loadingLevel == 1:
				lobby.loadBasicDetails()
				lobby.associatedNode.refreshUI()
				refreshBrowseList = true
				toContinue = true
				continue
			elif lobby.loadingLevel == 2:
				lobby.loadAllDetails()
				lobby.associatedNode.refreshUI()
				refreshBrowseList = true
				if openedLobby and lobby == openedLobby:
					refreshOpenedLobby = true
				continue
	if refreshOpenedLobby and Storage.OPENED_LOBBY == openedLobby:
		findButton.refreshActiveTab()
	if refreshBrowseList:
		applySort()
	set_process(toContinue)
