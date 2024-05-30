class_name SceneGame extends Node2D

enum RoundPhaseState {
	Ready = 0,
	Engage = 1,
	ActiveMatch = 2,
	Ko = 3,
	VictoryPose = 4,
	PostMatchMenu = 5
}

@onready var inputManagerP1 : InputBufferManager = $InputManagerP1
@onready var inputManagerP2 : InputBufferManager = $InputManagerP2
@onready var collisionManager : CollisionManager = $CollisionManager
@onready var stage : Stage = $Stage
@onready var camera : Camera2D = $Camera
var _cameraLogicalPosition : Vector2i
@onready var character1 : Character = $Characters/Character1
@onready var character2 : Character = $Characters/Character2
@onready var hudMain : HudManager = $Canvas/Hud
var _hitFreezeFrames : int = -1
var _lastFrameComboHitFreeze : bool = false
var _comboHitFreeze : bool = false
var _roundPhaseCounter : int = -1
var _roundPhaseState : RoundPhaseState = RoundPhaseState.Ready
var _roundWonCharacter1 : int = 0
var _roundWonCharacter2 : int = 0
@export_category("Settings")
@export var phaseTransitionMaxCounter = 120
@export var hitFreezeComboFrames = 10
@export var hitFreezeWallFrames = 5
@export_category("Debug")
@export var debugMode : bool = false
@export var networkMode : bool = false
@export var preventDeath : bool = false
@export var startActivePhaseImmediately : bool = false

var _lastStateSaved = {}

enum HitDetectionFlags {
	HasHit = 0,
	TargetReaction = 1,
	DamageToApply = 2,
	MeterGain = 3
}

enum GameStateVars {
	Character1State = 0,
	Character2State = 1,
	HitFreezeLastFrame = 2,
	HitFreezeCounter = 3,
	HitFreezeBool = 4,
	CameraLogicalPositionX = 5,
	CameraLogicalPositionY = 6,
	RoundPhaseState = 7,
	RoundPhaseFrameCounter = 8,
	TimerTicks = 9,
	RoundWonCharacter1 = 10,
	RoundWonCharacter2 = 11,
	SystemMessageManagerState = 900,
	InputManagerCharacter1 = 901,
	InputManagerCharacter2 = 902,
}

func _save_state() -> Dictionary:
	var stateDict = {}
	stateDict[GameStateVars.Character1State] = character1._save_state().duplicate()
	stateDict[GameStateVars.Character2State] = character2._save_state().duplicate()
	stateDict[GameStateVars.HitFreezeLastFrame] = _lastFrameComboHitFreeze
	stateDict[GameStateVars.HitFreezeCounter] = _hitFreezeFrames
	stateDict[GameStateVars.HitFreezeBool] = _comboHitFreeze
	stateDict[GameStateVars.CameraLogicalPositionX] = _cameraLogicalPosition.x
	stateDict[GameStateVars.CameraLogicalPositionY] = _cameraLogicalPosition.y
	stateDict[GameStateVars.RoundPhaseState] = _roundPhaseState
	stateDict[GameStateVars.RoundPhaseFrameCounter] = _roundPhaseCounter
	stateDict[GameStateVars.RoundWonCharacter1] = _roundWonCharacter1
	stateDict[GameStateVars.RoundWonCharacter2] = _roundWonCharacter2
	if !networkMode:
		stateDict[GameStateVars.SystemMessageManagerState] = hudMain.systemMessageManager._save_state().duplicate()
		stateDict[GameStateVars.InputManagerCharacter1] = inputManagerP1._save_state().duplicate()
		stateDict[GameStateVars.InputManagerCharacter2] = inputManagerP2._save_state().duplicate()
	return stateDict
	
func _load_state(state : Dictionary) -> void:
	character1._load_state(state[GameStateVars.Character1State])
	character2._load_state(state[GameStateVars.Character2State])
	_comboHitFreeze = state[GameStateVars.HitFreezeBool]
	_hitFreezeFrames = state[GameStateVars.HitFreezeCounter]
	_lastFrameComboHitFreeze = state[GameStateVars.HitFreezeLastFrame]
	_cameraLogicalPosition.x = state[GameStateVars.CameraLogicalPositionX]
	_cameraLogicalPosition.y = state[GameStateVars.CameraLogicalPositionY]
	_roundPhaseState = state[GameStateVars.RoundPhaseState]
	_roundPhaseCounter = state[GameStateVars.RoundPhaseFrameCounter]
	_roundWonCharacter1 = state[GameStateVars.RoundWonCharacter1]
	_roundWonCharacter2 = state[GameStateVars.RoundWonCharacter2]
	if !networkMode:
		hudMain.systemMessageManager._load_state(state[GameStateVars.SystemMessageManagerState])
		inputManagerP1._load_state(state[GameStateVars.InputManagerCharacter1])
		inputManagerP2._load_state(state[GameStateVars.InputManagerCharacter2])
	hudMain.update(character1, character2, false)
	hudMain.update_round_won(_roundWonCharacter1, _roundWonCharacter2)

