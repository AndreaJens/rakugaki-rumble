class_name HudManager extends Control

enum SystemMessage {
	Ko,
	Ready,
	Engage
}

@export var koTexture : Texture2D
@export var readyTexture : Texture2D
@export var engageTexture : Texture2D
@onready var systemMessageBillboard : Sprite2D = $SystemMessage

var messageToTexture = {}
# Called when the node enters the scene tree for the first time.
func _ready():
	messageToTexture = {
		SystemMessage.Ko : koTexture,
		SystemMessage.Ready : readyTexture,
		SystemMessage.Engage : engageTexture,
	}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func update(character1 : Character, character2 : Character):
	if (character1.is_ko() or character2.is_ko()):
		show_message(HudManager.SystemMessage.Ko)
	$HpBarChar1.max_value = character1.characterData.characterMaxHealth
	$HpBarChar1.value = character1.characterState.currentHealth
	$HpBarChar2.max_value = character2.characterData.characterMaxHealth
	$HpBarChar2.value = character2.characterState.currentHealth
	if character1.comboCounter > 0:
		$ComboCounter1.visible = true
	else:
		$ComboCounter1.visible = false
	if character2.comboCounter > 0:
		$ComboCounter2.visible = true
	else:
		$ComboCounter2.visible = false

func updateComboCounterZoom(zoomLevel : float):
	$ComboCounter1.scale.x = zoomLevel
	$ComboCounter2.scale.x = zoomLevel

func show_message(type : SystemMessage):
	systemMessageBillboard.visible = true
	systemMessageBillboard.texture = messageToTexture[type]

func hide_message():
	systemMessageBillboard.visible = false
