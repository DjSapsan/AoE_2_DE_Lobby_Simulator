extends Button

@onready var eloField = %L_elo
@onready var teamPanel = preload("res://scenes/balancedTeamScene.tscn")
@onready var main = get_node("/root/Control")
@onready var balanceDisplay = %BalanceDisplay
@onready var lobbyPlayersList = %LobbyPlayersList
@onready var rebalance_button: Button = %RebalanceButton
@onready var balance_alg_setts: OptionButton = %BalanceAlgSetts

const template = "\t\t\t[u][b]TEAM {team} ({elo})[/b][/u]\n{players}"

var total_players
var min_diff
var num_teams = 2

var manual = false
static var teamsRegex:RegEx

var cant = false
var current_teams:Dictionary

func _ready():
	teamsRegex = RegEx.new()
	teamsRegex.compile("^.*\n")

func startBalancing():
	if Global.ACTIVE_BROWSER_ID == 1:
		return
	disabled = true
	rebalance_button.visible = false
	manual = false
	var playerNodes = lobbyPlayersList.get_children().filter(func(slot): return slot.associatedPlayer != null)
	current_teams = balance_teams(playerNodes)
	refresh_team_display()

func refresh_team_display():
	main.removeTeamDisplay()

	if cant:
		balanceDisplay.visible=false
		disabled = true
		return
	else:
		balanceDisplay.visible=true
		disabled = false

	var sorted_keys = current_teams.keys()
	sorted_keys.sort()

	for i in sorted_keys:
		var listTxt := ""
		var sumElo := 0.0
		for playerNode in current_teams[i]:
			listTxt += playerNode.nameLabel.text + "\n"
			sumElo += float(playerNode.eloField.text)

		var newBalancedTeamPanel = teamPanel.instantiate()
		newBalancedTeamPanel.text = template.format({"team": i + 1, "players": listTxt, "elo": String.num(sumElo, 0)})
		balanceDisplay.add_child(newBalancedTeamPanel)

	disabled = false

func manual_refresh_teams():
	manual = true
	rebalance_button.visible = true
	var playerNodes = lobbyPlayersList.get_children().filter(func(slot): return slot.associatedPlayer != null)
	current_teams.clear()
	for p in playerNodes:
		if p.team_index > 0:
			var team_key = p.team_index - 1
			if !current_teams.has(team_key):
				current_teams[team_key] = []
			if p not in current_teams[team_key]:
				current_teams[team_key].push_back(p)
	refresh_team_display()

# ---------- helpers ----------

func _player_elo(p) -> float:
	return float(p.eloField.text)

func _apply_current_teams_and_set_players(teams: Dictionary) -> void:
	current_teams.clear()
	for k in teams.keys():
		current_teams[k] = teams[k]
	for team_key in current_teams.keys():
		for player in current_teams[team_key]:
			player.set_team(team_key + 1)

# ---------- existing unconstrained search (type 2) ----------
func find_teams(players: Array, teams: Dictionary, index := 0) -> void:
	if index == total_players:
		var team_ratings := {}
		for team_key in teams.keys():
			var team_rating := 0.0
			for player in teams[team_key]:
				team_rating += _player_elo(player)
			team_ratings[team_key] = team_rating
		var diff = abs(team_ratings.values().max() - team_ratings.values().min())
		if diff < min_diff:
			min_diff = diff
			var best := {}
			for key in teams.keys():
				best[key] = teams[key].duplicate(true)
			_apply_current_teams_and_set_players(best)
		return

	for i in teams.keys():
		var new_teams := {}
		for key in teams.keys():
			new_teams[key] = teams[key].duplicate(true)
		if players[index] not in new_teams[i]:
			new_teams[i].push_back(players[index])
		find_teams(players, new_teams, index + 1)

# ---------- equal-sized fair search (type 0) ----------
func find_teams_equal(players: Array, teams: Dictionary, counts: Dictionary, target_size: int, index := 0) -> void:
	if index == total_players:
		# all teams at target_size by construction
		var team_ratings := {}
		for team_key in teams.keys():
			var team_rating := 0.0
			for player in teams[team_key]:
				team_rating += _player_elo(player)
			team_ratings[team_key] = team_rating
		var diff = abs(team_ratings.values().max() - team_ratings.values().min())
		if diff < min_diff:
			min_diff = diff
			var best := {}
			for key in teams.keys():
				best[key] = teams[key].duplicate(true)
			_apply_current_teams_and_set_players(best)
		return

	# try placing current player into any team that still has capacity
	for i in teams.keys():
		if counts[i] >= target_size:
			continue
		var new_teams := {}
		var new_counts := {}
		for key in teams.keys():
			new_teams[key] = teams[key].duplicate(true)
			new_counts[key] = counts[key]
		new_teams[i].push_back(players[index])
		new_counts[i] += 1
		find_teams_equal(players, new_teams, new_counts, target_size, index + 1)

# ---------- pair strongest with weakest (type 1) ----------
func balance_pairs(players: Array) -> Dictionary:
	var entries := []
	for p in players:
		entries.append({"p": p, "elo": _player_elo(p)})
	entries.sort_custom(func(a, b): return a["elo"] > b["elo"]) # descending

	var teams := {}
	var sums := {}
	for t in range(num_teams):
		teams[t] = []
		sums[t] = 0.0

	var i := 0
	var j := entries.size() - 1
	while i <= j:
		var pair := []
		pair.append(entries[i])
		if i != j:
			pair.append(entries[j])
		i += 1
		j -= 1

		# choose team with current lowest sum
		var target_team := 0
		var best_sum := INF
		for k in teams.keys():
			if sums[k] < best_sum:
				best_sum = sums[k]
				target_team = k

		for ent in pair:
			teams[target_team].push_back(ent["p"])
			sums[target_team] += ent["elo"]

	# apply and return
	_apply_current_teams_and_set_players(teams)
	return current_teams

# ---------- dispatcher ----------
func balance_teams(playerItems: Array) -> Dictionary:
	var alg_type: int = balance_alg_setts.selected

	total_players = playerItems.size()
	min_diff = INF

	# guard: no players
	if total_players == 0:
		current_teams.clear()
		for x in range(num_teams):
			current_teams[x] = []
		return current_teams
	
	cant = false
	match alg_type:
		0:
			# equal number of players + fair
			if total_players % num_teams != 0:
				#push_warning("Equal teams not possible: %d players across %d teams." % [total_players, num_teams])
				cant = true
				return {}
			var target_size := int(total_players / num_teams)
			var init := {}
			var counts := {}
			for x in range(num_teams):
				init[x] = []
				counts[x] = 0
			find_teams_equal(playerItems, init, counts, target_size)
			return current_teams

		1:
			# strongest+weakest paired
			return balance_pairs(playerItems)

		2:
			# existing method: unconstrained sizes, minimize Elo diff
			var initu := {}
			for x in range(num_teams):
				initu[x] = []
			find_teams(playerItems, initu)
			return current_teams

		_:
			# default to existing method
			var initd := {}
			for x in range(num_teams):
				initd[x] = []
			find_teams(playerItems, initd)
			return current_teams

func format_player_list(input_text: String) -> String:
	var result := teamsRegex.sub(input_text, "", true)
	result = result.strip_edges(true, true)
	var players := result.split("\n")
	return ", ".join(players)

func _on_pressed():
	if !Storage.CURRENT_LOBBY:
		return
	var out := ""
	for i in current_teams.keys():
		var team = balanceDisplay.get_children()[i]
		out += ("T%d: " % (i + 1)) + format_player_list(team.text) + " | "
	DisplayServer.clipboard_set(out)
