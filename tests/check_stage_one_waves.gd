extends SceneTree


func _initialize() -> void:
	var waves := StageOneWaves.new()
	var expected: Array[int] = [8, 10, 11, 14, 20]
	var failed: bool = false
	for wave: int in range(1, 6):
		var roster: Array[int] = waves.roster(wave)
		var total: int = 0
		for count: int in roster:
			if count < 0:
				failed = true
			total += count
		if roster.size() != 4 or total != expected[wave - 1]:
			push_error("Invalid roster total for wave %d" % wave)
			failed = true
	if waves.starting_coins != 200 or waves.preparation_seconds != 10.0 or not waves.roster(0).is_empty() or not waves.roster(6).is_empty():
		push_error("Invalid stage setup or wave boundary")
		failed = true
	print("STAGE ROSTER: %s" % ("FAILED" if failed else "passed"))
	quit(1 if failed else 0)
