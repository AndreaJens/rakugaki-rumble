class_name Character extends Node2D

enum State 
{
	Ground = 0, 
	Air = 1
}
enum ReservedMoveIndex 
{
	Idle = 0,
	Falling = 1,
	HurtGround = 2,
	HurtAir = 3,
	Ko = 4,
}

@export var characterData : CharacterData
@export var initialLogicalPosition : Vector2i = Vector2i(0, 0)
@onready var characterState : CharacterState = $CharacterState
@onready var animationPlayer : AnimationPlayer = $AnimationPlayer
var moveNameToIndex : Dictionary = {}
var currentMove : CharacterMove = null
@onready var pushBox : MoveBox = $PushBox
var hitBoxes : Array[HitBox] = []
var hurtBoxes : Array[HurtBox] = []
@export var immortal : bool = false

# FUNCTIONS FOR SNOPEK ROLLBACK ADDON
func _save_state() -> Dictionary:
	var stateDict = characterState._save_state()
	return stateDict

func _load_state(state : Dictionary) -> void:
	characterState._load_state(state)
	_apply_move_load_state()
	update_screen_position()
	_update_boxes()
	if characterState.onLeftSide: 
		scale = Vector2(1, 1)
	else:
		scale = Vector2(-1, 1)

# Called when the node enters the scene tree for the first time.
func _ready():
	var moveIndex = 0
	for move in characterData.characterMoves:
		moveNameToIndex[move.internalName] = moveIndex
		moveIndex += 1
	hitBoxes.clear()
	hurtBoxes.clear()
	for child in $HitBoxes.get_children():
		if child is HitBox:
			hitBoxes.push_back(child)	
	for child in $HurtBoxes.get_children():
		if child is HurtBox:
			hurtBoxes.push_back(child)
	
func get_sprite() -> Sprite2D:
	return $Sprite2D
	
func is_on_left_side() -> bool:
	return characterState.onLeftSide
	
func set_on_left_side(onLeftSide : bool):
	characterState.onLeftSide = onLeftSide
	
func deactivate_boxes():
	pushBox.active = false
	if pushBox.is_mirrored():
		pushBox.mirror()
	for hitBox in hitBoxes:
		hitBox.active = false
		if hitBox.is_mirrored():
			hitBox.mirror()
	for hurtBox in hurtBoxes:
		hurtBox.active = false
		if hurtBox.is_mirrored():
			hurtBox.mirror()
	
func reset_character(resetMeter : bool = false):
	characterState.currentHealth = characterData.characterMaxHealth
	if resetMeter:
		characterState.currentMeter = 0
	characterState.logicalPosition = initialLogicalPosition
	characterState.logicalVelocity = Vector2i(0, 0)
	characterState.logicalAcceleration = Vector2i(0, 0)
	characterState.moveId = ReservedMoveIndex.Idle
	characterState.currentFrame = characterData.characterMoves[characterState.moveId].startingFrame
	characterState.comboCounter = 0
	characterState.bounceCounter = 0
	characterState.affectedByHitFreeze = false
	deactivate_boxes()
	apply_new_move( characterData.characterMoves[characterState.moveId] )
	update_screen_position()
	_update_boxes()

func reset_character_to_idle_full_health():
	characterState.currentHealth = characterData.characterMaxHealth
	characterState.logicalVelocity = Vector2i(0, 0)
	characterState.logicalAcceleration = Vector2i(0, 0)
	characterState.moveId = ReservedMoveIndex.Idle
	characterState.currentFrame = characterData.characterMoves[characterState.moveId].startingFrame
	deactivate_boxes()
	apply_new_move( characterData.characterMoves[characterState.moveId] )
	_update_boxes()

func _clamp_state_variables():
	characterState.currentHealth = max(0, 
		min(characterState.currentHealth, characterData.characterMaxHealth))
	characterState.currentMeter = max(0, 
		min(characterState.currentMeter, characterData.characterMaxMeter))

