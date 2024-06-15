class_name SceneGame extends Node2D

signal close_network_session

var character1Path : String
var character2Path : String
var player1DeviceId : int = 0
var player2DeviceId : int = 1

enum RoundPhaseState {
	Ready = 0,
	Engage = 1,
	ActiveMatch = 2,
	PreKo = 3,
	Ko = 4,
	VictoryPose = 5,
	PostMatchMenu = 6,
	PreRestartMatch = 7,
}

# additional scene parameters for startup - will be called in _ready
enum AdditionalGameSceneStartupParameter{
	Character1Path = 0,
	Character2Path = 1,
	StagePath = 2,
	Player1DeviceId = 3,
	Player2DeviceId = 4,
}
var additionalSceneStartupParameters : Dictionary = {}

@onready var inputManagerP1 : InputBufferManager = $InputManagerP1
@onready var inputManagerP2 : InputBufferManager = $InputManagerP2
@onready var collisionManager : CollisionManager = $CollisionManager
@onready var pauseMenu : GenericMenu = $SystemMessages/PauseMenu
@onready var stage : Stage = $Stage
@onready var camera : Camera2D = $Camera
var _cameraLogicalPosition : Vector2i
@onready var character1 : Character = $Characters/CharacterParent/Character1
@onready var character2 : Character = $Characters/CharacterParent/Character2
@onready var hitspark1 : HitSpark = $Characters/HitSparksParent/HitSpark1
@onready var hitspark2 : HitSpark = $Characters/HitSparksParent/HitSpark2
@onready var hudMain : HudManager = $Canvas/Hud
var _hitFreezeFrames : int = -1
var _lastFrameComboHitFreeze : bool = false
var _comboHitFreeze : bool = false
var _spikeHitFreeze : bool = false
var _wallHitFreeze : bool = false
var _roundPhaseCounter : int = -1
var _roundPhaseState : RoundPhaseState = RoundPhaseState.Ready
var _roundWonCharacter1 : int = 0
var _roundWonCharacter2 : int = 0
var _timerTicks : int = -1
var _closeSignalSent : bool = false
var _internalUpdateTick : int = 0
@onready var rematchMenuP1 : RematchMenu = $SystemMessages/System/RematchMenuP1
@onready var rematchMenuP2 : RematchMenu = $SystemMessages/System/RematchMenuP2

@export_category("Match Settings")
@export_range(0, 5, 1) var roundsToWin : int = 3
@export_range(0, 99, 1, "suffix:s") var timerSeconds : int = 45
@export var hasWallDamage : bool = true
@export_category("Settings")
@export var phaseTransitionMaxCounter = 120
@export var hitFreezeComboFrames = 10
@export var hitFreezeWallFrames = 8
@export var hitFreezeDownSpikeFrames = 25
@export_category("Alt. Colors")
@export var altColor1Shader : ShaderMaterial
@export_category("Debug")
@export var debugMode : bool = false
@export var hitFreezeOnWallCollisionBothPlayers : bool = false
@export var networkMode : bool = false
@export var preventDeath : bool = false
@export var startActivePhaseImmediately : bool = false

var _lastStateSaved = {}

enum HitDetectionFlags {
	HasHit = 0,
	TargetReaction = 1,
	DamageToApply = 2,
	MeterGain = 3,
	IntersectionBox = 4
}

enum GameStateVars {
	Character1State = 0,
	Character2State = 1,
	HitFreezeLastFrame = 2,
	HitFreezeCounter = 3,
	HitFreezeBool = 4,
	CameraLogicalPositionX = 5,
	CameraLogicalPositionY = 6,
	CameraScreenPositionX = 105,
	CameraScreenPositionY = 106,
	RoundPhaseState = 7,
	RoundPhaseFrameCounter = 8,
	TimerTicks = 9,
	RoundWonCharacter1 = 10,
	RoundWonCharacter2 = 11,
	HitFreezeWallBool = 12,
	WallSplatFreezeFrames = 13,
	WallSplatCharacterId = 14,
	HitFreezeSpikeBool = 15,
	SystemMessageManagerState = 900,
	InputManagerCharacter1 = 901,
	InputManagerCharacter2 = 902,
	PreventDeathFlag = 999,
	InternalUpdateTick = 9000,
	PostMatchMenu1State = 9001,
	PostMatchMenu2State = 9001,
	CloseSignalSent = 10000,
	Char1Projectile1 = 20000,
	Char1Projectile2 = 20001,
	Char1Projectile3 = 20002,
	Char1Projectile4 = 20003,
	Char2Projectile1 = 30000,
	Char2Projectile2 = 30001,
	Char2Projectile3 = 30002,
	Char2Projectile4 = 30003,
}

func _save_state() -> Dictionary:
	var stateDict = {}
	stateDict[GameStateVars.Character1State] = character1._save_state()#.duplicate()
	stateDict[GameStateVars.Character2State] = character2._save_state()#.duplicate()
	stateDict[GameStateVars.HitFreezeLastFrame] = _lastFrameComboHitFreeze
	stateDict[GameStateVars.HitFreezeCounter] = _hitFreezeFrames
	stateDict[GameStateVars.HitFreezeBool] = _comboHitFreeze
	stateDict[GameStateVars.HitFreezeWallBool] = _wallHitFreeze
	stateDict[GameStateVars.HitFreezeSpikeBool] = _spikeHitFreeze
	stateDict[GameStateVars.CameraLogicalPositionX] = _cameraLogicalPosition.x
	stateDict[GameStateVars.CameraLogicalPositionY] = _cameraLogicalPosition.y
	stateDict[GameStateVars.RoundPhaseState] = _roundPhaseState
	stateDict[GameStateVars.RoundPhaseFrameCounter] = _roundPhaseCounter
	stateDict[GameStateVars.RoundWonCharacter1] = _roundWonCharacter1
	stateDict[GameStateVars.RoundWonCharacter2] = _roundWonCharacter2
	stateDict[GameStateVars.TimerTicks] = _timerTicks
	stateDict[GameStateVars.PreventDeathFlag] = preventDeath
	stateDict[GameStateVars.CloseSignalSent] = _closeSignalSent
	stateDict[GameStateVars.InternalUpdateTick] = _internalUpdateTick
	if !networkMode:
		stateDict[GameStateVars.SystemMessageManagerState] = hudMain.systemMessageManager._save_state().duplicate()
		stateDict[GameStateVars.InputManagerCharacter1] = inputManagerP1._save_state().duplicate()
		stateDict[GameStateVars.InputManagerCharacter2] = inputManagerP2._save_state().duplicate()
		stateDict[GameStateVars.PostMatchMenu1State] = rematchMenuP1._save_state()
		stateDict[GameStateVars.PostMatchMenu2State] = rematchMenuP2._save_state()
		if character1.projectiles.size() > 3:
			stateDict[GameStateVars.Char1Projectile4] = character1.projectiles[3]._save_state()
		if character1.projectiles.size() > 2:
			stateDict[GameStateVars.Char1Projectile3] = character1.projectiles[2]._save_state()
		if character1.projectiles.size() > 1:
			stateDict[GameStateVars.Char1Projectile2] = character1.projectiles[1]._save_state()
		if character1.projectiles.size() > 0:
			stateDict[GameStateVars.Char1Projectile1] = character1.projectiles[0]._save_state()
		if character2.projectiles.size() > 3:
			stateDict[GameStateVars.Char2Projectile4] = character2.projectiles[3]._save_state()
		if character2.projectiles.size() > 2:
			stateDict[GameStateVars.Char2Projectile3] = character2.projectiles[2]._save_state()
		if character2.projectiles.size() > 1:
			stateDict[GameStateVars.Char2Projectile2] = character2.projectiles[1]._save_state()
		if character2.projectiles.size() > 0:
			stateDict[GameStateVars.Char2Projectile1] = character2.projectiles[0]._save_state()
	return stateDict
	
