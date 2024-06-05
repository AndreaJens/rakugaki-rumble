extends Node

enum NetworkPlayer {
	Spectator = 0,
	Player1 = -1,
	Player2 = 1
}

var connectedPlayers = {}
var ipAddress : String ="127.0.0.1"
var port : String = "8081"
var nameToDisplay : String = "AkumajoDracula"
var localPlayerId : NetworkPlayer = NetworkPlayer.Spectator
var character1Path : String = "chara_naomi"
var character2Path : String = "chara_naomi"
var numberOfRounds : int = 3
var localPlayerDeviceId : int = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
