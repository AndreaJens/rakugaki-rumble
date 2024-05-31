class_name HudManager extends Control

enum SystemMessage {
	Ko,
	Ready,
	Engage
}

@export var koTexture : Texture2D
@export var readyTexture : Texture2D
@export var engageTexture : Texture2D
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
	$Infinity1.visible = character1.infinityInstallActive
	$Infinity2.visible = character2.infinityInstallActive
	var scaleVal : float = 0.6 + 0.2 * (internalUpdateTick % 20) / 20.0
	$Infinity1.scale = Vector2(scaleVal, scaleVal)
	$Infinity2.scale = Vector2(scaleVal, scaleVal)

	if updateSystemMessages:
		systemMessageManager.update()

func update_combo_counter_zoom(zoomLevel : float):
	$ComboCounter1.scale.x = zoomLevel
	$ComboCounter2.scale.x = zoomLevel
	
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
