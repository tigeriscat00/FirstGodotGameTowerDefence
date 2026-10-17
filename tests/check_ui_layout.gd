extends SceneTree
## Contextual cards must fit every build cell without reserving a sidebar.

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
    tutorial.set_process(false)
    tutorial.board.set_process(false)
    tutorial._set_step(tutorial.Step.PRACTICE)
    var card: PanelContainer = tutorial.get_node("HUD/SelectionCard")
    var guide: Panel = tutorial.get_node("HUD/Dialogue")
    var top_bar: Panel = tutorial.get_node("HUD/TopBar")
    _check(not tutorial.has_node("HUD/Rail"), "No sidebar node covers the battlefield")
    _check(tutorial.board.size == Vector2(1152, 648), "Battlefield uses the entire logical canvas")
    _check(not tutorial.has_node("HUD/Freeze"), "Skills belong to the selected tower, not the toolbar")
    for cell: int in tutorial.board.build_cells():
        var tower: DefenseTower = tutorial.board.add_tower(cell, tutorial.balance)
        for with_guide: bool in [true, false]:
            tutorial._show_dialogue(with_guide)
            tutorial._on_board_clicked(tower.position)
            await process_frame
            tutorial._refresh_stats()
            _check(card.visible, "Clicking a tower opens its popup at cell %d" % cell)
            var usable := Rect2(16, 76, 1120, (guide.position.y - 12.0 if with_guide else 632.0) - 76.0)
            _check(usable.encloses(card.get_rect()), "Popup stays clear of the toolbar, dialogue and window edges at cell %d" % cell)
            _check(not card.get_rect().has_point(tower.position), "Popup does not cover its own tower at cell %d" % cell)
            tutorial._on_board_clicked(Vector2(820, 480))
            _check(not card.visible and not tutorial.tower_popup_open, "Clicking empty ground closes the contextual popup")
        tower.queue_free()
        await process_frame
    tutorial._show_dialogue(true)
    tutorial._process(tutorial.combat_message_seconds + 0.1)
    # Manually restored messages stay until hidden; automatic messages time out.
    _check(guide.visible, "Manually reopened Sphinx message remains readable")
    tutorial._set_step(tutorial.Step.PRACTICE)
    tutorial._process(tutorial.combat_message_seconds + 0.1)
    _check(not guide.visible, "Automatic combat tip hides after its reading time")
    print("UI LAYOUT CHECKS: %d checks, %d failures" % [checks, failures])
    root.get_node("Sfx").stop_all()
    root.get_node("Music").stop()
    await create_timer(0.1).timeout
    quit(1 if failures else 0)
