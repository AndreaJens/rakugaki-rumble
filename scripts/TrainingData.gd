class_name TrainingModeStatsContainer extends Control

var _maxComboHitNumber : int = 0
var _currentComboHitNumber : int = 0
var _currentComboDamageValue : int = 0
var _maxComboDamageValue : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if visible:
		_update_labels()

func _update_values(character : Character):
	if character.characterState.comboCounter > _maxComboHitNumber:
		_maxComboHitNumber = character.characterState.comboCounter
	if character.characterState.comboDamage > _maxComboDamageValue:
		_maxComboDamageValue = character.characterState.comboDamage
	if character.characterState.comboCounter > 0:
		_currentComboHitNumber = character.characterState.comboCounter
	if character.characterState.comboDamage > 0:
		_currentComboDamageValue = character.characterState.comboDamage

func _update_labels():
	$Grid/MaxComboCountLabel.text = str(_maxComboHitNumber)
	$Grid/MaxComboDamageValueLabel.text = str(_maxComboDamageValue)
	$Grid/CurrentComboCountLabel.text = str(_currentComboHitNumber)
	$Grid/ComboDamageValueLabel.text = str(_currentComboDamageValue)

