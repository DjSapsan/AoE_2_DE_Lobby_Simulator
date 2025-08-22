extends Node

const VERSION = 1.97

# Define color index with explicit colors
const ColorIndex: Dictionary = {
	0: Color(0, 0, 1),  # Blue
	1: Color(1, 0, 0),  # Red
	2: Color(0, 1, 0),  # Green
	3: Color(1, 1, 0),  # Yellow
	4: Color(0, 1, 1),  # Cyan
	5: Color(1, 0, 1),  # Magenta
	6: Color(0.25, 0.25, 0.25), # Grey
	7: Color(1, 0.5, 0),  # Orange
	4294967295: Color(0, 0, 0, 0.2),  # Empty
}

# Define team index with textual descriptions
const TeamIndex = [
	"-",
	"1",
	"2",
	"3",
	"4",
]

const SETTINGS_FILE_PATH = "user://BalanceAge.cfg"

const URL_AOE_API: String = "https://aoe-api.worldsedgelink.com"
const URL_SPEC_WSS: String = "wss://data.aoe2lobby.com/ws/"
#const URL_SPEC_WSS: String = "wss://aoe2recs.com/dashboard/api/"
const URL_UPDATE: String = "https://github.com/DjSapsan/AoE-2-DE-Lobby-Simulator/releases/latest"
const URL_API_Updates = "https://api.github.com/repos/DjSapsan/AoE-2-DE-Lobby-Simulator/releases/latest"
const URL_API_ELO: String = "/community/leaderboard/getpersonalstat"
const URL_HALF_ELO = URL_AOE_API + URL_API_ELO + "?title=age2&profile_names="
const URL_CHECK_SMURF = "https://smurf.new-chapter.eu/api/check_player?player_id="
#const URL_PLAYER_STATS = "https://www.aoe2insights.com/user/"
const URL_PLAYER_STATS = "https://www.aoe2companion.com/profile/"

var ELO_ZERO: float = 1100
var ELO_FACTOR: float = 110
var ELO_SCALE: float = 1.1

var ACTIVE_BROWSER:Control
var ACTIVE_BROWSER_ID:int = 0

var LAST_LOBBY_UPDATE = 0
var LAST_SPECS_UPDATE = 0

var ELO_OUTDATED_MIN = 60   #when Elo is counted as outdated so it requires refresh

var OStype:String

var regex_end_number
func _ready():
	regex_end_number = RegEx.new()
	regex_end_number.compile("(\\d+)$")
	match OS.get_name():
		"Windows":
			OStype = "Windows"
		"macOS":
			OStype = "macOS"
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			OStype = "Linux/BSD"
		"Android":
			OStype = "Android"
		"iOS":
			OStype = "iOS"
		"Web":
			OStype = "Web"


func GetDigits(s: String) -> int:
	return int(regex_end_number.search(s).get_string(0))

#leaderboards
# 1v1 Random Map: 3
# Team Random Map: 4
# 1v1 Deathmatch: 1
# Team Deathmatch: 2
# Unranked: 0
# 1v1 Empire Wars: 13
# Team Empire Wars: 14
# Battle Royale: 10