func deal_damage(damage : int):
	if can_be_dealt_damage():
		add_health(-damage)

func gain_meter(meterGain : int):
	if can_gain_meter():
		add_meter(meterGain)

func add_health(health : int):
	characterState.currentHealth += health
	_clamp_state_variables()

func add_meter(meterGain : int):
	characterState.currentMeter += meterGain
	_clamp_state_variables()

func mark_successful_hit():
	characterState.currentMoveHasHit = true

func pause_animation():
	animationPlayer.pause()

func resume_animation():
	animationPlayer.play()

func set_animation_frame(frame : int):
	animationPlayer.seek(frame / (GameDatabaseAccessor.frameRateFps as float), true)

func advance_current_animation(frames : int = 1):
	animationPlayer.advance(frames / (GameDatabaseAccessor.frameRateFps as float))

func update_screen_position():
	position.x = characterState.logicalPosition.x / GameDatabaseAccessor.screenCoordMultiplier
	position.y = characterState.logicalPosition.y / GameDatabaseAccessor.screenCoordMultiplier

func get_character_full_name() -> String:
	return characterData.characterFullName

func get_character_display_name() -> String:
	return characterData.characterDisplayName

func get_character_preview() -> Texture2D:
	return characterData.characterPortrait
	
func is_still() -> bool:
	return (characterState.logicalVelocity.x == 0 and 
		characterState.logicalVelocity.y == 0 and 
		characterState.logicalAcceleration.x == 0 and
		characterState.logicalAcceleration.y == 0)

func can_turn_around() -> bool:
	if is_airborne():
		return false
	if currentMove and currentMove.canTurnMidMove:
		return true
	if !is_still():
		return false 
	return false
	
func is_airborne() -> bool:
	return characterState.characterStanceType == Character.State.Air 
	
func is_ko() -> bool:
	return !immortal and characterState.currentHealth <= 0

func _apply_move_load_state():
	deactivate_boxes()
	currentMove = characterData.characterMoves[characterState.moveId]
	animationPlayer.set_current_animation(currentMove.animationName)
	set_animation_frame(characterState.currentFrame)

func apply_move_by_name(moveName : String) -> bool:
	if moveNameToIndex.has(moveName):
		apply_new_move(characterData.characterMoves[moveNameToIndex[moveName]])
		return true
	return false

func apply_new_move(move : CharacterMove):
	deactivate_boxes()
	characterState.currentMoveHasHit = false
	characterState.moveId = moveNameToIndex[move.internalName]
	animationPlayer.set_current_animation(move.animationName)
	set_animation_frame(move.startingFrame)
	characterState.currentFrame = move.startingFrame
	var horizontalDirectionMult = 1
	if (!is_on_left_side()):
		horizontalDirectionMult = -1
	var logicalVel := move.logicalVelocityPerFrame
	var logicalAcc := move.logicalAccelerationPerFrame
	logicalVel.x = horizontalDirectionMult * logicalVel.x
	logicalAcc.x = horizontalDirectionMult * logicalAcc.x
	#var sameSign : bool = ((characterState.logicalVelocity.x <= 0 and logicalVel.x <= 0) or
		#(characterState.logicalVelocity.x >= 0 and logicalVel.x >= 0))
	if move.keepMomentumPercent > 0:
		@warning_ignore("integer_division")
		characterState.logicalVelocity.x += logicalVel.x * move.keepMomentumPercent / 100
		# temporary momentum transfer test
		if (characterState.logicalVelocity.y <= 0):
			@warning_ignore("integer_division")
			characterState.logicalVelocity.y += logicalVel.y * move.keepMomentumPercent / 100
		else:
			characterState.logicalVelocity.y = logicalVel.y
	else:
		characterState.logicalVelocity = logicalVel
	characterState.logicalAcceleration = logicalAcc
	currentMove = move
	
