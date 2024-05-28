class_name CharacterState extends Node

@export var logicalPosition : Vector2i = Vector2i(0, 0)
@export var logicalVelocity : Vector2i = Vector2i(0, 0)
@export var logicalAcceleration : Vector2i = Vector2i(0, 0)
@export var moveId : int = -1
@export var currentFrame : int = 0
@export var currentHealth : int = 0
@export var currentMeter : int = 0
@export var currentHitStunCounter : int = 0
@export var characterStanceType : Character.State = Character.State.Ground

func to_state_array() -> Array[int]:
	return [
		moveId, 
		currentFrame, 
		currentHealth, 
		currentMeter, 
		logicalPosition.x, logicalPosition.y,
		logicalVelocity.x, logicalVelocity.y,
		logicalAcceleration.x, logicalAcceleration.y,
		currentHitStunCounter,
		characterStanceType,
	]

func load_from_state_array( state : Array[int] ):
	moveId = state[0]
	currentFrame = state[1]
	currentHealth = state[2]
	currentMeter = state[3]
	logicalPosition = Vector2i( state[4], state[5] )
	logicalVelocity = Vector2i( state[6], state[7] )
	logicalAcceleration = Vector2i( state[8], state[9] )
	currentHitStunCounter = state[10]
	@warning_ignore("int_as_enum_without_cast")
	characterStanceType = state[11]
