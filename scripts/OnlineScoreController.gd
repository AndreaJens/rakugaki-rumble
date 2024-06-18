extends Control
var dictionaryKey : String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if visible and NetworkAssistant.onlineScores.has(dictionaryKey):
		$Player1Score.text = str(NetworkAssistant.onlineScores[dictionaryKey][0])
		$Player2Score.text = str(NetworkAssistant.onlineScores[dictionaryKey][1])
		$FPS.text = "FPS: %s" % Performance.get_monitor(Performance.TIME_FPS)
	
func set_dictionary_key(newKey : String):
	dictionaryKey = newKey
