extends Path2D

const GRACE: float = 10 #grace allows for inputs close to a corner to still work
const GRACE_ERR: float = 10;

#i don't like entire file its freaky
var lower_bound: Array[float]
var lower_bound_err: Array[float]
var upper_bound: Array[float]
var upper_bound_err: Array[float]
var curve_len: float

func _ready():
	curve_len = curve.get_baked_length()
	var seg_len: float = curve_len / 4
	lower_bound.resize(4)
	lower_bound_err.resize(4)
	upper_bound.resize(4)
	upper_bound_err.resize(4)
	for i in range(4):
		lower_bound[i] = i * seg_len - GRACE - seg_len / 2
		upper_bound[i] = (i+1) * seg_len + GRACE - seg_len / 2
		lower_bound_err[i] = i * seg_len - GRACE - GRACE_ERR - seg_len / 2
		upper_bound_err[i] = (i+1) * seg_len + GRACE + GRACE_ERR - seg_len / 2
	#top segment has to be handled specially cause its where the path loops
	lower_bound[0] += curve_len
	lower_bound_err[0] += curve_len

func get_segment_with_grace(progress: float) -> Array[bool]:
	var res: Array[bool] = []
	res.resize(12)
	res.fill(false)
	
	#top segment has to be handled specially cause its where the path loops
	res[0] = lower_bound[0] <= progress || progress <= upper_bound[0]
	res[4] = !res[0] && (lower_bound_err[0] <= progress && progress <= lower_bound[0])
	res[8] = !res[0] && (upper_bound[0] <= progress && progress <= upper_bound_err[0])

	for i in range(1, 4):
		#player is in segment
		res[i] = lower_bound[i] <= progress && progress <= upper_bound[i]
		#player is not in segment but still within an acceptable error
		res[i + 4] = !res[i] && (lower_bound_err[i] <= progress && progress <= lower_bound[i])
		res[i + 8] = !res[i] && (upper_bound[i] <= progress && progress <= upper_bound_err[i])

	return res

func get_segment_id(progress: float) -> int:
	var seg_len: float = curve_len / 4
	if -seg_len / 2 + curve_len <= progress || progress < seg_len / 2:
		return 0
	for i in range(1, 4):
		if i * seg_len - seg_len / 2 <= progress && progress < (i+1) *seg_len - seg_len / 2:
			return i
	printerr("could not evaluate segment index for progress: ", progress, "and curve length of:", curve_len)
	return -1 #this indicateds something went wrong, tho considering the modolo of progress is handeled by godot this should never happen

func get_progress_from_vector(pos: Vector2) -> float:
	#returns a progress value s.t. it is either to the left or right or the battleground & at the same height of pos
	var res: float = curve_len / 8
	res += pos.y - 16 if pos.x > res + 16 else curve_len * 3/4 - pos.y + 16
	print(res)
	return res
