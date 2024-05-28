class_name JoypadAssignment extends Node2D

@export var joyGeneric : Texture2D
@export var joyPlayer1 : Texture2D
@export var joyPlayer2 : Texture2D
@export var readyTex : Texture2D
@export var audioPlayer : AudioStreamPlayer
@export var cursorChime : AudioStream
@export var decisionChime : AudioStream
var joypadIcons : Array[Sprite2D]
var joypadAssigned : bool = false
var player1Confirm : bool = false
var player2Confirm : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in $Joypads.get_children():
		child.visible = false
		joypadIcons.push_back(child)
		
func playCursorChime():
	audioPlayer.stream = cursorChime
	audioPlayer.play()
	
func playDecisionChime():
	audioPlayer.stream = decisionChime
	audioPlayer.play()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if visible:
		var connectedJoypads = Input.get_connected_joypads()
		if InputOverseer.player1DeviceId >= 0:
			if InputOverseer.input_is_action_just_pressed("confirm", InputOverseer.player1DeviceId):
				if !player1Confirm:
					player1Confirm = true
					playDecisionChime()
					$Confirm/ConfirmP1.texture = readyTex
		elif InputOverseer.input_is_action_just_pressed_kb("confirm_p1"):
				player1Confirm = true
				playDecisionChime()
				$Confirm/ConfirmP1.texture = readyTex
		if InputOverseer.player2DeviceId >= 0:
			if InputOverseer.input_is_action_just_pressed("confirm", InputOverseer.player2DeviceId):
				if !player2Confirm:
					player2Confirm = true
					playDecisionChime()
					$Confirm/ConfirmP2.texture = readyTex
		elif InputOverseer.input_is_action_just_pressed_kb("confirm_p2"):
				player2Confirm = true
				playDecisionChime()
				$Confirm/ConfirmP2.texture = readyTex
		if player1Confirm and player2Confirm:
			joypadAssigned = true
		if !joypadAssigned:
			for i in range(0, connectedJoypads.size()):
				joypadIcons[i].visible = true
			for i in range(0, connectedJoypads.size()):
				var joy = connectedJoypads[i]
				if InputOverseer.player1DeviceId == -1 and InputOverseer.player2DeviceId != joy:
					if InputOverseer.input_is_action_just_pressed("move_l", joy):
						InputOverseer.player1DeviceId = joy
						playCursorChime()
						break
				elif InputOverseer.player1DeviceId == joy and !player1Confirm:
					if InputOverseer.input_is_action_just_pressed("move_r", joy):
						InputOverseer.player1DeviceId = -1
						playCursorChime()
						break 
				if InputOverseer.player2DeviceId == -1 and InputOverseer.player1DeviceId != joy:
					if InputOverseer.input_is_action_just_pressed("move_r", joy):
						InputOverseer.player2DeviceId = joy
						playCursorChime()
						break 
				elif InputOverseer.player2DeviceId == joy and !player2Confirm:
					if InputOverseer.input_is_action_just_pressed("move_l", joy):
						InputOverseer.player2DeviceId = -1
						playCursorChime()
						break 
			for i in range(0, connectedJoypads.size()):
				var joy = connectedJoypads[i]
				if i < joypadIcons.size():
					if InputOverseer.player1DeviceId == joy:
						joypadIcons[i].texture = joyPlayer1
						joypadIcons[i].position.x = 320
					elif InputOverseer.player2DeviceId == joy:
						joypadIcons[i].texture = joyPlayer2
						joypadIcons[i].position.x = 960
					else:
						joypadIcons[i].texture = joyGeneric
						joypadIcons[i].position.x = 640	
		
	
