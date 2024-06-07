extends Node2D

@export var systemMessageLabel : Label
@export var syncingMessageLabel : Label
@export var ipAddressField : LineEdit
@export var portField : LineEdit
@export var playerNameField : LineEdit
@export var connectionUILayer : CanvasLayer
@export var characterNameSprite : Sprite2D
@export var sceneParentNode : Node2D
@export var charaSelectMenu : MenuButton
@export var sceneToInstantiate : PackedScene

const LOG_FILE_DIRECTORY := "user://rollback_logs"
var logging_enabled : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	NetworkAssistant.connectedPlayers.clear()
	charaSelectMenu.get_popup().hide_on_checkable_item_selection = false
	_setup_network_connection_callbacks()

func _setup_network_connection_callbacks():
	multiplayer.peer_connected.connect(_on_network_peer_connected)
	multiplayer.peer_disconnected.connect(_on_network_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	SyncManager.sync_started.connect(_on_SyncManager_sync_started)
	SyncManager.sync_lost.connect(_on_SyncManager_sync_lost)
	SyncManager.sync_regained.connect(_on_SyncManager_sync_regained)
	SyncManager.sync_error.connect(_on_SyncManager_sync_error)
	SyncManager.sync_stopped.connect(_on_SyncManager_sync_stopped)
	NetworkAssistant.connectedPlayers.clear()
	ipAddressField.text = NetworkAssistant.ipAddress
	portField.text = NetworkAssistant.port
	playerNameField.text = NetworkAssistant.nameToDisplay

func _setup_game_scene_online():
	var scene = sceneToInstantiate.instantiate() as SceneGame
	scene.preventDeath = false
	scene.debugMode = false
	scene.networkMode = true
	scene.hitFreezeComboFrames = 10
	scene.hitFreezeWallFrames = 10
	scene.hitFreezeDownSpikeFrames = 20
	scene.roundsToWin = NetworkAssistant.numberOfRounds
	scene.close_network_session.connect(_close_session)
	scene.additionalSceneStartupParameters = {
		SceneGame.AdditionalGameSceneStartupParameter.Character1Path : NetworkAssistant.character1Path,
		SceneGame.AdditionalGameSceneStartupParameter.Character2Path : NetworkAssistant.character2Path,
	}
	if NetworkAssistant.localPlayerId == NetworkAssistant.NetworkPlayer.Player1:
		scene.additionalSceneStartupParameters[SceneGame.AdditionalGameSceneStartupParameter.Player1DeviceId] = NetworkAssistant.localPlayerDeviceId
	elif NetworkAssistant.localPlayerId == NetworkAssistant.NetworkPlayer.Player2:
		scene.additionalSceneStartupParameters[SceneGame.AdditionalGameSceneStartupParameter.Player2DeviceId] = NetworkAssistant.localPlayerDeviceId
	sceneParentNode.add_child(scene)
	for i in NetworkAssistant.connectedPlayers:
		if NetworkAssistant.connectedPlayers[i]["player_side"] == 1:
			scene.inputManagerP2.set_multiplayer_authority(i)
			print("Authorithy for Player 2 is Peer %s" % i)
		elif NetworkAssistant.connectedPlayers[i]["player_side"] == -1:
			scene.inputManagerP1.set_multiplayer_authority(i)
			print("Authorithy for Player 1 is Peer %s" % i)
	syncingMessageLabel.visible = false
	#SyncManager.start()
	
func _setup_game_scene_offline():
	var scene = sceneToInstantiate.instantiate()
	scene.preventDeath = false
	scene.debugMode = false
	scene.networkMode = true
	scene.roundsToWin = NetworkAssistant.numberOfRounds
	scene.additionalSceneStartupParameters = {
		SceneGame.AdditionalGameSceneStartupParameter.Character1Path : NetworkAssistant.character1Path,
		SceneGame.AdditionalGameSceneStartupParameter.Character2Path : NetworkAssistant.character2Path,
		SceneGame.AdditionalGameSceneStartupParameter.Player1DeviceId : 0,
		SceneGame.AdditionalGameSceneStartupParameter.Player2DeviceId : 1,
	}
	sceneParentNode.add_child(scene)
	SyncManager.input_delay = 0

@rpc("any_peer")
func _send_player_info(peer_id : int, playerSide : int, characterPath : String):
	if !NetworkAssistant.connectedPlayers.has(peer_id):
		NetworkAssistant.connectedPlayers[peer_id] = {
			"peer_id" : peer_id,
			"player_side" : playerSide,
			"character_path" : characterPath,
		}
		if playerSide == 1:
			NetworkAssistant.character2Path = characterPath
			print("New character 2 path received: %s" % characterPath)
		elif playerSide == -1:
			NetworkAssistant.character1Path = characterPath
			print("New character 1 path received: %s" % characterPath)
	if multiplayer.is_server():
		for i in NetworkAssistant.connectedPlayers:
			print("Sending info to peer %s" % i)
			_send_player_info.rpc(i, NetworkAssistant.connectedPlayers[i]["player_side"], NetworkAssistant.connectedPlayers[i]["character_path"])

@rpc("any_peer", "call_local", "reliable")
func _start_online_match(_peer_id : int):
	pass

func _on_host_button_pressed():
	NetworkAssistant.localPlayerId = NetworkAssistant.NetworkPlayer.Player1
	NetworkAssistant.character1Path = charaSelectMenu._get_selected_character()
	SyncManager.reset_network_adaptor()
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(portField.text as int, 1)
	multiplayer.multiplayer_peer = peer
	syncingMessageLabel.visible = true
	connectionUILayer.visible = false
	_send_player_info(multiplayer.get_unique_id(), -1, NetworkAssistant.character1Path)
	NetworkAssistant.ipAddress = ipAddressField.text
	NetworkAssistant.nameToDisplay = playerNameField.text

func _on_client_button_pressed():
	NetworkAssistant.localPlayerId = NetworkAssistant.NetworkPlayer.Player2
	NetworkAssistant.character2Path = charaSelectMenu._get_selected_character()
	SyncManager.reset_network_adaptor()
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ipAddressField.text, portField.text as int)
	multiplayer.multiplayer_peer = peer
	systemMessageLabel.text = "LOOKING FOR HOST..."
	systemMessageLabel.visible = true
	connectionUILayer.visible = false
	
