class_name LobbyClass

# players keys
const CIV_KEY := 1
const COLOR_KEY := 3
const TEAM_KEY := 7

# lobby option keys
const START_IN_KEY := 0
const ALLOW_CHEATS_KEY := 1
const END_IN_KEY := 4
const GAME_TYPE_KEY := 5
const MAP_SIZE_KEY := 8
const MAP_ID_KEY := 10
const MAX_POP_KEY := 28
const RESOURCES_KEY := 37
const SCENARIO_NAME_KEY := 38
const GAME_SPEED_KEY := 41
const TREATY_KEY := 57
const DATA_MOD_ID_KEY := 59
const AI_DIFFICULTY_KEY := 61
const FULL_TECH_TREE_KEY := 62
const DATA_MOD_NAME_KEY := 63
const LOCK_SPEED_KEY := 65
const LOCK_TEAMS_KEY := 66
const SHARED_EXPLORATION_KEY := 76
const TURBO_MODE_KEY := 79
const VICTORY_CONDITION_KEY := 80
const VICTORY_KEY := 81
const MAP_REVEAL_KEY := 82
const TEAM_POSITION_KEY := 86
const TEAM_TOGETHER_KEY := 87#?
const IS_EW_KEY := 89
const IS_SD_KEY := 90
const IS_REGICIDE_KEY := 91
const ANTIQUITY_KEY := 100

var id: int
var steam_id: String
var title: String = ""
var password: bool = false
var maxPlayers: int = 8

var startgametime: int

var gameModeName: String
var map: String = "-"
var mapID: int
var size: String
var AI_difficulty: String
var resources: String
var maxPop: int
var speed: String
var mapReveal: String
var startIn: String
var endIn: String
var treaty: String
var victory: String
var victoryCondition: String

var isLockSpeed: bool = false
var isCheats: bool = false
var isTurbo: bool = false
var isFullTech: bool = false
var isEW: bool = false
var isSD: bool = false
var isRegicide: bool = false
var isAntiquity: bool = false
var isLockTeams: bool = false
var isTogether: bool = false
var isTeamPosition: bool = false
var isSharedExploration: bool = false

var rankedType: String = "-"
var isVisible: bool = true
var isObservable: bool = true
var observerDelay: int = 0
var dataModName: String = "AoE2 DE"
var dataModID: int
var isModded: bool = false

var totalPlayers: int = 0
var isHideCivs: bool = false
var server: String

var slotinfo
var slots: Array [CorePlayerClass] = [null,null,null,null,null,null,null,null]
var teams: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
var realTeams: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
var civs: Array[int] = [65537, 65537, 65537, 65537, 65537, 65537, 65537, 65537]
var colors: Array[int] = [4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295]
#var ready:  Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
#var openedSlots: Array[bool] = [true, true, true, true, true, true, true, true]

# 0 - not checking, 1 = loading, 2 = done
var isCheckSmurfs := 0
var isOngoging := false

var index: String = ""	#text index for searching

var associatedNode: Control

#var host: CorePlayerClass = null
#var host_id: String = ""

# Constructor
func _init(source, kind, steamIDs:Dictionary = {}):

	match kind:
		"lobby":
			id = source.id
			steam_id = steamIDs.get(id,"")
			totalPlayers = source.matchmembers.size()
			maxPlayers = source.maxplayers

			#Decode options and parse game/map types
			slotinfo = JSON.parse_string("["+decode_slots(source.slotinfo)+"]")[1]
			title = source.description
			parseOptionBytes(decode_options(source.options))
			putPlayersInSlotsWithInfo()

			if isModded:
				title = "🌟 "+title
			#map = str(source.mapname)
			server = source.relayserver_region
			password = source.passwordprotected
			isVisible = source.visible > 0
			isObservable = source.isobservable > 0
			observerDelay = int(source.observerdelay)
