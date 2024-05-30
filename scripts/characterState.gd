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
@export var comboCounter : int = 0
@export var roundState : SceneGame.RoundPhaseState = SceneGame.RoundPhaseState.ActiveMatch

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
		CharacterStateValues.RoundPhaseState : roundState,
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
	comboCounter = state[CharacterStateValues.ComboCounter]
	roundState = state[CharacterStateValues.RoundPhaseState]
