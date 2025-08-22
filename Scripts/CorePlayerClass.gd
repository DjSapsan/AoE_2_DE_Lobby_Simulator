class_name CorePlayerClass

var id: int
var alias: String = ""
var shortAlias: String = ""
var shortestAlias: String = ""

var steamName: String = ""
var country: String = "NO"
var flag: String = "🌐" #flag if possible
var AKA: PackedStringArray
var isAI: bool = false	#🤖 🖳⚙

var slot #slot reference in a lobby

var stat: Dictionary
var lastTimeElo: float = -1
var overridenElo
var notRanked := true

var smurfs: Dictionary [CorePlayerClass, bool]
var significantSmurfs: bool = false

var lastTimeSmurfs: float = -1

static var regex_split: RegEx
static var regex_brackets: RegEx
static var regex_clan_prefix: RegEx
static var regex_remove_platforms: RegEx
static var trailing_digits_regex: RegEx

static func _static_init():
	regex_clan_prefix = RegEx.new()
	#regex_clan_prefix.compile(r'^[^\p{L}]*[\p{L}\p{N}]{2,5}\s*[^\'\p{L}\p{N}\s]{1,3}\s*(\p{L}.{3,})$')
	regex_clan_prefix.compile(r'^.*[\p{L}\p{N}\p{S}]{2,5}\s*[^\p{L}\s]{1,3}\s*(\p{L}[\p{L}\p{N}].{1,})$')
	regex_brackets = RegEx.new()
	regex_brackets.compile(r"[\[({<][^\]\)\}>]*[\]\)\}>](?=.{3,}$)")
	regex_split = RegEx.new()
	regex_split.compile(r"(?:[\p{Lu}]+(?![\p{Ll}\p{N}]))|(?:[\p{Lu}][\p{Ll}\p{N}]+)|(?:[\p{Ll}\p{N}]+)")
	trailing_digits_regex = RegEx.new()
	trailing_digits_regex.compile(r"^(.*?)(\d{2,})$")
	regex_remove_platforms = RegEx.new()
	regex_remove_platforms.compile(r"(?i)(\W)*?(twitch(\.tv)?|youtube(\.tv)?)(\W)*")

func updateElo(data: Dictionary) -> void:

	var now = Time.get_unix_time_from_system()
		
	data.games = data.wins + data.losses
	if data.games == 0:
		data.wr = 0.5
	else:
		data.wr = data.wins / data.games
	stat[int(data.leaderboard_id)] = data
	if data.leaderboard_id == 3 or data.leaderboard_id == 4:
		notRanked = false
	lastTimeElo = now

func addSmurf(s:CorePlayerClass):
	smurfs[s] = true

func hasSmurfs() -> bool:
	return not smurfs.is_empty()

# Constructor
func _init(source):
	id = int(source.profile_id)
	alias = source.alias
	steamName = source.name
	country = source.country
	flag = getFlagCode(source.country)

func getShortStat():
	var result ="%-20s (ID: %10d)" % [alias, id]
	if stat.has(3):
		result += "RM = %4d %5.2f%%" % [stat[3].rating, stat[3].wr]
	return result

# converts Elo from RM to TG and vice versa
func RM_to_TG(elo, toLB):
	if toLB == 4:
		return (0.6889521364481163 * elo + 359.44192245019207)
	elif toLB == 3:
		return (elo - 359.44192245019207) / 0.6889521364481163

#LB_ID - leaderboard ID
# 3 - leaderboard 1v1
# 4 - leaderboard TG
# TG/RM = 0.75
func estimateElo(LB_ID):
	if notRanked:
		return Global.ELO_ZERO
		
	var current_rating := 0.0
	var highest_rating := 0.0
	var winrate := 0.5  # Default winrate
	var estimated_elo := 0.0
	var confidence := 1.0
	var base := 0.0
	var delta := 0.0
	
	var alternative_LB_ID = 4 if LB_ID == 3 else 3

	var stat_entry = stat.get(LB_ID, null)
	var alt_stat_entry = stat.get(alternative_LB_ID, null)

	if stat_entry:
		current_rating = stat_entry.rating
		highest_rating = stat_entry.highestrating if stat_entry.highestrating > 0 else current_rating
		winrate = clamp(stat_entry.wr, 0.001, 0.999)
		confidence = clamp( ( 1.01 - 1.0 / stat_entry.games), 0.001, 0.999)
		base = (current_rating + 3.0 * highest_rating) / 4.0
		delta = Global.ELO_FACTOR * (log(winrate / (1.0 - winrate)) / log(10))
		estimated_elo = clamp(base + confidence * delta, 100, 4000)

		# if other rating is too different, then the player is much better than the main Elo tells,
		# otherwise disregard
		if alt_stat_entry:
			var expectedElo = RM_to_TG(alt_stat_entry.rating, alternative_LB_ID)
			if expectedElo > estimated_elo:
				confidence = clamp( ( 1.01 - 1.0 / alt_stat_entry.games), 0.001, 0.999)
				var bonus = 0.1*confidence*(expectedElo - estimated_elo)
				estimated_elo += bonus

	elif alt_stat_entry:
		# Use the alternative leaderboard stats, adjusted
		winrate = clamp(alt_stat_entry.wr, 0.001, 0.999)
		confidence = clamp( ( 1.01 - 1.0 / alt_stat_entry.games), 0.001, 0.999)
		base = (alt_stat_entry.rating) #no highest rating for TG
		delta = Global.ELO_FACTOR * (log(winrate / (1.0 - winrate)) / log(10))
		estimated_elo = clamp(base + confidence * delta, 100, 4000)
		estimated_elo = RM_to_TG(estimated_elo, alternative_LB_ID)

	else:
		# No stats available
		return Global.ELO_ZERO

	return int(estimated_elo)

