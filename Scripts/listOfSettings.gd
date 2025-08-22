extends VBoxContainer

@onready var estimate_elo_setts: CheckBox = %EstimateEloSetts
@onready var number_of_teams_setts: OptionButton = %NumberOfTeamsSetts
@onready var balance_alg_setts: OptionButton = %BalanceAlgSetts
@onready var more_info_setts: CheckBox = %MoreInfoSetts
@onready var lobby_players_list: VBoxContainer = %LobbyPlayersList
@onready var balancer: Button = %BalanceButton
@onready var short_names_label: Label = $ShortNamesLabel

func _on_desired_teams_item_selected(index):
	balancer.num_teams = index + 2
	balancer.startBalancing()

func _on_balance_type_item_selected(index):
	balancer.startBalancing()

func _on_estimate_elo_setts_toggled(isEstimateElo: bool) -> void:
	lobby_players_list.refreshAllElo()
	balancer.startBalancing()

func _on_short_names_setts_changed(value: float) -> void:
	match value:
		2.:
			short_names_label.text = "Names full:"
		1.:
			short_names_label.text = "Names with no clans:"
		0.:
			short_names_label.text = "Names short:"

	lobby_players_list.refreshAllNames()
	balancer.startBalancing()
