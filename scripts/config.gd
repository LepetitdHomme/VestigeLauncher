class_name Config
extends Node

# App Information
const APP_NAME = "Vestige"
const CURRENT_VERSION = "1.0.0"

# GitHub release information
const GITHUB_USERNAME = "LepetitdHomme"
const GITHUB_REPO = "your-public-releases-repo"

# In config.gd
static func get_app_directory() -> String:
	return OS.get_executable_path().get_base_dir()

static func get_main_app_path() -> String:
	var base_dir = get_app_directory()
	
	# Assuming the app is in a subdirectory called "app"
	match OS.get_name():
		"Windows":
			return base_dir.path_join("app").path_join("app.exe")
		_:
			# For Mac and Linux, use the appropriate binary name
			return base_dir.path_join("app").path_join("app")

static func get_app_pck_path() -> String:
	return get_app_directory().path_join("app").path_join("app.pck")

static func get_version_file_path() -> String:
	return get_app_directory().path_join("version.json")

static func get_temp_download_path() -> String:
	return get_app_directory().path_join("temp_download")

static func get_github_latest_release_url() -> String:
	return "https://api.github.com/repos/%s/%s/releases/latest" % [GITHUB_USERNAME, GITHUB_REPO]
