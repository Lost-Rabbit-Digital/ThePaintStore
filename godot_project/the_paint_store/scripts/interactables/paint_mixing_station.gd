extends StaticBody2D

# Add the Interactable class to implement its interface
var interactable: Interactable

# Signals
signal mixing_started(player)
signal mixing_completed(player, color)

# Properties
@export var station_name: String = "Mixing Station"
@export var station_level: int = 1
@export_range(0.5, 3.0) var mixing_speed_multiplier: float = 1.0
@export var available_base_colors: Array[String] = ["white", "clear"]

# References
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_position: Marker2D = $PromptPosition

# State variables
var is_in_use: bool = false
var current_user = null

func _ready() -> void:
	# Create and set up the interactable component
	interactable = Interactable.new()
	interactable.interaction_prompt = "Press E to use %s" % station_name
	add_child(interactable)
	
	# Connect signals
	interactable.interaction_started.connect(_on_interaction_started)
	interactable.interaction_completed.connect(_on_interaction_completed)

func _on_interaction_started(interactor) -> void:
	# Check if station is already in use
	if is_in_use:
		return
	
	# Start using the station
	is_in_use = true
	current_user = interactor
	
	# If interactor is a player, set them to busy
	if interactor.has_method("set_busy"):
		interactor.set_busy(true)
	
	# Play animation if available
	if animation_player and animation_player.has_animation("start_mixing"):
		animation_player.play("start_mixing")
	
	# Emit signal that mixing has started
	mixing_started.emit(interactor)
	
	# Start the mixing mini-game
	start_mixing_minigame(interactor)

func _on_interaction_completed(interactor) -> void:
	# Reset station state
	is_in_use = false
	current_user = null
	
	# If interactor is a player, set them to not busy
	if interactor.has_method("set_busy"):
		interactor.set_busy(false)
	
	# Play animation if available
	if animation_player and animation_player.has_animation("stop_mixing"):
		animation_player.play("stop_mixing")

func start_mixing_minigame(player) -> void:
	# This would be where you switch to the mixing mini-game scene or UI
	# For this example, we'll just simulate completing the mini-game after a delay
	
	# Create a timer to simulate mini-game duration
	var timer = Timer.new()
	timer.wait_time = 2.0 / mixing_speed_multiplier  # Adjust based on station level
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(func():
		# Generate a result color (in a real implementation, this would come from the mini-game)
		var mixed_color = Color(randf(), randf(), randf())
		
		# Emit completion signal with the mixed color
		mixing_completed.emit(player, mixed_color)
		
		# Complete the interaction
		interactable.interaction_completed.emit(player)
		
		# Remove the timer
		timer.queue_free()
	)
	timer.start()

# Public methods that would be implemented in a full game

func upgrade_station() -> void:
	station_level += 1
	mixing_speed_multiplier += 0.25
	
	# Update visuals based on level
	match station_level:
		2:
			# Add medium quality texture
			if sprite:
				sprite.texture = load("res://assets/mixing_station_level_2.png")
			# Add more base colors
			available_base_colors.append("neutral")
		3:
			# Add high quality texture
			if sprite:
				sprite.texture = load("res://assets/mixing_station_level_3.png")
			# Add more base colors
			available_base_colors.append("deep_base")
		_:
			# Higher levels
			pass

func can_mix_color(color_name: String) -> bool:
	# Check if the station can mix the specified color
	# This would involve checking if the required base and tints are available
	return station_level >= get_color_complexity(color_name)

func get_color_complexity(color_name: String) -> int:
	# This would be implemented based on your game's color system
	# Returns a complexity level for different colors
	match color_name:
		"white", "black", "red", "blue", "yellow":
			return 1
		"green", "orange", "purple", "brown":
			return 2
		"metallic", "pearlescent":
			return 3
		_:
			return 1
