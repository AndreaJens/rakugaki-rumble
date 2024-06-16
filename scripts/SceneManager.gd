extends Node

#var current_scene = null
enum SceneType {
	Title, 
	MainMenu, 
	CharacterSelectionTraining, 
	CharacterSelectionMultiplayer, 
	CharacterSelectionVsCpu, 
	ModeSelection, 
	SingleMatchMultiplayer, 
	Training, 
	SingleMatchVsCpu,
	NetplayMenu,
	Quit}

signal switch_scene(String, SceneType)
signal scene_switched

var sceneTypeToPath = {
	SceneType.ModeSelection : "res://media/scenes/scene_mode_selection.tscn",
	SceneType.CharacterSelectionTraining : "res://media/scenes/scene_character_selection.tscn",
	SceneType.CharacterSelectionVsCpu : "res://media/scenes/scene_character_selection.tscn",
	SceneType.CharacterSelectionMultiplayer : "res://media/scenes/scene_character_selection.tscn",
	SceneType.SingleMatchMultiplayer : "res://media/scenes/scene_game.tscn",
	SceneType.SingleMatchVsCpu : "res://media/scenes/scene_game.tscn",
	SceneType.NetplayMenu : "res://media/scenes/netplay_menu.tscn",
	SceneType.Training : "res://media/scenes/scene_game.tscn",
}

func goto_scene(path, type):
	emit_signal("switch_scene", path, type)
	#get_tree().change_scene_to_file(path)

func goto_scene_type(scene_type : SceneType):
	if scene_type == SceneType.Quit:
		get_tree().quit()
		return
	elif sceneTypeToPath.has(scene_type):
		goto_scene(sceneTypeToPath[scene_type], scene_type)
		
func _on_scene_switched():
	emit_signal("scene_switched")
#func _ready():
#	var root = get_tree().root
#	current_scene = root.get_child(root.get_child_count() - 1)
#
#func goto_scene_type(scene_type : SceneType):
#	if sceneTypeToPath.has(scene_type):
#		goto_scene(sceneTypeToPath[scene_type])
#
#func goto_scene(path):
#	# This function will usually be called from a signal callback,
#	# or some other function in the current scene.
#	# Deleting the current scene at this point is
#	# a bad idea, because it may still be executing code.
#	# This will result in a crash or unexpected behavior.
#
#	# The solution is to defer the load to a later time, when
#	# we can be sure that no code from the current scene is running:
#
#	call_deferred("_deferred_goto_scene", path)
#
#
#func _deferred_goto_scene(path):
#	# It is now safe to remove the current scene
#	current_scene.queue_free()
#
#	# Load the new scene.
#	var s = ResourceLoader.load(path)
#
#	# Instance the new scene.
#	current_scene = s.instantiate()
#
#	# Add it to the active scene, as child of root.
#	get_tree().root.add_child(current_scene)
#
#	# Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
#	get_tree().current_scene = current_scene