#
		#for aoe2lobby
		#"spec":
			#id = source.lobbyid
			#title = "👁 " + source.description
			#maxPlayers = source.maxplayers
			#map = source.Map
			#gameModeName = source.Game_Mode
			#server = source.relayserver_region
			##password = source.passwordprotected
			#translateMembers(source.slot)
			#startgametime = source.startgametime
			#isOngoging = true

		# # for aoe2recs.com
		# "spec":
		# 	id = source.id
		# 	title = "👁 " + source.diplomacy
		# 	maxPlayers = source.players.size()
		# 	map = source.map
		# 	gameModeName = source.game_type
		# 	server = source.server
		# 	#password = source.passwordprotected
		# 	translateMembers(source.players)
		# 	startgametime = source.start_timestamp

		#"spec_update":
			#id = source.id
			#title = "👁 " + source.match_diplomacy
			#maxPlayers = 8
			#map = source.match_map
			#gameModeName = source.game_type
			#server = source.server
			##password = source.passwordprotected
			#translateMembers(source.players)
			#startgametime = source.last_match

	index = index + title.to_lower()+map.to_lower()
	if title == "test":
		pass
	#host_id = str(source.host_profile_id)
	#host = Storage.PLAYERS[int(source.host_profile_id)]

# translates values from the spectators API source into the internal representation
func translateMembers(source):
	var player: CorePlayerClass
	#var k
	#var p_id: int
	var pos: int
	#var groups
	var p: CorePlayerClass
	for positions in source:
		var position = source[positions]
		for player_index in position:
			p = position[player_index]
			player = translatePlayer(p)
			pos = int(player_index[1]) - 1
			slots[pos] = player
			colors[pos] = int(p["color"])-1
			teams[pos] = int(p["team"])
			if Tables.REVERSE_CIVS_TABLE.has(p["civ"]):
				civs[pos] = Tables.REVERSE_CIVS_TABLE[p["civ"]]
			else:
				civs[pos] = Tables.REVERSE_CIVS_TABLE["unknown"]
			totalPlayers += 1

#for aoe2lobby
## translates values from the spectators API source into the internal representation
#func translatePlayer(source):
	#var p: CorePlayerClass
	#if source.has("name") and source.name == "AI":
		#p = Storage.PLAYERS[-1]
	#elif Storage.PLAYERS.has(source.profile_id):
		#p = Storage.PLAYERS[source.profile_id]
	#else:
		#var newP = {}
		#newP["profile_id"] = source.profile_id
		#newP["alias"] = source.name if source.has("name") else "unknown"
		#newP["name"] = "" #source.steamprofile if source["steamprofile"] else ""
		#newP["country"] = source.country if source["country"] else "NO"
#
		#var stat = {}
		#
		#index = index + newP["alias"]
		#
		#p = Storage.PLAYERS_addOne(newP)
	#return p


# for aoe2recs.com
# translates values from the spectators API source into the internal representation
func translatePlayer(source):
	var p: CorePlayerClass
	if Storage.PLAYERS.has(source.profile_id):
		p = Storage.PLAYERS[source.profile_id]
	elif source.has("name") and source.name == "AI":
		p = Storage.PLAYERS[0]
	else:
		var newP := {}
		newP["profile_id"] = source.profile_id
		newP["alias"] = source.name if source.has("name") else "<unknown>"
		newP["name"] = "" #source.steamprofile if source["steamprofile"] else "" #not required yet
		if source.has("country") and source.country:
			newP["country"] = source.country
		else:
			newP["country"] = "NO"

		index = index + newP["alias"]

		p = Storage.PLAYERS_addOne(newP)
	return p

func decode_options(input: String) -> PackedByteArray:
	var decoded: PackedByteArray = Marshalls.base64_to_raw(input)
	var unzipped: PackedByteArray = decoded.decompress(16384, FileAccess.COMPRESSION_DEFLATE)

	# unzipped is a UTF-8 string that contains base64 text (your `txt`)
	var txt := unzipped.get_string_from_utf8().replace('"', '')

	# this becomes the binary stream with [u32len][ascii "k:v"]...
	var bin := Marshalls.base64_to_raw(txt)
	return bin

# Function to decode options (as already implemented)
func decode_slots(input: String) -> String:
	var decoded: PackedByteArray = Marshalls.base64_to_raw(input)
	var unzipped: PackedByteArray = decoded.decompress(16384, 1)
	return unzipped.get_string_from_ascii()

# func set_match_type_from_options(decoded_options: Dictionary):
# 	var game_type = get_option_value(decoded_options, GAME_TYPE_KEY, null)
# 	if game_type == null:
# 		return

