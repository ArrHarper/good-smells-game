extends Node2D
class_name IsometricSorter

# This class handles automatic Y-sorting for isometric objects
# Optimized to only update z-index when nodes move

# Register nodes that should be sorted
var sorted_nodes = {} # Now a dictionary to store node:last_position pairs

func _ready():
	# We'll process less frequently since we're only checking position changes
	set_process(true)
	set_process_priority(100) # Lower priority for z-sorting

func _process(_delta):
	# Only sort nodes when they change position
	sort_nodes_by_position_change()

# Register a node to be Y-sorted
func register_node(node: Node2D):
	if not sorted_nodes.has(node):
		# Store the node with its current position
		sorted_nodes[node] = node.global_position
		
		# Disconnect signal if it was already connected
		if node.is_connected("tree_exiting", _on_node_tree_exiting.bind(node)):
			node.disconnect("tree_exiting", _on_node_tree_exiting.bind(node))
			
		# Connect tree_exiting signal to automatically unregister
		node.connect("tree_exiting", _on_node_tree_exiting.bind(node))
		
		# Set initial z-index
		update_node_z_index(node)

# Add sorted object - alias for register_node for consistency
func add_sorted_object(node: Node2D):
	register_node(node) # Use existing functionality

# Unregister a node from Y-sorting
func unregister_node(node: Node2D):
	if sorted_nodes.has(node):
		sorted_nodes.erase(node)

# Handle node removal
func _on_node_tree_exiting(node: Node2D):
	unregister_node(node)

# Sort registered nodes but only if they've moved
func sort_nodes_by_position_change():
	var nodes_to_remove = []
	
	# Check each node for position changes
	for node in sorted_nodes:
		if not is_instance_valid(node):
			# Add invalid nodes to removal list
			nodes_to_remove.append(node)
			continue
			
		if node is Node2D:
			# Skip if node hasn't moved
			if sorted_nodes[node].is_equal_approx(node.global_position):
				continue
				
			# Update stored position and z-index
			sorted_nodes[node] = node.global_position
			update_node_z_index(node)
	
	# Clean up any invalid nodes
	for node in nodes_to_remove:
		sorted_nodes.erase(node)

# Update Z-index for a single node
func update_node_z_index(node: Node2D):
	# Skip certain node types that manage their own z-index
	if node is CharacterBody2D:
		return
		
	# In isometric view, z_index is based on Y position
	# Objects with higher Y values should appear in front
	var z_value = int(node.global_position.y)
	
	# Assign the calculated z_index to the node
	node.z_index = z_value

# Helper function to automatically register all children of a node
func register_children_recursive(parent: Node):
	for child in parent.get_children():
		if child is Node2D:
			register_node(child)
		
		# Recurse into children
		if child.get_child_count() > 0:
			register_children_recursive(child)