func turn_around():
	characterState.onLeftSide = !characterState.onLeftSide
	if characterState.onLeftSide: 
		scale = Vector2(1, 1)
	else:
		scale = Vector2(-1, 1)

func multiply_horizontal_movement(factor : int, accel : bool = false):
	@warning_ignore("integer_division")
	characterState.logicalVelocity.x = characterState.logicalVelocity.x * factor / 100
	if accel:
		@warning_ignore("integer_division")
		characterState.logicalAcceleration.x = characterState.logicalAcceleration.x * factor / 100
	if factor < 0:
		turn_around()

func multiply_vertical_movement(factor : int, accel : bool = false):
	@warning_ignore("integer_division")
	characterState.logicalVelocity.y =  characterState.logicalVelocity.y * factor / 100
	if accel:
		@warning_ignore("integer_division")
		characterState.logicalAcceleration.y = characterState.logicalAcceleration.y * factor / 100

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _update_boxes():
	update_hit_boxes_logic()
	if (GameDatabaseAccessor.showBoxes):
		pushBox.visible = true
		for hitBox in hitBoxes:
			hitBox.visible = hitBox.active
		for hurtBox in hurtBoxes:
			hurtBox.visible = hurtBox.active
	else:
		pushBox.visible = false
		for hitBox in hitBoxes:
			hitBox.visible = false
		for hurtBox in hurtBoxes:
			hurtBox.visible = false
	# mirror boxes when needed
	if is_on_left_side():
		if pushBox.is_mirrored():
			pushBox.mirror()
		for hitBox in hitBoxes:
			if hitBox.active and hitBox.is_mirrored():
				hitBox.mirror()
		for hurtBox in hurtBoxes:
			if hurtBox.active and hurtBox.is_mirrored():
				hurtBox.mirror()
	else:
		if !pushBox.is_mirrored():
			pushBox.mirror()
		for hitBox in hitBoxes:
			if hitBox.active and !hitBox.is_mirrored():
				hitBox.mirror()
		for hurtBox in hurtBoxes:
			if hurtBox.active and !hurtBox.is_mirrored():
				hurtBox.mirror()

func get_collision_box() -> Rect2i:
	var pbox = pushBox.get_box()
	var pos = characterState.logicalPosition + pbox.position
	return Rect2i(pos, pbox.size)

func get_collision_box_top_left() -> Rect2i:
	return get_box_top_left(pushBox)

func get_box_top_left(box : MoveBox) -> Rect2i:
	var pbox = box.get_box()
	var pos = characterState.logicalPosition + pbox.position - pbox.size / 2
	return Rect2i(pos, pbox.size)
	
func get_logical_position() -> Vector2i:
	return characterState.logicalPosition
	
func get_logical_velocity() -> Vector2i:
	return characterState.logicalVelocity

func pushbox_is_active() -> bool:
	return pushBox.active
	
func set_new_logical_position(newPos : Vector2i):
	characterState.logicalPosition = newPos
	update_screen_position()
	
func _update_character_logical_position():
	characterState.logicalVelocity.x += characterState.logicalAcceleration.x
	characterState.logicalVelocity.y += characterState.logicalAcceleration.y
	characterState.logicalPosition.x += characterState.logicalVelocity.x
	characterState.logicalPosition.y += characterState.logicalVelocity.y
	
func _update_character_stance():
	if (characterState.logicalPosition.y >= initialLogicalPosition.y):
		characterState.logicalPosition.y = initialLogicalPosition.y
		if (characterState.characterStanceType == State.Air):
			# trigger on-landing conditions
			if currentMove:
				for followup in currentMove.cancelRoutes:
					if !followup.is_valid(characterState.currentFrame):
						continue
					if !moveNameToIndex.has(followup.targetMoveName):
						continue
					var moveIndex : int = moveNameToIndex[followup.targetMoveName]
					var moveToTest = characterData.characterMoves[moveIndex]
					if followup.automaticCancelOnLanding:
						apply_new_move(moveToTest)
						break
			characterState.characterStanceType = State.Ground
	# update states
	if characterState.logicalPosition.y < initialLogicalPosition.y:
		characterState.characterStanceType = State.Air
	else:
		characterState.characterStanceType = State.Ground

