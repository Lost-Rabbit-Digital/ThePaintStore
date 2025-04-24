extends Node
class_name Interactable

# Signals
signal interaction_started(interactor)
signal interaction_completed(interactor)

# Properties
@export var interaction_prompt: String = "Press E to interact"
@export var is_interactable: bool = true
@export var required_tool: String = ""  # If a specific tool is needed to interact

# Override this method in derived classes
func can_interact(interactor: Node) -> bool:
	if not is_interactable:
		return false
	
	# Check if interactor has required tool if one is specified
	if required_tool != "" and interactor.has_method("has_tool"):
		return interactor.has_tool(required_tool)
	
	return true

# This is the main interaction method to be implemented by child classes
func interact(interactor: Node) -> void:
	interaction_started.emit(interactor)
	
	# Child classes should override this method with their specific interaction logic
	
	interaction_completed.emit(interactor)

# Optionally override to provide custom prompt text
func get_interaction_prompt() -> String:
	return interaction_prompt

# Called when object becomes interactable
func set_interactable(value: bool) -> void:
	is_interactable = value
