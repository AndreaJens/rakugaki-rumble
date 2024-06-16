class_name CharacterMove extends Resource

@export var characterState : Character.State
@export var internalName : String
@export var displayName : String
@export_category("Animation")
@export var animationName : String
@export var startingFrame : int
@export var endingFrame : int
@export_category("Logic")
@export var isHitStunState := false
@export var loop : bool
@export var canTurnMidMove : bool = false
@export_category("Movement")
@export var logicalVelocityPerFrame : Vector2i
@export var logicalAccelerationPerFrame : Vector2i
@export var keepMomentumPercent : int = 0
@export_category("Projectiles")
@export var spawnProjectileAtFrame : Dictionary = {}
@export_category("Extra")
@export var canGainMeter : bool = true
@export_category("Conditions")
@export var meterCost : int
@export var canMeterBreak : bool = false
@export var forcedMeterBreak : bool = false
@export var canBeUsedBeforeRoundBegins := false
@export var canBeUsedAfterRoundEnds : bool = false
@export var requiresInfinityInstall : bool = false
@export var requiresZeroInstall : bool = false
@export var requiresAnyInstall : bool = false
@export_category("Move Input")
@export var forbiddenButtons : Array[GameDatabaseAccessor.GameInputButton] = []
@export var bufferStartLeniency := 3
@export var bufferLengthLeniency := 10
@export var useRawBuffer := false
@export var input : Array[GameDatabaseAccessor.GameInputButton]
@export var inputVariant1 : Array[GameDatabaseAccessor.GameInputButton]
@export var inputVariant2 : Array[GameDatabaseAccessor.GameInputButton]
@export var inputVariant3 : Array[GameDatabaseAccessor.GameInputButton]
@export_category("Cancels")
@export var cancelRoutes : Array[MoveCancelRoute] = []
@export var guardFrames := Vector2i(-1, -1) 
@export_category("Extra Effects")
@export var timestopFrames := 0

#func _conditional_print(value):
	#if internalName == "attackJumpKnee":
		#print(value)

func check_input_against_buffer(
	moveInput : Array[GameDatabaseAccessor.GameInputButton],
	inputBuffer : Array[int], 
	onLeftSide : bool = true,
	extraLeniency : int = 0 ) -> bool:
	if moveInput.is_empty():
		return false
	if inputBuffer.size() < moveInput.size():
		return false
	var inputLength = moveInput.size()
	var bufferLength = inputBuffer.size()
	var lowerBound = max(-1, bufferLength - bufferLengthLeniency - bufferStartLeniency - extraLeniency)
	var startupLeniencyCounter = 0
	var numberOfMatches = 0
	var currentBufferIndex = bufferLength - 1
	var forbiddenInputRightSide : Array[GameDatabaseAccessor.GameInputButton] = []
	# check for forbidden buttons
	if !forbiddenButtons.is_empty():
		for forbiddenButton in forbiddenButtons:
			var inputToForbid = forbiddenButton
			# apply side correction
			if inputToForbid & GameDatabaseAccessor.GameInputButton.Right:
				@warning_ignore("int_as_enum_without_cast")
				inputToForbid |= GameDatabaseAccessor.GameInputButton.Left
				@warning_ignore("int_as_enum_without_cast")
				inputToForbid &= ~GameDatabaseAccessor.GameInputButton.Right
			elif inputToForbid & GameDatabaseAccessor.GameInputButton.Left:
				@warning_ignore("int_as_enum_without_cast")
				inputToForbid |= GameDatabaseAccessor.GameInputButton.Right
				@warning_ignore("int_as_enum_without_cast")
				inputToForbid &= ~GameDatabaseAccessor.GameInputButton.Left
			# also for button releases
			if inputToForbid & GameDatabaseAccessor.GameInputButton.ReleaseRight:
				@warning_ignore("int_as_enum_without_cast")
				inputToForbid |= GameDatabaseAccessor.GameInputButton.ReleaseLeft
				@warning_ignore("int_as_enum_without_cast")
				inputToForbid &= ~GameDatabaseAccessor.GameInputButton.ReleaseRight
			elif inputToForbid & GameDatabaseAccessor.GameInputButton.ReleaseLeft:
				@warning_ignore("int_as_enum_without_cast")
				inputToForbid |= GameDatabaseAccessor.GameInputButton.ReleaseRight
				@warning_ignore("int_as_enum_without_cast")
				inputToForbid &= ~GameDatabaseAccessor.GameInputButton.ReleaseLeft
			forbiddenInputRightSide.push_back(inputToForbid)
	for i in range(inputLength - 1, -1, -1):
		var inputToCheck = moveInput[i]
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
		var testRangeIndex = currentBufferIndex
		for k in range(testRangeIndex, lowerBound, -1):
			currentBufferIndex = k
			var currentInput = inputBuffer[k]
			var currentInputIsDirection = currentInput & GameDatabaseAccessor.GameInputButton.AnyDirection
			var inputToCheckIsDirection = inputToCheck & GameDatabaseAccessor.GameInputButton.AnyDirection
			var skipCondition = (
				currentInput == 0 or
				(currentInputIsDirection and !inputToCheckIsDirection) or
				(!currentInputIsDirection and inputToCheckIsDirection)
			)
			if (moveInput.size() == 1 or numberOfMatches > 0) and !forbiddenButtons.is_empty():
				if onLeftSide:
					for forbiddenInput in forbiddenButtons:
						if (currentInput & forbiddenInput) == forbiddenInput:
							return false
				else:
					for forbiddenInput in forbiddenInputRightSide:
						if (currentInput & forbiddenInput) == forbiddenInput:
							return false
			if (numberOfMatches == 0 and skipCondition and inputToCheck != 0):
				startupLeniencyCounter += 1
			if startupLeniencyCounter > (bufferStartLeniency + extraLeniency):
				return false
			if (currentInput & inputToCheck) == inputToCheck:
				numberOfMatches += 1
				for j in range(k - 1, lowerBound, -1):
					currentBufferIndex -= 1
					var testInput = inputBuffer[j]
					if (!(testInput & GameDatabaseAccessor.GameInputButton.AnyDirection) or
						testInput != inputBuffer[k]):
							break
				break
		if numberOfMatches >= inputLength:
			return true
	return false

func check_input_match(
	inputBuffer : Array[int], 
	onLeftSide : bool = true,
	extraLeniency : int = 0) -> bool:
	if (check_input_against_buffer(input, inputBuffer, onLeftSide, extraLeniency)):
		return true
	if (!inputVariant1.is_empty()):
		if (check_input_against_buffer(inputVariant1, inputBuffer, onLeftSide, extraLeniency)):
			return true
	if (!inputVariant2.is_empty()):
		if (check_input_against_buffer(inputVariant2, inputBuffer, onLeftSide, extraLeniency)):
			return true
	if (!inputVariant3.is_empty()):
		if (check_input_against_buffer(inputVariant3, inputBuffer, onLeftSide, extraLeniency)):
			return true
	return false