func getElo(LB) -> int:
	if stat.has(LB):
		return int(stat[LB].rating)
	return Global.ELO_ZERO

func getWR(LB) -> float:
	if stat.has(LB):
		return stat[LB].wr
	return 0.5

func isEloOutdated():
	return ( Time.get_unix_time_from_system() - lastTimeElo ) / 60 > Global.ELO_OUTDATED_MIN

func is_upper(s: String) -> bool:
	if s.to_lower() == s:	# if the string is the same when converted to lowercase, then it's not uppercase
		return false
	return true


# 3 = full
# 2 = less
# 1 = smallest
func getName(reduceLevel: int = 2) -> String:
	if reduceLevel == 2:
		return alias
	
	if shortAlias == "":
		makeShortNames() #will work only if requested
	
	if reduceLevel == 1:
		return shortAlias
	
	return shortestAlias
	
const nameLimit = 11  # Define the character nameLimit for the shortened name
const nameEnough = 4  # if 4 chars then just return
func makeShortNames() -> void:
	# 1) Pre-processing: Trim, remove platform mentions, and remove clan prefixes.
	var name = alias.strip_edges()
	name = regex_remove_platforms.sub(name, "", true)

	var matching = regex_brackets.search(name)
	if matching:
		name = regex_brackets.sub(name, "", false)
	elif regex_clan_prefix.search(name):
		name = regex_clan_prefix.search(name).get_string(1)

	name = name.strip_edges()
	if name.length() > 0:
		shortAlias = name
	else:
		shortAlias = alias.left(nameLimit)

	# 2) Tokenize the name using the regex.
	var tokens: Array[String] = []
	for result in regex_split.search_all(name):
		var token = result.get_string().strip_edges()
		if token.length() > 0:
			tokens.append(token)
	if tokens.is_empty():
		shortestAlias = shortAlias
		return
	
	# Only check the last token for trailing digits
	if tokens.size() > 0:
		var last_token = tokens[-1]
		var m = trailing_digits_regex.search(last_token)
		# Only split if there's a non-empty prefix
		if m and m.get_string(1) != "":
			var prefix = m.get_string(1)
			var digits = m.get_string(2)
			tokens[-1] = prefix
			tokens.append(digits)

	# 3) Score tokens and pick the best one.
	var best_token: String = tokens[0]
	var best_score: int = -1000
	for i in range(tokens.size()):
		var token = tokens[i]
		# Start with a score equal to the token's length.
		var score = token.length()
		# Bonus: first token gets +1.
		if i == 0:
			score += 1
		# Bonus: add +5 for a present uppercase letter.
		if is_upper(token):
			score += 4
		# Penalty: tokens with 3 or less characters get -3.
		if token.length() <= 3:
			score -= 3
		# Select token with highest score.
		if score > best_score:
			best_score = score
			best_token = token

	# Ensure the result does not exceed the maximum allowed length.
	if best_token.length() > nameLimit:
		best_token = best_token.left(nameLimit)
	
	if best_token.length() > 0:
		shortestAlias = best_token
	else:
		shortestAlias = shortAlias

func getFlagCode(_country: String):
	if _country == "AI":
		return "🤖"
	elif _country == "NO":
		return "🌐"
	var code = _country.to_upper()
	var f = ""
	var offset
	offset = code[0].unicode_at(0) - 65 + 0x1F1E6
	f += char(offset)
	offset = code[1].unicode_at(0) - 65 + 0x1F1E6
	f += char(offset)
	return f

func getStatProperty(lb, property):
	if stat.has(lb):
		return stat[lb][property]

	return 0
