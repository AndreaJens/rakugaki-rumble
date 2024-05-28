class_name CharacterMove extends Resource

@export var characterState : Character.State
@export var internalName : String
@export var displayName : String
@export var animationName : String
@export var startingFrame : int
@export var endingFrame : int
@export var isHitStunState := false
@export var keepMomentumPercent : int = 0
@export var loop : bool
@export var canTurnMidMove : bool = false
@export var logicalVelocityPerFrame : Vector2i
@export var logicalAccelerationPerFrame : Vector2i
@export var input : Array[GameDatabaseAccessor.GameInputButton]
@export var cancelRoutes : Array[MoveCancelRoute] = []
@export var guardFrames := Vector2i(-1, -1) 
@export var bufferStartLeniency := 3
@export var bufferLengthLeniency := 10
@export var useRawBuffer := false

func check_input_match(inputBuffer : Array[int], onLeftSide : bool = true) -> bool:
	if input.is_empty():
		return false
	if inputBuffer.size() < input.size():
		return false
	var inputLength = input.size()
	var bufferLength = inputBuffer.size()
	var lowerBound = max(-1, bufferLength - bufferLengthLeniency - bufferStartLeniency)
	var startupLeniencyCounter = 0
	var numberOfMatches = 0
	for i in range(inputLength - 1, -1, -1):
		var inputToCheck = input[i]
		if !onLeftSide:
			# apply side correction
			if inputToCheck & GameDatabaseAccessor.GameInputButton.Right:
				@warning_ignore("int_as_enum_without_cast")
				inputToCheck |= GameDatabaseAccessor.GameInputButton.Left
				@warning_ignore("int_as_enum_without_cast")
				inputToCheck &= ~GameDatabaseAccessor.GameInputButton.Right
			elif inputToCheck & GameDatabaseAccessor.GameInputButton.Left:
				@warning_ignore("int_as_enum_without_cast")
				inputToCheck |= GameDatabaseAccessor.GameInputButton.Right
				@warning_ignore("int_as_enum_without_cast")
				inputToCheck &= ~GameDatabaseAccessor.GameInputButton.Left
			# also for button releases
			if inputToCheck & GameDatabaseAccessor.GameInputButton.ReleaseRight:
				@warning_ignore("int_as_enum_without_cast")
				inputToCheck |= GameDatabaseAccessor.GameInputButton.ReleaseLeft
				@warning_ignore("int_as_enum_without_cast")
				inputToCheck &= ~GameDatabaseAccessor.GameInputButton.ReleaseRight
			elif inputToCheck & GameDatabaseAccessor.GameInputButton.ReleaseLeft:
				@warning_ignore("int_as_enum_without_cast")
				inputToCheck |= GameDatabaseAccessor.GameInputButton.ReleaseRight
				@warning_ignore("int_as_enum_without_cast")
				inputToCheck &= ~GameDatabaseAccessor.GameInputButton.ReleaseLeft
				
		for k in range(bufferLength - 1, lowerBound, -1):
			var currentInput = inputBuffer[k]
			var currentInputIsDirection = currentInput & GameDatabaseAccessor.GameInputButton.AnyDirection
			var inputToCheckIsDirection = inputToCheck & GameDatabaseAccessor.GameInputButton.AnyDirection
			var skipCondition = (
				currentInput == 0 or
				(currentInputIsDirection and !inputToCheckIsDirection) or
				(!currentInputIsDirection and inputToCheckIsDirection)
			)
			if (numberOfMatches == 0 and skipCondition and inputToCheck != 0):
				startupLeniencyCounter += 1
			if startupLeniencyCounter > bufferStartLeniency:
				return false
			if (currentInput & inputToCheck) == inputToCheck:
				numberOfMatches += 1
				break
		if numberOfMatches >= inputLength:
			return true
	return false
