extends Node

var LOBBIES: Dictionary = {}
var PLAYERS: Dictionary = {}
var SPECS: Dictionary = {}

var CURRENT_LOBBY: LobbyClass

func _ready():
	addAIPlayers()

# Resets the LOBBIES dictionary
func LOBBIES_reset():
	LOBBIES.clear()

func LOBBIES_remove_absent(received_ids):
	var ids_to_remove = []
	for id in LOBBIES.keys():
		if id not in received_ids:
			ids_to_remove.append(id)
	for id in ids_to_remove:
		LOBBIES.erase(id)

func LOBBIES_add(data,steamIDs):
	for l in data:
		var id = l.id
		var new_lobby: LobbyClass = LobbyClass.new(l, "lobby",steamIDs)
		LOBBIES[id] = new_lobby
		#if the lobby was refreshed:
		if CURRENT_LOBBY and CURRENT_LOBBY.id == id:
			CURRENT_LOBBY = new_lobby

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

# Resets the SPECS dictionary
func SPECS_reset():
	SPECS.clear()

# remove specs from the data
func SPECS_remove(lobby_ids):
	for i in lobby_ids:
		if Storage.SPECS.has(i):
			var l = Storage.SPECS[i]
			l.associatedNode.queue_free()
			Storage.SPECS.erase(i)

func SPECS_removeOne(lobby_id):
	if Storage.SPECS.has(lobby_id):
		var l = Storage.SPECS[lobby_id]
		l.associatedNode.queue_free()
		Storage.SPECS.erase(lobby_id)


# Adds specs from the data
func SPECS_changeOne(id, data):
	if data:
		var new_spec: LobbyClass = LobbyClass.new(data, "spec")
		SPECS[new_spec.id] = new_spec
		return new_spec
	else:
		SPECS_removeOne(id)

func SPECS_refresh(data):
	for id in data:
		var s = data[id]
		if SPECS.has(id):
			pass
			#print("Updating spec")
			# Update existing spec
			#var existing_spec = SPECS[id]
			#existing_spec.update(s)
		else:
			# Add new spec
			var new_spec: LobbyClass = LobbyClass.new(s, "spec")
			SPECS[id] = new_spec

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
