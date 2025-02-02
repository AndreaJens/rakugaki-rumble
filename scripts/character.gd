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
	Victory = 5
}

@export var characterData : CharacterData
@export var initialLogicalPosition : Vector2i = Vector2i(0, 0)
@onready var characterState : CharacterState = $CharacterState
@onready var animationPlayer : AnimationPlayer = $AnimationPlayer
@onready var audioPlayer : AudioStreamPlayer = $AudioStreamPlayer
var moveNameToIndex : Dictionary = {}
var currentMove : CharacterMove = null
@onready var pushBox : MoveBox = $PushBox
var hitBoxes : Array[HitBox] = []
var hurtBoxes : Array[HurtBox] = []
var projectiles : Array[CharacterProjectile] = []
var projectileNameDict : Dictionary = {}
@export var inNetworkMatch : bool = false
@export var immortal : bool = false
# used only for cosmetic stuff that doesn't influence the game state
var _rng = RandomNumberGenerator.new()
var wallbounceSound : SoundAtFrame = preload("res://media/sounds/walllbounce_sound.tres")

@export var infinityInstallActive : bool = false:
	set (value):
		if !characterState:
			return
		if !characterState.hasInfinityInstallActive and value:
			characterState.installDurationFrameCounter = GameDatabaseAccessor.defaultInfinityInstallDurationTicks
		if value:
			characterState.hasInfinityInstallActive = value
	get:
		if !characterState:
			return false
		return characterState.hasInfinityInstallActive
		
@export var zeroInstallActive : bool = false:
	set (value):
		if !characterState:
			return
		if !characterState.hasZeroInstallActive and value:
			characterState.installDurationFrameCounter = GameDatabaseAccessor.defaultZeroInstallDurationTicks
		#if !value:
			#characterState.installDurationFrameCounter = -1
		if value:
			characterState.hasZeroInstallActive = value
	get:
		if !characterState:
			return false
		return characterState.hasZeroInstallActive

# FUNCTIONS FOR SNOPEK ROLLBACK ADDON
func _save_state() -> Dictionary:
	var stateDict = characterState._save_state()
	return stateDict

func _load_state(state : Dictionary) -> void:
	characterState._load_state(state)
	#var installFrames = characterState.installDurationFrameCounter
	#infinityInstallActive = characterState.hasInfinityInstallActive
	#zeroInstallActive = characterState.hasZeroInstallActive
	#characterState.installDurationFrameCounter = installFrames
	_apply_move_load_state()
	update_screen_position()
	_update_boxes()
	if characterState.onLeftSide: 
		scale = Vector2(1, 1)
	else:
		scale = Vector2(-1, 1)

func initialize_from_directory(characterDataPath : String) -> bool:
	var characterPath = "res://media/characters/" + characterDataPath + "/characterData.tres"
	if ResourceLoader.exists(characterPath):
		characterData = ResourceLoader.load(characterPath)
		var blankLibraryPath = "res://media/characters/" + characterDataPath + "/anim_library.tres"
		var library = ResourceLoader.load(blankLibraryPath)
		if animationPlayer.has_animation_library(characterData.characterAnimationLibraryPrefix):
			animationPlayer.remove_animation_library(characterData.characterAnimationLibraryPrefix)
		animationPlayer.add_animation_library(characterData.characterAnimationLibraryPrefix, library)
		for move in characterData.characterMoves:
			var commonFolderPath : String = "res://media/characters/all_chara_common/animations/"
			var characterFolderPath : String = "res://media/characters/" + characterDataPath + "/animations/"
			var resourceName : String = commonFolderPath + move.animationName + ".res"
			var commonResourceName : String = characterFolderPath + move.animationName + ".res"
			if ResourceLoader.exists(resourceName):
				var anim = ResourceLoader.load(resourceName)
				animationPlayer.get_animation_library(characterData.characterAnimationLibraryPrefix).add_animation(move.animationName, anim)
			elif ResourceLoader.exists(commonResourceName):
				var anim = ResourceLoader.load(commonResourceName)
				animationPlayer.get_animation_library(characterData.characterAnimationLibraryPrefix).add_animation(move.animationName, anim)
			else:
				print("Animation %s could not be loaded?" % move.animationName)
				print("  Path 1: %s" % resourceName)
				print("  Path 2: %s" % commonResourceName)
		# now load projectiles
		var projectileIndex = 0
		var tempProjectiles = []
		for child in $Projectiles.get_children():
			if child is CharacterProjectile:
				tempProjectiles.push_back(child)
		for projectileType in characterData.characterProjectileTypes:
			var projectilePath = ("res://media/characters/" + characterDataPath + 
				"/projectiles/" + projectileType + "/characterData.tres")
			if !ResourceLoader.exists(projectilePath):
				print("Projectile %s not found at path %s" % [projectileType, projectilePath])
				continue
			else:
				var projectileSetupPath =  characterDataPath + "/projectiles/" + projectileType
				var result = tempProjectiles[projectileIndex].initialize_from_directory(projectileSetupPath)
				projectileIndex += 1
				if result:
					print("Projectile %s loaded successfully" % projectileType)
				else:
					print("Error: projectile %s not found" % projectileType)
				if projectileIndex >= tempProjectiles.size():
					break
		_initialize()
		return true
	else:
		return false
	
