extends "res://scripts/actors/zombie.gd"

const DOG_ART: Texture2D = preload("res://assets/generated/realistic_zombie_dog_run.png")
const TOILET_ART: Texture2D = preload("res://assets/generated/toilet_zombie_walk.png")
# Per-frame visible centers and foot baselines, measured at alpha >= 128.
const DOG_VISIBLE_WIDTH: float = 360.0
const DOG_CENTER_X: Array[float] = [207.5, 197.0, 193.5, 189.0, 198.0, 194.0, 193.0, 192.0]
const DOG_FEET_Y: Array[float] = [434.0, 429.0, 422.0, 416.0, 371.0, 373.0, 370.0, 370.0]
const TOILET_CENTER_X: Array[float] = [206.0, 182.5, 192.5, 177.5, 205.5, 192.5, 186.0, 192.5]
const TOILET_FEET_Y: Array[float] = [507.0, 505.0, 508.0, 506.0, 491.0, 487.0, 491.0, 494.0]
const TOILET_VISIBLE_HEIGHT: float = 494.0
@export_range(55.0, 120.0) var dog_width: float = 86.0
var kind: String = "standard"

func setup_stage(config: TutorialBalance, enemy_kind: String) -> void:
	kind = enemy_kind
	setup(config, kind == "semiboss" or kind == "boss")
	gold_reward = 10
	if kind == "standard":
		power = 55
	match kind:
		"dog":
			health = 50
			power = 35
			move_speed = 80.0
		"toilet":
			health = 200
			power = 35
			move_speed = 27.0
		"semiboss":
			gold_reward = 15
		"boss":
			health = 1000
			power = 130
			move_speed = 30.0
			gold_reward = 20
	max_health = health

func _ready() -> void:
	if kind == "dog":
		$Art.texture = DOG_ART
		$Art.hframes = 4
		$Art.vframes = 2
	elif kind == "toilet":
		$Art.texture = TOILET_ART
		$Art.hframes = 4
		$Art.vframes = 2
	super._ready()
	match kind:
		"dog":
			$SemibossLabel.text = "DOG"
			$SemibossLabel.show()
		"toilet":
			$SemibossLabel.text = "TOILET"
			$SemibossLabel.show()
		"semiboss":
			$Art.modulate = Color(0.8, 0.48, 0.42)
		"boss":
			$Art.modulate = Color(0.6, 0.26, 0.26)
			$SemibossLabel.text = "BOSS"
	queue_redraw()

func _apply_walk_frame(frame: int) -> void:
	if kind == "toilet":
		$Art.frame = frame
		var height: float = minf(104.0, maxf(72.0, (position.y - 68.0) / 0.89))
		var toilet_scale: float = height / TOILET_VISIBLE_HEIGHT
		$Art.scale = Vector2.ONE * toilet_scale
		$Art.position = Vector2(
			-(TOILET_CENTER_X[frame] - TOILET_ART.get_width() / 8.0) * toilet_scale,
			-(TOILET_FEET_Y[frame] - TOILET_ART.get_height() / 4.0) * toilet_scale)
		return
	if kind != "dog":
		super._apply_walk_frame(frame)
		return
	# The base movement controller advances the frame by distance travelled.
	# Align the generated poses by their visible centers and feet.
	$Art.frame = frame
	var scale_factor: float = dog_width / DOG_VISIBLE_WIDTH
	$Art.scale = Vector2.ONE * scale_factor
	var foot_offset: float = (DOG_FEET_Y[frame] - DOG_ART.get_height() / 4.0) * scale_factor
	var center_offset: float = (DOG_CENTER_X[frame] - DOG_ART.get_width() / 8.0) * scale_factor
	$Art.position = Vector2(-center_offset, -foot_offset)

func _update_health_display() -> void:
	super._update_health_display()
	if kind == "dog":
		# The dog is shorter than the upright zombie; keep its bar nearby while
		# leaving the label below the HUD on the uppermost lane.
		$Health.position = Vector2(-36.0, maxf(-72.0, 94.0 - position.y))
		$SemibossLabel.position = Vector2(-55.0, $Health.position.y - 24.0)

func _draw() -> void:
	super._draw()
	if kind == "boss":
		draw_arc(Vector2(0,-35), 51, 0, TAU, 32, Color("f04c3f"), 5)
