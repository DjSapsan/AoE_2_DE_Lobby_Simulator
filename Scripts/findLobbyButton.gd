extends Button

@onready var http_request_lobbies: HTTPRequest = $HTTPRequest_lobbies
@onready var http_request_elo: HTTPRequest = $HTTPRequest_elo
@onready var http_request_smurf: HTTPRequest = $HTTPRequest_smurf
@onready var request_spec_node: Node = $WebSocket_spec

@onready var searchField: LineEdit = %SearchField
@onready var browser = %Browser
@onready var status = %Status
@onready var lobbyTab: PanelContainer = %Lobby
@onready var lobbyTabCheck: PanelContainer = %Check
@onready var tabs_node: TabContainer = %TabsNode

static var regex_lobby: RegEx
static var regex_steamID: RegEx

# holds functions to process data about ongoing matches for spectating
#var FUNCTIONS_TABLE: Dictionary
var steamIDs: Dictionary

#var _pending_smurf_requests = {}

func _ready() -> void:
	regex_lobby = RegEx.new()
	regex_steamID = RegEx.new()
	regex_lobby.compile("^(\\d{9,}|aoe2de://0/\\d+)$")
	regex_steamID.compile(r'"id":(\d+),"steamlobbyid":(\d*)')
	#regex_steamID.compile("\"id\"\\s*:\\s*(\\d+)\\s*,\\s*\"steamlobbyid\"\\s*:\\s*(\\d+)")

	_on_find_button_pressed()
	#initFUNCTIONS_TABLE()

func find_cases(_str: String) -> String:
	if _str.length() == 0:
		return "empty"
	if regex_lobby.search(_str) != null:
		return "lobby_id"
	return "general"

#https://aoe-api.worldsedgelink.com/community/advertisement/findAdvertisements?title=age2&start=0
func request_advertisements(start:int=0):
	var endpoint: String = "/community/advertisement/findAdvertisements"
	var query_string: String = "title=age2&start=%d" % start
	var url = Global.URL_AOE_API + endpoint + "?" + query_string
	http_request_lobbies.request(url)
	var results = await http_request_lobbies.request_completed
	return results

func requestLobbies():
	var start: int = 0
	var rawResults: Array
	var jsonResults: Dictionary
	var lobbies: Array
	var players: Array
	var received_lobby_ids: Array = []
	var json_string: String

	status.changeStatus("Loading lobbies...", 0)

	var repeat := true
	var matchesSize: int = 0
	while repeat:
		rawResults = await request_advertisements(start)
		if rawResults[1] != 200:
			status.changeStatus("Error " + str(rawResults[1]), 1)
			#print("Error ", rawResults[1])
			return

		json_string = rawResults[3].get_string_from_utf8()
		steamIDs = extract_id_and_lobby(json_string)
		jsonResults = JSON.parse_string(json_string)
		matchesSize = jsonResults.matches.size()
		if matchesSize == 0:
			break
		elif matchesSize < 100:
			repeat = false

		lobbies = jsonResults.matches
		players = jsonResults.avatars

		Storage.PLAYERS_add(players)
		Storage.LOBBIES_add(lobbies,steamIDs)

		lobbyTab.refreshLobby()
		lobbyTabCheck.refreshLobby()

		for lobby_data in lobbies:
			received_lobby_ids.append(lobby_data.id)

		browser.populateLobbiesList()

		start += 100

	if received_lobby_ids.size() > 0:
		Storage.LOBBIES_remove_absent(received_lobby_ids)
		browser.populateLobbiesList()

	status.showAmountOfLobbies()
	Global.LAST_LOBBY_UPDATE = Time.get_unix_time_from_system()

func extract_id_and_lobby(json_text: String) -> Dictionary:
	var id_to_steamID : Dictionary = {}
	var pos := 0
	while true:
		var m := regex_steamID.search(json_text, pos)
		if m == null:
			break
		id_to_steamID[int(m.get_string(1))] = m.get_string(2)
		pos = m.get_end(0)+1000  # advance for next match
	return id_to_steamID

func requestPlayersElo(listOfPlayers, isAll: bool = false, doRefresh: bool = true):
	var array = []
	for p:CorePlayerClass in listOfPlayers:
		if (p) and (isAll or p.isEloOutdated()) and not p.isAI:
			array.append("\""+p.steamName+"\"")

	if array.size() == 0:
		return

	var players_list = "[%s]" % (",".join(array))
	var full_url: String = Global.URL_HALF_ELO + players_list

	http_request_elo.request(full_url)
	var rawResults = await http_request_elo.request_completed

	if rawResults[1] == 200:
		var jsonResults = JSON.parse_string(rawResults[3].get_string_from_utf8())

		var lookup:Dictionary = {}
		for statGroup in jsonResults.statGroups:
			var statgroup_id = int(statGroup.id)
			lookup[statgroup_id] = statGroup

		for stat in jsonResults.leaderboardStats:
			var statgroup_id = int(stat.statgroup_id)
			var data_item = lookup[statgroup_id]
			var p_id:int = int(data_item.members[0].profile_id)

			for p in listOfPlayers:
				if p and p.id == p_id:
					p.updateElo(stat)

		if doRefresh:
			lobbyTab.on_elo_updated()
	else:
		status.changeStatus("! Error fetching Elo")
		#print("Error ", rawResults[1])


