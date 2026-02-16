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

	for raw_team_key in sorted_keys:
		var team_key: int = int(raw_team_key)
		var listTxt := ""
		var sumElo := 0.0
		for playerNode in current_teams[team_key]:
			listTxt += playerNode.nameLabel.text + "\n"
			sumElo += float(playerNode.eloField.text)

		var newBalancedTeamPanel = teamPanel.instantiate()
		var global_team_index := team_key
		newBalancedTeamPanel.text = template.format({
			"team": Global.TeamIndex[global_team_index],
			"players": listTxt,
			"elo": String.num(sumElo, 0)
		})
		balanceDisplay.add_child(newBalancedTeamPanel)

	disabled = false

func manual_refresh_teams():
	rebalance_button.visible = true
	var playerNodes = lobbyPlayersList.get_children().filter(func(slot): return slot.associatedPlayer != null)
	current_teams.clear()
	for p in playerNodes:
		var global_team_index := _player_team_index(p)
		var team_key = global_team_index
		if !current_teams.has(team_key):
			current_teams[team_key] = []
		if p not in current_teams[team_key]:
			current_teams[team_key].push_back(p)
	refresh_team_display()

# ---------- helpers ----------

func _player_elo(p) -> float:
	return float(p.eloField.text)

func _player_team_index(p) -> int:
	if p.has_method("getTeam"):
		return int(p.getTeam())
	return int(p.team_index)

func _apply_current_teams_and_set_players(teams: Dictionary) -> void:
	current_teams.clear()
	for k in teams.keys():
		current_teams[k] = teams[k]
	for team_key in current_teams.keys():
		for player in current_teams[team_key]:
			player.set_team(int(team_key)+1)

# Fills out_caps with per-team capacities. Returns true on success.
# If enforce_equal is requested and players aren't divisible, sets 'cant' and returns false.
func _compute_capacities(n: int, t: int, enforce_equal: bool, out_caps: Array) -> bool:
	out_caps.clear()
	var base := int(floor(float(n) / float(t)))
	var extra := n % t
	if enforce_equal and extra != 0:
		cant = true
		return false
	for i in range(t):
		out_caps.append(base + (0 if enforce_equal else (1 if i < extra else 0)))
	return true

# Backtracking helper for best Elo balance
func _backtrack(players: Array, enforce_equal: bool, capacities: Array, teams: Array, sums: Array, counts: Array, idx: int) -> void:
	if idx == total_players:
		var max_sum := -INF
		var min_sum := INF
		for s in sums:
			if s > max_sum: max_sum = s
			if s < min_sum: min_sum = s
		var diff: float = abs(max_sum - min_sum)
		if diff < min_diff:
			min_diff = diff
			var best := {}
			for k in range(num_teams):
				best[k] = teams[k].duplicate(true)
			_apply_current_teams_and_set_players(best)
		return

	var p = players[idx]
	var elo := _player_elo(p)
	for t in range(num_teams):
		if enforce_equal and counts[t] >= capacities[t]:
			continue
		teams[t].push_back(p)
		sums[t] += elo
		counts[t] += 1
		_backtrack(players, enforce_equal, capacities, teams, sums, counts, idx + 1)
		counts[t] -= 1
		sums[t] -= elo
		teams[t].pop_back()

# ---------- unified, efficient backtracking search ----------
# Uses in-place mutation with push/pop to avoid cloning at every step.
func _search_best_distribution(players: Array, enforce_equal: bool, capacities: Array) -> void:
	var teams: Array = []
	var sums: Array = []
	var counts: Array = []
	for _i in range(num_teams):
		teams.append([])
		sums.append(0.0)
		counts.append(0)
	min_diff = INF
	_backtrack(players, enforce_equal, capacities, teams, sums, counts, 0)

# ---------- pair strongest with weakest (type 1), simplified ----------
func balance_pairs(players: Array) -> Dictionary:
	# Sort players by Elo descending
	var entries := []
	for p in players:
		entries.append({"p": p, "elo": _player_elo(p)})
	entries.sort_custom(func(a, b): return a["elo"] > b["elo"]) # descending

	# capacities ensure final spread <= 1 across teams
	var caps: Array = []
	if !_compute_capacities(entries.size(), num_teams, false, caps):
		return {}
	var teams := {}
	var sums := {}
	var left_cap := {}
	for t in range(num_teams):
		teams[t] = []
		sums[t] = 0.0
		left_cap[t] = caps[t]

	var i := 0
	var j := entries.size() - 1
	while i <= j:
		var pair := []
		pair.append(entries[i])
		if i != j:
			pair.append(entries[j])

		# Try to place the pair into the single lowest-sum team if capacity allows; else split
		var target_team := -1
		var lowest_sum := INF
		for k in teams.keys():
			if left_cap[k] >= pair.size() and sums[k] < lowest_sum:
				lowest_sum = sums[k]
				target_team = k

		if target_team != -1:
			for ent in pair:
				teams[target_team].push_back(ent["p"])
				sums[target_team] += ent["elo"]
				left_cap[target_team] -= 1
		else:
			# Split across two lowest-sum teams with capacity
			pair.sort_custom(func(a, b): return a["elo"] > b["elo"]) # stronger first
			for ent in pair:
				var pick_team := -1
				var best_sum := INF
				for k in teams.keys():
					if left_cap[k] > 0 and sums[k] < best_sum:
						best_sum = sums[k]
						pick_team = k
				if pick_team == -1:
					cant = true
					return {}
				teams[pick_team].push_back(ent["p"])
				sums[pick_team] += ent["elo"]
				left_cap[pick_team] -= 1

		i += 1
		j -= 1

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
			# equal number of players + fair: must be divisible
			var caps0: Array = []
			if !_compute_capacities(total_players, num_teams, true, caps0):
				return {}
			_search_best_distribution(playerItems, true, caps0)
			return current_teams

		1:
			# strongest+weakest paired (spread<=1 enforced via capacities)
			return balance_pairs(playerItems)

		2:
			# unconstrained sizes, minimize Elo diff
			_search_best_distribution(playerItems, false, [])
			return current_teams

		_:
			# default to unconstrained method
			_search_best_distribution(playerItems, false, [])
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
	var sorted_keys := current_teams.keys()
	sorted_keys.sort()
	var children := balanceDisplay.get_children()
	for idx in range(sorted_keys.size()):
		var team_key: int = int(sorted_keys[idx])
		var global_team_index := team_key
		var team_node = children[idx]
		out += ("T%s: " % Global.TeamIndex[global_team_index]) + format_player_list(team_node.text) + " | "
	DisplayServer.clipboard_set(out)
