extends Node

var STEAM_APP_ID: int = 4433870
var STEAM_ID: int = 0
var STEAM_NAME = ""
var IS_ONLINE: bool = false
var IS_OWNED: bool = false
var boardhandle : int

var ACHIEVEMENTS : Dictionary = {
	"TEST_ACHIEVEMENT_ONE" = false,
	"TEST_ACHIEVEMENT_TWO" = false,
}

var STATISTICS : Dictionary = {
	"DEATH" = 0
}

var leaderboard_info = []
var player_name
var score

func _ready():
	if !OS.has_feature("standalone"):
		_initialize_Steam()
		get_statistics()
		Steam.findLeaderboard("Highscore")

func _process(_delta):
	Steam.run_callbacks()

func _init():
	OS.set_environment("SteamAppId", str(STEAM_APP_ID))
	OS.set_environment("SteamGameId", str(STEAM_APP_ID))
	
	Steam.leaderboard_find_result.connect(leaderboard_results)
	Steam.leaderboard_scores_downloaded.connect(leaderboard_scores)

func _initialize_Steam():
	var INIT: Dictionary = Steam.steamInitEx(false)

	if INIT['status'] > 0:
		print("Failed to initialize Steam. " + str(INIT['verbal'])+" Shutting down...")
		get_tree().quit()

	IS_ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_NAME = Steam.getPersonaName()
	IS_OWNED = Steam.isSubscribed()
	
	if IS_OWNED == false:
		print("User does not own this game")
		get_tree().quit()

func setLeaderboardScore(leaderboardscore : int):
	Steam.uploadLeaderboardScore(leaderboardscore)

func leaderboard_results(handle, found):
	if found:
		boardhandle = handle
		Steam.downloadLeaderboardEntries(1, 10)

func leaderboard_scores(message, handle, result):
	leaderboard_info = result
	for r in result:
		var name = Steam.getFriendPersonaName(r["steam_id"])
		var score = r["score"]

func get_leaderboard_entry(slot : int):
	if leaderboard_info.find(slot) == null: 
		return
	player_name = Steam.getFriendPersonaName(leaderboard_info[slot].steam_id)
	score = leaderboard_info[slot].score


func unlock_achievements(name):
	if ACHIEVEMENTS.has(name):
		ACHIEVEMENTS[name] = true
		Steam.setAchievement(str(name))
		Steam.storeStats()

func store_statistics(name, value):
	if STATISTICS.has(name):
		Steam.setStatInt(name, value)
		Steam.storeStats()

func get_statistics():
	for stats in STATISTICS:
		STATISTICS[stats] = Steam.getStatInt(stats) 
