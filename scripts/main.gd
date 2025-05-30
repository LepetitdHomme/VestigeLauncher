extends Control

@onready var status_label = $ColorRect/ScrollContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var progress_bar = $ColorRect/ScrollContainer/MarginContainer/VBoxContainer/ProgressBar
@onready var h_box_container_2 = $ColorRect/ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer2
@onready var update_info = $ColorRect/ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer2/TextEdit
@onready var update_button = $ColorRect/ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer/UpdateButton
@onready var skip_button = $ColorRect/ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer/SkipButton
@onready var launch_button = $ColorRect/ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer/LaunchButton


func _ready():
	adjust_viewport()
	# Connect signals from the global UpdateManager singleton
	UpdateManager.update_check_completed.connect(_on_update_check_completed)
	UpdateManager.download_progress.connect(_on_download_progress)
	UpdateManager.download_completed.connect(_on_download_completed)
	UpdateManager.error_occurred.connect(_on_error)
	
	# Connect button signals
	update_button.pressed.connect(_on_update_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	launch_button.pressed.connect(_on_launch_button_pressed)
	
	# Initial UI setup
	progress_bar.visible = false
	update_info.visible = false
	update_button.visible = false
	skip_button.visible = false
	launch_button.visible = false
	
	# Begin update check
	status_label.text = "Checking for updates..."
	UpdateManager.check_for_updates()


func get_ui_scale_factor(dpi: float, screen_size: Vector2) -> float:
	var reference_dpi := 109.0
	var reference_resolution := Vector2(2560, 1440)

	var dpi_ratio := dpi / reference_dpi
	var res_ratio := (screen_size.x * screen_size.y) / (reference_resolution.x * reference_resolution.y)

	var custom_scale := 0.0 * dpi_ratio + 0.8 * res_ratio
	return clamp(custom_scale, 1.0, 2.0)


func adjust_viewport():
	# Reference setup: 2K (2560x1440), ~27", ~109 DPI
	var dpi = DisplayServer.screen_get_dpi()
	var screen_size = DisplayServer.screen_get_size()
	var scale_factor = get_ui_scale_factor(dpi, screen_size)
	print("INFO: dpi:", dpi)
	print("INFO: screen:", screen_size)
	print("INFO: scale factor:", scale_factor)
	get_viewport().content_scale_factor = scale_factor


func _on_update_check_completed(has_update: bool, version_info: Dictionary):
	if has_update:
		status_label.text = "Update available: " + version_info.get("tag_name", "New Version")
		update_info.visible = true
		
		# Show changelog
		var changelog = version_info.get("body", "")
		if not changelog.is_empty():
			h_box_container_2.visible = true
			update_info.text = changelog
		
		# Find download URL for current platform
		var download_url = ""
		for asset in version_info.get("assets", []):
			var asset_name = asset.get("name", "")
			if _is_asset_for_current_platform(asset_name):
				download_url = asset.get("browser_download_url", "")
				break
		
		if download_url != "":
			update_button.visible = true
			update_button.disabled = false
			skip_button.visible = true
			UpdateManager.download_url = download_url
		else:
			status_label.text = "No compatible update found for your platform"
			launch_button.visible = true
	else:
		status_label.text = "You have the latest version"
		launch_button.visible = true

func _on_download_progress(percent: float):
	progress_bar.visible = true
	progress_bar.value = percent
	status_label.text = "Downloading update: %d%%" % int(percent)

func _on_download_completed(success: bool):
	progress_bar.visible = false
	
	if success:
		status_label.text = "Installing update..."
		if UpdateManager.install_update():
			status_label.text = "Update installed successfully!"
		else:
			status_label.text = "Failed to install update."
	else:
		pass
		#status_label.text = "Download failed."
	
	launch_button.visible = true

func _on_error(message: String):
	print(message)
	status_label.text = "Error: " + message
	launch_button.visible = true

func _on_update_button_pressed():
	update_button.disabled = true
	skip_button.visible = false
	update_info.visible = false
	status_label.text = "Starting download..."
	UpdateManager.download_update(UpdateManager.download_url)

func _on_skip_button_pressed():
	update_button.visible = false
	skip_button.visible = false
	update_info.visible = false
	status_label.text = "Update skipped"
	launch_button.visible = true

func _on_launch_button_pressed():
	status_label.text = "Launching application..."
	UpdateManager.launch_app()

func _is_asset_for_current_platform(asset_name: String) -> bool:
	#print_debug(OS.get_name())
	var platform = OS.get_name().to_lower()
	#print_debug(platform)
	var asset_lower = asset_name.to_lower()
	#print_debug(asset_lower)

	# Simplified check - just look for the platform name in the asset name
	return platform in asset_lower
