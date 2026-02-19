extends Node

var PLAYERS: Dictionary = {}

var LOBBIES: Dictionary = {}
var SPECS: Dictionary = {}

var LIVE_LOBBIES: Dictionary = {}

var OPENED_LOBBY: LobbyClass

func _ready():
	addAIPlayers()

# Resets the LOBBIES dictionary
func LOBBIES_reset():
	LOBBIES.clear()
	LIVE_LOBBIES.clear()

func LOBBIES_remove_absent(received_ids):
	var ids_to_remove = []
	for id in LOBBIES.keys():
		if id not in received_ids:
			ids_to_remove.append(id)
	for id in ids_to_remove:
		LOBBIES.erase(id)

#from the fresh data, may have duplicates
#TODO add logic for handling duplicates
func LOBBIES_create(data):
	for d in data:
		var id = d.id
		var new_lobby: LobbyClass = LobbyClass.new(d)
		LOBBIES[id] = new_lobby
		LIVE_LOBBIES[id] = true
		#if the lobby was refreshed:
		if OPENED_LOBBY and OPENED_LOBBY.id == id:
			OPENED_LOBBY = new_lobby

func LOBBIES_refresh(data, steamIDs):
	for d in data:
		var id = d.id
		if LOBBIES.has(id):
			var existing_lobby = LOBBIES[id]
			existing_lobby.loadDetails(d, steamIDs)
		else:
			var new_lobby: LobbyClass = LobbyClass.new(d)
			LOBBIES[id] = new_lobby

# Resets the PLAYERS dictionary
func PLAYERS_reset():
	PLAYERS.clear()

# Adds new players from the data
func PLAYERS_add(data):
	for p in data:
		if not PLAYERS.has(int(p.profile_id)):
			var new_player: CorePlayerClass = CorePlayerClass.new(p)
			PLAYERS[new_player.id] = new_player

# Adds new players from the data
func PLAYERS_addOne(p):
	if not PLAYERS.has(int(p.profile_id)):
		var new_player: CorePlayerClass = CorePlayerClass.new(p)
		PLAYERS[new_player.id] = new_player
		return new_player
	else:
		return PLAYERS[int(p.profile_id)]

# Move this to a separate utility script if needed for more lists
func LIST_findInIndex(search: String, list: Dictionary) -> LobbyClass:
	search = search.to_lower()
	for id in list:
		var lobby = list[id] as LobbyClass
		if lobby.index.contains(search):
			return lobby
	return null

func addAIPlayers():
	#var AIs: Dictionary
	var ai = {
	"profile_id" : -1,
	"alias" : "AI",
	"name" : "",
	"country" : "AI",
	}
	var new = Storage.PLAYERS_addOne(ai)
	new.isAI = true
