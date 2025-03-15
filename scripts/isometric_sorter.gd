extends Node2D
class_name IsometricSorter

# This class handles automatic Y-sorting for isometric objects
# Attach this as an autoload or as a child of your main scene

# Register nodes that should be sorted
var sorted_nodes = []

func _ready():
	# Call this every frame to update sorting
	set_process(true)

func _process(_delta):
	# Sort all registered nodes by their Y position
	sort_nodes_by_y()

# Register a node to be Y-sorted
func register_node(node: Node2D):
	if not sorted_nodes.has(node):
		sorted_nodes.append(node)
		
		# Disconnect signal if it was already connected
		if node.is_connected("tree_exiting", _on_node_tree_exiting.bind(node)):
			node.disconnect("tree_exiting", _on_node_tree_exiting.bind(node))
			
		# Connect tree_exiting signal to automatically unregister
		node.connect("tree_exiting", _on_node_tree_exiting.bind(node))

# Unregister a node from Y-sorting
func unregister_node(node: Node2D):
	if sorted_nodes.has(node):
		sorted_nodes.erase(node)

# Handle node removal
func _on_node_tree_exiting(node: Node2D):
	unregister_node(node)

# Sort registered nodes by their Y position
func sort_nodes_by_y():
	# Sort nodes by y position (higher y = appears in front)
	for node in sorted_nodes:
		if is_instance_valid(node):
			# In isometric view, z_index is based on Y position
			# Objects with higher Y values should appear in front
			node.z_index = int(node.global_position.y)

# Helper function to automatically register all children of a node
func register_children_recursive(parent: Node):
	for child in parent.get_children():
		if child is Node2D:
			register_node(child)
		
		# Recurse into children
		if child.get_child_count() > 0:
			register_children_recursive(child) 