# Called when the node enters the scene tree for the first time.
func _ready():
	#character2/Sprite2D.flip_h = true
	_reset_round()
	_init_hud()
	_lastStateSaved = _save_state()
	add_to_group('network_sync')
	
func _reset_round():
	hudMain.hide_message()
	stage.update_stage_position()
	var stagePos = stage.position * GameDatabaseAccessor.screenCoordMultiplierInt
	var charOffset = stage.characterOffset * GameDatabaseAccessor.screenCoordMultiplierInt
	character1.initialLogicalPosition = Vector2(stagePos.x - charOffset.x, charOffset.y)
	character2.initialLogicalPosition = Vector2(stagePos.x + charOffset.x, charOffset.y)
	character1.reset_character()
	character2.reset_character()
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
	if debugMode:
		if InputOverseer.input_is_action_just_pressed_kb("toggle_boxes_debug"):
				GameDatabaseAccessor.showBoxes = !GameDatabaseAccessor.showBoxes
		elif InputOverseer.input_is_action_just_pressed_kb("replenish_healthbars_debug"):
				if character1.is_ko():
					character1.reset_character_to_idle_full_health()
				if character2.is_ko():
					character2.reset_character_to_idle_full_health()
				character1.characterState.currentHealth = character1.characterData.characterMaxHealth
				character2.characterState.currentHealth = character2.characterData.characterMaxHealth
				_roundPhaseState = RoundPhaseState.ActiveMatch
				_roundPhaseCounter = -1
				hudMain.hide_message(true)
		elif InputOverseer.input_is_action_just_pressed_kb("save_state_debug"):
			_lastStateSaved = _save_state()
		elif InputOverseer.input_is_action_just_pressed_kb("load_state_debug"):
			if !_lastStateSaved.is_empty():
				_load_state(_lastStateSaved)

func _establish_round_winner():
	if character1.is_ko():
		_roundWonCharacter2 += 1
	if character2.is_ko():
		_roundWonCharacter1 += 1

func _update_game_phase_transition():
	@warning_ignore("integer_division")
	var phaseTransitionMessageThreshold = phaseTransitionMaxCounter / 4
	if  _roundPhaseState == RoundPhaseState.Ready and _roundPhaseCounter < 0:
		_roundPhaseCounter = phaseTransitionMaxCounter
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
				_reset_round()
	character1.characterState.roundState = _roundPhaseState
	character2.characterState.roundState = _roundPhaseState

func _update_character_input():
	#if (_roundPhaseState == RoundPhaseState.ActiveMatch or 
		#_roundPhaseState == RoundPhaseState.Ko):
	inputManagerP1.update_buffer()
	inputManagerP2.update_buffer()

func _update_character_state():
	# this is a measure to improve move detection during hit freeze
	var extraInputLeniency = 0
	if !_comboHitFreeze and _lastFrameComboHitFreeze:
		extraInputLeniency = hitFreezeComboFrames
	character1.update(inputManagerP1, extraInputLeniency)
	character2.update(inputManagerP2, extraInputLeniency)
	
	character1.immortal = preventDeath
	character2.immortal = preventDeath
	
	if character1.can_turn_around():
		if character1.characterState.logicalPosition.x <= character2.characterState.logicalPosition.x:
			character1.set_on_left_side(true) 
			character1.scale = Vector2(1, 1)
		else:
			character1.set_on_left_side(false) 
			character1.scale = Vector2(-1, 1)
	if character2.can_turn_around():
		if character2.characterState.logicalPosition.x < character1.characterState.logicalPosition.x:
			character2.set_on_left_side(true) 
			character2.scale = Vector2(1, 1)
		else:
			character2.set_on_left_side(false) 
			character2.scale = Vector2(-1, 1)
		
