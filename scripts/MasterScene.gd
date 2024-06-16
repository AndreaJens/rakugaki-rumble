extends Node

signal scene_successfully_switched

var player1DeviceId : int = 0
var player2DeviceId : int = 1
var character1Path : String = "chara_naomi"
var character2Path : String = "chara_naomi"

# Called when the node enters the scene tree for the first time.
func _ready():
	SceneManager.switch_scene.connect(goto_scene)
	scene_successfully_switched.connect(SceneManager._on_scene_switched)

func goto_scene(path : String, type : SceneManager.SceneType):
	for child in get_children():
		if child is SceneCharacterSelection:
			player1DeviceId = child.player1DeviceId
			player2DeviceId = child.player2DeviceId
			character1Path = child.character1Path
			character2Path = child.character2Path
		elif child is SceneGame:
			player1DeviceId = child.player1DeviceId
			player2DeviceId = child.player2DeviceId
			character1Path = child.character1Path
			character2Path = child.character2Path
		remove_child(child) # Crashes without explicitly removing from the scene.
		child.queue_free()
	var new_scene = load(path).instantiate()
	_add_extra_scene_parameters(new_scene, type)
	add_child(new_scene)
	emit_signal("scene_successfully_switched")
#	# Instance the new scene.
#	current_scene = s.instantiate()
#
#	# Add it to the active scene, as child of root.
#	get_tree().root.add_child(current_scene)
func _add_extra_scene_parameters(scene, type : SceneManager.SceneType):
	match type:
		SceneManager.SceneType.CharacterSelectionTraining:
			scene.additionalSceneStartupParameters = {
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Character1Path : character1Path,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Character2Path : character2Path,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Player1DeviceId : player1DeviceId,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Player2DeviceId : player2DeviceId,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.NextSceneType : SceneManager.SceneType.Training,
			}
		SceneManager.SceneType.CharacterSelectionVsCpu:
			scene.additionalSceneStartupParameters = {
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Character1Path : character1Path,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Character2Path : character2Path,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Player1DeviceId : player1DeviceId,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Player2DeviceId : player2DeviceId,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.NextSceneType : SceneManager.SceneType.SingleMatchVsCpu,
			}
		SceneManager.SceneType.CharacterSelectionMultiplayer:
			scene.additionalSceneStartupParameters = {
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Character1Path : character1Path,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Character2Path : character2Path,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Player1DeviceId : player1DeviceId,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Player2DeviceId : player2DeviceId,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.NextSceneType : SceneManager.SceneType.SingleMatchMultiplayer,
			}
		SceneManager.SceneType.Training:
			scene.preventDeath = true
			scene.debugMode = true
			scene.networkMode = false
			scene.roundsToWin = 0
			scene.additionalSceneStartupParameters = {
				SceneGame.AdditionalGameSceneStartupParameter.Character1Path : character1Path,
				SceneGame.AdditionalGameSceneStartupParameter.Character2Path : character2Path,
				SceneGame.AdditionalGameSceneStartupParameter.Player1DeviceId : player1DeviceId,
				SceneGame.AdditionalGameSceneStartupParameter.Player2DeviceId : player2DeviceId,
			}
		SceneManager.SceneType.SingleMatchMultiplayer:
			scene.preventDeath = false
			scene.debugMode = false
			scene.networkMode = false
			scene.roundsToWin = 3
			scene.additionalSceneStartupParameters = {
				SceneGame.AdditionalGameSceneStartupParameter.Character1Path : character1Path,
				SceneGame.AdditionalGameSceneStartupParameter.Character2Path : character2Path,
				SceneGame.AdditionalGameSceneStartupParameter.Player1DeviceId : player1DeviceId,
				SceneGame.AdditionalGameSceneStartupParameter.Player2DeviceId : player2DeviceId,
			}
		SceneManager.SceneType.SingleMatchVsCpu:
			scene.preventDeath = false
			scene.debugMode = false
			scene.networkMode = false
			scene.roundsToWin = 3
			scene.additionalSceneStartupParameters = {
				SceneGame.AdditionalGameSceneStartupParameter.Character1Path : character1Path,
				SceneGame.AdditionalGameSceneStartupParameter.Character2Path : character2Path,
				SceneGame.AdditionalGameSceneStartupParameter.Player1DeviceId : player1DeviceId,
				SceneGame.AdditionalGameSceneStartupParameter.Player2DeviceId : -1,
				SceneGame.AdditionalGameSceneStartupParameter.Player2isCpu : true,
			}
	
