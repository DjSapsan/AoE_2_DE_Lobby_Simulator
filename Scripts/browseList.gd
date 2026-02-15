extends Container

const lobbyItem: PackedScene = preload("res://scenes/lobbyItem.tscn")
const ROW_DARK := 0xffffffff
const ROW_LIGHT := 0xffffff80

@onready var searchField = %SearchField
@onready var finder = %FindButton
@onready var browseHeaders = %BrowseHeaders

@onready var lobbiesListNode = $LobbiesListNode
@onready var specListNode = $SpecListNode
@onready var tabsNode = %TabsNode

func clearLobbiesList():
	for l in lobbiesListNode.get_children():
		l.queue_free()
				
func populateLobbiesList():
	var lobbies := Storage.LOBBIES

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
	if tabsNode.current_tab == 1 or tabsNode.current_tab == 2:
		return
	var text = searchField.text
	var case_type: String = finder.find_cases(text)
	var toHide = browseHeaders.hidePasswords
	var search_text = text.to_lower()
	
	var active_browser = Global.ACTIVE_BROWSER
	if not active_browser:
		return  # Ensure active_browser is valid

	var visible_index := 0
	var v: = true
	for lItem in active_browser.get_children():
		var lobby = lItem.associatedLobby
		if case_type == "empty":
			v = not (toHide and lobby.password)
			lItem.visible = v
			if v:
				var row_color = ROW_DARK if visible_index % 2 == 0 else ROW_LIGHT
				lItem.set_row_self_modulate(row_color)
				visible_index += 1

		else:
			v = lobby.index.contains(search_text) and not (toHide and lobby.password)
			lItem.visible = v
			if v:
				var row_color = ROW_DARK if visible_index % 2 == 0 else ROW_LIGHT
				lItem.set_row_self_modulate(row_color)
				visible_index += 1