func _load_state(state : Dictionary) -> void:
	character1._load_state(state[GameStateVars.Character1State])
	character2._load_state(state[GameStateVars.Character2State])
	_comboHitFreeze = state[GameStateVars.HitFreezeBool]
	_wallHitFreeze = state[GameStateVars.HitFreezeWallBool]
	_spikeHitFreeze = state[GameStateVars.HitFreezeSpikeBool]
	_hitFreezeFrames = state[GameStateVars.HitFreezeCounter]
	_lastFrameComboHitFreeze = state[GameStateVars.HitFreezeLastFrame]
	_cameraLogicalPosition.x = state[GameStateVars.CameraLogicalPositionX]
	_cameraLogicalPosition.y = state[GameStateVars.CameraLogicalPositionY]
	_roundPhaseState = state[GameStateVars.RoundPhaseState]
	_roundPhaseCounter = state[GameStateVars.RoundPhaseFrameCounter]
	_roundWonCharacter1 = state[GameStateVars.RoundWonCharacter1]
	_roundWonCharacter2 = state[GameStateVars.RoundWonCharacter2]
	_timerTicks = state[GameStateVars.TimerTicks]
	preventDeath = state[GameStateVars.PreventDeathFlag]
	_closeSignalSent = state[GameStateVars.CloseSignalSent]
	_internalUpdateTick = state[GameStateVars.InternalUpdateTick]
	camera.position = _cameraLogicalPosition / GameDatabaseAccessor.screenCoordMultiplier
	camera.reset_smoothing()
	if !networkMode:
		hudMain.systemMessageManager._load_state(state[GameStateVars.SystemMessageManagerState])
		inputManagerP1._load_state(state[GameStateVars.InputManagerCharacter1])
		inputManagerP2._load_state(state[GameStateVars.InputManagerCharacter2])
		rematchMenuP1._load_state(state[GameStateVars.PostMatchMenu1State])
		rematchMenuP2._load_state(state[GameStateVars.PostMatchMenu2State])
		if character1.projectiles.size() > 3:
			character1.projectiles[3]._load_state(state[GameStateVars.Char1Projectile4])
		if character1.projectiles.size() > 2:
			character1.projectiles[2]._load_state(state[GameStateVars.Char1Projectile3])
		if character1.projectiles.size() > 1:
			character1.projectiles[1]._load_state(state[GameStateVars.Char1Projectile2])
		if character1.projectiles.size() > 0:
			character1.projectiles[0]._load_state(state[GameStateVars.Char1Projectile1])
		if character2.projectiles.size() > 3:
			character2.projectiles[3]._load_state(state[GameStateVars.Char2Projectile4])
		if character2.projectiles.size() > 2:
			character2.projectiles[2]._load_state(state[GameStateVars.Char2Projectile3])
		if character2.projectiles.size() > 1:
			character2.projectiles[1]._load_state(state[GameStateVars.Char2Projectile2])
		if character2.projectiles.size() > 0:
			character2.projectiles[0]._load_state(state[GameStateVars.Char2Projectile1])
		hitspark1.deactivate_hitspark()
		hitspark2.deactivate_hitspark()
	hudMain.update(character1, character2, _internalUpdateTick, false)
	hudMain.update_round_won(_roundWonCharacter1, _roundWonCharacter2)

# Called when the node enters the scene tree for the first time.
func _ready():
	#character2/Sprite2D.flip_h = true
	if additionalSceneStartupParameters.has(AdditionalGameSceneStartupParameter.Character1Path):
		character1Path = additionalSceneStartupParameters[AdditionalGameSceneStartupParameter.Character1Path]
		var success = character1.initialize_from_directory(character1Path)
		print("character %s loaded with status %s" % [character1Path, success])
	if additionalSceneStartupParameters.has(AdditionalGameSceneStartupParameter.Character2Path):
		character2Path = additionalSceneStartupParameters[AdditionalGameSceneStartupParameter.Character2Path]
		var success = character2.initialize_from_directory(character2Path)
		print("character %s loaded with status %s" % [character2Path, success])
		if altColor1Shader:
			character2.get_sprite().material = altColor1Shader
	if additionalSceneStartupParameters.has(AdditionalGameSceneStartupParameter.Player1DeviceId):
		player1DeviceId = additionalSceneStartupParameters[AdditionalGameSceneStartupParameter.Player1DeviceId]
	if additionalSceneStartupParameters.has(AdditionalGameSceneStartupParameter.Player2DeviceId):
		player2DeviceId = additionalSceneStartupParameters[AdditionalGameSceneStartupParameter.Player2DeviceId]
	inputManagerP1.deviceId = player1DeviceId
	inputManagerP2.deviceId = player2DeviceId
	#if networkMode:
		#camera.position_smoothing_enabled = false
	hitspark1.networkMode = networkMode
	hitspark2.networkMode = networkMode
	if networkMode:
		$Canvas/Player1Name.text = NetworkAssistant.player1Name
		$Canvas/Player2Name.text = NetworkAssistant.player2Name
		$Canvas/Player1Name.visible = true
		$Canvas/Player2Name.visible = true
	_reset_round()
	_init_hud()
	_lastStateSaved = _save_state()
	hudMain.trainingMessage.visible = preventDeath
	hudMain.hide_unused_round_counters(roundsToWin)
	add_to_group('network_sync')

