extends CharacterBody2D
class_name PlayerController

# Movement parameters
@export var max_speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1000.0
@export var rotation_speed: float = 10.0  # For smooth rotation if needed

# Interaction parameters
@export var interaction_distance: float = 50.0
@export_node_path("Area2D") var interaction_area_path

# Animation parameters
@export var use_rotation: bool = false  # Set to true if player should rotate to face movement direction

# Signals
signal interaction_triggered(object)

# Node references
var interaction_area: Area2D

# State tracking
var is_busy: bool = false  # Set to true when in mini-games or dialog

func _ready() -> void:
	if interaction_area_path:
		interaction_area = get_node(interaction_area_path)

func _physics_process(delta: float) -> void:
	if is_busy:
		return  # Skip movement processing if player is busy
		
	# Get input direction
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Handle movement
	_handle_movement(input_direction, delta)
	
	# Handle interaction input
	if Input.is_action_just_pressed("interact"):
		_handle_interaction()

func _handle_movement(direction: Vector2, delta: float) -> void:
	if direction != Vector2.ZERO:
		# Accelerate in input direction
		velocity = velocity.move_toward(direction.normalized() * max_speed, acceleration * delta)
		
		# Handle rotation if enabled
		if use_rotation:
			rotation = lerp_angle(rotation, direction.angle(), rotation_speed * delta)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Apply movement
	move_and_slide()
	
	# Update animation
	_update_animation()

func _update_animation() -> void:
	# Get access to the AnimationTree if available
	var anim_tree = $AnimationTree if has_node("AnimationTree") else null
	
	if anim_tree and anim_tree.has_method("set"):
		if velocity.length() > 0.1:
			# Calculate movement direction for animation blending
			var movement_direction = Vector2(velocity.x, velocity.y).normalized()
			
			# Update blend positions for animation tree
			anim_tree.set("parameters/Idle/blend_position", movement_direction)
			anim_tree.set("parameters/Walk/blend_position", movement_direction)
			
			# Transition to walk animation
			anim_tree.set("parameters/conditions/is_moving", true)
			anim_tree.set("parameters/conditions/is_idle", false)
		else:
			# Transition to idle animation
			anim_tree.set("parameters/conditions/is_moving", false)
			anim_tree.set("parameters/conditions/is_idle", true)

func _handle_interaction() -> void:
	# Get interactable objects in range
	var interactables = _get_interactables()
	
	# If we found interactable objects, interact with the closest one
	if not interactables.is_empty():
		var closest = _get_closest_interactable(interactables)
		interaction_triggered.emit(closest)

func _get_interactables() -> Array:
	var interactables = []
	
	if interaction_area:
		# Use interaction area if available
		var overlapping_bodies = interaction_area.get_overlapping_bodies()
		var overlapping_areas = interaction_area.get_overlapping_areas()
		
		# Filter for interactable objects
		for body in overlapping_bodies:
			if body.has_method("interact"):
				interactables.append(body)
				
		for area in overlapping_areas:
			if area.has_method("interact"):
				interactables.append(area)
	else:
		# Fallback to distance-based detection
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = global_position
		query.collision_mask = 0x2  # Adjust based on your collision layers
		query.collide_with_bodies = true
		query.collide_with_areas = true
		
		var result = space_state.intersect_point(query, 32)  # Limit to reasonable number
		
		for item in result:
			var collider = item.collider
			if collider.has_method("interact") and global_position.distance_to(collider.global_position) <= interaction_distance:
				interactables.append(collider)
	
	return interactables

func _get_closest_interactable(interactables: Array) -> Node:
	var closest_distance = INF
	var closest_object = null
	
	for object in interactables:
		var distance = global_position.distance_to(object.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_object = object
	
	return closest_object

# Public methods
func set_busy(busy: bool) -> void:
	is_busy = busy
	if is_busy:
		velocity = Vector2.ZERO

func teleport_to(position: Vector2) -> void:
	global_position = position

func face_direction(direction: Vector2) -> void:
	if use_rotation:
		rotation = direction.angle()