func spawn_projectile(projectileType : String, maxDurationTicks : int, offset : Vector2i):
	var projIndex = projectileNameDict[projectileType]
	if projectiles[projIndex].isActive():
		return
	else:
		var projPosition = get_logical_position()
		projPosition.y += offset.y
		if is_on_left_side():
			projPosition.x += offset.x
		else:
			projPosition.x -= offset.x
		var meterGainAllowed = true
		if currentMove and !currentMove.canGainMeter:
			meterGainAllowed = false
		projectiles[projIndex].activate(projPosition, is_on_left_side(), maxDurationTicks, meterGainAllowed)

# Called when the node enters the scene tree for the first time.
func _ready():
	if characterData:
		_initialize()
	_rng.set_seed(hash(Time.get_ticks_usec()))

func _initialize():
	var moveIndex = 0
	moveNameToIndex.clear()
	for move in characterData.characterMoves:
		moveNameToIndex[move.internalName] = moveIndex
		moveIndex += 1
	hitBoxes.clear()
	hurtBoxes.clear()
	projectiles.clear()
	projectileNameDict.clear()
	for child in $HitBoxes.get_children():
		if child is HitBox:
			hitBoxes.push_back(child)	
	for child in $HurtBoxes.get_children():
		if child is HurtBox:
			hurtBoxes.push_back(child)
	for child in $Projectiles.get_children():
		if child is CharacterProjectile:
			if child.isInitialized():
				projectiles.push_back(child)
				projectileNameDict[child.characterData.characterFullName] = projectiles.size() -1
	
func get_sprite() -> Sprite2D:
	return $Sprite2D
	
func is_on_left_side() -> bool:
	return characterState.onLeftSide
	
func set_on_left_side(onLeftSide : bool):
	characterState.onLeftSide = onLeftSide
	
func has_active_install() -> bool:
	return characterState.hasZeroInstallActive or characterState.hasInfinityInstallActive

func update_victory_pose():
	if !is_airborne() and characterState.moveId != ReservedMoveIndex.Victory:
		apply_new_move(characterData.characterMoves[ReservedMoveIndex.Victory])
	
func adjust_move_damage(damage : int) -> int:
	if zeroInstallActive and damage > 0:
		@warning_ignore("integer_division")
		damage = damage * 2 / 3
		damage = max(1, damage)
	return damage
	
func deactivate_boxes():
	pushBox.active = false
	if pushBox.is_mirrored():
		pushBox.mirror()
	for hitBox in hitBoxes:
		hitBox.active = false
		hitBox.moveReactionOnHitGround = GameDatabaseAccessor.defaultGroundHitReaction
		hitBox.moveReactionOnHitAir = GameDatabaseAccessor.defaultAirHitReaction
		hitBox.hitReactionGroundCode = 0
		hitBox.hitReactionAirCode = 1
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
	characterState.meterBroken = false
	disable_all_installs()
	#infinityInstallActive = false
	#zeroInstallActive = false
	
	deactivate_boxes()
	apply_new_move( characterData.characterMoves[characterState.moveId] )
	update_screen_position()
	_update_boxes()

