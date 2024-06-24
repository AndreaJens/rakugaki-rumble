extends Node

@export var musicVolume : int = 10
@export var sfxVolume : int = 10
@export var muteMusic : bool = false
@export var muteSfx : bool = false
const OptionFileName : String = "user://options.cfg"

func save_to_file():
	var saveFile = FileAccess.open(OptionFileName, FileAccess.WRITE)
	var data : Dictionary = {
		"musicVolume" : musicVolume,
		"sfxVolume" : sfxVolume,
		"muteMusic" : muteMusic,
		"muteSfx" : muteSfx,
	}
	# JSON provides a static method to serialized JSON string.
	var jsonString = JSON.stringify(data)
	# Store the save dictionary as a new line in the save file.
	saveFile.store_line(jsonString)

func load_from_file():
	if not FileAccess.file_exists(OptionFileName):
		print("No option save file found. Creating one...")
		save_to_file()
		return # Error! We don't have a save to load.
	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var saveFile = FileAccess.open(OptionFileName, FileAccess.READ)
	if saveFile.get_position() < saveFile.get_length():
		var jsonString = saveFile.get_line()
		# Creates the helper class to interact with JSON
		var json = JSON.new()
		# Check if there is any error while parsing the JSON string, skip in case of failure
		var parseResult = json.parse(jsonString)
		if not parseResult == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", jsonString, " at line ", json.get_error_line())
			return
		# Get the data from the JSON object
		var data = json.get_data()
		for key in data.keys():
			set(key, data[key])

func get_music_volume() -> float:
	if muteMusic:
		return -100.
	return (10 - musicVolume) * -5.


func get_sfx_volume() -> float:
	if muteSfx:
		return -100.
	return (10 - sfxVolume) * -5.
