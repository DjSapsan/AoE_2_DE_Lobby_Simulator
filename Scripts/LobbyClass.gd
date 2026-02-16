class_name LobbyClass

const GAME_TYPE_KEY := 5
const MAP_TYPE_KEY := 10
const MAP_CUSTOM_KEY := 10
const GAME_SPEED_KEY := 41
const HIDDEN_KEY := 85
const MODDED_KEY := 60
const MOD_NAME_KEY := 63
const SCENARIO_NAME_KEY := 38
const RMS_NAME_KEY := 11
const EXPANSION := 67 #?

const COLOR_KEY := 3
const CIV_KEY := 1

var id: int
var steam_id: String
var title: String = ""
var password: bool = false
var hidden_civs: bool = false
var is_modded: bool = false
var maxPlayers: int = 8
var match_type: String
var startgametime: int
var server: String
var map: String = "-"
var size: String
var resources: String
var maxPop: int
var victory: String
var speed: String
var totalPlayers: int = 0
var observers: int = 0

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
			var decoded_options: Dictionary = decode_options(source.options)
			title = source.description
			parse_options(decoded_options)
			putPlayersInSlotsWithInfo()

			if is_modded:
				title = "🌟 "+title
			#map = str(source.mapname)
			server = source.relayserver_region
			password = source.passwordprotected
#
		#for aoe2lobby
		#"spec":
			#id = source.lobbyid
			#title = "👁 " + source.description
			#maxPlayers = source.maxplayers
			#map = source.Map
			#match_type = source.Game_Mode
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
		# 	match_type = source.game_type
		# 	server = source.server
		# 	#password = source.passwordprotected
		# 	translateMembers(source.players)
		# 	startgametime = source.start_timestamp

		#"spec_update":
			#id = source.id
			#title = "👁 " + source.match_diplomacy
			#maxPlayers = 8
			#map = source.match_map
			#match_type = source.game_type
			#server = source.server
			##password = source.passwordprotected
			#translateMembers(source.players)
			#startgametime = source.last_match

	index = index + title.to_lower()+map.to_lower()
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


# Function to decode options (as already implemented)
func decode_options(input: String) -> Dictionary:
	var decoded: PackedByteArray = Marshalls.base64_to_raw(input)
	var unzipped: PackedByteArray = decoded.decompress(16384, 1)
	var txt := unzipped.get_string_from_utf8().replace('"', '')
	var array := Marshalls.base64_to_raw(txt)
	var result := getDictionary(array)
	return result

# Function to decode options (as already implemented)
func decode_slots(input: String) -> String:
	var decoded: PackedByteArray = Marshalls.base64_to_raw(input)
	var unzipped: PackedByteArray = decoded.decompress(16384, 1)
	return unzipped.get_string_from_ascii()

# Function to parse game and map types from decoded options
func parse_options(decoded_options: Dictionary):
	if title == "test":
		pass
		#var x = Marshalls.base64_to_raw(decoded_options[52])
		#var p = x.get_string_from_utf32()

	# if title == "CBA 6x":
	# 	var s = ""
	# 	for key in decoded_options.keys():
	# 		s += "%s : %s , " % [key, decoded_options[key]]
	# 	print(title,s)

	# Parse game type using the conversion table
	if decoded_options.has(GAME_TYPE_KEY):
		var game_type_id := int(decoded_options[GAME_TYPE_KEY])
		if Tables.GAME_TYPE_TABLE.has(game_type_id):
			match_type = Tables.GAME_TYPE_TABLE[game_type_id]
		else:
			match_type = "Other type"

	if decoded_options.has(HIDDEN_KEY) and int(decoded_options[HIDDEN_KEY]) == 1:
		hidden_civs = true
	if decoded_options.has(MODDED_KEY) and decoded_options[MODDED_KEY] != "0":
		is_modded = true

	# Parse map type using the conversion table
	var m: String
	if decoded_options[MAP_TYPE_KEY]:
		m = Tables.MAPS_TABLE.get(int(decoded_options[MAP_TYPE_KEY]), "")
	if m == "":
		if decoded_options.has(RMS_NAME_KEY):
			m = decoded_options[RMS_NAME_KEY].get_file().get_basename()
		#elif decoded_options.has(MAP_CUSTOM_KEY):
		#	var map_name = decoded_options[MAP_CUSTOM_KEY].get_file().get_basename()
		#	m = map_name
		else:
			m = "other map"
	map = m


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

	if title == "test":
		pass
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
					if hidden_civs:
						civs[position] = -2
					else:
						c = int(meta[CIV_KEY])
						if c > 45 and c < 65537:
							pass
						civs[position] = int(meta[CIV_KEY])
					colors[position] = int(meta[COLOR_KEY])
					var t: String = meta.get(7)
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
	if title == "test":
		pass
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