func reset_character_to_idle_full_health():
	characterState.currentHealth = characterData.characterMaxHealth
	characterState.currentMeter =  characterData.characterMaxMeter
	characterState.meterBroken = false
	#infinityInstallActive = false
	#zeroInstallActive = false
	disable_all_installs()
	characterState.logicalVelocity = Vector2i(0, 0)
	characterState.logicalAcceleration = Vector2i(0, 0)
	characterState.comboCounter = 0
	characterState.bounceCounter = 0
	characterState.affectedByHitFreeze = false
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
	animationPlayer.set_current_animation(characterData.characterAnimationLibraryPrefix + "/" + currentMove.animationName)
	set_animation_frame(characterState.currentFrame)

func tick_animation_forward():
	characterState.currentFrame += 1
	set_animation_frame(characterState.currentFrame)
	_update_boxes()

func apply_move_by_name(moveName : String) -> bool:
	if moveNameToIndex.has(moveName):
		apply_new_move(characterData.characterMoves[moveNameToIndex[moveName]])
		return true
	return false

func activate_meter_break():
	characterState.meterBroken = true
	characterState.currentMeter = 0
	characterState.hasInfinityInstallActive = false
	characterState.hasZeroInstallActive = false
	characterState.installDurationFrameCounter = -1
	
func apply_new_move(move : CharacterMove):
	deactivate_boxes()
	if move.meterCost > characterState.currentMeter:
		activate_meter_break()
	if move.forcedMeterBreak:
		activate_meter_break()
	add_meter(-move.meterCost)
	characterState.currentMoveHasHit = false
	characterState.moveId = moveNameToIndex[move.internalName]
	animationPlayer.set_current_animation(characterData.characterAnimationLibraryPrefix + "/" + move.animationName)
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
	_play_sound_if_needed()
	
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
	characterState.logicalVelocity.x = max(
		-GameDatabaseAccessor.characterAbsVelocityCapX, 
		min(GameDatabaseAccessor.characterAbsVelocityCapX, characterState.logicalVelocity.x))	

#func _update_install_aura():
	#$Aura.visible = has_active_install()
	#if has_active_install():
		#$Aura.scale = get_sprite().scale
		#$Aura.texture = get_sprite().texture
		#$Aura.offset = get_sprite().offset
		#$Aura.z_index = get_sprite().z_index
		#$Aura.hframes = get_sprite().hframes
		#$Aura.vframes = get_sprite().vframes
		#$Aura.frame = get_sprite().frame
		#var zoomLevel : float = 0.9
		#if characterState.installDurationFrameCounter % 20 < 10:
			#zoomLevel = 1.1
		#$Aura.scale = Vector2(zoomLevel * $Aura.scale.x, zoomLevel * $Aura.scale.y)
			
func _update_character_installs():
	if has_active_install() and characterState.installDurationFrameCounter >= 0:
		#print(characterState.installDurationFrameCounter)
		characterState.installDurationFrameCounter -= 1
		if characterState.installDurationFrameCounter < 0:
			disable_all_installs()
			#infinityInstallActive = false
			#zeroInstallActive = false	
	#_update_install_aura()

func disable_all_installs():
	characterState.hasInfinityInstallActive = false
	characterState.hasZeroInstallActive = false
	characterState.installDurationFrameCounter = -1
	
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
		hitBox.moveReactionOnHitGround = hitBox.HitReactionDict[hitBox.hitReactionGroundCode]
		hitBox.moveReactionOnHitAir = hitBox.HitReactionDict[hitBox.hitReactionAirCode]
		if characterState.currentMoveHasHit and hitBox.deactivateOnHit:
			hitBox.active = false

func can_perform_move(moveToTest : CharacterMove) -> bool:
	if characterState.roundState == SceneGame.RoundPhaseState.PostMatchMenu:
		return false
	if ((characterState.roundState == SceneGame.RoundPhaseState.Ko or 
		characterState.roundState == SceneGame.RoundPhaseState.PreKo) and 
		!moveToTest.canBeUsedAfterRoundEnds):
		return false
	if (characterState.roundState == SceneGame.RoundPhaseState.Ready or
		characterState.roundState == SceneGame.RoundPhaseState.Engage):
			if !moveToTest.canBeUsedBeforeRoundBegins:
				return false
	if moveToTest.meterCost > characterState.currentMeter and (
		characterState.meterBroken or !moveToTest.canMeterBreak):
		return false
	if moveToTest.requiresInfinityInstall and !infinityInstallActive:
		return false
	if moveToTest.requiresZeroInstall and !zeroInstallActive:
		return false
	if moveToTest.requiresAnyInstall and !has_active_install():
		return false
	return true

