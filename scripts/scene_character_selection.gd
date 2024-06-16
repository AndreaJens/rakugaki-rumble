class_name SceneCharacterSelection extends Node2D

@export var _menu_p1 : GenericMenu
@export var _menu_p2 : GenericMenu
var character1Path : String
var character2Path : String
var player1DeviceId : int = 0
var player2DeviceId : int = 1
var nextSceneType : SceneManager.SceneType = SceneManager.SceneType.SingleMatchMultiplayer
# Called when the node enters the scene tree for the first time.

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

func _check_if_cancel_p1_selection_needed() -> bool:
	if !_menu_p1.selection_performed():
		return false
	if (InputOverseer.input_is_action_just_pressed("cancel", player1DeviceId)  or 
		InputOverseer.input_is_action_just_pressed_kb("cancel_p1")):
			return true
	return false
		
func _update_input_p1() -> int:
	if (InputOverseer.input_is_action_just_pressed("cancel", player1DeviceId)  or 
		InputOverseer.input_is_action_just_pressed_kb("cancel_p1")):
			if !_menu_p1.selection_performed() and !_menu_p2.selection_performed():
				SceneManager.goto_scene_type(SceneManager.SceneType.ModeSelection)
	var allButtonsPressed = 0
	if (InputOverseer.input_is_action_just_pressed("confirm", player1DeviceId) or 
		InputOverseer.input_is_action_just_pressed_kb("confirm_p1")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Confirm
	if (InputOverseer.input_is_action_pressed("move_u", player1DeviceId) or 
		InputOverseer.input_is_action_pressed_kb("move_u_p1")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Up
	if (InputOverseer.input_is_action_pressed("move_d", player1DeviceId)  or 
		InputOverseer.input_is_action_pressed_kb("move_d_p1")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Down
	if (InputOverseer.input_is_action_just_pressed("cancel", player1DeviceId)  or 
		InputOverseer.input_is_action_just_pressed_kb("cancel_p1")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Cancel
	return allButtonsPressed

func _update_input_p2() -> int:
	var allButtonsPressed = 0
	if (InputOverseer.input_is_action_just_pressed("confirm", player2DeviceId) or 
		InputOverseer.input_is_action_just_pressed_kb("confirm_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Confirm
	if (InputOverseer.input_is_action_pressed("move_u", player2DeviceId) or 
		InputOverseer.input_is_action_pressed_kb("move_u_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Up
	if (InputOverseer.input_is_action_pressed("move_d", player2DeviceId)  or 
		InputOverseer.input_is_action_pressed_kb("move_d_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Down
	if (InputOverseer.input_is_action_just_pressed("cancel", player2DeviceId)  or 
		InputOverseer.input_is_action_just_pressed_kb("cancel_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Cancel
	return allButtonsPressed
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _player1_only() -> bool:
	return nextSceneType == SceneManager.SceneType.Training or nextSceneType == SceneManager.SceneType.SingleMatchVsCpu

func _process(_delta):
	if _player1_only():
		var buttonsPressedP1 = _update_input_p1()
		if _check_if_cancel_p1_selection_needed():
			_menu_p1.active = true
			_menu_p2.active = false
			_menu_p1.cancel_selection()
			_menu_p2.cancel_selection()
		if _menu_p1.selection_performed():
			_menu_p2.active = true
			_menu_p1.active = false
		else:
			_menu_p2.active = false
			_menu_p1.active = true
		_menu_p1.update(buttonsPressedP1)
		_menu_p2.update(buttonsPressedP1)
	else:
		var buttonsPressedP1 = _update_input_p1()
		var buttonsPressedP2 = _update_input_p2()
		_menu_p1.update(buttonsPressedP1)
		_menu_p2.update(buttonsPressedP2)	
	if _menu_p1.selection_performed() and _menu_p2.selection_performed():
		character1Path = mapOptions[_menu_p1.get_highlighted_option()]
		character2Path = mapOptions[_menu_p2.get_highlighted_option()]
		SceneManager.goto_scene_type(nextSceneType)
