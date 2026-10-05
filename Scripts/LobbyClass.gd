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
const MAP_RMS_KEY := 11
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
const HIDDEN_KEY := 85
const TEAM_POSITION_KEY := 86
const TEAM_TOGETHER_KEY := 87#?
const IS_EW_KEY := 89
const IS_SD_KEY := 90
const IS_REGICIDE_KEY := 91
const ANTIQUITY_KEY := 100

# aoe2lobby (ongoing matches) has its own value tables: field -> [property, text by value]
const SPEC_TEXTS := {
	"size": ["size", ["Tiny (2 p) [120]", "Small (3 p) [144]", "Medium (4 p) [168]", "Normal (6 p) [200]", "Large (8 p) [220]", "Huge [240]", "Ludicrous [480]"]],
	"ai_difficulty": ["AI_difficulty", ["Easiest", "Moderate", "Hard", "Extreme", "Standard", "Hardest"]],
	"resources": ["resources", ["Standard", "Low", "Medium", "High", "Ultra High", "Infinite", "Random"]],
	"speed": ["speed", ["Slow", "Casual", "Normal", "Fast"]],
	"reveal_map": ["mapReveal", ["Normal", "Explored", "All Visible"]],
	"starting_age": ["startIn", ["Standard", "Dark Age", "Feudal Age", "Castle Age", "Imperial Age", "Post-Imperial Age"]],
	"ending_age": ["endIn", ["Dark Age", "Imperial Age", "Standard", "Castle Age", "Feudal Age"]],
	"victory": ["victory", ["Standard", "Conquest", "Time Limit", "Score", "Last Man Standing", "Custom"]],
}
const SPEC_MODES := ["Random Map", "Empire Wars", "Regicide", "King of the Hill", "Death Match", "Battle Royale", "Sudden Death", "Capture the Relic", "Defend the Wonder", "Wonder Race", "Scenario", "Co-Op Campaign"]
const SPEC_SERVERS := ["brazilsouth", "australiasoutheast", "ukwest", "southeastasia", "westeurope", "westus3", "koreacentral", "centralindia", "eastus", "chilecentral", "southcentralus"]
# aoe2lobby field -> property, for values taken as they are
const SPEC_FLAGS := {
	"cheats": "isCheats", "turbo_mode": "isTurbo", "full_tech_tree": "isFullTech", "ew_mode": "isEW",
	"sudden_death_mode": "isSD", "regicide_mode": "isRegicide", "antiquity_mode": "isAntiquity",
	"lock_teams": "isLockTeams", "lock_speed": "isLockSpeed", "team_together": "isTogether",
	"team_positions": "isTeamPosition", "shared_exploration": "isSharedExploration", "hide_civilizations": "isHideCivs",
}
# aoe2lobby civilizations whose ids differ from the game ones (0 = hidden)
const SPEC_CIVS := {0: -2, 65: 54, 67: 46, 68: 47, 69: 48, 70: 49, 71: 50, 72: 51, 73: 52, 74: 53, 75: 58, 76: 57, 77: 59}

var id: int
var steam_id: String
var title: String = ""
var password: bool = false
var maxPlayers: int = 8

var startgametime: int
var fresh: bool = false
var goneTime: float	# when the lobby left the open list

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

var totalPlayers: int = 1
var isHideCivs: bool = false
var server: String

# map options decoded by decode_options: official game key (int) -> raw value string.
# Kept for the whole lifetime of the lobby.
var options: Dictionary = {}

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

#only temporarely to load the details iteratively
var sourceCache

var associatedNode: Control

# three levels of loading:
# first = .id, .description, 1 / .maxplayers
# second = everything
# third = generating the sharing code

var loadingLevel := 0
var sharingCode := ""

# level 1 of loading
func _init(source, isSpec := false):
	if isSpec:
		id = int(source.matchid)
		setSpecSource(source)
		return
	id = source.id
	steam_id = Storage.STEAM_IDS.get(int(id), "")
	title = source.description
	totalPlayers = source.matchmembers.size()
	maxPlayers = source.maxplayers
	password = source.passwordprotected
	index = str(source.id) + title.to_lower()
	loadingLevel = 1

