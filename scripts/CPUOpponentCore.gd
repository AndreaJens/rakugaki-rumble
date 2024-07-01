class_name CpuOpponentCore extends Node

@export var active : bool = false
@export var difficultyLevel : int = 5
@export var ticksBetweenDecisions : int = 20
@export var ticksBetweenInputs : int = 0
@export var actor : Character
@export var opponent : Character
@export var logic : CpuOpponentRuleset = null

var _currentInputSequence : Array[GameDatabaseAccessor.GameInputButton] = []
var _currentInputIndex : int = -1
var _ticksSinceLastDecision : int = -1
var _ticksSinceLastInput : int = 0
var _currentCombo : CpuOpponentCombo = null
var _currentComboIndex : int = -1
var _currentComboLength : int = -1
var _canShuffleNewCombo : bool = true

var _distanceBetweenCharacters : Vector2i
var _rng = RandomNumberGenerator.new()	

func _ready():
	_rng.seed = hash(Time.get_ticks_usec())

func fetch_input_for_next_frame() -> Dictionary:
	# reset canned combo if the character is hit stun
	if (actor.in_hit_stun() or actor.is_ko()) and _currentCombo:
		_reset_combo()
	# reset canned combo if the character hits a neutral state
	if (!opponent.in_hit_stun() and _currentCombo):
		_reset_combo()
	var currentInput : int = 0
	var allPressedButtons : int = 0
	var shuffleNewMove : bool = true
	if !_currentInputSequence.is_empty():
		if _currentInputIndex < _currentInputSequence.size():
			if _ticksSinceLastInput >= ticksBetweenInputs:
				currentInput = _currentInputSequence[_currentInputIndex]
				allPressedButtons = _currentInputSequence[_currentInputIndex]
				_currentInputIndex += 1
				_ticksSinceLastInput = 0
			else:
				currentInput = GameDatabaseAccessor.GameInputButton.None
				allPressedButtons = GameDatabaseAccessor.GameInputButton.None
				_ticksSinceLastInput += 1
			shuffleNewMove = false
		else:
			_currentInputIndex = -1
			_ticksSinceLastInput = ticksBetweenInputs
			_currentInputSequence.clear()
	if _ticksSinceLastDecision > 0:
		_ticksSinceLastDecision -= 1
	else:
		if shuffleNewMove:
			if _currentCombo:
				var newMoveFound : CpuOpponentMove = _get_move_from_combo()
				if newMoveFound:
					currentInput = _currentInputSequence[_currentInputIndex]
					allPressedButtons = _currentInputSequence[_currentInputIndex]
					_currentComboIndex += 1
					if newMoveFound.tickToNextMove >= 0:
						_ticksSinceLastDecision = newMoveFound.tickToNextMove
					else:
						_ticksSinceLastDecision = 0
			else:
				var newCombo = _shuffle_new_combo()
				if !newCombo:
					_canShuffleNewCombo = false
					var newMoveFound : CpuOpponentMove = _shuffle_new_move()
					if newMoveFound and !_currentInputSequence.is_empty():
						currentInput = _currentInputSequence[_currentInputIndex]
						allPressedButtons = _currentInputSequence[_currentInputIndex]
						_ticksSinceLastInput = ticksBetweenInputs
						if newMoveFound.tickToNextMove >= 0:
							_ticksSinceLastDecision = newMoveFound.tickToNextMove
						else:
							_ticksSinceLastDecision = _ticks_between_decisions()
				else:
					_currentCombo = newCombo
					_currentComboIndex = 0
					_currentComboLength = newCombo.moves.size()
					_canShuffleNewCombo = false
					var newMove = _get_move_from_combo()
					if newMove:
						if newMove.tickToNextMove >= 0:
							_ticksSinceLastDecision = newMove.tickToNextMove
						else:
							_ticksSinceLastDecision = 0
						currentInput = _currentInputSequence[_currentInputIndex]
						allPressedButtons = _currentInputSequence[_currentInputIndex]
						_ticksSinceLastInput = ticksBetweenInputs
						_currentComboIndex += 1
					else:
						_reset_combo()
	var outInput : Dictionary = {}
	outInput[InputBufferManager.InputBufferState.AllPressedButtons] = allPressedButtons
	outInput[InputBufferManager.InputBufferState.NewlyPressedButtons] = currentInput
	return outInput

func _reset_combo() -> void:
	_currentCombo = null
	_canShuffleNewCombo = true
	_currentComboLength = -1
	_currentComboIndex = -1

