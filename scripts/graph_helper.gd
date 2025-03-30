class_name GraphHelper
## General Helper class for dealing with Graph Data (NOT with GraphEdit/GraphNode)

## returns an Dictonary (used as a set) of values from a graph [method GraphHelper.bfs_get_value(get_value: Callable, get_graph_children: Callable, start_idx: int, max_depth: int, graph_array: Array) -> Array]
## [param graph_array] An Array of nodes of the graph
## [param get_value]: A Callable that takes an element of [param graph_array] and returns a desired value
## [param get_graph_children] A Callable that takes an element of [param graph_array] and returns a list of indices of its children
## [param start_idx] The index of the [param graph_array] element where the bfs should start
## [param max_depth] If set to a non-negative value will stop the bfs algoritm from travaling deeper then max_depth
static func bfs_get_values(graph_array: Array, get_value: Callable, get_graph_children: Callable, start_idx: int, max_depth: int) -> Dictionary:
	if max_depth < 0: max_depth = len(graph_array) + 1
	var visited: Dictionary = {}
	var result: Dictionary = {}
	var queue: Array = [[graph_array[start_idx], 0]]
	while !queue.is_empty():
		var temp_pair = queue.pop_back()
		var curr_node = temp_pair[0]
		var curr_depth = temp_pair[1]
		result[get_value.call(curr_node)] = null
		visited[curr_node] = null
		if curr_depth >= max_depth: continue
		for idx in get_graph_children.call(curr_node):
			if visited.has(graph_array[idx]): continue
			queue.push_front([graph_array[idx], curr_depth + 1])
	return result

## returns an (Dictionary used as a set) of unreachable values from a graph [method GraphHelper.bfs_are_unreachable (get_value: Callable, get_graph_children: Callable, start_idx: int, max_depth: int, graph_array: Array) -> Array]
## [param graph_array] An Array of nodes of the graph
## [param get_value]: A Callable that takes an element of [param graph_array] and returns a desired value (the type of value should be the same as of the elements of [param values]
## [param get_graph_children] A Callable that takes an element of [param graph_array] and returns a list of indices of its children
## [param start_idx] The index of the [param graph_array] element where the bfs should start
## [param values] A Dictonary (used as a set) of values that are checked for reachability. The returnvalue of [method GraphHelper.dfs_are_unreachable (get_value: Callable, get_graph_children: Callable, start_idx: int, max_depth: int, graph_array: Array) -> Array] is always a subset of this argument
static func bfs_are_unreachable(graph_array: Array, get_value: Callable, get_graph_children: Callable, start_idx: int, values: Dictionary) -> Dictionary:
	var visited: Dictionary = {}
	var result: Dictionary = values.duplicate()
	var queue: Array = [graph_array[start_idx]]
	while !queue.is_empty():
		var curr_node = queue.pop_back()
		var val = get_value.call(curr_node)
		if result.has(val):
			result.erase(val)
		visited[curr_node] = null
		for idx in get_graph_children.call(curr_node):
			if visited.has(graph_array[idx]): continue
			queue.push_front(graph_array[idx])
	return result

