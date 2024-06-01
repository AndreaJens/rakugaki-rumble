class_name HudManager extends Control

enum SystemMessage {
	Ko,
	Ready,
	Engage,
	Matchpoint,
	P1Win,
	P2Win,
	Rematch
}

@export var roundNeutralTexture : Texture2D
@export var roundWonTexture : Texture2D
@export var systemMessageManager : SystemMessageHud
@export var trainingMessage : Sprite2D

@onready var roundCountersP1 : Node2D = $RoundCountersP1
@onready var roundCountersP2 : Node2D = $RoundCountersP2

var _roundCountersP1Nodes = []
var _roundCountersP2Nodes = []
var internalUpdateTick = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_roundCountersP1Nodes.clear()
	_roundCountersP2Nodes.clear()
	for child in roundCountersP1.get_children():
		_roundCountersP1Nodes.push_back(child)
	for child in roundCountersP2.get_children():
		_roundCountersP2Nodes.push_back(child)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func update(character1 : Character, character2 : Character, updateSystemMessages : bool = true):
	internalUpdateTick += 1
	internalUpdateTick %= 6000
	$HpBarChar1.max_value = character1.characterData.characterMaxHealth
	$HpBarChar1.value = character1.characterState.currentHealth
	$HpBarChar2.max_value = character2.characterData.characterMaxHealth
	$HpBarChar2.value = character2.characterState.currentHealth
	if character1.characterState.comboCounter > 0:
		$ComboCounter1.visible = true
	else:
		$ComboCounter1.visible = false
	if character2.characterState.comboCounter > 0:
		$ComboCounter2.visible = true
	else:
		$ComboCounter2.visible = false
	# INSTALLS
	$Infinity1.visible = character1.infinityInstallActive
	$Infinity2.visible = character2.infinityInstallActive
	$Zero1.visible = character1.zeroInstallActive
	$Zero2.visible = character2.zeroInstallActive
	$SpBar1.visible = !character1.has_active_install()
	$SpBar2.visible = !character2.has_active_install()
	$SpBar1/MAX.visible = character1.characterState.currentMeter == character1.characterData.characterMaxMeter 
	$SpBar2/MAX.visible = character2.characterState.currentMeter == character2.characterData.characterMaxMeter
	
	$SpBar1/SuperMeter.max_value = character1.characterData.characterMaxMeter 
	$SpBar2/SuperMeter.max_value = character2.characterData.characterMaxMeter 
	$SpBar1/SuperMeter.value = character1.characterState.currentMeter 
	$SpBar2/SuperMeter.value = character2.characterState.currentMeter 
 
	# check if character is METER BROKEN
	if character1.characterState.meterBroken:
		$SpBar1.visible = false
	if character2.characterState.meterBroken:
		$SpBar2.visible = false
	
	var offsetVal : float = 4.
	if internalUpdateTick % 10 < 5:
		offsetVal = -4.
	$Infinity1.offset = Vector2(offsetVal, 0)
	$Infinity2.offset = Vector2(offsetVal, 0)
	$Zero1.offset = Vector2(offsetVal, 0)
	$Zero2.offset = Vector2(offsetVal, 0)
	$SpBar1/MAX.offset = Vector2(offsetVal, 0)
	$SpBar2/MAX.offset = Vector2(offsetVal, 0)

	if updateSystemMessages:
		systemMessageManager.update()

func update_combo_counter_zoom(zoomLevel : float):
	$ComboCounter1.scale.x = zoomLevel
	$ComboCounter2.scale.x = zoomLevel

func hide_unused_round_counters(maxRoundsToWin : int):
	for i in range(0, _roundCountersP1Nodes.size()):
		if i >= maxRoundsToWin:
			_roundCountersP1Nodes[i].visible = false
			_roundCountersP2Nodes[i].visible = false

func update_round_won(roundWonChar1 : int, roundWonChar2 : int):
	for sprite in _roundCountersP1Nodes:
		sprite.texture = roundNeutralTexture
	for sprite in _roundCountersP2Nodes:
		sprite.texture = roundNeutralTexture
	for index in range(0, min(roundWonChar1, _roundCountersP1Nodes.size())):
		_roundCountersP1Nodes[index].texture = roundWonTexture
	for index in range(0, min(roundWonChar2, _roundCountersP2Nodes.size())):
		_roundCountersP2Nodes[index].texture = roundWonTexture

func show_message(type : SystemMessage):
	systemMessageManager.show_message(type)

func hide_message(instant : bool = false):
	systemMessageManager.hide_message()
	if instant:
		systemMessageManager.disable_message()