# 	var game_type_id := int(game_type)
# 	gameModeName = Tables.GAME_TYPE_TABLE.get(game_type_id, "Other type")

# func set_isHideCivs_from_options(decoded_options: Dictionary):
# 	if get_option_int(decoded_options, HIDDEN_KEY, 0) == 1:
# 		isHideCivs = true

# func set_modded_from_options(decoded_options: Dictionary):
# 	var modded_value = get_option_value(decoded_options, MODDED_KEY, null)
# 	if modded_value != null and str(modded_value) != "0":
# 		isModded = true

# func get_map_from_options(decoded_options: Dictionary) -> String:
# 	var map_name := ""
# 	var map_type = get_option_value(decoded_options, MAP_TYPE_KEY, null)
# 	if map_type:
# 		map_name = Tables.MAPS_TABLE.get(int(map_type), "")

# 	if map_name == "":
# 		var rms_name = get_option_value(decoded_options, IS_RMS_NAME, null)
# 		if rms_name != null:
# 			map_name = str(rms_name).get_file().get_basename()
# 		#elif decoded_options.has(MAP_CUSTOM_KEY):
# 		#	var custom_map = decoded_options[MAP_CUSTOM_KEY].get_file().get_basename()
# 		#	map_name = custom_map
# 		else:
# 			map_name = "other map"

# 	return map_name
	
# taking options from the decoded byte array in the loop to avoid allocating memory and work
# func processOptionKV(K:int, V):
# 	if title == "test":
# 		pass

# 	var t	# temp var

# 	t = options.get(CUSTOM_MAP_KEY, "") 
# 	if t == "y":
# 		map = Tables.MAPS_TABLE.get(int(t), "unknown map")
# 		gameModeName = "Random Map"
# 	elif t == "n":
# 		pass
# 	elif t == "":
# 		map = "unknown map"

# 	t = options.get(SCENARIO_KEY, "")
# 	if t == "n":
# 		pass
# 	if t == "y":
# 		map = "scenario"
# 		gameModeName = "Scenario"
# 	elif t == "":
# 		pass
# 	else:
# 		dataModName = t
# 		dataModID = options.get(DATA_MOD_ID_KEY, 0)
# 		isModded = true


# Extract dictionary from packed array
func getDictionary(packed_array: PackedByteArray) -> Dictionary:
	var printable_array := PackedByteArray()
	
	var byte: int
	for i in range(5, packed_array.size()):
		byte = packed_array[i]
		if byte >= 32 and byte <= 126:  # ASCII printable range
			printable_array.append(byte)
		else:
			printable_array.append(9)  #tab

	var printable_string := printable_array.get_string_from_ascii()

	var dictionary := {}
	var pairs := printable_string.split("\t", false)

	var key_value: PackedStringArray
	var key: int
	var value
	for pair in pairs:
		if pair.find(":") != -1:
			key_value = pair.split(":", false)
			if key_value.size() == 2:
				key = int(key_value[0])
				value = key_value[1]
				dictionary[key] = value

	#if title == "test":
		#pass
	return dictionary

# Function to parse slot information and assign players to slots
func putPlayersInSlotsWithInfo():
	var position := 0
	var c := 0
	var profile_id := 0
	var player : CorePlayerClass
	var meta: PackedStringArray
	totalPlayers = 0
	for slot in slotinfo:
		profile_id = int(slot["profileInfo.id"])  # Extract profile ID

		if slot.metaData == "IkFBPT0i" or slot.metaData == "": #EMPTY
			slots[position] = null
		#elif slot.metaData == null:
			#slots[position] = null
			##openedSlots[position] = true
		else:
			totalPlayers += 1
			if Storage.PLAYERS.has(profile_id):
				player = Storage.PLAYERS[profile_id]
				meta = decodeMetaData(slot["metaData"])

				index += player.alias.to_lower()
				slots[position] = player
				#ready[position] = int(slot["isReady"])

				if player.isAI:
					pass

				if meta.size() > 0:
					if isHideCivs:
						civs[position] = -2
					else:
						c = int(meta[CIV_KEY])
						if c > 45 and c < 65537:
							pass
						civs[position] = int(meta[CIV_KEY])
					colors[position] = int(meta[COLOR_KEY])
					var t: String = meta.get(TEAM_KEY)
					var t_int: int = 0
					if t == "":
						realTeams[position] = 5
					else:
						t_int = int(t)-1
						if t_int >= 0 and t_int < 5:
							realTeams[position] = t_int
						else:
							realTeams[position] = 5
			else:
				pass
				#print("warning! Got data but no player in the list ", profile_id)

		position = position + 1

