extends Node

enum NetworkPlayer {
	Spectator = 0,
	Player1 = -1,
	Player2 = 1
}

var connectedPlayers = {}
var ipAddress : String ="127.0.0.1"
var port : String = "8081"
var nameToDisplay : String = ""
var player1Name : String = ""
var player2Name : String = ""
var localPlayerId : NetworkPlayer = NetworkPlayer.Spectator
var character1Path : String = "chara_naomi"
var character2Path : String = "chara_naomi"
var numberOfRounds : int = 3
var localPlayerDeviceId : int = 0
var localPlayerInputDelay : int = 2
const DmmbDeviceId : int = 420
const LOG_FILE_DIRECTORY := "user://rollback_logs"
var loggingEnabled : bool = false
var showScores : bool = true
var onlineScores : Dictionary = {}

func start_new_log():
	if loggingEnabled and not SyncReplay.active:
		if DirAccess.dir_exists_absolute(LOG_FILE_DIRECTORY) == false:
			DirAccess.make_dir_absolute(LOG_FILE_DIRECTORY)
		var datetime : String = Time.get_datetime_string_from_system(true)
		datetime = datetime.replace(":", "")
		datetime = datetime.replace("-", "")
		var log_file_name = "log_p%s_%s.log" % [multiplayer.get_unique_id(), datetime ]
		print(LOG_FILE_DIRECTORY + "/" + log_file_name)
		SyncManager.start_logging(LOG_FILE_DIRECTORY + "/" + log_file_name)

func close_log():
	if loggingEnabled:
		SyncManager.stop_logging()
		print("stopped logging")

func close_session():
	if onlineScores.has("host_guest"):
		onlineScores.erase("host_guest")
		onlineScores.erase("guest_host")
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	if SyncManager.started:
		SyncManager.stop()
		SyncManager.clear_peers()
	#for peerKey in connectedPlayers:
		#if multiplayer.is_server() and peerKey != 1:
			#multiplayer.disconnect_peer(peerKey, true)
		#elif !multiplayer.is_server() and peerKey !=  multiplayer.get_unique_id():
			#multiplayer.disconnect_peer(peerKey, true)
	connectedPlayers.clear()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
