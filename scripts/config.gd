class_name Config
extends Node

# App Information
const APP_NAME = "Vestige"

# GitHub release information
const GITHUB_USERNAME = "LepetitdHomme"
const GITHUB_REPO = "VestigeLauncher"


static func get_current_version() -> String:
	var current_version : String = "v0.0.0"
	var file = FileAccess.open(Config.get_version_file_path(), FileAccess.READ)
	if file:
		current_version = file.get_as_text()

	return current_version.substr(1)


static func get_app_directory() -> String:
	if OS.get_name() == "macOS":
		 # Use the app's user data directory, which is guaranteed to be writable
		return OS.get_user_data_dir()
	else:
		return OS.get_executable_path().get_base_dir()


static func get_app_pck_path() -> String:
	return get_app_directory().path_join("vestige.pck")

static func get_version_file_path() -> String:
	return get_app_directory().path_join(".version")

#static func get_temp_download_path() -> String:
	#return get_app_directory().path_join("temp_download")

static func get_github_latest_release_url() -> String:
	return "https://api.github.com/repos/%s/%s/releases/latest" % [GITHUB_USERNAME, GITHUB_REPO]