func _get_move_from_combo() -> CpuOpponentMove:
	if !_currentCombo:
		_reset_combo()
		return null
	if _currentComboIndex >= _currentComboLength:
		_reset_combo()
		return null
	if _currentCombo.moves[_currentComboIndex]:
		var allRulesValid := true
		for rule in _currentCombo.moves[_currentComboIndex].conditions:
			allRulesValid = allRulesValid and _check_rule(rule)
			if !allRulesValid:
				return null
		if _move_is_valid(_currentCombo.moves[_currentComboIndex].targetMoveName):
			_set_input_from_move(_currentCombo.moves[_currentComboIndex].targetMoveName)
			return _currentCombo.moves[_currentComboIndex]
		else:
			_reset_combo()
			return null
	return null

func _shuffle_new_combo() -> CpuOpponentCombo:
	if !logic:
		return null
	if !_canShuffleNewCombo:
		return null
	if _rng.randi_range(0, 100) > _combo_likelihood():
		return null
	if actor and opponent:
		_distanceBetweenCharacters = opponent.get_logical_position() - actor.get_logical_position()
	var validCombos : Dictionary = {}
	var currentWeight : int = 0
	for cpuCombo in logic.combos:
		var allRulesValid := true
		for rule in cpuCombo.conditions:
			allRulesValid = allRulesValid and _check_rule(rule)
			if !allRulesValid:
				break
		if allRulesValid:
			currentWeight += cpuCombo.weight
			validCombos[currentWeight] = cpuCombo
	# draw random
	if currentWeight > 0:
		var value = _rng.randi_range(0, currentWeight) 
		var keyArray = validCombos.keys().duplicate()
		keyArray.sort()
		for key in keyArray:
			if value < key:
				return validCombos[key]
	return null

func _shuffle_new_move() -> CpuOpponentMove:
	if !logic:
		return null
	if actor and opponent:
		_distanceBetweenCharacters = opponent.get_logical_position() - actor.get_logical_position()
	var validMoves : Dictionary = {}
	var currentWeight : int = 0
	for cpuMove in logic.moves:
		var allRulesValid := true
		for rule in cpuMove.conditions:
			allRulesValid = allRulesValid and _check_rule(rule)
			if !allRulesValid:
				break
		if allRulesValid:
			currentWeight += cpuMove.weight
			validMoves[currentWeight] = cpuMove
	# draw random
	if currentWeight > 0:
		var value = _rng.randi_range(0, currentWeight) 
		var keyArray = validMoves.keys().duplicate()
		keyArray.sort()
		for key in keyArray:
			if value < key:
				if _move_is_valid(validMoves[key].targetMoveName):
					_canShuffleNewCombo = true
					_set_input_from_move(validMoves[key].targetMoveName)
					return validMoves[key]
				break
	return null
		

func _move_is_valid(moveName : String) -> bool:
	if !actor.moveNameToIndex.has(moveName):
		return false
	var move = actor.characterData.characterMoves[actor.moveNameToIndex[moveName]]
	return actor.can_perform_move(move)

func _ticks_between_decisions() -> int:
	return ticksBetweenDecisions

func _combo_likelihood() -> int:
	return difficultyLevel * 10

func _set_input_from_move(moveName : String):
	if !actor:
		_currentInputSequence.clear()
		_currentInputIndex = -1
	if actor.moveNameToIndex.has(moveName):
		var move = actor.characterData.characterMoves[actor.moveNameToIndex[moveName]]
		_currentInputSequence = move.input.duplicate()
		_currentInputIndex = 0
		if !actor.is_on_left_side():
			for i in range(0, _currentInputSequence.size()):
				var inputToCheck = _currentInputSequence[i]
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
				_currentInputSequence[i] = inputToCheck
		#print(_currentInputSequence)

