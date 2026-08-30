extends RefCounted
# Animation XML Parser
class_name AXP

const _execFrames = ["HitFrame", "HurtFrame", "ReturnFrame", "RushFrame"]
const _execFramesCamelCase = ["hitFrame", "hurtFrame", "returnFrame", "rushFrame"]
const _execFrameMapping = {
	"hitFrame": "_on_hit_frame",
	"hurtFrame": "_on_hurt_frame",
	"returnFrame": "_on_return_frame",
	"rushFrame": "_on_rush_frame"
}

static func xml_to_dictionary(xml_string: String) -> Dictionary:
	var parser: XMLParser = XMLParser.new()
	var error = parser.open_buffer(xml_string.to_utf8_buffer())
	if error != OK:
		push_error("Failed to parse XML string. Error code: ", error)
		return {}
	var root: Dictionary = {"name": "root", "children": []}
	var node_stack: Array = [root]
	
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		match node_type:
			XMLParser.NODE_ELEMENT:
				var element_name = parser.get_node_name()
				var attributes = {}
				for i in range(parser.get_attribute_count()):
					attributes[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
				var new_node = {
					"name": element_name,
					"attributes": attributes,
					"children": [],
					"content": ""
				}
				node_stack[-1]["children"].append(new_node)
				if not parser.is_empty():
					node_stack.append(new_node)
			XMLParser.NODE_ELEMENT_END:
				if node_stack.size() > 1:
					node_stack.pop_back()
			XMLParser.NODE_TEXT:
				var text = parser.get_node_data().strip_edges()
				if not text.is_empty():
					node_stack[-1]["content"] = text
	return root["children"][0] if not root["children"].is_empty() else {}


static func find_child_node(node, cname: String):
	for child in node.children:
		if child.name == cname:
			return child
	return null

static func anim_to_dict(anim): # still missing properties but fuck it we ball
	var nameNode = find_child_node(anim, "Name")
	var indexNode = find_child_node(anim, "Index")
	var frameWidthNode = find_child_node(anim, "FrameWidth")
	var frameHeightNode = find_child_node(anim, "FrameHeight")
	var durationsNode = find_child_node(anim, "Durations")
	var copyOfNode = find_child_node(anim, "CopyOf")
	
	var rushFrameNode = find_child_node(anim, "RushFrame")
	var hitFrameNode = find_child_node(anim, "HitFrame")
	var returnFrameNode = find_child_node(anim, "ReturnFrame")
	
	var durations: Array[int] = []
	var result = {}
	if durationsNode != null:
		for durationNode in durationsNode.children:
			if durationNode.name != "Duration":
				printerr("unexpected node: {} during parsing durations", durationNode.name)
				continue
			durations.push_back(int(durationNode.content))
		result.durations = durations
	if nameNode != null:
		result.name = nameNode.content
	if indexNode != null:
		result.index = int(indexNode.content)
	if frameWidthNode != null:
		result.frameWidth = int(frameWidthNode.content)
	if frameHeightNode != null:
		result.frameHeight = int(frameHeightNode.content)
	if rushFrameNode != null:
		result.rushFrame = int(rushFrameNode.content)
	if hitFrameNode != null:
		result.hitFrame = int(hitFrameNode.content)
	if returnFrameNode != null:
		result.returnFrame = int(returnFrameNode.content)
	if copyOfNode != null:
		result.copyOf = copyOfNode.content
	return result
static func load_anxml(path: String):
	var xstr: String = FileAccess.get_file_as_string(path)
	var dict = xml_to_dictionary(xstr)
	# name, attributes, children, content
	var animationsNode = find_child_node(dict, "Anims")
	if animationsNode == null:
		printerr("Couldn't find child node Anims for importing SpriteCollab Animation Data, aborting")
		return null
	var animations: Array[Dictionary] = []
	for animation in animationsNode.children:
		animations.push_back(anim_to_dict(animation))
	return {
		"animations": animations
	}
static func _has_any_inside(arr1: Array, arr2: Array):
	for i in arr1:
		for j in arr2:
			if arr1.has(j):
				return true
	return false
static func animation_to_gd(anim: Dictionary):
	var animation: Animation = Animation.new()
	#print(anim.durations)
	var totalLen = anim.durations.reduce(func(a, b): return a+b, 0)
	var lengthInSeconds = float(totalLen) / 30 # here we assume EoS is running in 30fps
	#print(totalLen)
	animation.length = lengthInSeconds
	animation.loop_mode = Animation.LOOP_LINEAR
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	var exec_track: int = -1
	if _has_any_inside(anim.keys(), _execFramesCamelCase):
		exec_track = animation.add_track(Animation.TYPE_METHOD)
		animation.track_set_path(exec_track, ".")
	animation.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_NEAREST)
	animation.track_set_path(track_idx, ".:frame_coords:x")
	
	var timeElapsed = 0 #(float(anim.durations[0])/totalLen)*lengthInSeconds
	var frames = 0
	for duration in anim.durations:
		var timeTaken = (float(duration) / totalLen) * lengthInSeconds
		#print("duration: %d; time taken: %f; elapsed: %f; frames: %d" % [duration, timeTaken, timeElapsed, frames])
		timeElapsed += timeTaken
		var key_idx = animation.track_insert_key(track_idx, timeElapsed, frames)
		for execFrame in _execFramesCamelCase:
			if anim.has(execFrame) && anim.get(execFrame) == frames: # probably horribly inefficient but eh
				#print("adding exec frame %s" % execFrame)
				animation.track_insert_key(exec_track, timeElapsed, {
					"method": _execFrameMapping[execFrame],
					"args": []
				})
		#animation.track_set_key_transition(track_idx, key_idx, 1.0)
		frames += 1
	animation.set_meta("spritecollab_fulldata", anim)
	return animation
static func _find_animation(dict: Dictionary, name: StringName):
	for anim in dict.animations:
		if anim.name == name:
			return anim
	return null
static func get_animation(dict: Dictionary, name: StringName):
	var anim: Dictionary = _find_animation(dict, name)
	if anim.has("copyOf"):
		var newAnim = _find_animation(dict, anim.copyOf)
		if newAnim == null:
			return null
		var dupeAnim  = newAnim.duplicate(true)
		dupeAnim.name = anim.name
		return dupeAnim
	return anim