func update_hit_boxes_logic():
	for hitBox in hitBoxes:
		if characterState.currentMoveHasHit and hitBox.deactivateOnHit:
			hitBox.active = false

func can_perform_move(moveToTest : CharacterMove) -> bool:
	if (characterState.roundState == SceneGame.RoundPhaseState.Ready or
		characterState.roundState == SceneGame.RoundPhaseState.Engage):
			if !moveToTest.canBeUsedBeforeRoundBegins:
				return false
	return true

func can_be_updated():
	return !characterState.affectedByHitFreeze

func can_be_dealt_damage() -> bool:
	return characterState.roundState == SceneGame.RoundPhaseState.ActiveMatch

func can_gain_meter() -> bool:
	return characterState.roundState == SceneGame.RoundPhaseState.ActiveMatch

func _update_current_move( inputManager : InputBufferManager, extraLeniency : int = 0 ):
	if !currentMove	or !currentMove.isHitStunState:
		characterState.bounceCounter = 0
		characterState.affectedByHitFreeze = false
	if currentMove:
		var newMovePerformed := false
		characterState.currentFrame += 1
		set_animation_frame(characterState.currentFrame)
		# look for followups
		if is_ko():
			if characterState.moveId != ReservedMoveIndex.Ko:
				if !is_airborne():
					apply_new_move(characterData.characterMoves[ReservedMoveIndex.Ko])
			return
		for followup in currentMove.cancelRoutes:
			if !followup.is_valid(characterState.currentFrame):
				continue
			if !moveNameToIndex.has(followup.targetMoveName):
				continue
			if !followup.onWhiff and !characterState.currentMoveHasHit:
				continue
			var moveIndex : int = moveNameToIndex[followup.targetMoveName]
			var moveToTest = characterData.characterMoves[moveIndex]
			if !can_perform_move(moveToTest):
				continue
			var inputBuffer = []
			if moveToTest.useRawBuffer:
				inputBuffer = inputManager.get_current_raw_buffer()
			else:
				inputBuffer = inputManager.get_current_buffer()
			if followup.activeIfNothingPressed and (
				inputBuffer.is_empty() or
				inputBuffer.back() == GameDatabaseAccessor.GameInputButton.None
				):
				apply_new_move(moveToTest)
				newMovePerformed = true
				break
			elif moveToTest.check_input_match(inputBuffer, is_on_left_side(), extraLeniency):
				apply_new_move(moveToTest)
				newMovePerformed = true
				break
		if characterState.currentFrame >= currentMove.endingFrame:
			if !newMovePerformed:
				for followup in currentMove.cancelRoutes:
					if followup.autoPerformAtMoveEnd:
						var moveIndex : int = moveNameToIndex[followup.targetMoveName]
						var moveToTest = characterData.characterMoves[moveIndex]
						if !can_perform_move(moveToTest):
							continue
						apply_new_move(moveToTest)
						newMovePerformed = true
						break
			if !newMovePerformed:
				if currentMove.loop:
					apply_new_move(currentMove)
				else:
					if characterState.characterStanceType == State.Air:
						apply_new_move(characterData.characterMoves[ReservedMoveIndex.Falling])
					else:
						apply_new_move(characterData.characterMoves[ReservedMoveIndex.Idle])

func update( inputManager : InputBufferManager, extraInputLeniency : int = 0 ):
	_update_boxes()
	_clamp_state_variables()
	_update_current_move(inputManager, extraInputLeniency)
	_update_character_logical_position()
	_update_character_stance()
	update_screen_position()
	_update_boxes()
					

