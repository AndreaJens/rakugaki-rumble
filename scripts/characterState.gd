class_name CharacterState extends Node

enum CharacterStateValues{
	MoveId = 0,
	CurrentFrame = 1,
	CurrentHealth = 2,
	CurrentMeter = 3,
	CurrentStance = 4,
	LogicalPositionX = 5,
	LogicalPositionY = 6,
	LogicalVelocityX = 7,
	LogicalVelocityY = 8,
	LogicalAccelerationX = 9,
	LogicalAccelerationY = 10,
	CurrentMoveHasHit = 11,
	IsOnLeftSide = 12,
	ComboCounter = 13,
	RoundPhaseState = 14,
	BounceCounter = 15,
	AffectedByHitFreeze = 16,
	InfinityInstallActive = 17,
	ZeroInstallActive = 18,
	InstallFrameCounter = 19,
	ComboDamage = 20,
	MeterBroken = 21,
}

enum WallBounceId {
	None = 0,
	Left = 0,
	Right = 0,
}

@export var logicalPosition : Vector2i = Vector2i(0, 0)
@export var logicalVelocity : Vector2i = Vector2i(0, 0)
@export var logicalAcceleration : Vector2i = Vector2i(0, 0)
@export var moveId : int = -1
@export var currentFrame : int = 0
@export var currentHealth : int = 0
@export var currentMeter : int = 0
@export var characterStanceType : Character.State = Character.State.Ground
@export var currentMoveHasHit : bool = false
@export var onLeftSide : bool = false
@export var comboDamage : int = 0
@export var comboCounter : int = 0
@export var bounceCounter : int = 0
@export var affectedByHitFreeze : bool = false
@export var roundState : SceneGame.RoundPhaseState = SceneGame.RoundPhaseState.ActiveMatch
@export var hasInfinityInstallActive : bool = false
	#set(value):
		#if !value:
			#print("wtf?")
		#hasInfinityInstallActive = value
@export var hasZeroInstallActive : bool = false
@export var installDurationFrameCounter : int = -1
@export var meterBroken : bool = false

func _save_state() -> Dictionary:
	return {
		CharacterStateValues.MoveId : moveId, 
		CharacterStateValues.CurrentFrame : currentFrame, 
		CharacterStateValues.CurrentHealth : currentHealth, 
		CharacterStateValues.CurrentMeter : currentMeter, 
		CharacterStateValues.LogicalPositionX : logicalPosition.x, 
		CharacterStateValues.LogicalPositionY :	logicalPosition.y,
		CharacterStateValues.LogicalVelocityX : logicalVelocity.x,
		CharacterStateValues.LogicalVelocityY : logicalVelocity.y,
		CharacterStateValues.LogicalAccelerationX : logicalAcceleration.x, 
		CharacterStateValues.LogicalAccelerationY : logicalAcceleration.y,
		CharacterStateValues.CurrentStance : characterStanceType,
		CharacterStateValues.CurrentMoveHasHit : currentMoveHasHit,
		CharacterStateValues.IsOnLeftSide : onLeftSide,
		CharacterStateValues.ComboCounter : comboCounter,
		CharacterStateValues.ComboDamage : comboDamage,
		CharacterStateValues.RoundPhaseState : roundState,
		CharacterStateValues.BounceCounter : bounceCounter,
		CharacterStateValues.AffectedByHitFreeze : affectedByHitFreeze,
		CharacterStateValues.InfinityInstallActive : hasInfinityInstallActive,
		CharacterStateValues.ZeroInstallActive : hasZeroInstallActive,
		CharacterStateValues.InstallFrameCounter : installDurationFrameCounter,
		CharacterStateValues.MeterBroken : meterBroken,
	}

func _load_state( state : Dictionary ) -> void:
	moveId = state[CharacterStateValues.MoveId]
	currentFrame = state[CharacterStateValues.CurrentFrame]
	currentHealth = state[CharacterStateValues.CurrentHealth]
	currentMeter = state[CharacterStateValues.CurrentMeter]
	logicalPosition = Vector2i( state[CharacterStateValues.LogicalPositionX], 
								state[CharacterStateValues.LogicalPositionY] )
	logicalVelocity = Vector2i( state[CharacterStateValues.LogicalVelocityX], 
								state[CharacterStateValues.LogicalVelocityY] )
	logicalAcceleration = Vector2i( state[CharacterStateValues.LogicalAccelerationX], 
									state[CharacterStateValues.LogicalAccelerationY] )
	@warning_ignore("int_as_enum_without_cast")
	characterStanceType = state[CharacterStateValues.CurrentStance]
	currentMoveHasHit = state[CharacterStateValues.CurrentMoveHasHit]
	onLeftSide = state[CharacterStateValues.IsOnLeftSide]
	comboDamage = state[CharacterStateValues.ComboDamage]
	comboCounter = state[CharacterStateValues.ComboCounter]
	bounceCounter = state[CharacterStateValues.BounceCounter]
	roundState = state[CharacterStateValues.RoundPhaseState]
	affectedByHitFreeze = state[CharacterStateValues.AffectedByHitFreeze]
	hasInfinityInstallActive = state[CharacterStateValues.InfinityInstallActive]
	hasZeroInstallActive = state[CharacterStateValues.ZeroInstallActive]
	installDurationFrameCounter = state[CharacterStateValues.InstallFrameCounter]
	meterBroken = state[CharacterStateValues.MeterBroken]
