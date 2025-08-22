extends HBoxContainer

@onready var browseFilterTitles = $BrowseFilterTitles
@onready var browseFilterPlayers = $BrowseFilterPlayers
@onready var browseFilterMap = $BrowseFilterMap
@onready var browseFilterServer = $BrowseFilterServer
@onready var browseFilterPassword = $BrowseFilterPassword

@onready var sortButtonActive
@onready var sortDirection:int = 0 # 0 - nothing, -1 - down, 1 - up
@onready var sortBy = ""

@onready var browser = %Browser
var hidePasswords:bool = false

func addArrowToTitle(text):
	if sortDirection == 0:
		return text
	elif sortDirection == -1:
		return "↓" + text
	elif sortDirection == 1:
		return "↑" + text

func removeArrow():
	if sortDirection != 0:
		sortButtonActive.text = sortButtonActive.text.right(-1)

func _on_browse_filter_titles_pressed():
	if sortButtonActive != browseFilterTitles:
		removeArrow()
		sortButtonActive = browseFilterTitles
		sortDirection = -1
	else:
		sortDirection -= 1
		if sortDirection < -1:
			sortDirection = 1
	sortBy = "titles"
	sortButtonActive.text = addArrowToTitle("Title")
	applySort()


func _on_browse_filter_players_pressed():
	if sortButtonActive != browseFilterPlayers:
		browseFilterPlayers.text = ""
		removeArrow()
		sortButtonActive = browseFilterPlayers
		sortDirection = -1
	else:
		sortDirection -= 1
		if sortDirection < -1:
			sortDirection = 1
	sortBy = "players"
	sortButtonActive.text = addArrowToTitle("")
	applySort()

func _on_browse_filter_map_pressed():
	if sortButtonActive != browseFilterMap:
		removeArrow()
		sortButtonActive = browseFilterMap
		sortDirection = -1
	else:
		sortDirection -= 1
		if sortDirection < -1:
			sortDirection = 1
	sortBy = "map"
	sortButtonActive.text = addArrowToTitle("Map")
	applySort()

func _on_browse_filter_server_pressed():
	if sortButtonActive != browseFilterServer:
		removeArrow()
		sortButtonActive = browseFilterServer
		sortDirection = -1
	else:
		sortDirection -= 1
		if sortDirection < -1:
			sortDirection = 1
	sortBy = "server"
	sortButtonActive.text = addArrowToTitle("Server")
	applySort()

func _on_browse_filter_password_pressed():
	hidePasswords = !hidePasswords
	
	if hidePasswords:
		browseFilterPassword.text = "X"
	else:
		browseFilterPassword.text = ""

	browser.applyFilter()
	#var allLobbies = Global.ACTIVE_BROWSER.get_children()
	#for lItem in allLobbies:
		#var lobby = lItem.associatedLobby
		#lItem.visible = not (lobby.password and hidePasswords)

func applySort():
	
	var newOrder = Global.ACTIVE_BROWSER.get_children()

	match sortBy:
		"titles":
			newOrder.sort_custom(func(a,b):
				var lobbyA = a.associatedLobby
				var lobbyB = b.associatedLobby
				return sortDirection*(lobbyA.title.naturalnocasecmp_to(lobbyB.title)) < 0
			)

		"players":
			newOrder.sort_custom(func(a,b):
				var lobbyA = a.associatedLobby
				var lobbyB = b.associatedLobby
				return sortDirection*(lobbyA.totalPlayers - (lobbyB.totalPlayers)) < 0
			)

		"server":
			newOrder.sort_custom(func(a,b):
				var lobbyA = a.associatedLobby
				var lobbyB = b.associatedLobby
				return sortDirection*(lobbyA.server.naturalnocasecmp_to(lobbyB.server)) < 0
			)
			
		"map":
			newOrder.sort_custom(func(a,b):
				var lobbyA = a.associatedLobby
				var lobbyB = b.associatedLobby
				return sortDirection*(str(lobbyA.map).naturalnocasecmp_to(str(lobbyB.map))) < 0
			)

	for node in Global.ACTIVE_BROWSER.get_children():
		Global.ACTIVE_BROWSER.remove_child(node)
	for node in newOrder:
		node.visible = not (hidePasswords and node.associatedLobby.password)
		Global.ACTIVE_BROWSER.add_child(node)
