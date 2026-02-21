extends Button

signal refresh_completed

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

var jsonCache: Dictionary = {}

static var regex_lobby: RegEx
static var regex_steamID: RegEx

const TAB_LOBBY := 1
const TAB_CHECK := 2
const DEBUG_LOBBIES_PATH_PATTERN := "res://txt/debug_lobbies%d.json"
const EMPTY_ADVERTISEMENT_PAGE := "{\"result\":{\"code\":0,\"message\":\"SUCCESS\"},\"matches\":[],\"avatars\":[]}"

var isAutorefresh: bool = false

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

	#initFUNCTIONS_TABLE()

static func find_cases(s: String) -> String:
	if s.length() == 0:
		return "empty"
	if regex_lobby.search(s) != null:
		return "lobby_id"
	return "general"

#https://aoe-api.worldsedgelink.com/community/advertisement/findAdvertisements?title=age2&start=0
func request_advertisements(start:int=0):
	if OS.is_debug_build():
		return request_advertisements_debug(start)

	var endpoint: String = "/community/advertisement/findAdvertisements"
	var query_string: String = "title=age2&start=%d" % start
	var url = Global.URL_AOE_API + endpoint + "?" + query_string
	http_request_lobbies.request(url)
	var results = await http_request_lobbies.request_completed
	return results

func request_advertisements_debug(start: int) -> Array:
	var page_index := int(start / 100) + 1
	var path := DEBUG_LOBBIES_PATH_PATTERN % page_index

	if not FileAccess.file_exists(path):
		return [HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), EMPTY_ADVERTISEMENT_PAGE.to_utf8_buffer()]

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return [HTTPRequest.RESULT_REQUEST_FAILED, 500, PackedStringArray(), PackedByteArray()]

	var file_data := file.get_as_text()
	file.close()
	return [HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), file_data.to_utf8_buffer()]

func requestLobbies():
	var loop: int = 0
	var rawResults: Array
	var lobbies: Array
	var players: Array
	var json_string: String

	status.changeStatus("Loading lobbies...", 0)

	Storage.LIVE_LOBBIES.clear()  # Clear live lobbies before loading new batch

	var matchesSize: int = 1
	#============== start loading loop ==============
	while matchesSize > 0:
		rawResults = await request_advertisements(loop * 100)
		if rawResults[1] != 200:
			status.changeStatus("Error " + str(rawResults[1]), 1)
			#print("Error ", rawResults[1])
			return

		json_string = rawResults[3].get_string_from_utf8()
		jsonCache[loop] = JSON.parse_string(json_string)
		matchesSize = jsonCache[loop].matches.size()
		if matchesSize == 0:
			break

		steamIDs = extract_id_and_lobby(json_string)

		lobbies = jsonCache[loop].matches
		players = jsonCache[loop].avatars

		Storage.PLAYERS_add(players)
		Storage.LOBBIES_add(lobbies)

		browser.ammendLobbiesList(lobbies)

		loop += 1
	#============== end loading loop ==============
	updateAllLobbyItems()
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

func updateAllLobbyItems():
	var lobby: LobbyClass
	var lobbyItems = browser.getLobbiesItems()
	for item in lobbyItems:
		lobby = item.associatedLobby
		if Storage.LIVE_LOBBIES.has(lobby):
			#lobby.updateDetails()
			item.refreshUI()
		else:
			item.queue_free()

# func requestPlayerSmurfs() -> void:
# 	var lobby = Storage.OPENED_LOBBY
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

func refreshActiveTab() -> void:
	if tabs_node.current_tab == TAB_CHECK:
		lobbyTabCheck.refreshLobby()
	elif tabs_node.current_tab == TAB_LOBBY:
		lobbyTab.refreshLobby()

func openLobby(justRefresh: bool = true):
	var txt = searchField.text

	if justRefresh or (Storage.OPENED_LOBBY and txt.is_empty()):
		refreshActiveTab()
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
			#if Storage.OPENED_LOBBY:
			#	lobbyTab.closeCurrentLobby()
			return

	if not lobby:
		lobbyTab.closeCurrentLobby()
		lobbyTabCheck.closeCurrentLobby()
		return

	Storage.OPENED_LOBBY = lobby
	refreshActiveTab()

func openSelectedLobby(selected):
	lobbyTab.openSelectedLobby(selected)

func _pressed() -> void:
	if disabled:
		return

	disabled = true
	await downloadAllLobbies()
	disabled = false

	openLobby(tabs_node.current_tab == TAB_LOBBY)

	status.showAmountOfLobbies()
	refresh_completed.emit()

# hotkey
func _unhandled_input(event):
	if event.is_action_pressed("StartSearch"):
		_pressed()

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
