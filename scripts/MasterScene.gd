class_name MasterScene extends Node

signal scene_successfully_switched

var player1DeviceId : int = 0
var player2DeviceId : int = 1
var character1Path : String = "chara_naomi"
var character2Path : String = "chara_naomi"
var cpuDifficultyLevel : int = 5
var cpuActionTicks : int = 15
var cpuInputTicks : int = 0
var stageBackgroundTexture : Texture2D
@onready var sceneChild : SceneBase = $StartupScene
@onready var screenshotAssistant : ScreenshotAssistant = $ScreenshotAssistant

# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalOptions.load_from_file()
	SceneManager.switch_scene.connect(goto_scene)
	scene_successfully_switched.connect(SceneManager._on_scene_switched)

func _process(_delta):
	if !(sceneChild is NetplayMenu):
		if InputOverseer.input_is_action_just_pressed_kb("screenshot"):
			screenshotAssistant.take_screenshot()
		if InputOverseer.input_is_action_just_pressed_kb("fullscreen_toggle"):
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				print("The game is windowed")
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				print("The game is fullscreen")
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
func _calculate_cpu_params(difficulty : SceneCharacterSelection.DifficultySettings):
	match difficulty:
		SceneCharacterSelection.DifficultySettings.Easy:
			cpuDifficultyLevel = 0
			cpuActionTicks = 20
			cpuInputTicks = 0
		SceneCharacterSelection.DifficultySettings.Medium:
			cpuDifficultyLevel = 5
			cpuActionTicks = 15
			cpuInputTicks = 0
		SceneCharacterSelection.DifficultySettings.Hard:
			cpuDifficultyLevel = 10
			cpuActionTicks = 10
			cpuInputTicks = 0

func goto_scene(path : String, type : SceneManager.SceneType):
	for child in get_children():
		if child is SceneBase:
			if child is SceneCharacterSelection:
				player1DeviceId = child.player1DeviceId
				player2DeviceId = child.player2DeviceId
				character1Path = child.character1Path
				character2Path = child.character2Path
				_calculate_cpu_params(child.get_selected_cpu_level())
				stageBackgroundTexture = child.get_stage_background_texture()
			elif child is SceneGame:
				player1DeviceId = child.player1DeviceId
				player2DeviceId = child.player2DeviceId
				character1Path = child.character1Path
				character2Path = child.character2Path
			remove_child(child) # Crashes without explicitly removing from the scene.
			child.queue_free()
	var newScene = load(path).instantiate()
	_add_extra_scene_parameters(newScene, type)
	add_child(newScene)
	for child in get_children():
		if child is SceneBase:
			sceneChild = child
			print(sceneChild)
			break
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
		SceneManager.SceneType.CharacterSelectionPlayerVsCpu:
			scene.additionalSceneStartupParameters = {
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Character1Path : character1Path,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Character2Path : character2Path,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Player1DeviceId : player1DeviceId,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Player2DeviceId : player2DeviceId,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.NextSceneType : SceneManager.SceneType.SingleMatchPlayerVsCpu,
			}
		SceneManager.SceneType.CharacterSelectionCpuVsCpu:
			scene.additionalSceneStartupParameters = {
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Character1Path : character1Path,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Character2Path : character2Path,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Player1DeviceId : player1DeviceId,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.Player2DeviceId : player2DeviceId,
				SceneCharacterSelection.AdditionalSceneCharacterSelectStartupParameter.NextSceneType : SceneManager.SceneType.SingleMatchCpuVsCpu,
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
			scene.startActivePhaseImmediately = true
			scene.roundsToWin = 0
			scene.additionalSceneStartupParameters = {
				SceneGame.AdditionalGameSceneStartupParameter.Character1Path : character1Path,
				SceneGame.AdditionalGameSceneStartupParameter.Character2Path : character2Path,
				SceneGame.AdditionalGameSceneStartupParameter.Player1DeviceId : player1DeviceId,
				SceneGame.AdditionalGameSceneStartupParameter.Player2DeviceId : player2DeviceId,
				SceneGame.AdditionalGameSceneStartupParameter.StageBackground : stageBackgroundTexture,
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
				SceneGame.AdditionalGameSceneStartupParameter.StageBackground : stageBackgroundTexture,
			}
		SceneManager.SceneType.SingleMatchPlayerVsCpu:
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
				SceneGame.AdditionalGameSceneStartupParameter.Player2AILevel : cpuDifficultyLevel,
				SceneGame.AdditionalGameSceneStartupParameter.Player2AITicks : cpuActionTicks,
				SceneGame.AdditionalGameSceneStartupParameter.Player1AIInputTicks : cpuInputTicks,
				SceneGame.AdditionalGameSceneStartupParameter.Player2AIInputTicks : cpuInputTicks,
				SceneGame.AdditionalGameSceneStartupParameter.StageBackground : stageBackgroundTexture,
			}
		SceneManager.SceneType.SingleMatchCpuVsCpu:
			scene.preventDeath = false
			scene.debugMode = false
			scene.networkMode = false
			scene.roundsToWin = 3
			scene.additionalSceneStartupParameters = {
				SceneGame.AdditionalGameSceneStartupParameter.Character1Path : character1Path,
				SceneGame.AdditionalGameSceneStartupParameter.Character2Path : character2Path,
				SceneGame.AdditionalGameSceneStartupParameter.Player1DeviceId : player1DeviceId,
				SceneGame.AdditionalGameSceneStartupParameter.Player2DeviceId : -1,
				SceneGame.AdditionalGameSceneStartupParameter.Player1isCpu : true,
				SceneGame.AdditionalGameSceneStartupParameter.Player2isCpu : true,
				SceneGame.AdditionalGameSceneStartupParameter.Player1AILevel : cpuDifficultyLevel,
				SceneGame.AdditionalGameSceneStartupParameter.Player2AILevel : cpuDifficultyLevel,
				SceneGame.AdditionalGameSceneStartupParameter.Player1AITicks : cpuActionTicks,
				SceneGame.AdditionalGameSceneStartupParameter.Player2AITicks : cpuActionTicks,
				SceneGame.AdditionalGameSceneStartupParameter.Player1AIInputTicks : cpuInputTicks,
				SceneGame.AdditionalGameSceneStartupParameter.Player2AIInputTicks : cpuInputTicks,
				SceneGame.AdditionalGameSceneStartupParameter.StageBackground : stageBackgroundTexture,
			}
	