func _adjust_character_momentum(character : Character):
	if !character.currentMove:
		return
	if !character.currentMove.isHitStunState or character.currentMove.characterState != Character.State.Air:
		return
	if !character.is_airborne():
		return
	var leftWallDistance : int = collisionManager.distance_from_left_corner(character, stage)
	var rightWallDistance : int = collisionManager.distance_from_right_corner(character, stage)
	@warning_ignore("integer_division")
	var boxHalfSize : int = character.get_collision_box().size.x / 2
	if (leftWallDistance <= boxHalfSize
		and character.get_logical_velocity().x < 0):
			character.multiply_horizontal_movement(-150, false)
			character.multiply_vertical_movement(125)
			_hitFreezeFrames = hitFreezeWallFrames
			_comboHitFreeze = false
	elif (rightWallDistance <= boxHalfSize
		and character.get_logical_velocity().x > 0):
			character.multiply_horizontal_movement(-150, false)
			character.multiply_vertical_movement(125)
			_hitFreezeFrames = hitFreezeWallFrames
			_comboHitFreeze = false
		
func _constrain_character_position_to_camera_viewport(character : Character):
	var collBox = character.get_collision_box()
	var leftBoundary = collBox.position.x - collBox.size.x / 2
	var rightBoundary = collBox.position.x + collBox.size.x / 2
	var cameraViewport = get_viewport_rect().size * GameDatabaseAccessor.screenCoordMultiplierInt
	var leftCameraBoundary = _cameraLogicalPosition.x - cameraViewport.x / 2
	var rightCameraBoundary = _cameraLogicalPosition.x + cameraViewport.x / 2
	var currentCharacterLogicalPosition = character.get_logical_position()
	if leftBoundary < leftCameraBoundary:
		currentCharacterLogicalPosition.x += abs(leftBoundary - leftCameraBoundary)
	elif rightBoundary > rightCameraBoundary:
		currentCharacterLogicalPosition.x -= abs(rightBoundary - rightCameraBoundary)
	character.set_new_logical_position(currentCharacterLogicalPosition)
			
func _update_camera(immediate : bool = false):
	if immediate:
		camera.position_smoothing_enabled = false
	else:
		camera.position_smoothing_enabled = true
	var cameraTargetPosition = (character1.position + character2.position) / 2
	var cameraViewportSize = get_viewport_rect().size
	var cameraX = cameraTargetPosition.x
	var cameraY = cameraTargetPosition.y
	var cameraYBottom = cameraTargetPosition.y + cameraViewportSize.y / 2
	var cameraYTop = cameraTargetPosition.y - cameraViewportSize.y / 2
	var cameraXLeft = cameraTargetPosition.x - cameraViewportSize.x / 2
	var cameraXRight = cameraTargetPosition.x + cameraViewportSize.x / 2
	if cameraXLeft < stage.position.x - stage.stageSize.x / 2.:
		cameraX += abs(cameraXLeft - (stage.position.x - stage.stageSize.x / 2.))
	elif cameraXRight > stage.position.x + stage.stageSize.x / 2.:
		cameraX -= abs(cameraXRight - (stage.position.x + stage.stageSize.x / 2.))
	if cameraYTop < stage.position.y - stage.stageSize.y / 2.:
		cameraY += abs(cameraYTop - (stage.position.y - stage.stageSize.y / 2.))
	elif cameraYBottom > stage.position.y + stage.stageSize.y / 2.:
		cameraY -= abs(cameraYBottom - (stage.position.y + stage.stageSize.y / 2.))
	cameraTargetPosition.y = cameraY
	cameraTargetPosition.x = cameraX
	camera.position = cameraTargetPosition
	_cameraLogicalPosition = Vector2i(cameraTargetPosition.x * 1000, cameraTargetPosition.y * 1000)

func _process_damage_collisions(attacker : Character, defender : Character) -> Dictionary:
	var result : Dictionary = {}
	result[HitDetectionFlags.HasHit] = false
	result[HitDetectionFlags.TargetReaction] = "hurtG"
	result[HitDetectionFlags.DamageToApply] = 0
	result[HitDetectionFlags.MeterGain] = 0
	for hitBox in attacker.hitBoxes:
		if hitBox.active:
			for hurtBox in defender.hurtBoxes:
				if hurtBox.active:
					if (attacker.get_box_top_left(hitBox).
							intersects(defender.get_box_top_left(hurtBox))):
						result[HitDetectionFlags.HasHit] = true
						result[HitDetectionFlags.DamageToApply] = hitBox.damage
						if defender.is_airborne():
							result[HitDetectionFlags.TargetReaction] = hitBox.moveReactionOnHitAir
						else:
							result[HitDetectionFlags.TargetReaction] = hitBox.moveReactionOnHitGround
						result[HitDetectionFlags.MeterGain] = hitBox.meterGain
						if hitBox.deactivateOnHit:
							hitBox.active = false
						break
	return result

