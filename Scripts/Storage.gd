extends Node

var PLAYERS: Dictionary = {}

var LOBBIES: Dictionary = {}
var SPECS: Dictionary = {}

var OPENED_LOBBY: LobbyClass

func _ready():
	addAIPlayers()

# Resets the LOBBIES dictionary
func LOBBIES_reset():
	LOBBIES.clear()

#from the fresh data, may have duplicates
func LOBBIES_add(source: Array):
	var id: int
	var lobby: LobbyClass
	for s in source:
		id = int(s.id)

		if LOBBIES.has(id):
			lobby = LOBBIES[id]
			lobby.title = s.description
			lobby.totalPlayers = s.matchmembers.size()
			lobby.maxPlayers = s.maxplayers
			lobby.index = str(id) + lobby.title.to_lower()

		else:
			lobby = LobbyClass.new(s)
			LOBBIES[id] = lobby
		
		lobby.sourceCache = s
		lobby.fresh = true

func LOBBIES_update(s:Dictionary):
	var lobby = LOBBIES[s.id]
	#CONTINUE

# Resets the PLAYERS dictionary
func PLAYERS_reset():
	PLAYERS.clear()

# Adds new players from the data
func PLAYERS_add(source: Array):
	var id: int
	var player: CorePlayerClass
	for p in source:
		id = int(p.profile_id)
		if not PLAYERS.has(id):
			player = CorePlayerClass.new(p)
			PLAYERS[player.id] = player

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
