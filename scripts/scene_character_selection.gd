class_name SceneCharacterSelection extends SceneBase

@export var _menu_p1 : GenericMenu
@export var _menu_p2 : GenericMenu
@export var _difficultySelector : DifficultySelector
@export var _stageBackgrounds : Array[Texture2D] = []
@export var pvpTexture : Texture2D
@export var pvcTexture : Texture2D
@export var cvcTexture : Texture2D
var _stageBackgroundIndex : int = 0
var _sceneChange : bool = false
var character1Path : String
var character2Path : String
var player1DeviceId : int = 0
var player2DeviceId : int = 1
var nextSceneType : SceneManager.SceneType = SceneManager.SceneType.SingleMatchMultiplayer
# Called when the node enters the scene tree for the first time.

enum DifficultySettings {
	Easy,
	Medium,
	Hard
}

enum AdditionalSceneCharacterSelectStartupParameter{
	Character1Path = 0,
	Character2Path = 1,
	StagePath = 2,
	Player1DeviceId = 3,
	Player2DeviceId = 4,
	NextSceneType = 5
}
var additionalSceneStartupParameters : Dictionary = {}

var mapOptions = {
	0 : "chara_naomi",
	1 : "chara_rhozetta",
	2 : "chara_gridd",
	3 : "chara_whitechapel",
}

func _ready():
	_menu_p1.options = [0, 1, 2, 3]
	_menu_p2.options = [0, 1, 2, 3]
	if additionalSceneStartupParameters.has(AdditionalSceneCharacterSelectStartupParameter.Player1DeviceId):
		player1DeviceId = additionalSceneStartupParameters[AdditionalSceneCharacterSelectStartupParameter.Player1DeviceId]
	if additionalSceneStartupParameters.has(AdditionalSceneCharacterSelectStartupParameter.Player2DeviceId):
		player2DeviceId = additionalSceneStartupParameters[AdditionalSceneCharacterSelectStartupParameter.Player2DeviceId]
	if additionalSceneStartupParameters.has(AdditionalSceneCharacterSelectStartupParameter.NextSceneType):
		nextSceneType = additionalSceneStartupParameters[AdditionalSceneCharacterSelectStartupParameter.NextSceneType]
	if nextSceneType == SceneManager.SceneType.SingleMatchPlayerVsCpu:
		$Logo.visible = false
		$VSCPU_Banner.visible = true
		_difficultySelector.visible = true
		if pvcTexture:
			$VSCPU_Banner.texture = pvcTexture
			$VSCPU_Banner.scale = Vector2(0.6, 0.6)
			_difficultySelector.scale = Vector2(1.0, 1.0)
	elif nextSceneType == SceneManager.SceneType.SingleMatchCpuVsCpu:
		$Logo.visible = false
		$VSCPU_Banner.visible = true
		_difficultySelector.visible = true
		if cvcTexture:
			$VSCPU_Banner.texture = cvcTexture
			$VSCPU_Banner.scale = Vector2(0.6, 0.6)
			_difficultySelector.scale = Vector2(1.0, 1.0)
	elif nextSceneType == SceneManager.SceneType.SingleMatchMultiplayer:
		$Logo.visible = true
		if pvpTexture:
			$Logo.texture = pvpTexture
		$VSCPU_Banner.visible = false
		_difficultySelector.visible = false
		
func _check_if_cancel_p1_selection_needed() -> bool:
	if !_menu_p1.selection_performed():
		return false
	if (InputOverseer.input_is_action_just_pressed("cancel", player1DeviceId)  or 
		InputOverseer.input_is_action_just_pressed_kb("cancel_p1")):
			return true
	return false

func _update_stage_selection(inputs : int):
	if !_stageBackgrounds.is_empty():
		if (inputs &  GameDatabaseAccessor.GameInputButton.ScrollRight):
			_stageBackgroundIndex += 1
			_stageBackgroundIndex %= _stageBackgrounds.size()
		elif (inputs &  GameDatabaseAccessor.GameInputButton.ScrollLeft):
			_stageBackgroundIndex -= 1
			if _stageBackgroundIndex < 0:
				_stageBackgroundIndex = _stageBackgrounds.size() - 1
		
