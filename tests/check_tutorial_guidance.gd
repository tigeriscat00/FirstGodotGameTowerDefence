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
    tutorial.set_process(false)
    tutorial.board.set_process(false)
    var cue: Control = tutorial.get_node("TutorialCue")
    _check(not tutorial.has_node("HUD/Dialogue/Text/Next"), "No dialogue advance button exists")
    _check(cue.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Sparkles do not intercept game clicks")
    _check(cue.focus_id == "Shop", "Opening shop icon is highlighted")
    tutorial._toggle_shop()
    _check(cue.focus_id == "Buy", "Shop purchase is the next highlighted action")
    tutorial._buy()
    _check(tutorial.step == tutorial.Step.PLACE and cue.focus_id == "BuildCell", "Purchase automatically teaches placement")
    _check(not cue.focus_rect.has_point(tutorial.board.zombie.position), "Placement cue never frames the zombie in the old default cell")
    tutorial.board.pointer = tutorial.board.cell_center(26)
    tutorial._refresh_stats()
    _check(cue.focus_rect == tutorial.board.cell_rect(26), "Placement sparkle follows the valid green hovered cell")
    tutorial.board.pointer = tutorial.board.zombie.position
    tutorial._refresh_stats()
    _check(not cue.focus_rect.has_point(tutorial.board.zombie.position), "Hovering over the enemy keeps the placement cue on clear ground")
    var blocked: int = tutorial.board.placement_cue_cell()
    var temporary: DefenseTower = tutorial.board.add_tower(blocked, tutorial.balance)
    tutorial.board.pointer = temporary.position
    tutorial._refresh_stats()
    _check(not cue.focus_rect.has_point(temporary.position), "Occupied tower cells are not suggested for placement")
    tutorial.board.towers.erase(temporary)
    temporary.queue_free()
    await process_frame
    tutorial.board.pointer = Vector2(-100, -100)
    tutorial._on_board_clicked(tutorial.board.cell_center(24))
    _check(tutorial.step == tutorial.Step.TOWER and cue.focus_id == "Tower", "Placement automatically teaches tower inspection")
    var tower: DefenseTower = tutorial.board.towers[0]
    tutorial._on_board_clicked(tower.position)
    _check(tutorial.step == tutorial.Step.UPGRADE and cue.follow_target == tutorial.side.get_node("Upgrade"), "Upgrade gets the sparkle outline")
    tutorial._process(20.0)
    _check(tutorial.step == tutorial.Step.UPGRADE and not tower.upgraded, "Action lessons never skip the required action on a timer")
    tutorial._upgrade()
    _check(tutorial.step == tutorial.Step.FREEZE and cue.focus_id == "Tower", "Upgrade automatically teaches tower skills")
    tutorial._on_board_clicked(tower.position)
    _check(cue.focus_id == "Q", "Required Freeze skill is highlighted")
    tutorial._activate_skill(0)
    tutorial._refresh_stats()
    _check(cue.focus_id == "Zombie", "Targeting highlights the zombie")
    tutorial._on_board_clicked(tutorial.board.zombie.position)
    _check(tutorial.step == tutorial.Step.FIGHT, "Casting Freeze starts guided combat automatically")
    tutorial.board.zombie.take_damage(999)
    await process_frame
    _check(tutorial.step == tutorial.Step.DEBRIEF and tutorial.advance_time > 0.0, "Kill reward starts the automatic debrief")
    tutorial._toggle_pause()
    var remaining: float = tutorial.advance_time
    tutorial._process(20.0)
    _check(tutorial.step == tutorial.Step.DEBRIEF and tutorial.advance_time == remaining, "Settings pause automatic lesson progression")
    tutorial._toggle_pause()
    tutorial._process(1.0)
    _check(tutorial.step == tutorial.Step.DEBRIEF, "Debrief leaves reading time before the wave")
    tutorial._process(tutorial.message_read_seconds)
    _check(tutorial.step == tutorial.Step.PRACTICE and is_instance_valid(tutorial.board.zombie), "Next wave starts without a Begin defense click")
    tutorial.board.zombie.queue_free()
    await process_frame
    tutorial.practice_left = 1
    tutorial._spawn_zombie()
    var boss: TutorialZombie = tutorial.board.zombie
    var start: Vector2 = boss.position
    tutorial._process(1.0)
    _check(tutorial.step == tutorial.Step.SEMIBOSS and boss.position == start, "Semiboss holds while Sphinx's introduction is read")
    tutorial._process(tutorial.message_read_seconds)
    _check(tutorial.step == tutorial.Step.PRACTICE and boss.position == start, "Semiboss starts automatically without spending its reading time moving")
    tutorial._process(0.1)
    _check(boss.position != start, "Semiboss moves after the introduction")
    print("GUIDANCE CHECKS: %d checks, %d failures" % [checks, failures])
    root.get_node("Sfx").stop_all()
    root.get_node("Music").stop()
    await create_timer(0.1).timeout
    quit(1 if failures else 0)
