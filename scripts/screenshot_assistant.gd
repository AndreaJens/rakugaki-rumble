class_name ScreenshotAssistant extends Node

enum ImageFormat {
	PNG, 
	JPG
	}

const SCREENSHOT_DIRECTORY = "user://screenshots"
@export var imageFormat : ImageFormat = ImageFormat.PNG

func take_screenshot(node : Node = self) -> bool:
	if DirAccess.dir_exists_absolute(SCREENSHOT_DIRECTORY) == false:
		DirAccess.make_dir_absolute(SCREENSHOT_DIRECTORY)
	if node and node.get_viewport() and node.get_viewport().get_texture():
		var capture = node.get_viewport().get_texture().get_image()
		var datetime : String = Time.get_datetime_string_from_system(true)
		datetime = datetime.replace(":", "")
		datetime = datetime.replace("-", "")
		var format : String
		match(imageFormat):
			ImageFormat.PNG:
				format = "png"
			ImageFormat.JPG:
				format = "jpg"
		var filename = SCREENSHOT_DIRECTORY + ("/RakuRan-%s.%s" % [datetime, format])
		var outcome : Error = Error.ERR_PRINTER_ON_FIRE
		match(imageFormat):
			ImageFormat.PNG:
				outcome = capture.save_png(filename)
			ImageFormat.JPG:
				outcome = capture.save_jpg(filename)
		return outcome == Error.OK
	else:
		return false