func _check_rule(rule : CpuOpponentRule) -> bool:
	# TODO: manage all additional rules not covered yet
	match rule.trigger:
		CpuOpponentRule.ConditionTrigger.Always:
			return true
		CpuOpponentRule.ConditionTrigger.CurrentMoveName:
			return _rule_value_check_equality(rule.operator, rule.valueString, actor.currentMove.internalName)
		CpuOpponentRule.ConditionTrigger.TotalDistanceFromOpponent:
			return _rule_value_check(rule.operator, _distanceBetweenCharacters.length(), rule.valueInt)
		CpuOpponentRule.ConditionTrigger.HorizontalDistanceFromOpponent:
			return _rule_value_check(rule.operator, _distanceBetweenCharacters.abs().x, rule.valueInt)
		CpuOpponentRule.ConditionTrigger.VerticalDistanceFromOpponent:
			return _rule_value_check(rule.operator, _distanceBetweenCharacters.abs().y, rule.valueInt)
		CpuOpponentRule.ConditionTrigger.Meter:
			return _rule_value_check(rule.operator, actor.characterState.currentMeter, rule.valueInt)
		CpuOpponentRule.ConditionTrigger.OpponentMeter:
			return _rule_value_check(rule.operator, opponent.characterState.currentMeter, rule.valueInt)
		CpuOpponentRule.ConditionTrigger.Health:
			return _rule_value_check(rule.operator, actor.characterState.currentHealth, rule.valueInt)
		CpuOpponentRule.ConditionTrigger.OpponentHealth:
			return _rule_value_check(rule.operator, opponent.characterState.currentHealth, rule.valueInt)
		CpuOpponentRule.ConditionTrigger.Airborne:
			return _rule_value_check_bool(rule.operator, actor.is_airborne())
		CpuOpponentRule.ConditionTrigger.OpponentIsPerformingAttackMove:
			return _rule_value_check_bool(rule.operator, 
				opponent.currentMove and !opponent.currentMove.canBeUsedBeforeRoundBegins)
		CpuOpponentRule.ConditionTrigger.OpponentAirborne:
			return _rule_value_check_bool(rule.operator, opponent.is_airborne())
		CpuOpponentRule.ConditionTrigger.IsInHitstun:
			return _rule_value_check_bool(rule.operator, actor.in_hit_stun())
		CpuOpponentRule.ConditionTrigger.OpponentInHitStun:
			return _rule_value_check_bool(rule.operator, opponent.in_hit_stun())
		CpuOpponentRule.ConditionTrigger.HasHitOpponent:
			return _rule_value_check_bool(rule.operator, actor.characterState.currentMoveHasHit)
		CpuOpponentRule.ConditionTrigger.CpuLevel:
			return _rule_value_check(rule.operator, difficultyLevel, rule.valueInt)
		CpuOpponentRule.ConditionTrigger.InfinityInstall:
			return _rule_value_check_bool(rule.operator, actor.infinityInstallActive)
		CpuOpponentRule.ConditionTrigger.ZeroInstall:
			return _rule_value_check_bool(rule.operator, actor.zeroInstallActive)
		CpuOpponentRule.ConditionTrigger.AnyInstall:
			return _rule_value_check_bool(rule.operator, actor.has_active_install)
		CpuOpponentRule.ConditionTrigger.OpponentInfinityInstall:
			return _rule_value_check_bool(rule.operator, opponent.infinityInstallActive)
		CpuOpponentRule.ConditionTrigger.OpponentZeroInstall:
			return _rule_value_check_bool(rule.operator, opponent.zeroInstallActive)
		CpuOpponentRule.ConditionTrigger.OpponentAnyInstall:
			return _rule_value_check_bool(rule.operator, opponent.has_active_install())
	return false
	
func _rule_value_check(comparison : CpuOpponentRule.ConditionComparison , value1, value2) -> bool:
		match comparison:
			CpuOpponentRule.ConditionComparison.Equal:
				return value1 == value2
			CpuOpponentRule.ConditionComparison.Different:
				return value1 != value2
			CpuOpponentRule.ConditionComparison.GreaterThan:
				return value1 > value2
			CpuOpponentRule.ConditionComparison.GreaterThanOrEqual:
				return value1 >= value2
			CpuOpponentRule.ConditionComparison.LowerThan:
				return value1 < value2
			CpuOpponentRule.ConditionComparison.LowerThanOrEqual:
				return value1 <= value2
		return false
		
func _rule_value_check_bool(comparison : CpuOpponentRule.ConditionComparison , value) -> bool:
		match comparison:
			CpuOpponentRule.ConditionComparison.Equal:
				return value
			CpuOpponentRule.ConditionComparison.Different:
				return !value
		return false

func _rule_value_check_equality(comparison : CpuOpponentRule.ConditionComparison , value1, value2) -> bool:
		match comparison:
			CpuOpponentRule.ConditionComparison.Equal:
				return value1 == value2
			CpuOpponentRule.ConditionComparison.Different:
				return value1 != value2
		return false

func _process(_delta):
	if !active:
		return
