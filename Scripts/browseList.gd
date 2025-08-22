extends Container

const lobbyItem: PackedScene = preload("res://scenes/lobbyItem.tscn")

@onready var searchField = %searchField
@onready var finder = %FindButton
@onready var browseHeaders = %BrowseHeaders

@onready var lobbiesListNode = $LobbiesListNode
@onready var specListNode = $SpecListNode

func clearLobbiesList():
	for l in lobbiesListNode.get_children():
		l.queue_free()

func populateLobbiesList():
	var lobbies = Storage.LOBBIES

	clearLobbiesList()

	# Add or replace lobby items
	for id in lobbies:
		var lobby = lobbies[id]
		var lItem = lobbyItem.instantiate()
		lItem.associatedLobby = lobby
		lobby.associatedNode = lItem
		setupLobbyItem(lItem, lobby)
		lobbiesListNode.add_child(lItem)

	browseHeaders.applySort()
	applyFilter()

func setupLobbyItem(lItem, lobby):
	var obj = lItem.get_child(0)
	obj.get_child(0).text = lobby.title
	obj.get_child(1).text = "%d/%d" % [lobby.totalPlayers, lobby.maxPlayers]
	obj.get_child(2).text = lobby.map
	obj.get_child(3).text = lobby.server
	obj.get_child(4).text = "X" if lobby.password else ""

func clearSpecList():
	for l in specListNode.get_children():
		l.queue_free()

func populateSpecList():
	var specs = Storage.SPECS

	clearSpecList()

	# Add spec items
	for id in specs:
		var spec = specs[id]
		var lItem = lobbyItem.instantiate()
		lItem.associatedLobby = spec
		spec.associatedNode = lItem
		setupSpecItem(lItem, spec)
		specListNode.add_child(lItem)

	applyFilter()
	browseHeaders.applySort()

#TODO integrate with regular lobbies
func setupSpecItem(lItem, spec):
	var obj = lItem.get_child(0)
	obj.get_child(0).text = spec.title
	obj.get_child(1).text = "%d/%d" % [spec.totalPlayers, spec.maxPlayers]
	obj.get_child(2).text = spec.map
	obj.get_child(3).text = spec.server
	#obj.get_child(4).text = "X" if spec.password else ""

func applyFilter(_null=null):
	var text = searchField.text
	var case_type: String = finder.find_cases(text)
	var toHide = browseHeaders.hidePasswords
	
	var active_browser = Global.ACTIVE_BROWSER
	if not active_browser:
		return  # Ensure active_browser is valid

	for lItem in active_browser.get_children():
		var lobby = lItem.associatedLobby
		match case_type:
			"empty":
				lItem.visible = true and not (toHide and lobby.password)
			"lobby_id":
				var lobby_id = lobby.id
				if lobby_id == Global.GetDigits(text):
					lItem.visible = true and not (toHide and lobby.password)
				else:
					lItem.visible = false
			_:
				if lobby.index.contains(text.to_lower()):
					lItem.visible = true and not (toHide and lobby.password)
				else:
					lItem.visible = false