func decodeMetaData(data) -> PackedStringArray:
	#if title == "test":
		#pass
	var decodedOne := Marshalls.base64_to_raw(data)
	var txt := decodedOne.get_string_from_utf8().replace('"', '')
	var decodedTwo := Marshalls.base64_to_raw(txt)

	var printable_array := PackedByteArray()

	for i in range(5, decodedTwo.size()):
		var byte := decodedTwo[i]
		if byte >= 32 and byte <= 126:  # ASCII printable range
			printable_array.append(byte)
		else:
			printable_array.append(9)  # tab

	var printable_string := printable_array.get_string_from_ascii()
	var result: PackedStringArray = printable_string.split("\t", false)
	return result

func getRegularURL() -> String:
	var type:int = 0
	if isOngoging:
		type = 1
	return "aoe2de://%d/%d" % [type, id]

func getSteamURL() -> String:
	#var type:int = 0
	#if isOngoging:
		#type = 1
	var url := "steam://joinlobby/813780/" + steam_id
	return url
	
func _read_u32_le(data: PackedByteArray, offset: int) -> int:
	# little-endian: b0 + (b1<<8) + (b2<<16) + (b3<<24)
	return int(data[offset]) \
		| (int(data[offset + 1]) << 8) \
		| (int(data[offset + 2]) << 16) \
		| (int(data[offset + 3]) << 24)

# static var debug_baseline_by_lobby: Dictionary = {}

func parseOptionBytes(data: PackedByteArray):
	#var debugStringK = ""
	#var debugStringV = ""
	#if title == "test":
		#pass
		
	var i := 1

	while i + 4 <= data.size():
		var n := _read_u32_le(data, i)
		i += 4

		if n <= 0:
			continue
		if i + n > data.size():
			break  # truncated/corrupt or wrong endianness

		var s := data.slice(i, i + n).get_string_from_ascii()
		i += n

		var sep := s.find(":")
		if sep == -1:
			continue

		var key := int(s.substr(0, sep))
		var val_str := s.substr(sep + 1)
		
		#debugStringK += "%d, " % [key]
		#debugStringV += val_str + ", "
		
		if optionFunctions.has(key):
			optionFunctions[key].call(self, val_str)
		
	#if title == "test":
		#pass		
		#print("\nParsed options: ")
		#print("\n",debugStringK)
		#print("\n",debugStringV)
	# 	var debug_key := str(id)
	# 	var expected_debug: String = str(debug_baseline_by_lobby.get(debug_key, ""))
	# 	if expected_debug != "" and debugStringV != expected_debug:
	# 		var parsed_keys := debugStringK.split(",", false)
	# 		var parsed_values := debugStringV.split(",", false)
	# 		var expected_values := expected_debug.split(",", false)
	# 		var j := 0
	# 		for parsed_entry in parsed_values:
	# 			if j >= parsed_keys.size() or j >= expected_values.size():
	# 				break
	# 			var key_str := parsed_keys[j].strip_edges()
	# 			var parsed_value := parsed_entry.strip_edges()
	# 			var expected_value := expected_values[j].strip_edges()
	# 			if parsed_value != expected_value and key_str != "":
	# 				print("[%s] %s -> %s" % [key_str, parsed_value, expected_value])
	# 			j += 1
	# 	debug_baseline_by_lobby[debug_key] = debugStringV
	# 	#print("\nParsed options: ")
	# 	#print("\n",debugStringK)
	# 	#print("\n",debugStringV)
	

