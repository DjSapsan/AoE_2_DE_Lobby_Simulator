extends Node

@onready var Request = HTTPRequest

const URL: String = "https://aoe-api.worldsedgelink.com"

# Signals
signal search_completed(result)

var json = JSON.new()

# This will make a request to check for player in both open lobbies and ongoing matches
func search_for_player(id: String):
	var start: int = 0
	var all_matches: String
	var n_of_matches: int = 0

	while true:
		all_matches = await(request_advertisements(start, 100))
		n_of_matches = (all_matches.matchn(id) if 1 else 0)
		start += 100
		if all_matches.find(id) != -1 or (n_of_matches == 0 or start > 300):
			break

	emit_signal("search_completed", json.parse(all_matches))

# Function to find advertisements
func request_advertisements(start: int, count: int):
	var endpoint: String = "/community/advertisement/findAdvertisements"
	var query_string: String = "title=age2&start=%d&count=%d" % [start, count]
	var response = await Request.https_get(URL + endpoint + "?" + query_string)
	return response

# Function to request players' Elo
func request_players_elo(table):
	var endpoint: String = "/community/leaderboard/getpersonalstat"
	var query_string: String = "title=age2"
	var players_string: String = create_steam_path_string(table)
	if players_string.is_empty():
		return []
	var players_list: String = "[%s]" % players_string
	var response = await(Request.https_get(URL + endpoint + "?" + query_string + "&profile_names=" + players_list))
	return json.parse(response)

# Function to create a string for Steam paths
func create_steam_path_string(table):
	var result = []
	for item in table:
		result.append('"%s"' % item.name)
	return ",".join(result)

# Function to find matches by player name
func find_match_by_player_name(all_lobbies, player_name):
	var player_avatar = all_lobbies.avatars.find(player_name) #avatar -> avatar.alias == player_name)
	if player_avatar == null:
		return []
	var player_id = player_avatar.id
	return all_lobbies.matches.filter(func (x): all_lobbies.matchmembers.has("id") and all_lobbies.matchmembers.id == player_id)

func find():
	pass