func _on_network_peer_connected(peer_id : int):
	systemMessageLabel.text = "CONNECTED"
	_send_player_info.rpc_id(1, multiplayer.get_unique_id(), 1, NetworkAssistant.character2Path)
	print(multiplayer.get_unique_id())
	SyncManager.add_peer(peer_id)
	if multiplayer.is_server():
		systemMessageLabel.text = "STARTING SERVER..."
		_start_online_match.rpc(peer_id)
		await(get_tree().create_timer(2.0).timeout)
		SyncManager.input_delay = 1
		SyncManager.start()
	
func _on_connected_to_server():
	_send_player_info.rpc_id(1, multiplayer.get_unique_id(), 1, NetworkAssistant.character2Path)
	
func _on_network_peer_disconnected(_peer_id : int):
	pass
	
func _on_SyncManager_sync_started():
	_setup_game_scene_online()
	systemMessageLabel.text = "SYNC STARTED"
	if logging_enabled and not SyncReplay.active:
		if DirAccess.dir_exists_absolute(LOG_FILE_DIRECTORY) == false:
			DirAccess.make_dir_absolute(LOG_FILE_DIRECTORY)
			
		#var datetime = Time.get_datetime_string_from_system()
		var log_file_name = "debuglog" + str(multiplayer.get_unique_id()) + ".log"
		print(LOG_FILE_DIRECTORY + "/" + log_file_name)
		SyncManager.start_logging(LOG_FILE_DIRECTORY + "/" + log_file_name)
		
	
func _on_SyncManager_sync_lost():
	syncingMessageLabel.visible = true
	
func _on_SyncManager_sync_regained():
	syncingMessageLabel.visible = false

func _on_SyncManager_sync_error(msg : String):
	systemMessageLabel.text = "Sync Error: " + msg
	NetworkAssistant.close_session()
	await(get_tree().create_timer(1.0).timeout)
	_reset_scene()

func _on_SyncManager_sync_stopped() -> void:
	if logging_enabled:
		SyncManager.stop_logging()
		print("stopped logging")

func _on_hide_ip_toggle_toggled(toggled_on):
	if toggled_on == true:
		ipAddressField.secret = true
	else:
		ipAddressField.secret = false

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_F10:
			_close_session()

func _close_session():
	NetworkAssistant.close_session()
	_reset_scene()

func _reset_scene():
	for child in sceneParentNode.get_children():
		if child is SceneGame:
			child.close_network_session.disconnect(_close_session)
		sceneParentNode.remove_child(child)
		child.queue_free()
	connectionUILayer.visible = true
	syncingMessageLabel.visible = false
	systemMessageLabel.visible = false

func _on_log_toggle_toggled(toggled_on):
	if toggled_on == true:
		logging_enabled = true
	else:
		logging_enabled = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	characterNameSprite.texture = charaSelectMenu._get_selected_texture()

func _on_back_to_menu_button_button_up():
	SceneManager.goto_scene_type(SceneManager.SceneType.ModeSelection)