# array of functions for each option key to avoid if-else:
static var optionFunctions: Dictionary = {
	
	DATA_MOD_ID_KEY: func(l:LobbyClass,v):
		if (v!="0"):
			l.dataModID = int(v)
			l.isModded = true
		pass,

	SCENARIO_NAME_KEY: func(l:LobbyClass,v):
		l.map = v
		l.gameModeName = "Scenario"
		l.size = "-"
		pass,

	MAX_POP_KEY: func(l:LobbyClass,v):
		l.maxPop = int(v)
		pass,

	SHARED_EXPLORATION_KEY: func(l:LobbyClass,v):
		if v =="y":
			l.isSharedExploration = true
		pass,
	
	MAP_SIZE_KEY: func(l:LobbyClass,v):
		l.size = Tables.MAP_SIZES_TABLE.get(int(v), "?")
		pass,
	
	LOCK_TEAMS_KEY: func(l:LobbyClass,v):
		if v == "y":
			l.isLockTeams = true
		pass,
	
	LOCK_SPEED_KEY: func(l:LobbyClass,v):
		if v == "y":
			l.isLockSpeed = true
		pass,
	
	ALLOW_CHEATS_KEY: func(l:LobbyClass,v):
		if v == "y":
			l.isCheats = true
		pass,
	
	TURBO_MODE_KEY: func(l:LobbyClass,v):
		if v == "y":
			l.isTurbo = true
		pass,
	
	FULL_TECH_TREE_KEY: func(l:LobbyClass,v):
		if v == "y":
			l.isFullTech = true
		pass,
	
	#75 record game
	# 75: func(l:LobbyClass,v):
	# 	if v == "y":
	# 		l.isRecording = true
	# 	pass,

	#extreme, hardest, hard, moderate, standard, easiest
	AI_DIFFICULTY_KEY: func(l:LobbyClass,v):
		l.AI_difficulty = Tables.LOBBY_AI_DIFFICULTY_TABLE.get(int(v), "?")
		pass,
	
	RESOURCES_KEY: func(l:LobbyClass,v):
		l.resources = Tables.LOBBY_RESOURCES_TABLE.get(int(v), "?")
		pass,

	GAME_SPEED_KEY: func(l:LobbyClass,v):
		l.speed = Tables.LOBBY_SPEED_TABLE.get(int(v), "?")
		pass,

	MAP_REVEAL_KEY: func(l:LobbyClass,v):
		l.mapReveal = Tables.LOBBY_MAP_REVEAL_TABLE.get(int(v), "?")
		pass,

	START_IN_KEY: func(l:LobbyClass,v):
		l.startIn = Tables.LOBBY_START_IN_TABLE.get(int(v), "?")
		pass,
	
	END_IN_KEY: func(l:LobbyClass,v):
		l.endIn = Tables.LOBBY_END_IN_TABLE.get(int(v), "?")
		pass,

	TREATY_KEY: func(l:LobbyClass,v):
		l.treaty = v
		pass,

	GAME_TYPE_KEY: func(l:LobbyClass,v):
		l.gameModeName = Tables.GAME_TYPE_TABLE.get(int(v), "?")
		pass,

	MAP_ID_KEY: func(l:LobbyClass,v):
		l.map = Tables.MAPS_TABLE.get(int(v), "?")
		l.mapID = int(v)
		pass,

	VICTORY_CONDITION_KEY: func(l:LobbyClass,v):
		l.victoryCondition = v
		pass,

	VICTORY_KEY: func(l:LobbyClass,v):
		l.victory = Tables.LOBBY_VICTORY_TABLE.get(int(v), "?")
		pass,

	ANTIQUITY_KEY: func(l:LobbyClass,v):
		if v == "y":
			l.isAntiquity = true
		pass,

	#64 is custom map
	# 64: func(l:LobbyClass,v):
	# 	if v == "y":
	# 		l.gameModeName = "Scenario"
	# 	pass,

	#is team together
	TEAM_TOGETHER_KEY: func(l:LobbyClass,v):
		if v == "y":
			l.isTogether = true
		pass,
	
	TEAM_POSITION_KEY: func(l:LobbyClass,v):
		if v == "y":
			l.isTeamPosition = true
		pass,
	
	#is EW, is SD, is Regicide
	IS_EW_KEY: func(l:LobbyClass,v):
		if v == "y":
			l.isEW = true
		pass,
	IS_SD_KEY: func(l:LobbyClass,v):
		if v == "y":
			l.isSD = true
		pass,

	IS_REGICIDE_KEY: func(l:LobbyClass,v):
		if v == "y":
			l.isRegicide = true
		pass,	
	
	DATA_MOD_NAME_KEY: func(l:LobbyClass,v):
		l.dataModName = v
		pass,
}