# level 1 for an ongoing match (aoe2lobby), also turns an open lobby into an ongoing one.
# Only the values the source provides override the old ones.
func setSpecSource(source: Dictionary):
	isOngoging = true
	sourceCache = source
	startgametime = int(source.start_time)
	if source.steam_lobbyid:
		steam_id = source.steam_lobbyid
	if source.password != null:
		password = source.password
	if source.data_mod:
		dataModName = source.data_mod
		isModded = true
	title = ("👁 🌟 " if isModded else "👁 ") + source.description
	if source.mode != null and int(source.mode) >= 0 and int(source.mode) < SPEC_MODES.size():
		gameModeName = SPEC_MODES[int(source.mode)]
	if source.scenario:
		map = source.scenario.trim_suffix(".aoe2scenario")
	elif source.custom_map:
		map = source.custom_map.trim_suffix(".rms")
	elif int(source.mapid) < 0:	# maps missing in aoe2lobby's table come as their game id
		map = Tables.MAPS_TABLE.get(-int(source.mapid), source.map_name)
	else:
		map = source.map_name
	# slots_taken/slots_total skip AI and are sometimes 0, so the slots are counted
	index = str(id) + title.to_lower()
	totalPlayers = 0
	for slot in source.slots.values():
		if slot.status == 2 or slot.status == 3:	# AI or player
			totalPlayers += 1
			if slot.get("name"):
				index += slot.name.to_lower()
	maxPlayers = maxi(int(source.slots_total), totalPlayers)
	loadingLevel = 1

#level 2 of loading - for the list
func loadBasicDetails():
	if isOngoging:
		loadSpecSettings()
	else:
		parseOptionBytes(decode_options(sourceCache.options))
	loadingLevel = 2
	# if title == "test":
	# 	pass

func loadSpecSettings():
	var i: int
	for key in SPEC_TEXTS:
		if sourceCache[key] != null:
			i = int(sourceCache[key])
			if i >= 0 and i < SPEC_TEXTS[key][1].size():
				set(SPEC_TEXTS[key][0], SPEC_TEXTS[key][1][i])
	for key in SPEC_FLAGS:
		if sourceCache[key] != null:
			set(SPEC_FLAGS[key], sourceCache[key])
	if sourceCache.population != null:
		maxPop = int(sourceCache.population)
	if sourceCache.treaty_length != null:
		treaty = str(int(sourceCache.treaty_length))
	if sourceCache.victory_threshold != null:
		victoryCondition = str(int(sourceCache.victory_threshold))
	if gameModeName == "Scenario":
		size = "-"

#level 3 of loading - for searching and filtering
func loadAllDetails():
	if isOngoging:
		if sourceCache.server != null and int(sourceCache.server) >= 0 and int(sourceCache.server) < SPEC_SERVERS.size():
			server = SPEC_SERVERS[int(sourceCache.server)]
		if sourceCache.observable != null:
			isObservable = sourceCache.observable
		if sourceCache.observer_delay != null:
			observerDelay = int(sourceCache.observer_delay * 60)	# minutes in aoe2lobby
		loadingLevel = 3
		return
	server = sourceCache.relayserver_region
	isVisible = sourceCache.visible > 0
	isObservable = sourceCache.isobservable > 0
	observerDelay = int(sourceCache.observerdelay)
	totalPlayers = sourceCache.matchmembers.size()
	var player: CorePlayerClass
	for member in sourceCache.matchmembers:
		player = Storage.PLAYERS.get(int(member.profile_id))
		if player:
			index += player.alias.to_lower()
	loadingLevel = 3

#level 4 of loading - only when opening the lobby
func loadInternalDetails():
	if not sourceCache:
		return
	if isOngoging:
		putSpecPlayersInSlots(sourceCache.slots)
	else:
		var slotinfo: Array = JSON.parse_string("["+decode_slots(sourceCache.slotinfo)+"]")[1]
		putPlayersInSlotsWithInfo(slotinfo)
	loadingLevel = 4
	sourceCache = null