# func requestPlayerSmurfs() -> void:
# 	var lobby = Storage.CURRENT_LOBBY
# 	var slots = lobby.slots
# 	var unchecked_players: Array = slots.filter(
# 		func(p): return p and p.lastTimeSmurfs < 0 and not p.isAI and p.id
# 	)
# 	if unchecked_players.is_empty():
# 		return

# 	var gatheredSmurfs: Array[CorePlayerClass] = []
# 	var req := HTTPRequest.new()
# 	add_child(req)

# 	var results
# 	for i in range(unchecked_players.size()):
# 		var player: CorePlayerClass = unchecked_players[i]
# 		var url := Global.URL_CHECK_SMURF + str(player.id)
# 		_pending_smurf_requests[player.id] = true

# 		req.request(url)
# 		results = await req.request_completed
# 		var body: PackedByteArray = results[3]

# 		_pending_smurf_requests.erase(player.id)

# 		if int(results[1]) != 200:
# 			continue

# 		var json = JSON.parse_string(body.get_string_from_utf8())
# 		if json.has("smurfs"):
# 			for item in json.smurfs:
# 				for s in item:
# 					var id:int = int(s.profile_id)
# 					if id > 0:
# 						var newTable = {
# 							"profile_id" = id,
# 							"alias" = s.name,
# 							"name" = "/steam/" + s.steam_id,
# 							"country" = "NO"
# 						}
# 						var newS = Storage.PLAYERS_addOne(newTable)
# 						player.addSmurf(newS)
# 						gatheredSmurfs.append(newS)

# 	await requestPlayersElo(gatheredSmurfs, false, false)
# 	if results[1] == 200:
# 		lobby.isCheckSmurfs = 2
# 	else:
# 		lobby.isCheckSmurfs = 0
# 	gatheredSmurfs.clear()
# 	lobbyTab.on_smurfs_updated()
# 	req.queue_free()

func downloadAllLobbies():
	#Storage.PLAYERS_reset()
	await requestLobbies()
	Global.LAST_LOBBY_UPDATE = Time.get_unix_time_from_system()

func openLobby(justRefresh: bool = true):
	var txt = searchField.text

	if justRefresh or (Storage.CURRENT_LOBBY and txt.is_empty()):
		lobbyTab.refreshLobby()
		lobbyTabCheck.refreshLobby()
		return

	var lobby
	match find_cases(txt):
		"general":
			lobby = Storage.LIST_findInIndex(txt, Storage.LOBBIES)
			searchField.text = ""
		"lobby_id":
			var id = int(Global.GetDigits(txt))
			lobby = Storage.LOBBIES.get(id)
		_:
			#if Storage.CURRENT_LOBBY:
			#	lobbyTab.closeCurrentLobby()
			return

	if not lobby:
		lobbyTab.closeCurrentLobby()
		lobbyTabCheck.closeCurrentLobby()
		return

	Storage.CURRENT_LOBBY = lobby
	lobbyTab.refreshLobby()
	lobbyTabCheck.refreshLobby()

func openSelectedLobby(selected):
	lobbyTab.openSelectedLobby(selected)
	lobbyTabCheck.refreshLobby()

func _on_find_button_pressed(isAuto: bool = false):
	if disabled:
		return

	disabled = true

	await downloadAllLobbies()

	var is_lobbyTab := tabs_node.current_tab > 0
	openLobby(isAuto or not is_lobbyTab)

	disabled = false
	status.showAmountOfLobbies()

func _unhandled_input(event):
	if event.is_action_pressed("StartSearch"):
		_on_find_button_pressed()

##for aoe2lobby
#func initFUNCTIONS_TABLE():
	#FUNCTIONS_TABLE["themes"] = func (data):
		#return false
#
	#FUNCTIONS_TABLE["allcurrentmatches"] = func (data):
		#Storage.SPECS_refresh(data["allcurrentmatches"])
		#return true
#
	#FUNCTIONS_TABLE["newmatches"] = func (data):
		#Storage.SPECS_refresh(data["newmatches"])
		#return true
#
	#FUNCTIONS_TABLE["deletedmatches"] = func (data):
		#Storage.SPECS_remove(data["deletedmatches"])
		#return true
#
	#FUNCTIONS_TABLE["updatedobservers"] = func (data):
		##Storage.SPECS[data.id].observers = data.observernum
		##browser.populateSpecList()
		#return false
