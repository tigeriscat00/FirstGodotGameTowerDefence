extends SceneTree

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	change_scene_to_file("res://scenes/tutorial/tutorial.tscn")
	await process_frame
	await process_frame
	var tutorial: Variant = current_scene
	var board: TutorialBattlefield = tutorial.board
	_check(board.size == Vector2(1152, 648) and board.position == Vector2.ZERO, "Battlefield fills the entire game canvas")
	_check(board.cell_at(Vector2(-1, 300)) == -1, "Outside lawn is not buildable")
	_check(board.cell_at(Vector2(40, 300)) == -1, "Enemy entry columns cannot be occupied")
	_check(board.cell_at(Vector2(300, 40)) == -1, "Top margin protects overhead enemy labels")
	_check(board.cell_at(Vector2(800, 632)) == -1, "Bottom/right boundary cannot overflow the grid")
	_check(board.build_cells().size() == 24, "Twenty-four cells are available for towers")
	for index: int in board.build_cells():
		var center: Vector2 = board.cell_center(index)
		_check(board.cell_at(center) == index, "Cell center snaps to its own cell")
		_check(board.cell_at(board.cell_rect(index).position + Vector2.ONE) == index, "Cell corners snap to the same cell")
		var tower: DefenseTower = board.add_tower(index, tutorial.balance)
		_check(tower.position == center and board.occupied(index), "Tower is centered and occupies one cell")
		_check(board.add_tower(index, tutorial.balance) == null, "Occupied cell rejects a second tower")
	_check(board.add_tower(-1, tutorial.balance) == null, "Invalid index cannot spawn a tower")
	tutorial._toggle_shop()
	tutorial._buy()
	_check(tutorial.gold == tutorial.balance.starting_gold and not tutorial.pending_tower, "Full grid does not charge for another tower")
	var first_cell: int = board.build_cells()[0]
	var first: DefenseTower = board.tower_at(board.cell_center(first_cell))
	first.take_damage(999)
	_check(not board.occupied(first_cell), "Destroyed tower releases its cell")
	_check(board.add_tower(first_cell, tutorial.balance) != null, "Released cell can be rebuilt")
	print("GRID CHECKS: %d checks, %d failures" % [checks, failures])
	root.get_node("Sfx").stop_all()
	root.get_node("Music").stop()
	await create_timer(0.1).timeout
	quit(1 if failures > 0 else 0)