#only on demand
func loadSharingCode(code: String):
	sharingCode = code

# aoe2lobby slots are "s1".."s8"; status 2 = AI, 3 = player, others are open/closed.
# Civs are not hidden: they are revealed once the game runs.
func putSpecPlayersInSlots(source: Dictionary):
	var s: Dictionary
	var pos: int
	var t: int
	slots.fill(null)
	totalPlayers = 0
	for key in source:
		s = source[key]
		pos = int(key.substr(1)) - 1
		if pos < 0 or pos > 7 or (s.status != 2 and s.status != 3):
			continue
		totalPlayers += 1
		slots[pos] = Storage.PLAYERS[-1] if s.status == 2 else getSpecPlayer(s)
		civs[pos] = specCiv(int(s.civilization))
		colors[pos] = int(s.color) if s.color != null else 4294967295
		t = int(s.team) - 1 if s.team != null else 5	# aoe2lobby: 1 = no team, 2-5 = teams 1-4
		realTeams[pos] = t if t >= 0 and t < 5 else 5
		teams[pos] = realTeams[pos]

func getSpecPlayer(s: Dictionary) -> CorePlayerClass:
	var country = s.get("country")
	return Storage.PLAYERS_addOne({
		"profile_id": int(s.profileid),
		"alias": s.name if s.get("name") else str(int(s.profileid)),
		"country": country if country and country.length() == 2 else "NO",
	})

# civs missing in aoe2lobby's table come negative and off by one: -63 is the game's 62
static func specCiv(c: int) -> int:
	if c < 0:
		return -c - 1
	return SPEC_CIVS.get(c, c)

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
func putPlayersInSlotsWithInfo(slotinfo: Array):
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

func join() -> void:
	var url: String = ""
	if Global.OStype == "Windows":
		url = getRegularURL()
	elif Global.OStype == "Linux/BSD":
		url = getSteamURL()
	if url != "":
		OS.shell_open(url)

func getRegularURL() -> String:
	var type:int = 0
	if isOngoging:
		type = 1
	return "aoe2de://%d/%d" % [type, id]

# joinlobby always joins, spectating needs the aoe2de:// link
func getSteamURL() -> String:
	if isOngoging:
		return getRegularURL()
	return "steam://joinlobby/813780/" + steam_id
	
func _read_u32_le(data: PackedByteArray, offset: int) -> int:
	# little-endian: b0 + (b1<<8) + (b2<<16) + (b3<<24)
	return int(data[offset]) \
		| (int(data[offset + 1]) << 8) \
		| (int(data[offset + 2]) << 16) \
		| (int(data[offset + 3]) << 24)

# static var debug_baseline_by_lobby: Dictionary = {}

func parseOptionBytes(data: PackedByteArray):
	# var debugStringK = ""
	# var debugStringV = ""
	#if title == "test":
		#pass
		
	options.clear()
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
		
		# debugStringK += "%d, " % [key]
		# debugStringV += val_str + ", "

		options[key] = val_str
		if optionFunctions.has(key):
			optionFunctions[key].call(self, val_str)
		
	# if id==457229479:
	# 	pass
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
			if not l.isModded:	# only applies on the the first load
				l.dataModID = int(v)
				l.isModded = true
				l.title = "🌟 " + l.title
		pass,

	SCENARIO_NAME_KEY: func(l:LobbyClass,v:String):
		l.map = v.trim_suffix(".aoe2scenario")
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

	HIDDEN_KEY: func(l:LobbyClass,v):
		if v == "1":
			l.isHideCivs = true
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
		l.victory = Tables.LOBBY_VICTORY_TABLE.get(int(v), "-")
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

	#take the value and remove last 4 chars
	MAP_RMS_KEY: func(l:LobbyClass,v):
		l.map = v.left(-4)
		pass,
}
