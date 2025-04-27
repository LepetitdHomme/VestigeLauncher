extends Node

signal update_check_completed(has_update: bool, version_info: Dictionary)
signal download_progress(percent: float)
signal download_completed(success: bool)
signal error_occurred(message: String)

var _http_request: HTTPRequest
var _downloading: bool = false
var _current_release : String = "v0.0.0"
var download_url: String = ""

func _ready():
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	#_http_request.download_progress.connect(_on_download_progress)


func check_for_updates() -> void:
	if not _is_internet_available():
		error_occurred.emit("No internet connection available")
		update_check_completed.emit(false, {})
		return
	
	var url = Config.get_github_latest_release_url()
	var error = _http_request.request(url)
	
	if error != OK:
		error_occurred.emit("Failed to start update check")
		update_check_completed.emit(false, {})


func download_update(download_url: String) -> void:
	if _downloading:
		return

	_downloading = true

	var download_path = Config.get_app_directory().path_join("new_version")
	#
	## Fixed error: separate the assignment from the request
	_http_request.download_file = download_path
	var error = _http_request.request(download_url)
	
	if error != OK:
		print_debug(error)
		_downloading = false
		error_occurred.emit("Failed to start download")
		download_completed.emit(false)


func install_update() -> bool:
	# Extract the downloaded update to the correct location
	var download_path = Config.get_app_directory().path_join("new_version")
	
	# Use gdunzip or another method to extract the ZIP file
	# For simplicity, we'll assume it's just a direct PCK replacement
	
	var dir = DirAccess.open("user://")
	var error = dir.copy(download_path, Config.get_app_pck_path())
	
	if error != OK:
		error_occurred.emit("Failed to install update")
		return false
	
	# Save the new version info
	var file = FileAccess.open(Config.get_version_file_path(), FileAccess.WRITE)
	if file:
		file.store_string(_current_release)
	
	# Clean up temp files
	dir.remove(download_path)
	
	return true



func launch_app() -> void:
	var app_pck_path = Config.get_app_pck_path()
	
	print("PCK path: " + app_pck_path)
	
	if not FileAccess.file_exists(app_pck_path):
		error_occurred.emit("Application PCK not found at: " + app_pck_path)
		return
	
	var launch_success = false
	
	if OS.get_name() == "macOS":
		# On macOS, use create_instance which is designed for this purpose
		# This creates a new instance of the same application with different arguments
		var args = ["--main-pack", app_pck_path]
		print("Creating new instance with args: " + str(args))
		launch_success = OS.create_instance(args)
		print("Create instance result: " + str(launch_success))
	else:
		# On Windows/Linux, use create_process
		var app_path = OS.get_executable_path()
		print("Executable path: " + app_path)
		var pid = OS.create_process(app_path, ["--main-pack", app_pck_path])
		print("Process creation result: " + str(pid))
		launch_success = (pid > 0)
	
	if not launch_success:
		error_occurred.emit("Failed to launch application")
		return
	
	get_tree().quit()


func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if _downloading:
		_downloading = false
		download_completed.emit(result == OK)
		return
	
	if result != OK or response_code != 200:
		error_occurred.emit("Failed to check for updates. Error code: " + str(response_code))
		update_check_completed.emit(false, {})
		return
	
	var json_string = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		error_occurred.emit("Failed to parse update information")
		update_check_completed.emit(false, {})
		return
	
	var release_info = json.get_data()
	#print_debug(release_info)
	_current_release = release_info.get("tag_name", "v0.0.0")

	# Extract version from tag_name (usually in format v1.0.0)
	var remote_version = release_info.get("tag_name", "")
	if remote_version.begins_with("v"):
		remote_version = remote_version.substr(1)
	
	var has_update = _is_newer_version(remote_version, Config.get_current_version())
	#print_debug(remote_version)
	#print_debug(Config.get_current_version())
	update_check_completed.emit(has_update, release_info)


func _on_download_progress(bytes_downloaded: int, total_bytes: int):
	var percent = float(bytes_downloaded) / float(total_bytes) * 100.0 if total_bytes > 0 else 0
	download_progress.emit(percent)


func _is_internet_available() -> bool:
	var http = HTTPClient.new()
	var err = http.connect_to_host("api.github.com", 443)
	return err == OK


func _is_newer_version(remote_version: String, current_version: String) -> bool:
	# Simple semantic version comparison
	var remote_parts = remote_version.split(".")
	var current_parts = current_version.split(".")
	
	for i in range(3):  # Compare major.minor.patch
		var remote_num = int(remote_parts[i]) if i < remote_parts.size() else 0
		var current_num = int(current_parts[i]) if i < current_parts.size() else 0
		
		if remote_num > current_num:
			return true
		elif remote_num < current_num:
			return false
	
	return false  # Versions are equal
