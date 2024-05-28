extends Node2D

@onready var inputManagerP1 : InputBufferManager = $InputManagerP1
@onready var inputManagerP2 : InputBufferManager = $InputManagerP2
@onready var collisionManager : CollisionManager = $CollisionManager
@onready var stage : Stage = $Stage
@onready var camera : Camera2D = $Camera
var _cameraLogicalPosition : Vector2i
@onready var character1 : Character = $Characters/Character1
@onready var character2 : Character = $Characters/Character2
var _hitFreezeFrames : int = -1
var _comboHitFreeze : bool = false

enum HitDetectionFlags {
	HasHit = 0,
	TargetReaction = 1,
	DamageToApply = 2,
	MeterGain = 3
}

# Called when the node enters the scene tree for the first time.
func _ready():
	#character2/Sprite2D.flip_h = true
	stage.update_stage_position()
	var stagePos = stage.position * GameDatabaseAccessor.screenCoordMultiplierInt
	var charOffset = stage.characterOffset * GameDatabaseAccessor.screenCoordMultiplierInt
	character1.initialLogicalPosition = Vector2(stagePos.x - charOffset.x, charOffset.y)
	character2.initialLogicalPosition = Vector2(stagePos.x + charOffset.x, charOffset.y)
	character1.reset_character()
	character2.reset_character()
	_update_camera(true)

func _update_system_input():
	if InputOverseer.input_is_action_just_pressed_kb("fullscreen_toggle"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			print("windowed")
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			print("fullscreen")
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if InputOverseer.input_is_action_just_pressed_kb("toggle_boxes_debug"):
			GameDatabaseAccessor.showBoxes = !GameDatabaseAccessor.showBoxes
	if InputOverseer.input_is_action_just_pressed_kb("replenish_healthbars_debug"):
			character1.characterState.currentHealth = character1.characterData.characterMaxHealth
			character2.characterState.currentHealth = character2.characterData.characterMaxHealth

func _update_character_input():
	inputManagerP1.update_buffer()
	inputManagerP2.update_buffer()

func _update_character_state():
	
	character1.update(inputManagerP1)
	character2.update(inputManagerP2)
	
	if character1.can_turn_around():
		if character1.characterState.logicalPosition.x <= character2.characterState.logicalPosition.x:
			character1.onLeftSide = true 
			#character1.get_sprite().flip_h = false
			character1.scale = Vector2(1, 1)
		else:
			character1.onLeftSide = false 
			character1.scale = Vector2(-1, 1)
			#character1.get_sprite().flip_h = true
	if character2.can_turn_around():
		if character2.characterState.logicalPosition.x < character1.characterState.logicalPosition.x:
			character2.onLeftSide = true 
			character2.scale = Vector2(1, 1)
			#character2.get_sprite().flip_h = false
		else:
			character2.onLeftSide = false 
			#character2.get_sprite().flip_h = true
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
			_hitFreezeFrames = 5
			_comboHitFreeze = false
	elif (rightWallDistance <= boxHalfSize
		and character.get_logical_velocity().x > 0):
			character.multiply_horizontal_movement(-150, false)
			character.multiply_vertical_movement(125)
			_hitFreezeFrames = 5
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
		character2.comboCounter = 0
	if !character2.currentMove or !character2.currentMove.isHitStunState:
		character1.comboCounter = 0
	var p1AttackResult = _process_damage_collisions(character1, character2)
	var p2AttackResult = _process_damage_collisions(character2, character1)
	# manage damage and hit reactions
	if p1AttackResult[HitDetectionFlags.HasHit]:
		character1.mark_successful_hit()
		_hitFreezeFrames = 10
		_comboHitFreeze = true
		if character2.currentMove and character2.currentMove.isHitStunState:
			character1.comboCounter += 1
		else:
			character1.comboCounter = 0
	if p2AttackResult[HitDetectionFlags.HasHit]:
		character2.mark_successful_hit()
		_hitFreezeFrames = 10
		_comboHitFreeze = true
		if character1.currentMove and character1.currentMove.isHitStunState:
			character2.comboCounter += 1
		else:
			character2.comboCounter = 0
	if p1AttackResult[HitDetectionFlags.HasHit]:
		character1.add_meter(p1AttackResult[HitDetectionFlags.MeterGain])
		character2.deal_damage(p1AttackResult[HitDetectionFlags.DamageToApply])
		character2.comboCounter = 0
		var _success = character2.apply_move_by_name(p1AttackResult[HitDetectionFlags.TargetReaction])
	if p2AttackResult[HitDetectionFlags.HasHit]:
		character2.add_meter(p2AttackResult[HitDetectionFlags.MeterGain])
		character1.deal_damage(p2AttackResult[HitDetectionFlags.DamageToApply])
		character1.comboCounter = 0
		var _success = character1.apply_move_by_name(p2AttackResult[HitDetectionFlags.TargetReaction])

func _update_hud():
	$Canvas/Hud/HpBarChar1.max_value = character1.characterData.characterMaxHealth
	$Canvas/Hud/HpBarChar1.value = character1.characterState.currentHealth
	$Canvas/Hud/HpBarChar2.max_value = character2.characterData.characterMaxHealth
	$Canvas/Hud/HpBarChar2.value = character2.characterState.currentHealth
	if character1.comboCounter > 0:
		$Canvas/Hud/ComboCounter1.visible = true
	else:
		$Canvas/Hud/ComboCounter1.visible = false
	if character2.comboCounter > 0:
		$Canvas/Hud/ComboCounter2.visible = true
	else:
		$Canvas/Hud/ComboCounter2.visible = false
	if _hitFreezeFrames >= 5 and _comboHitFreeze:
		$Canvas/Hud/ComboCounter1.scale.x = 1.3
		$Canvas/Hud/ComboCounter2.scale.x = 1.3
	else:
		$Canvas/Hud/ComboCounter1.scale.x = 0.7
		$Canvas/Hud/ComboCounter2.scale.x = 0.7
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	_update_system_input()
	_update_character_input()
	if _hitFreezeFrames >= 0:
		_hitFreezeFrames -= 1
		camera.zoom = Vector2(1.1, 1.1)
		character1.pause_animation()
		character2.pause_animation()
		if _hitFreezeFrames == 0:
			_comboHitFreeze = false
			character1.resume_animation()
			character2.resume_animation()
	else:
		camera.zoom = Vector2(1., 1.)
		_update_character_state()	
		_adjust_character_momentum(character1)
		_adjust_character_momentum(character2)
		_update_camera()
		_constrain_character_position_to_camera_viewport(character1)
		_constrain_character_position_to_camera_viewport(character2)
		collisionManager.update_character_position_on_collision(character1, character2, stage)
		_update_hit_detection()
	_update_hud()
	