func _update_hit_detection():
	if !character1.currentMove or !character1.currentMove.isHitStunState:
		character2.characterState.comboCounter = 0
	if !character2.currentMove or !character2.currentMove.isHitStunState:
		character1.characterState.comboCounter = 0
	var p1AttackResult = _process_damage_collisions(character1, character2)
	var p2AttackResult = _process_damage_collisions(character2, character1)
	# manage damage and hit reactions
	if p1AttackResult[HitDetectionFlags.HasHit]:
		character1.mark_successful_hit()
		_hitFreezeFrames = hitFreezeComboFrames
		_comboHitFreeze = true
		if character2.currentMove and character2.currentMove.isHitStunState:
			character1.characterState.comboCounter += 1
		else:
			character1.characterState.comboCounter = 0
	if p2AttackResult[HitDetectionFlags.HasHit]:
		character2.mark_successful_hit()
		_hitFreezeFrames = hitFreezeComboFrames
		_comboHitFreeze = true
		if character1.currentMove and character1.currentMove.isHitStunState:
			character2.characterState.comboCounter += 1
		else:
			character2.characterState.comboCounter = 0
	if p1AttackResult[HitDetectionFlags.HasHit]:
		character1.gain_meter(p1AttackResult[HitDetectionFlags.MeterGain])
		character2.deal_damage(p1AttackResult[HitDetectionFlags.DamageToApply])
		character2.characterState.comboCounter = 0
		var _success = character2.apply_move_by_name(p1AttackResult[HitDetectionFlags.TargetReaction])
	if p2AttackResult[HitDetectionFlags.HasHit]:
		character2.gain_meter(p2AttackResult[HitDetectionFlags.MeterGain])
		character1.deal_damage(p2AttackResult[HitDetectionFlags.DamageToApply])
		character1.characterState.comboCounter = 0
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
	hudMain.update(character1, character2)
	@warning_ignore("integer_division")
	var comboCounterHitFreezeFrames = hitFreezeComboFrames / 2
	if _hitFreezeFrames >= comboCounterHitFreezeFrames and _comboHitFreeze:
		hudMain.update_combo_counter_zoom(1.3)
	else:
		hudMain.update_combo_counter_zoom(0.7)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if networkMode:
		return
	_update_system_input()
	_update_character_input()
	if _hitFreezeFrames >= 0:
		_hitFreezeFrames -= 1
		camera.zoom = Vector2(1.1, 1.1)
		if _hitFreezeFrames == 0:
			_comboHitFreeze = false
	else:
		camera.zoom = Vector2(1., 1.)
		_update_game_phase_transition()
		_update_character_state()	
		_adjust_character_momentum(character1)
		_adjust_character_momentum(character2)
		_update_camera()
		_constrain_character_position_to_camera_viewport(character1)
		_constrain_character_position_to_camera_viewport(character2)
		collisionManager.update_character_position_on_collision(character1, character2, stage)
		_update_hit_detection()
	_lastFrameComboHitFreeze = _comboHitFreeze
	_update_hud()
	
func _network_process(_input: Dictionary) -> void:
	if _hitFreezeFrames >= 0:
		_hitFreezeFrames -= 1
		camera.zoom = Vector2(1.1, 1.1)
		#character1.pause_animation()
		#character2.pause_animation()
		if _hitFreezeFrames == 0:
			_comboHitFreeze = false
			#character1.resume_animation()
			#character2.resume_animation()
	else:
		camera.zoom = Vector2(1., 1.)
		_update_game_phase_transition()
		_update_character_state()	
		_adjust_character_momentum(character1)
		_adjust_character_momentum(character2)
		_update_camera()
		_constrain_character_position_to_camera_viewport(character1)
		_constrain_character_position_to_camera_viewport(character2)
		collisionManager.update_character_position_on_collision(character1, character2, stage)
		_update_hit_detection()
	_lastFrameComboHitFreeze = _comboHitFreeze
	_update_hud()