func _is_paused() -> bool:
	return (pauseMenu and pauseMenu.visible)

func _can_pause_game() -> bool:
	if networkMode:
		return false
	if _roundPhaseState != RoundPhaseState.ActiveMatch:
		return false
	return true

func _check_for_game_pause():
	if !_can_pause_game():
		return
	if (InputOverseer.input_is_action_just_pressed_all_devices("pause") or
		InputOverseer.input_is_action_just_pressed_kb("pause_p1") or
		InputOverseer.input_is_action_just_pressed_kb("pause_p2")):
			if _is_paused():
				pauseMenu.reset_and_hide()
			else:
				pauseMenu.reset_and_hide()
				pauseMenu.visible = true

func _update_input_for_pause_menu() -> int:
	var allButtonsPressed = 0
	if (InputOverseer.input_is_action_just_pressed_all_devices("confirm") or 
		InputOverseer.input_is_action_just_pressed_kb("confirm_p1") or
		InputOverseer.input_is_action_just_pressed_kb("confirm_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Confirm
	if (InputOverseer.input_is_action_pressed_all_devices("move_u") or 
		InputOverseer.input_is_action_pressed_kb("move_u_p1") or
		InputOverseer.input_is_action_pressed_kb("move_u_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Up
	if (InputOverseer.input_is_action_pressed_all_devices("move_d") or 
		InputOverseer.input_is_action_pressed_kb("move_d_p1") or
		InputOverseer.input_is_action_pressed_kb("move_d_p2")):
			allButtonsPressed = allButtonsPressed | GameDatabaseAccessor.GameInputButton.Down
	return allButtonsPressed

func _update_pause_menu():
	var buttonsPressed = _update_input_for_pause_menu()
	pauseMenu.update(buttonsPressed)
	if pauseMenu.selection_performed():
		if pauseMenu.get_highlighted_option() == 0:
			pauseMenu.reset_and_hide()
		else:
			SceneManager.goto_scene_type(SceneManager.SceneType.ModeSelection)
	
func _reset_round(resetCharacterMeter : bool = false):
	hudMain.hide_message()
	rematchMenuP1.reset_and_hide()
	rematchMenuP2.reset_and_hide()
	stage.update_stage_position()
	var stagePos = stage.position * GameDatabaseAccessor.screenCoordMultiplierInt
	var charOffset = stage.characterOffset * GameDatabaseAccessor.screenCoordMultiplierInt
	character1.initialLogicalPosition = Vector2(stagePos.x - charOffset.x, charOffset.y)
	character2.initialLogicalPosition = Vector2(stagePos.x + charOffset.x, charOffset.y)
	character1.reset_character(resetCharacterMeter)
	character2.reset_character(resetCharacterMeter)
	if timerSeconds > 0:
		_timerTicks = timerSeconds * GameDatabaseAccessor.frameRateFps
	if startActivePhaseImmediately:
		_roundPhaseState = RoundPhaseState.ActiveMatch
	else:
		_roundPhaseState = RoundPhaseState.Ready
	_update_camera(true)

func _update_system_input():
	if InputOverseer.input_is_action_just_pressed_kb("fullscreen_toggle"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			print("windowed")
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			print("fullscreen")
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if debugMode and !networkMode:
		if InputOverseer.input_is_action_just_pressed_kb("toggle_boxes_debug"):
				GameDatabaseAccessor.showBoxes = !GameDatabaseAccessor.showBoxes
		elif InputOverseer.input_is_action_just_pressed_kb("refill_resources_debug"):
				if character1.is_ko() or character1.characterState.moveId == Character.ReservedMoveIndex.Victory:
					character1.reset_character_to_idle_full_health()
				if character2.is_ko() or character2.characterState.moveId == Character.ReservedMoveIndex.Victory:
					character2.reset_character_to_idle_full_health()
				character1.characterState.currentHealth = character1.characterData.characterMaxHealth
				character2.characterState.currentHealth = character2.characterData.characterMaxHealth
				character1.characterState.currentMeter = character1.characterData.characterMaxMeter
				character2.characterState.currentMeter = character2.characterData.characterMaxMeter
				character1.characterState.meterBroken = false
				#character1.infinityInstallActive = false
				#character1.zeroInstallActive = false
				character1.disable_all_installs()
				character2.characterState.meterBroken = false
				#character2.infinityInstallActive = false
				#character2.zeroInstallActive = false
				character2.disable_all_installs()
				_roundPhaseState = RoundPhaseState.ActiveMatch
				_roundPhaseCounter = -1
				rematchMenuP1.reset_and_hide()
				rematchMenuP2.reset_and_hide()
				hudMain.hide_message(true)
		elif InputOverseer.input_is_action_just_pressed_kb("save_state_debug"):
			_lastStateSaved = _save_state()
		elif InputOverseer.input_is_action_just_pressed_kb("load_state_debug"):
			if !_lastStateSaved.is_empty():
				_load_state(_lastStateSaved)
		#elif InputOverseer.input_is_action_just_pressed_kb("toggle_training_mode"):
			#if preventDeath:
				#preventDeath = false
				#hudMain.trainingMessage.visible = false
			#else:
				#preventDeath = true
				#hudMain.trainingMessage.visible = true
				#if character1.is_ko() or character1.characterState.moveId == Character.ReservedMoveIndex.Victory:
					#character1.reset_character_to_idle_full_health()
				#if character2.is_ko() or character2.characterState.moveId == Character.ReservedMoveIndex.Victory:
					#character2.reset_character_to_idle_full_health()
				#character1.characterState.currentHealth = character1.characterData.characterMaxHealth
				#character2.characterState.currentHealth = character2.characterData.characterMaxHealth
				#_roundPhaseState = RoundPhaseState.ActiveMatch
				#_roundPhaseCounter = -1
				#rematchMenuP1.reset_and_hide()
				#rematchMenuP2.reset_and_hide()
				#hudMain.hide_message(true)

func _establish_round_winner():
	if character1.is_ko():
		_roundWonCharacter2 += 1
	if character2.is_ko():
		_roundWonCharacter1 += 1
		
func _restart_match():
	_roundWonCharacter1 = 0
	_roundWonCharacter2 = 0
	hudMain.update_round_won(_roundWonCharacter1, _roundWonCharacter2)
	_reset_round(true)

func _update_post_match_menu():
	if _roundPhaseState != RoundPhaseState.PostMatchMenu:
		return
	if rematchMenuP1.visible:
		rematchMenuP1.update(inputManagerP1.get_all_pressed_buttons(), _internalUpdateTick)
	if rematchMenuP2.visible:
		rematchMenuP2.update(inputManagerP2.get_all_pressed_buttons(), _internalUpdateTick)

func _update_game_phase_transition():
	@warning_ignore("integer_division")
	var phaseTransitionMessageThreshold = phaseTransitionMaxCounter / 4
	if  _roundPhaseState == RoundPhaseState.Ready and _roundPhaseCounter < 0:
		_roundPhaseCounter = phaseTransitionMaxCounter
		if (roundsToWin > 0 and (_roundWonCharacter1 >= roundsToWin - 1 or
		_roundWonCharacter2 >= roundsToWin - 1)):
			hudMain.show_message(HudManager.SystemMessage.Matchpoint)
		else:
			hudMain.show_message(HudManager.SystemMessage.Ready)
	elif _roundPhaseState == RoundPhaseState.Ready and _roundPhaseCounter > 0:
		_roundPhaseCounter -= 1
		if _roundPhaseCounter == phaseTransitionMessageThreshold:
			hudMain.hide_message()
		if _roundPhaseCounter == 0:
			_roundPhaseState = RoundPhaseState.Engage
			_roundPhaseCounter = -1
	elif _roundPhaseState == RoundPhaseState.Engage and _roundPhaseCounter < 0:
		_roundPhaseCounter = phaseTransitionMaxCounter
		hudMain.show_message(HudManager.SystemMessage.Engage)
	elif _roundPhaseState == RoundPhaseState.Engage and _roundPhaseCounter > 0:
		_roundPhaseCounter -= 1
		if _roundPhaseCounter == phaseTransitionMessageThreshold:
			hudMain.hide_message()
			_roundPhaseCounter = -1
			_roundPhaseState = RoundPhaseState.ActiveMatch
	elif _roundPhaseState == RoundPhaseState.ActiveMatch:
		if ((character1.is_ko() and character1.is_airborne()) or 
		(character2.is_ko() and character2.is_airborne())):
			_roundPhaseCounter = -1
			_roundPhaseState = RoundPhaseState.PreKo
		elif ((character1.is_ko() and !character1.is_airborne()) or 
		(character2.is_ko() and !character2.is_airborne())) and _roundPhaseCounter < 0:
			_roundPhaseCounter = phaseTransitionMaxCounter
			hudMain.show_message(HudManager.SystemMessage.Ko)
			_roundPhaseState = RoundPhaseState.Ko
	elif _roundPhaseState == RoundPhaseState.PreKo:
		if ((character1.is_ko() and !character1.is_airborne()) or 
		(character2.is_ko() and !character2.is_airborne())) and _roundPhaseCounter < 0:
			_roundPhaseCounter = phaseTransitionMaxCounter
			hudMain.show_message(HudManager.SystemMessage.Ko)
			_roundPhaseState = RoundPhaseState.Ko
	elif _roundPhaseState == RoundPhaseState.Ko:
		if _roundPhaseCounter > 0:
			_roundPhaseCounter -= 1
			if _roundPhaseCounter == phaseTransitionMaxCounter - 10:
				_establish_round_winner()
				hudMain.update_round_won(_roundWonCharacter1, _roundWonCharacter2)
			if _roundPhaseCounter == phaseTransitionMessageThreshold:
				hudMain.hide_message()
			if _roundPhaseCounter == 0:
				_roundPhaseCounter = -1
				if (_roundWonCharacter1 >= roundsToWin or
					_roundWonCharacter2 >= roundsToWin) and (
						_roundWonCharacter1 != _roundWonCharacter2):
					if (_roundWonCharacter1 > _roundWonCharacter2):
						hudMain.show_message(HudManager.SystemMessage.P1Win)
					else:
						hudMain.show_message(HudManager.SystemMessage.P2Win)
					_roundPhaseState = RoundPhaseState.PostMatchMenu
					_roundPhaseCounter = phaseTransitionMaxCounter
				else:
					_reset_round()
	elif _roundPhaseState == RoundPhaseState.PostMatchMenu:
		if _roundPhaseCounter > 0:
			_roundPhaseCounter -= 1
			if _roundPhaseCounter == 0:
				rematchMenuP1.visible = true
				rematchMenuP2.visible = true
		if rematchMenuP1.selection_performed() and rematchMenuP2.selection_performed():
			if (rematchMenuP1.get_highlighted_option() == RematchMenu.Option.No or
				rematchMenuP2.get_highlighted_option() == RematchMenu.Option.No):
					#change scene
					if networkMode:		
						if !_closeSignalSent:					
							emit_signal("close_network_session")
							_closeSignalSent = true
					else:
						SceneManager.goto_scene_type(SceneManager.SceneType.ModeSelection)
			else:
				rematchMenuP1.reset_and_hide()
				rematchMenuP2.reset_and_hide()
				hudMain.hide_message()
				_roundPhaseState = RoundPhaseState.PreRestartMatch
				_roundPhaseCounter = phaseTransitionMessageThreshold
		elif rematchMenuP1.selection_performed() or rematchMenuP2.selection_performed():
			if ((rematchMenuP1.selection_performed() and rematchMenuP1.get_highlighted_option() == RematchMenu.Option.No) or
				(rematchMenuP2.selection_performed() and rematchMenuP2.get_highlighted_option() == RematchMenu.Option.No)):
					#change scene on NO
					if networkMode:		
						if !_closeSignalSent:					
							emit_signal("close_network_session")
							_closeSignalSent = true
					else:
						SceneManager.goto_scene_type(SceneManager.SceneType.ModeSelection)
	elif _roundPhaseState == RoundPhaseState.PreRestartMatch:
		if _roundPhaseCounter > 0:
			_roundPhaseCounter -= 1
			if _roundPhaseCounter == 0:
				_roundPhaseCounter = -1
				_restart_match()
	character1.characterState.roundState = _roundPhaseState
	character2.characterState.roundState = _roundPhaseState
	if !character1.is_ko() and _roundPhaseState >= RoundPhaseState.Ko:
		character1.update_victory_pose()
	if !character2.is_ko() and _roundPhaseState >= RoundPhaseState.Ko:
		character2.update_victory_pose()

func _update_character_input():
	#if (_roundPhaseState == RoundPhaseState.ActiveMatch or 
		#_roundPhaseState == RoundPhaseState.Ko):
	inputManagerP1.update_buffer()
	inputManagerP2.update_buffer()

func _adjust_character_sfx():
	var visibleInstallBg : bool = false
	if (character1.currentMove and character1.currentMove.timestopFrames > 0):
		visibleInstallBg = true
	elif (character2.currentMove and character2.currentMove.timestopFrames > 0):
		visibleInstallBg = true
	$Characters/InstallBackground.visible = visibleInstallBg
	$Characters/InstallBackground.position = camera.position

func _update_projectiles():
	character1.update_projectiles(inputManagerP1)
	character2.update_projectiles(inputManagerP2)

func _update_character_state():
	# this is a measure to improve move detection during hit freeze
	var extraInputLeniency = 0
	if !_comboHitFreeze and _lastFrameComboHitFreeze:
		extraInputLeniency = hitFreezeComboFrames
	var character1previousMove = character1.currentMove
	var character2previousMove = character2.currentMove
	if character1.can_be_updated():
		character1.update(inputManagerP1, extraInputLeniency)
	if character2.can_be_updated():
		character2.update(inputManagerP2, extraInputLeniency)
	
	# TIMESTOP! ZA WARUDO!
	if ((!character1previousMove and character1.currentMove) or 
		(character1previousMove and character1.currentMove and
		character1previousMove.internalName != character1.currentMove.internalName)):
		if character1.currentMove.timestopFrames > 0:
			_hitFreezeFrames = character1.currentMove.timestopFrames 
			character2.characterState.affectedByHitFreeze = true
			
	if ((!character2previousMove and character2.currentMove) or 
		(character2previousMove and character2.currentMove and
		character2previousMove.internalName != character2.currentMove.internalName)):
		if character2.currentMove.timestopFrames > 0:
			_hitFreezeFrames = character2.currentMove.timestopFrames 
			character1.characterState.affectedByHitFreeze = true
	
	character1.immortal = preventDeath
	character2.immortal = preventDeath
	if character1.can_be_updated():
		if character1.can_turn_around():
			if character1.characterState.logicalPosition.x <= character2.characterState.logicalPosition.x:
				#if !character1.characterState.onLeftSide:
					#character1.characterState.logicalVelocity.x = -character1.characterState.logicalVelocity.x
				character1.set_on_left_side(true) 
				character1.scale = Vector2(1, 1)
			else:
				#if character1.characterState.onLeftSide:
					#character1.characterState.logicalVelocity.x = -character1.characterState.logicalVelocity.x
				character1.set_on_left_side(false) 
				character1.scale = Vector2(-1, 1)
	if character2.can_be_updated():
		if character2.can_turn_around():
			if character2.characterState.logicalPosition.x < character1.characterState.logicalPosition.x:
				#if !character2.characterState.onLeftSide:
					#character2.characterState.logicalVelocity.x = -character2.characterState.logicalVelocity.x
				character2.set_on_left_side(true) 
				character2.scale = Vector2(1, 1)
			else:
				#if character2.characterState.onLeftSide:
					#character2.characterState.logicalVelocity.x = -character2.characterState.logicalVelocity.x
				character2.set_on_left_side(false) 
				character2.scale = Vector2(-1, 1)
	for projectile in character1.projectiles:
		if projectile.can_be_updated():
			if projectile.is_on_left_side():
				projectile.scale = Vector2(1, 1)
			else:
				projectile.scale = Vector2(-1, 1)
	for projectile in character2.projectiles:
		if projectile.can_be_updated():
			if projectile.is_on_left_side():
				projectile.scale = Vector2(1, 1)
			else:
				projectile.scale = Vector2(-1, 1)

func _apply_wall_damage(character : Character, opponent : Character):
	if !hasWallDamage:
		return
	#print("Wall speed %d!" % character.get_logical_velocity().x)
	@warning_ignore("integer_division")
	var damage : int = max(1, abs(character.get_logical_velocity().x / 20))
	if opponent.infinityInstallActive:
		@warning_ignore("integer_division")
		damage = max(1, abs(character.get_logical_velocity().x / 500))
		#print(damage)
	character.deal_damage(damage)
	opponent.characterState.comboCounter += 1
	opponent.characterState.comboDamage += damage
	
func _apply_wallsplat_damage(character : Character, opponent : Character):
	#print("Wall speed %d!" % character.get_logical_velocity().x)
	@warning_ignore("integer_division")
	var damage : int = max(1, abs(character.get_logical_velocity().x / 10))
	@warning_ignore("integer_division")
	damage = min(character.characterData.characterMaxHealth / 4, damage)
	character.deal_damage(damage)
	opponent.characterState.comboCounter += 1
	opponent.characterState.comboDamage += damage
	
func _adjust_character_momentum(character : Character, opponent : Character):
	if !character.can_be_updated():
		return
	if !character.currentMove:
		return
	if !character.currentMove.isHitStunState or character.currentMove.characterState != Character.State.Air:
		return
	if !character.is_airborne():
		return
	if opponent.zeroInstallActive:
		return
	var leftWallDistance : int = collisionManager.distance_from_left_corner(character, stage)
	var rightWallDistance : int = collisionManager.distance_from_right_corner(character, stage)
	@warning_ignore("integer_division")
	var boxHalfSize : int = character.get_collision_box().size.x / 2
	@warning_ignore("integer_division")
	var stageHalfSize : int = stage.logicalSize.x / 2
	var horizontalMomentumMultiplier : int = 150
	if opponent.infinityInstallActive:
		horizontalMomentumMultiplier = 180
	if !_wallHitFreeze:
		if ((leftWallDistance <= boxHalfSize and 
				character.get_logical_velocity().x < 0) or 
			(rightWallDistance <= boxHalfSize and 
				character.get_logical_velocity().x > 0)):
				if (character.is_ko() or (
					!opponent.infinityInstallActive and 
				character.characterState.bounceCounter >= 
				GameDatabaseAccessor.defaultMaxNumberOfBounces)):
					if (leftWallDistance <= boxHalfSize and 
					character.get_logical_velocity().x < 0):
						character.characterState.logicalPosition.x = (
							stage.logicalPosition.x - stageHalfSize +
							boxHalfSize)
					else:
						character.characterState.logicalPosition.x = (
							stage.logicalPosition.x + stageHalfSize -
							boxHalfSize)
					character.update_screen_position()
					if (character.currentMove.internalName != GameDatabaseAccessor.defaultWallsplatReaction and
						!character.is_ko()):
						_apply_wallsplat_damage(character, opponent)
						_hitFreezeFrames = hitFreezeWallFrames
						character.characterState.affectedByHitFreeze = true
					if character.is_ko():
						if (character.currentMove.internalName != GameDatabaseAccessor.defaultWallsplatReaction  + "_ko"):
							_hitFreezeFrames = hitFreezeWallFrames
							character.characterState.affectedByHitFreeze = true
							character.apply_move_by_name(
								GameDatabaseAccessor.defaultWallsplatReaction + "_ko"
							)
							#character.tick_animation_forward()
							#_constrain_character_position_to_camera_viewport(character)
					else:
						if (character.currentMove.internalName != GameDatabaseAccessor.defaultWallsplatReaction):
							character.apply_move_by_name(
								GameDatabaseAccessor.defaultWallsplatReaction
							)
							#character.tick_animation_forward()
							#_constrain_character_position_to_camera_viewport(character)
					_wallHitFreeze = true
					_comboHitFreeze = false
				else:
					character.multiply_horizontal_movement(-horizontalMomentumMultiplier, false)
					character.multiply_vertical_movement(125)
					character.characterState.bounceCounter += 1
					#print("BOUNCE %d" % character.characterState.bounceCounter)
					_apply_wall_damage(character, opponent)
					_hitFreezeFrames = hitFreezeWallFrames
					character.characterState.affectedByHitFreeze = true
					_wallHitFreeze = true
					_comboHitFreeze = false
		
func _constrain_character_position_to_camera_viewport(character : Character):
	if !camera.is_inside_tree():
		return
	var collBox = character.get_collision_box()
	@warning_ignore("integer_division")
	var boxHalfSize : int = collBox.size.x / 2
	var leftBoundary = collBox.position.x - boxHalfSize
	var rightBoundary = collBox.position.x + boxHalfSize
	var cameraViewport = GameDatabaseAccessor.cameraViewportSize.size * GameDatabaseAccessor.screenCoordMultiplierInt
	var leftCameraBoundary = _cameraLogicalPosition.x - cameraViewport.x / 2
	var rightCameraBoundary = _cameraLogicalPosition.x + cameraViewport.x / 2
	var currentCharacterLogicalPosition = character.get_logical_position()
	if leftBoundary < leftCameraBoundary:
		currentCharacterLogicalPosition.x += abs(leftBoundary - leftCameraBoundary)
	elif rightBoundary > rightCameraBoundary:
		currentCharacterLogicalPosition.x -= abs(rightBoundary - rightCameraBoundary)
	@warning_ignore("integer_division")
	var stageHalfSize : int = stage.logicalSize.x / 2
	var minX = stage.logicalPosition.x - stageHalfSize + boxHalfSize 
	var maxX = stage.logicalPosition.x + stageHalfSize - boxHalfSize 
	currentCharacterLogicalPosition.x = max(minX,
		min(currentCharacterLogicalPosition.x, maxX))
	character.set_new_logical_position(currentCharacterLogicalPosition)
			
func _update_camera(immediate : bool = false):
	if immediate:
		camera.reset_smoothing()
	elif !networkMode:
		camera.position_smoothing_enabled = true
	if !camera.is_inside_tree():
		return
	# check code here
	@warning_ignore("integer_division")
	var cameraTargetPosition = (character1.get_logical_position() + character2.get_logical_position()) / 2
	var cameraViewportSize = GameDatabaseAccessor.cameraViewportSize.size * GameDatabaseAccessor.screenCoordMultiplierInt #get_viewport_rect().size
	var cameraX = cameraTargetPosition.x
	var cameraY = cameraTargetPosition.y
	var cameraYBottom = cameraTargetPosition.y + cameraViewportSize.y / 2
	var cameraYTop = cameraTargetPosition.y - cameraViewportSize.y / 2
	var cameraXLeft = cameraTargetPosition.x - cameraViewportSize.x / 2
	var cameraXRight = cameraTargetPosition.x + cameraViewportSize.x / 2
	if cameraXLeft < stage.logicalPosition.x - stage.logicalSize.x / 2.:
		cameraX += abs(cameraXLeft - (stage.logicalPosition.x - stage.logicalSize.x / 2.))
	elif cameraXRight > stage.logicalPosition.x + stage.logicalSize.x / 2.:
		cameraX -= abs(cameraXRight - (stage.logicalPosition.x + stage.logicalSize.x / 2.))
	if cameraYTop < stage.logicalPosition.y - stage.logicalSize.y / 2.:
		cameraY += abs(cameraYTop - (stage.logicalPosition.y - stage.logicalSize.y / 2.))
	elif cameraYBottom > stage.logicalPosition.y + stage.logicalSize.y / 2.:
		cameraY -= abs(cameraYBottom - (stage.logicalPosition.y + stage.logicalSize.y / 2.))
	cameraTargetPosition.y = cameraY
	cameraTargetPosition.x = cameraX
	camera.position = cameraTargetPosition / GameDatabaseAccessor.screenCoordMultiplier
	_cameraLogicalPosition = cameraTargetPosition

func _process_damage_collisions(attacker : Character, defender : Character) -> Dictionary:
	var result : Dictionary = {}
	result[HitDetectionFlags.HasHit] = false
	result[HitDetectionFlags.TargetReaction] = GameDatabaseAccessor.defaultGroundHitReaction
	result[HitDetectionFlags.DamageToApply] = 0
	result[HitDetectionFlags.MeterGain] = 0
	result[HitDetectionFlags.IntersectionBox] = Rect2i(0,0,0,0)
	for hitBox in attacker.hitBoxes:
		if hitBox.active:
			for hurtBox in defender.hurtBoxes:
				if hurtBox.active:
					if (attacker.get_box_top_left(hitBox).
							intersects(defender.get_box_top_left(hurtBox))):
						result[HitDetectionFlags.HasHit] = true
						result[HitDetectionFlags.IntersectionBox] = (
							attacker.get_box_top_left(hitBox).
							intersection(defender.get_box_top_left(hurtBox)))
						var rawDamage = hitBox.damage
						result[HitDetectionFlags.DamageToApply] = attacker.adjust_move_damage(rawDamage)
						if defender.is_airborne() or (
							defender.characterState.currentHealth < rawDamage and 
							!defender.immortal):
							result[HitDetectionFlags.TargetReaction] = hitBox.moveReactionOnHitAir
						else:
							result[HitDetectionFlags.TargetReaction] = hitBox.moveReactionOnHitGround
						result[HitDetectionFlags.MeterGain] = hitBox.meterGain
						if hitBox.deactivateOnHit:
							hitBox.active = false
						break
	return result

func _update_projectile_hit_detection() -> bool:
	# manage damage and hit reactions
	var oneProjectileHasHit : bool = false
	var canGainMeterFromMoveP1 : bool = true 
	var canGainMeterFromMoveP2 : bool = true 
	var p1AttackResult = {}
	var p2AttackResult = {}
	var projectileP1Hit : CharacterProjectile
	var projectileP2Hit : CharacterProjectile
	#check for intra-projectile collisions
	for projectile in character1.projectiles:
		if projectile.isActive():
			for projectileOpp in character2.projectiles:
				if projectileOpp.isActive():
					p1AttackResult = _process_damage_collisions(projectile, projectileOpp)
					if p1AttackResult[HitDetectionFlags.HasHit]:
						projectileP1Hit = projectile
						oneProjectileHasHit = true
						var boxCenter = (p1AttackResult[HitDetectionFlags.IntersectionBox] as Rect2i).get_center()
						hitspark1.activate_hitspark(boxCenter)
						if projectile.deactivateOnHit:
							projectile.deactivate()
						if projectileOpp.deactivateOnHit:
							projectileOpp.deactivate()
	p1AttackResult = {}
	for projectile in character1.projectiles:
		if projectile.isActive():
			p1AttackResult = _process_damage_collisions(projectile, character2)
			if p1AttackResult[HitDetectionFlags.HasHit]:
				projectileP1Hit = projectile
				canGainMeterFromMoveP1 = projectile.meterGainAllowed
				oneProjectileHasHit = true
				if projectile.deactivateOnHit:
					projectile.deactivate()
				break
	for projectile in character2.projectiles:
		if projectile.isActive():
			p2AttackResult = _process_damage_collisions(projectile, character1)
			if p2AttackResult[HitDetectionFlags.HasHit]:
				projectileP2Hit = projectile
				oneProjectileHasHit = true
				canGainMeterFromMoveP2 = projectile.meterGainAllowed
				if projectile.deactivateOnHit:
					projectile.deactivate()
				break
	if !p1AttackResult.is_empty():
		_apply_hit_detection_reaction(p1AttackResult, projectileP1Hit, character1, character2)
	if !p2AttackResult.is_empty():
		_apply_hit_detection_reaction(p2AttackResult, projectileP2Hit, character2, character1)
	if !p1AttackResult.is_empty() and p1AttackResult[HitDetectionFlags.HasHit]:
		@warning_ignore("integer_division")
		var meterGainHitCharacter = (
			p1AttackResult[HitDetectionFlags.MeterGain] / 
			GameDatabaseAccessor.hitCharacterMeterGainFraction)
		if canGainMeterFromMoveP1:
			character1.gain_meter(p1AttackResult[HitDetectionFlags.MeterGain])
		character2.gain_meter(meterGainHitCharacter)
		character2.deal_damage(p1AttackResult[HitDetectionFlags.DamageToApply])
		character2.characterState.comboCounter = 0
		character2.characterState.comboDamage = 0
		var _success = character2.apply_move_by_name(p1AttackResult[HitDetectionFlags.TargetReaction])
	if !p2AttackResult.is_empty() and p2AttackResult[HitDetectionFlags.HasHit]:
		@warning_ignore("integer_division")
		var meterGainHitCharacter = (
			p2AttackResult[HitDetectionFlags.MeterGain] / 
			GameDatabaseAccessor.hitCharacterMeterGainFraction)
		if canGainMeterFromMoveP2:
			character2.gain_meter(p2AttackResult[HitDetectionFlags.MeterGain])
		character1.gain_meter(meterGainHitCharacter)
		character1.deal_damage(p2AttackResult[HitDetectionFlags.DamageToApply])
		character1.characterState.comboCounter = 0
		character1.characterState.comboDamage = 0
		var _success = character1.apply_move_by_name(p2AttackResult[HitDetectionFlags.TargetReaction])
	return oneProjectileHasHit

func _apply_hit_detection_reaction(
	attackResult : Dictionary, 
	attacker : Character,
	attackOwner : Character,
	defender : Character):
	if attackResult[HitDetectionFlags.HasHit]:
		attacker.mark_successful_hit()
		if attackResult[HitDetectionFlags.TargetReaction] == GameDatabaseAccessor.defaultDownSpikeReaction:
			_hitFreezeFrames = hitFreezeDownSpikeFrames
			_spikeHitFreeze = true
		else:
			_hitFreezeFrames = hitFreezeComboFrames
		attacker.characterState.affectedByHitFreeze = true
		defender.characterState.affectedByHitFreeze = true
		_comboHitFreeze = true
		_wallHitFreeze = false
		var boxCenter = (attackResult[HitDetectionFlags.IntersectionBox] as Rect2i).get_center()
		hitspark1.activate_hitspark(boxCenter)
		if defender.currentMove and defender.currentMove.isHitStunState:
			attackOwner.characterState.comboCounter += 1
			attackOwner.characterState.comboDamage += attackResult[HitDetectionFlags.DamageToApply]
		else:
			attackOwner.characterState.comboCounter = 0
			attackOwner.characterState.comboDamage = 0

func _update_hit_detection():
	if !character1.currentMove or !character1.currentMove.isHitStunState:
		character2.characterState.comboCounter = 0
		character2.characterState.comboDamage = 0
	if !character2.currentMove or !character2.currentMove.isHitStunState:
		character1.characterState.comboCounter = 0
		character1.characterState.comboDamage = 0
	var p1AttackResult = _process_damage_collisions(character1, character2)
	var p2AttackResult = _process_damage_collisions(character2, character1)
	var canGainMeterFromMoveP1 : bool = true 
	var canGainMeterFromMoveP2 : bool = true 
	if (character1.currentMove and !character1.currentMove.canGainMeter):
		canGainMeterFromMoveP1 = false
	if (character2.currentMove and !character2.currentMove.canGainMeter):
		canGainMeterFromMoveP2 = false
	# manage damage and hit reactions
	_apply_hit_detection_reaction(p1AttackResult, character1, character1, character2)
	_apply_hit_detection_reaction(p2AttackResult, character2, character2, character1)
	#if p1AttackResult[HitDetectionFlags.HasHit]:
		#character1.mark_successful_hit()
		#if p1AttackResult[HitDetectionFlags.TargetReaction] == GameDatabaseAccessor.defaultDownSpikeReaction:
			#_hitFreezeFrames = hitFreezeDownSpikeFrames
			#_spikeHitFreeze = true
		#else:
			#_hitFreezeFrames = hitFreezeComboFrames
		#character1.characterState.affectedByHitFreeze = true
		#character2.characterState.affectedByHitFreeze = true
		#_comboHitFreeze = true
		#_wallHitFreeze = false
		#var boxCenter = (p1AttackResult[HitDetectionFlags.IntersectionBox] as Rect2i).get_center()
		#hitspark1.activate_hitspark(boxCenter)
		#if character2.currentMove and character2.currentMove.isHitStunState:
			#character1.characterState.comboCounter += 1
			#character1.characterState.comboDamage += p1AttackResult[HitDetectionFlags.DamageToApply]
		#else:
			#character1.characterState.comboCounter = 0
			#character1.characterState.comboDamage = 0
	#if p2AttackResult[HitDetectionFlags.HasHit]:
		#character2.mark_successful_hit()
		#if p2AttackResult[HitDetectionFlags.TargetReaction] == GameDatabaseAccessor.defaultDownSpikeReaction:
			#_hitFreezeFrames = hitFreezeDownSpikeFrames
			#_spikeHitFreeze = true
		#else:
			#_hitFreezeFrames = hitFreezeComboFrames
		#character1.characterState.affectedByHitFreeze = true
		#character2.characterState.affectedByHitFreeze = true
		#_comboHitFreeze = true
		#_wallHitFreeze = false
		#var boxCenter = (p2AttackResult[HitDetectionFlags.IntersectionBox] as Rect2i).get_center()
		#hitspark2.activate_hitspark(boxCenter)
		#if character1.currentMove and character1.currentMove.isHitStunState:
			#character2.characterState.comboCounter += 1
			#character2.characterState.comboDamage += p2AttackResult[HitDetectionFlags.DamageToApply]
		#else:
			#character2.characterState.comboCounter = 0
			#character2.characterState.comboDamage = 0
	if p1AttackResult[HitDetectionFlags.HasHit]:
		@warning_ignore("integer_division")
		var meterGainHitCharacter = (
			p1AttackResult[HitDetectionFlags.MeterGain] / 
			GameDatabaseAccessor.hitCharacterMeterGainFraction)
		if canGainMeterFromMoveP1:
			character1.gain_meter(p1AttackResult[HitDetectionFlags.MeterGain])
		character2.gain_meter(meterGainHitCharacter)
		character2.deal_damage(p1AttackResult[HitDetectionFlags.DamageToApply])
		character2.characterState.comboCounter = 0
		character2.characterState.comboDamage = 0
		var _success = character2.apply_move_by_name(p1AttackResult[HitDetectionFlags.TargetReaction])
	if p2AttackResult[HitDetectionFlags.HasHit]:
		@warning_ignore("integer_division")
		var meterGainHitCharacter = (
			p2AttackResult[HitDetectionFlags.MeterGain] / 
			GameDatabaseAccessor.hitCharacterMeterGainFraction)
		if canGainMeterFromMoveP2:
			character2.gain_meter(p2AttackResult[HitDetectionFlags.MeterGain])
		character1.gain_meter(meterGainHitCharacter)
		character1.deal_damage(p2AttackResult[HitDetectionFlags.DamageToApply])
		character1.characterState.comboCounter = 0
		character1.characterState.comboDamage = 0
		var _success = character1.apply_move_by_name(p2AttackResult[HitDetectionFlags.TargetReaction])

func _init_hud():
	$Canvas/Hud/CharacterName1.texture = character1.characterData.characterNameTexture
	$Canvas/Hud/CharacterName1.position.x = $Canvas/Hud/HpBarChar1.position.x
	$Canvas/Hud/CharacterName2.texture = character2.characterData.characterNameTexture
	if $Canvas/Hud/CharacterName2.texture:
		$Canvas/Hud/CharacterName2.position.x = (
			$Canvas/Hud/HpBarChar2.position.x - 
			$Canvas/Hud/CharacterName2.texture.get_width() * 
			$Canvas/Hud/CharacterName2.scale.x)
	$Canvas/Hud/CharacterName1.visible = true
	$Canvas/Hud/CharacterName2.visible = true
	hudMain.update_round_won(0, 0)
	
func _update_hud():
	hudMain.update(character1, character2, _internalUpdateTick)
	@warning_ignore("integer_division")
	var comboCounterHitFreezeFrames = hitFreezeComboFrames / 2
	@warning_ignore("integer_division")
	var comboCounterWallHitFreezeFrames = hitFreezeWallFrames / 2
	if _hitFreezeFrames >= comboCounterHitFreezeFrames and _comboHitFreeze:
		hudMain.update_combo_counter_zoom(1.3)
	elif _hitFreezeFrames >= comboCounterWallHitFreezeFrames and _wallHitFreeze:
		hudMain.update_combo_counter_zoom(1.3)
	else:
		hudMain.update_combo_counter_zoom(0.7)

func _update_timer():
	if timerSeconds > 0 and !preventDeath:
		_timerTicks -= 1
		
func _update_hitsparks():
	hitspark1.update()
	hitspark2.update()
	
func _common_update_process():
	_internalUpdateTick += 1
	if _hitFreezeFrames >= 0:
		_hitFreezeFrames -= 1
		if _spikeHitFreeze:
			camera.zoom = Vector2(1.2, 1.2)
		elif (_comboHitFreeze or _wallHitFreeze):
			camera.zoom = Vector2(1.1, 1.1)
		else:
			camera.zoom = Vector2(1., 1.)
		if _hitFreezeFrames == 0:
			_comboHitFreeze = false
			_wallHitFreeze = false
			_spikeHitFreeze = false
			character1.characterState.affectedByHitFreeze = false
			character2.characterState.affectedByHitFreeze = false
	else:
		camera.zoom = Vector2(1., 1.)
	if character1.can_be_updated() or character2.can_be_updated():
		_update_game_phase_transition()
		_update_character_state()	
		_update_projectiles()
		_adjust_character_momentum(character1, character2)
		_adjust_character_momentum(character2, character1)
		if _wallHitFreeze and hitFreezeOnWallCollisionBothPlayers:
			if character1.characterState.affaffectedByHitFreeze:
				character2.characterState.affectedByHitFreeze = true
			elif character2.characterState.affaffectedByHitFreeze:
				character1.characterState.affectedByHitFreeze = true
		_update_camera()
		_constrain_character_position_to_camera_viewport(character1)
		_constrain_character_position_to_camera_viewport(character2)
		_adjust_character_sfx()
		collisionManager.update_character_position_on_collision(character1, character2, stage)
		var projectileHasHit = _update_projectile_hit_detection()
		if !projectileHasHit:
			_update_hit_detection()
	_update_hitsparks()
	_lastFrameComboHitFreeze = _comboHitFreeze
	_update_hud()
	_update_post_match_menu()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if networkMode:
		return
	_update_system_input()
	_check_for_game_pause()
	if _is_paused():
		_update_pause_menu()
	else:
		_update_character_input()
		_common_update_process()
	
func _network_process(_input: Dictionary) -> void:
	_common_update_process()