func can_be_updated():
	return !characterState.affectedByHitFreeze

func can_be_dealt_damage() -> bool:
	return characterState.roundState == SceneGame.RoundPhaseState.ActiveMatch

func can_gain_meter() -> bool:
	if has_active_install():
		return false
	if characterState.meterBroken:
		return false
	return characterState.roundState == SceneGame.RoundPhaseState.ActiveMatch

func in_hit_stun() -> bool:
	return currentMove	and currentMove.isHitStunState

func play_wall_bounce_sound():
	var pitchModulationCoeff : float = _rng.randf_range(-1,1)
	var pitch = wallbounceSound.pitch + 0.05 * pitchModulationCoeff
	if inNetworkMatch:
			var soundInfo := {
				'volume_db' : GlobalOptions.get_sfx_volume(),
				'pitch_scale' : pitch
			}
			SyncManager.play_sound(wallbounceSound.soundIdString, wallbounceSound.soundRes, soundInfo)
	else:
		audioPlayer.stream = wallbounceSound.soundRes
		audioPlayer.pitch_scale = pitch
		audioPlayer.volume_db = GlobalOptions.get_sfx_volume()
		audioPlayer.play()

func _play_sound_if_needed():
	if !currentMove:
		return
	var soundToPlay : SoundAtFrame = currentMove.sound_to_play_at_frame(characterState.currentFrame)
	if soundToPlay:
		var pitchModulationCoeff : float = _rng.randf_range(-1,1)
		var pitch = soundToPlay.pitch + 0.05 * pitchModulationCoeff
		if inNetworkMatch:
				var soundInfo := {
					'volume_db' : GlobalOptions.get_sfx_volume(),
					'pitch_scale' : pitch
				}
				SyncManager.play_sound(soundToPlay.soundIdString, soundToPlay.soundRes, soundInfo)
		else:
			#if audioPlayer.playing:
				#if audioPlayer.stream == soundToPlay.soundRes:
					#return
			audioPlayer.stream = soundToPlay.soundRes
			audioPlayer.pitch_scale = pitch
			audioPlayer.volume_db = GlobalOptions.get_sfx_volume()
			audioPlayer.play()
	

func _update_current_move( inputManager : InputBufferManager, extraLeniency : int = 0 ):
	if !currentMove	or !currentMove.isHitStunState:
		characterState.bounceCounter = 0
		characterState.affectedByHitFreeze = false
	if is_ko():
		if characterState.moveId != ReservedMoveIndex.Ko:
			if !is_airborne():
				apply_new_move(characterData.characterMoves[ReservedMoveIndex.Ko])
		return
	if currentMove:
		var newMovePerformed := false
		characterState.currentFrame += 1
		set_animation_frame(characterState.currentFrame)
		_play_sound_if_needed()
		# spawn projectiles if needed
		#print( currentMove.spawnProjectileAtFrame)
		if currentMove.spawnProjectileAtFrame.has(characterState.currentFrame):
			var offset : Vector2i = currentMove.spawnProjectileAtFrame[characterState.currentFrame]["offset"]
			var projType : String = currentMove.spawnProjectileAtFrame[characterState.currentFrame]["projType"]
			var duration : int = currentMove.spawnProjectileAtFrame[characterState.currentFrame]["duration"]
			spawn_projectile(projType, duration, offset)
		# look for followups
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
			if followup.autoCancelWhenValid:
				apply_new_move(moveToTest)
				newMovePerformed = true
			else:
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
					#print(moveToTest.internalName)
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
	_update_character_installs()
	_update_current_move(inputManager, extraInputLeniency)
	_update_character_logical_position()
	_update_character_stance()
	update_screen_position()
	_update_boxes()
					
func update_projectiles(  inputManager : InputBufferManager, extraInputLeniency : int = 0):
	for projectile in projectiles:
		projectile.initialLogicalPosition = initialLogicalPosition
		if projectile.can_be_updated():
			projectile.update(inputManager, extraInputLeniency)