func _update_input_p1() -> int:
	if (InputOverseer.input_is_action_just_pressed("cancel", player1DeviceId)  or 
		InputOverseer.input_is_action_just_pressed_kb("cancel_p1")):
			if !_menu_p1.selection_performed() and !_menu_p2.selection_performed():
				_menu_p1.play_cancel_sound()
				SceneManager.goto_scene_type(SceneManager.SceneType.ModeSelection)
	var allButtonsPressed = 0
	if (InputOverseer.input_is_action_just_pressed("confirm", player1DeviceId) or 
		InputOverseer.input_is_action_just_pressed_kb("confirm_p1")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Confirm
	if (InputOverseer.input_is_action_pressed("move_u", player1DeviceId) or 
		InputOverseer.input_is_action_pressed_kb("move_u_p1")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Up
	elif (InputOverseer.input_is_action_pressed("move_d", player1DeviceId)  or 
		InputOverseer.input_is_action_pressed_kb("move_d_p1")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Down
	if (InputOverseer.input_is_action_pressed("move_r", player1DeviceId) or 
		InputOverseer.input_is_action_pressed_kb("move_r_p1")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Right
	elif (InputOverseer.input_is_action_pressed("move_l", player1DeviceId)  or 
		InputOverseer.input_is_action_pressed_kb("move_l_p1")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Left
	if (InputOverseer.input_is_action_just_pressed("cancel", player1DeviceId)  or 
		InputOverseer.input_is_action_just_pressed_kb("cancel_p1")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Cancel
	if (InputOverseer.input_is_action_just_pressed("scroll_r", player1DeviceId) or 
		InputOverseer.input_is_action_just_pressed_kb("scroll_r_p1")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.ScrollRight
	elif (InputOverseer.input_is_action_just_pressed("scroll_l", player1DeviceId) or 
		InputOverseer.input_is_action_just_pressed_kb("scroll_l_p1")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.ScrollLeft
	return allButtonsPressed

func _update_input_p2() -> int:
	var allButtonsPressed = 0
	if (InputOverseer.input_is_action_just_pressed("confirm", player2DeviceId) or 
		InputOverseer.input_is_action_just_pressed_kb("confirm_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Confirm
	if (InputOverseer.input_is_action_pressed("move_u", player2DeviceId) or 
		InputOverseer.input_is_action_pressed_kb("move_u_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Up
	elif (InputOverseer.input_is_action_pressed("move_d", player2DeviceId)  or 
		InputOverseer.input_is_action_pressed_kb("move_d_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Down
	if (InputOverseer.input_is_action_just_pressed("cancel", player2DeviceId)  or 
		InputOverseer.input_is_action_just_pressed_kb("cancel_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Cancel
	if (InputOverseer.input_is_action_just_pressed("scroll_r", player2DeviceId) or 
		InputOverseer.input_is_action_just_pressed_kb("scroll_r_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.ScrollRight
	elif (InputOverseer.input_is_action_just_pressed("scroll_l", player2DeviceId) or 
		InputOverseer.input_is_action_just_pressed_kb("scroll_l_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.ScrollLeft
	return allButtonsPressed
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _player1_only() -> bool:
	return (nextSceneType == SceneManager.SceneType.Training or 
			nextSceneType == SceneManager.SceneType.SingleMatchPlayerVsCpu or
			nextSceneType == SceneManager.SceneType.SingleMatchCpuVsCpu)

func get_selected_cpu_level() -> DifficultySettings:
	@warning_ignore("int_as_enum_without_cast")
	return _difficultySelector.get_highlighted_option()

func get_stage_background_texture() -> Texture2D:
	if !_stageBackgrounds.is_empty() and _stageBackgrounds.size() > _stageBackgroundIndex:
		return _stageBackgrounds[_stageBackgroundIndex]
	return null

func _process(_delta):
	if _sceneChange:
		return
	if _player1_only():
		var buttonsPressedP1 = _update_input_p1()
		if _check_if_cancel_p1_selection_needed():
			_menu_p1.active = true
			_menu_p2.active = false
			_menu_p1.cancel_selection()
			_menu_p2.cancel_selection()
			_menu_p1.play_cancel_sound()
		if _menu_p1.selection_performed():
			_menu_p2.active = true
			_menu_p1.active = false
		else:
			_menu_p2.active = false
			_menu_p1.active = true
		_menu_p1.update(buttonsPressedP1)
		_menu_p2.update(buttonsPressedP1)
		if _difficultySelector.visible:
			_difficultySelector.update(buttonsPressedP1)
		_update_stage_selection(buttonsPressedP1)
	else:
		var buttonsPressedP1 = _update_input_p1()
		var buttonsPressedP2 = _update_input_p2()
		_menu_p1.update(buttonsPressedP1)
		_menu_p2.update(buttonsPressedP2)	
		_update_stage_selection(buttonsPressedP1 | buttonsPressedP2)
	$Stage/StageSprite.texture = get_stage_background_texture()
	if _menu_p1.selection_performed() and _menu_p2.selection_performed():
		character1Path = mapOptions[_menu_p1.get_highlighted_option()]
		character2Path = mapOptions[_menu_p2.get_highlighted_option()]
		_sceneChange = true
		await(get_tree().create_timer(0.5).timeout)
		SceneManager.goto_scene_type(nextSceneType)
