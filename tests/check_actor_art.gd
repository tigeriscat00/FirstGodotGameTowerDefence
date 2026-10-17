extends SceneTree
## Visual state checks on real actors, including limb frames and upgrade effects.

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
    var tower: DefenseTower = tutorial.board.add_tower(24, tutorial.balance)
    tower.set_process(false)
    var base_texture: Texture2D = tower.get_node("Art").texture
    tower.upgrade()
    _check(tower.get_node("Art").texture != base_texture, "Upgrade changes the tower's actual artwork")
    _check(tower.upgrade_elapsed == 0.0, "Successful upgrade starts the transformation animation")
    var upgraded_texture: Texture2D = tower.get_node("Art").texture
    tower._process(0.4)
    _check(tower.get_node("Art").modulate != Color.WHITE, "Upgrade animation visibly flashes the new tower")
    tower._process(2.0)
    _check(tower.upgrade_elapsed < 0.0 and tower.get_node("Art").modulate == Color.WHITE, "Upgrade finishes and returns to stable lighting")
    tower.upgrade()
    _check(tower.upgrade_elapsed < 0.0 and tower.get_node("Art").texture == upgraded_texture and tower.health == 200, "Repeated upgrades do not restart effects or award health again")
    var zombie: TutorialZombie = tutorial.board.spawn_zombie(tutorial.balance, 60.0)
    var art: Sprite2D = zombie.get_node("Art")
    _check(art.hframes == 4 and art.vframes == 2, "Zombie uses an eight-frame limb animation sheet")
    var frames: Dictionary = {}
    var no_towers: Array[DefenseTower] = []
    zombie.tick(0.1, no_towers, Vector2(904, zombie.position.y))
    _check(art.frame == 0, "Slow shuffle holds its first pose through a short step instead of rushing frames")
    for index: int in 20:
        zombie.tick(0.1, no_towers, Vector2(904, zombie.position.y))
        frames[art.frame] = true
    _check(frames.size() >= 7, "Walking cycles through distinct arm and leg poses")
    var frozen_frame: int = art.frame
    var frozen_position: Vector2 = zombie.position
    zombie.freeze(5.0)
    zombie.tick(1.0, no_towers, Vector2(904, zombie.position.y))
    _check(art.frame == frozen_frame and zombie.position == frozen_position, "Freeze stops limb animation and movement together")
    zombie.tick(4.0, no_towers, Vector2(904, zombie.position.y))
    zombie.tick(0.25, no_towers, Vector2(904, zombie.position.y))
    _check(art.frame != frozen_frame and zombie.position != frozen_position, "Walking resumes after Freeze expires")
    zombie.position = tower.position + Vector2(-50, 0)
    zombie.tick(0.1, tutorial.board.towers, tutorial.board.GATE)
    _check(art.frame == 0, "Attacking enemy stops its walk cycle")
    var fast: TutorialZombie = tutorial.board.spawn_zombie(tutorial.balance, 60.0)
    var slow: TutorialZombie = tutorial.board.spawn_zombie(tutorial.balance, 60.0)
    fast.move_speed = 90.0
    slow.move_speed = 45.0
    fast.tick(0.4, no_towers, Vector2(904, fast.position.y))
    slow.tick(0.8, no_towers, Vector2(904, slow.position.y))
    _check(fast.position == slow.position and fast.get_node("Art").frame == slow.get_node("Art").frame, "Equal ground distance gives the same limb pose regardless of movement speed or elapsed time")
    print("ACTOR ART CHECKS: %d checks, %d failures" % [checks, failures])
    root.get_node("Sfx").stop_all()
    root.get_node("Music").stop()
    await create_timer(0.1).timeout
    quit(1 if failures else 0)
