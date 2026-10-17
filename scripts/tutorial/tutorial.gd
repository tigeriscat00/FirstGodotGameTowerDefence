extends Control
## Guided actions unlock combat only after the player has tried the core tools.

enum Step { SHOP, BUY, CLOSE, INTRO, PLACE, ZOMBIE, TOWER, UPGRADE, FREEZE, FIGHT, DEBRIEF, PRACTICE, SEMIBOSS, WON, LOST }

@export var guide_name: String = "Sphinx"
@export var balance: TutorialBalance
@export_range(2.0, 12.0) var combat_message_seconds: float = 4.0

@onready var board: TutorialBattlefield = $Margin/Layout/Middle/Board
@onready var side: VBoxContainer = $HUD/SelectionCard/Side
@onready var shop: Control = $ShopOverlay
@onready var guide: Label = $HUD/Dialogue/Text/Guide
@onready var status: Label = $HUD/TopBar/Status
@onready var hint: Label = $HUD/Hint

var step: Step = Step.SHOP
var gold: int = 0
var kingdom_health: int = 0
var pending_tower: bool = false
var selected_tower: DefenseTower
var freeze_cooldown: float:
    get:
        return selected_tower.freeze_cooldown if is_instance_valid(selected_tower) else 0.0
    set(value):
        if is_instance_valid(selected_tower):
            selected_tower.freeze_cooldown = value
var practice_left: int = 0
var spawn_delay: float = 0.0
var is_paused: bool = false
var dialogue_time: float = 0.0
var hint_time: float = 0.0
var last_hint: String = ""
var tower_popup_open: bool = false
var advance_time: float = 0.0
@export_range(2.0, 8.0) var message_read_seconds: float = 4.0


func _ready() -> void:
    get_node("/root/Sfx").stop_combat()
    get_window().min_size = Vector2i(1152, 648)
    gold = balance.starting_gold
    kingdom_health = balance.kingdom_health
    board.build_range = balance.tower_range
    board.board_clicked.connect(_on_board_clicked)
    $HUD/TopBar/Shop.pressed.connect(_toggle_shop)
    shop.get_node("Card/Contents/Buy").pressed.connect(_buy)
    side.get_node("Upgrade").pressed.connect(_upgrade)
    side.get_node("Sell").pressed.connect(_sell)
    for slot: int in DefenseTower.MAX_SKILLS:
        side.get_node("Skills/" + "QWER"[slot]).pressed.connect(_activate_skill.bind(slot))
        side.get_node("Skills/" + "QWER"[slot] + "/Key").text = "QWER"[slot]
    $HUD/TopBar/Settings.pressed.connect(_toggle_pause)
    $SettingsOverlay/Card/Contents/Resume.pressed.connect(_toggle_pause)
    $SettingsOverlay/Card/Contents/Restart.pressed.connect(_restart)
    $SettingsOverlay/Card/Contents/Back.pressed.connect(_back_to_menu)
    shop.get_node("Card/Contents/Close").pressed.connect(_toggle_shop)
    side.get_node("Dismiss").pressed.connect(_deselect_tower)
    $HUD/DialogueToggle.pressed.connect(_toggle_dialogue)
    $VictoryCelebration.quit_requested.connect(_back_to_menu)
    # Initial word wrapping can temporarily report a tall minimum height before
    # the container receives its width. Resize again when that minimum settles.
    $HUD/Dialogue/Text.minimum_size_changed.connect(_layout_dialogue.call_deferred)
    shop.get_node("Card/Contents/Buy").text = "Buy - %d gold" % balance.tower_cost
    side.get_node("Upgrade").text = "Upgrade - %d gold" % balance.upgrade_cost
    _set_step(Step.SHOP)


func _unhandled_key_input(event: InputEvent) -> void:
    if step == Step.WON:
        return
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    match event.physical_keycode:
        KEY_B:
            _toggle_shop()
        KEY_Q, KEY_W, KEY_E, KEY_R:
            _activate_skill([KEY_Q, KEY_W, KEY_E, KEY_R].find(event.physical_keycode))
        KEY_ESCAPE:
            if board.freeze_aiming:
                board.freeze_aiming = false
                board.queue_redraw()
            elif shop.visible:
                _toggle_shop()
            elif tower_popup_open:
                _deselect_tower()
            else:
                _toggle_pause()
        _:
            return
    get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
    if not is_paused and not shop.visible:
        if advance_time > 0.0:
            advance_time = maxf(0.0, advance_time - delta)
            if advance_time == 0.0:
                _advance_after_message()
                return
        if dialogue_time > 0.0:
            dialogue_time = maxf(0.0, dialogue_time - delta)
            if dialogue_time == 0.0:
                _show_dialogue(false)
        if hint.text != last_hint:
            last_hint = hint.text
            hint_time = 3.0
        hint_time = maxf(0.0, hint_time - delta)
    hint.visible = hint_time > 0.0 and not hint.text.is_empty()
    if not is_paused and not shop.visible and step in [Step.FIGHT, Step.PRACTICE]:
        for tower: DefenseTower in board.towers:
            if is_instance_valid(tower):
                tower.freeze_cooldown = maxf(0.0, tower.freeze_cooldown - delta)
        board.tick(delta)
        if step == Step.PRACTICE and not is_instance_valid(board.zombie) and practice_left > 0:
            spawn_delay -= delta
            if spawn_delay <= 0.0:
                _spawn_zombie()
    _refresh_stats()


func _set_step(value: Step) -> void:
    step = value
    advance_time = message_read_seconds if step in [Step.DEBRIEF, Step.SEMIBOSS] else 0.0
    _show_dialogue(true)
    dialogue_time = combat_message_seconds if step in [Step.FIGHT, Step.PRACTICE] else 0.0
    var instructions: Array[String] = [
        "Open the shop: cart icon or B.",
        "Buy a Standard tower.",
        "Your tower is ready.",
        "I'm Sphinx. Let's defend our kingdom!",
        "Your tower is ready! Place it in an empty green cell.",
        "The zombie's health is inside its green bar.",
        "Health is inside the green bars. Click your tower to inspect it.",
        "Upgrade your tower for more health and power.",
        "Click your tower. Use Q / Freeze, then click the zombie.",
        "Freeze stops zombies and doubles your firing speed!",
        "You earned gold! The next wave starts shortly.",
        "Defend the kingdom! Use Freeze when enemies reach your tower.",
        "A semiboss comes at the end of every wave. Use Freeze when it enters tower range!",
        "Victory! You've learned to defend the kingdom.",
        "Kingdom lost. Open settings to restart and try Freeze."
    ]
    guide.text = "%s: %s" % [guide_name, instructions[step]]
    if step == Step.WON:
        tower_popup_open = false
        $HUD/Dialogue.hide()
        $HUD/DialogueToggle.hide()
        $VictoryCelebration.celebrate()
    _layout_dialogue()
    hint.text = ""
    _refresh_stats()


func _toggle_dialogue() -> void:
    _show_dialogue(not $HUD/Dialogue.visible)


func _show_dialogue(show_words: bool) -> void:
    $HUD/Dialogue.visible = show_words
    var toggle: Button = $HUD/DialogueToggle
    toggle.text = "×" if show_words else "?"
    _layout_dialogue()
    dialogue_time = 0.0


func _layout_dialogue() -> void:
    var panel: Panel = $HUD/Dialogue
    var height: float = 72.0
    panel.position.y = 632.0 - height
    panel.size.y = height
    $HUD/Dialogue/Text.size.y = height - 20.0
    $HUD/Dialogue/Portrait.position.y = 8.0
    $HUD/Dialogue/Portrait.size.y = height - 16.0
    $HUD/DialogueToggle.position = Vector2(852, panel.position.y + 12.0) if panel.visible else Vector2(20, 592)


func _toggle_shop() -> void:
    if is_paused or step in [Step.WON, Step.LOST]:
        return
    if not shop.visible and (pending_tower or step not in [Step.SHOP, Step.BUY, Step.PRACTICE]):
        hint.text = "Place your tower first." if pending_tower else "Finish Sphinx's lesson first."
        return
    shop.visible = not shop.visible
    get_node("/root/Sfx").set_combat_paused(shop.visible)
    board.freeze_aiming = false
    shop.get_node("Card/Contents/Feedback").text = ""
    if shop.visible:
        _deselect_tower()
        _show_dialogue(false)
    if step == Step.SHOP:
        _set_step(Step.BUY)
        _show_dialogue(false)
    _refresh_stats()


func _buy() -> void:
    if is_paused or not shop.visible or step not in [Step.BUY, Step.PRACTICE]:
        return
    if pending_tower:
        hint.text = "You already bought a tower. Close the shop and place it first."
        return
    if gold < balance.tower_cost:
        shop.get_node("Card/Contents/Feedback").text = "Not enough gold."
        return
    var has_space: bool = false
    for index: int in board.build_cells():
        if not board.occupied(index):
            has_space = true
    if not has_space:
        shop.get_node("Card/Contents/Feedback").text = "No empty cells. Sell a tower first."
        return
    gold -= balance.tower_cost
    pending_tower = true
    board.placing = true
    board.queue_redraw()
    shop.hide()
    get_node("/root/Sfx").set_combat_paused(false)
    if step == Step.BUY:
        _spawn_zombie(410.0)
        _set_step(Step.PLACE)
    else:
        hint.text = "Choose an empty cell."
        _show_dialogue(false)
    _refresh_stats()


func _on_board_clicked(point: Vector2) -> void:
    if is_paused or shop.visible or step in [Step.WON, Step.LOST]:
        return
    var zombie: TutorialZombie = board.zombie
    var hit_zombie: bool = is_instance_valid(zombie) and not zombie.settled and point.distance_to(zombie.position + Vector2(0, -20)) < (60.0 if zombie.is_semiboss else 48.0)
    if board.freeze_aiming:
        if not hit_zombie:
            hint.text = "Choose a zombie, or Esc to cancel Freeze."
            return
        _cast_freeze()
        return
    if pending_tower and step in [Step.PLACE, Step.PRACTICE]:
        var index: int = board.cell_at(point)
        if index < 0 or board.occupied(index):
            hint.text = "Choose an empty grid cell near the castle. No extra gold was charged."
            return
        selected_tower = board.add_tower(index, balance)
        tower_popup_open = false
        selected_tower.destroyed.connect(_on_tower_destroyed)
        pending_tower = false
        board.placing = false
        if step == Step.PLACE:
            board.align_lesson_enemy(selected_tower)
            _set_step(Step.TOWER)
        board.queue_redraw()
        _refresh_stats()
        return
    if hit_zombie:
        _deselect_tower()
        return
    else:
        var tower: DefenseTower = board.tower_at(point)
        if tower != null:
            selected_tower = tower
            tower_popup_open = true
            if step == Step.TOWER:
                _set_step(Step.UPGRADE)
        else:
            selected_tower = null
            tower_popup_open = false
    _refresh_stats()


func _upgrade() -> void:
    if is_paused or step not in [Step.UPGRADE, Step.PRACTICE] or not is_instance_valid(selected_tower):
        return
    if selected_tower.upgraded:
        hint.text = "This tower already has its tutorial upgrade."
        return
    if gold < balance.upgrade_cost:
        hint.text = "Not enough gold to upgrade."
        return
    gold -= balance.upgrade_cost
    selected_tower.upgrade()
    tower_popup_open = false
    if step == Step.UPGRADE:
        _set_step(Step.FREEZE)
    _refresh_stats()


func _sell() -> void:
    if is_paused or step != Step.PRACTICE or not is_instance_valid(selected_tower):
        return
    var paid: int = balance.tower_cost + (balance.upgrade_cost if selected_tower.upgraded else 0)
    gold += floori(paid * 0.5)
    selected_tower.settled = true
    selected_tower.queue_free()
    selected_tower = null
    board.queue_redraw()
    hint.text = "Tower sold for half of its total purchase and upgrade cost."
    _refresh_stats()


func _activate_skill(slot: int) -> void:
    if not tower_popup_open or not is_instance_valid(selected_tower) or selected_tower.settled:
        return
    if slot < 0 or slot >= mini(DefenseTower.MAX_SKILLS, selected_tower.skills.size()):
        return
    if selected_tower.skills[slot] == &"freeze":
        _aim_freeze()


func _aim_freeze() -> void:
    if is_paused or shop.visible or step not in [Step.FREEZE, Step.FIGHT, Step.PRACTICE]:
        return
    if not is_instance_valid(selected_tower) or selected_tower.settled or not selected_tower.skills.has(&"freeze"):
        return
    if freeze_cooldown > 0.0:
        hint.text = "Freeze recharges in %.1f seconds." % freeze_cooldown
        return
    if not is_instance_valid(board.zombie):
        hint.text = "Wait for the next zombie."
        return
    tower_popup_open = false
    board.freeze_aiming = not board.freeze_aiming
    hint.text = "Click the zombie to Freeze it." if board.freeze_aiming else "Freeze targeting cancelled."
    board.queue_redraw()


func _cast_freeze() -> void:
    if not is_instance_valid(board.zombie) or not is_instance_valid(selected_tower) or selected_tower.settled or freeze_cooldown > 0.0:
        return
    board.zombie.freeze(balance.freeze_duration)
    get_node("/root/Sfx").play(&"freeze")
    freeze_cooldown = balance.freeze_recharge
    board.freeze_aiming = false
    if step == Step.FREEZE:
        # Leave a moment to read the ice effect before the first demonstration shot.
        for tower: DefenseTower in board.towers:
            if is_instance_valid(tower):
                tower.cooldown = balance.shot_interval
        _set_step(Step.FIGHT)
    hint.text = "Freeze cast! Target stopped for up to %.0f seconds." % balance.freeze_duration
    board.queue_redraw()


func _spawn_zombie(start_x: float = 60.0) -> void:
    var semiboss: bool = step == Step.PRACTICE and practice_left == 1
    var zombie: TutorialZombie = board.spawn_zombie(balance, start_x, semiboss)
    zombie.died.connect(_on_zombie_died.bind(zombie))
    zombie.gate_hit.connect(_on_gate_hit)
    if semiboss:
        for tower: DefenseTower in board.towers:
            if is_instance_valid(tower):
                tower.freeze_cooldown = 0.0
        board.freeze_aiming = false
        _set_step(Step.SEMIBOSS)


func _on_zombie_died(zombie: TutorialZombie) -> void:
    var reward: int = zombie.gold_reward
    gold += reward
    board.freeze_aiming = false
    if step == Step.FIGHT:
        _set_step(Step.DEBRIEF)
    elif step == Step.PRACTICE:
        practice_left -= 1
        spawn_delay = 2.0
        if practice_left == 0:
            _set_step(Step.WON)
    hint.text = "%s defeated! Gold collected." % ("Semiboss" if zombie.is_semiboss else "Zombie")
    _refresh_stats()


func _on_gate_hit(damage: int) -> void:
    if step != Step.PRACTICE:
        return
    kingdom_health = maxi(0, kingdom_health - damage)
    hint.text = "The zombie is attacking the kingdom!"
    if kingdom_health == 0:
        _set_step(Step.LOST)


func _on_tower_destroyed() -> void:
    hint.text = "A tower was destroyed! Select another tower or build a replacement."
    if not is_instance_valid(selected_tower) or selected_tower.settled:
        selected_tower = null
        tower_popup_open = false
        board.freeze_aiming = false
    board.queue_redraw()


func _advance_after_message() -> void:
    if is_paused:
        return
    if step == Step.DEBRIEF:
        practice_left = balance.practice_zombies
        for tower: DefenseTower in board.towers:
            if is_instance_valid(tower):
                tower.freeze_cooldown = 0.0
        _set_step(Step.PRACTICE)
        _spawn_zombie()
    elif step == Step.SEMIBOSS:
        _set_step(Step.PRACTICE)
        guide.text = "%s: Click your tower, then Q / Freeze and choose the semiboss!" % guide_name


func _toggle_pause() -> void:
    is_paused = not is_paused
    get_node("/root/Sfx").set_combat_paused(is_paused)
    $SettingsOverlay.visible = is_paused
    if is_paused:
        tower_popup_open = false
        shop.hide()
        board.freeze_aiming = false
    _refresh_stats()


func _deselect_tower() -> void:
    tower_popup_open = false
    board.freeze_aiming = false
    selected_tower = null
    _refresh_stats()


func _refresh_stats() -> void:
    if not is_node_ready():
        return
    var phase: String = "Lesson %d/9" % mini(int(step) + 1, 9)
    if step == Step.PRACTICE:
        phase = "Defense: %d left" % practice_left
    elif step == Step.SEMIBOSS:
        phase = "SEMIBOSS - wave finale"
    elif step == Step.WON:
        phase = "VICTORY"
    elif step == Step.LOST:
        phase = "DEFEAT"
    status.text = phase.to_upper()
    $HUD/TopBar/Gold.text = str(gold)
    $HUD/TopBar/Kingdom.max_value = balance.kingdom_health
    $HUD/TopBar/Kingdom.value = kingdom_health
    $HUD/TopBar/Kingdom/Value.text = "%d / %d" % [kingdom_health, balance.kingdom_health]
    var title: String = "Select a tower"
    var hp: int = 0
    var maximum: int = 1
    var damage: int = 0
    var extra: String = ""
    var has_tower: bool = is_instance_valid(selected_tower) and not selected_tower.settled
    if has_tower:
        title = "STANDARD TOWER  /  %s" % ("II" if selected_tower.upgraded else "I")
        hp = selected_tower.health
        maximum = selected_tower.max_health
        damage = selected_tower.power
        var boosted: bool = is_instance_valid(board.zombie) and board.zombie.freeze_left > 0.0 and selected_tower.position.distance_to(board.zombie.position) <= balance.tower_range
        var interval: float = balance.boosted_interval if boosted else balance.shot_interval
        extra = "Range %d px | %.1fs per shot%s" % [int(balance.tower_range), interval, "\nFreeze boost active!" if boosted else ""]
    side.get_node("Selection").text = title
    side.get_node("Health/Value").text = "%d / %d" % [hp, maximum]
    side.get_node("Health").max_value = maximum
    side.get_node("Health").value = hp
    side.get_node("PowerLabel").text = "%d damage" % damage
    var card: PanelContainer = $HUD/SelectionCard
    card.visible = tower_popup_open and has_tower and not shop.visible and not is_paused
    if card.visible:
        # Keep the contextual card beside its tower and clear of the HUD/dialogue.
        var target: Vector2 = board.position + selected_tower.position
        var bottom: float = $HUD/Dialogue.position.y - 12.0 if $HUD/Dialogue.visible else 632.0
        card.position = Vector2(
            clampf(target.x + 56.0, 16.0, 1136.0 - card.size.x),
            clampf(target.y - card.size.y * 0.5, 76.0, bottom - card.size.y))
    side.get_node("Extra").text = extra
    for slot: int in DefenseTower.MAX_SKILLS:
        var button: Button = side.get_node("Skills/" + "QWER"[slot])
        var is_freeze: bool = has_tower and slot < selected_tower.skills.size() and selected_tower.skills[slot] == &"freeze"
        button.get_node("Name").text = ("Freeze" if freeze_cooldown <= 0.0 else "%ds" % ceili(freeze_cooldown)) if is_freeze else "Empty"
        button.get_node("Icon").visible = is_freeze
        button.disabled = not is_freeze or is_paused or shop.visible or step not in [Step.FREEZE, Step.FIGHT, Step.PRACTICE] or freeze_cooldown > 0.0
        button.modulate = Color.WHITE if is_freeze else Color(0.5, 0.6, 0.6, 0.65)
        button.tooltip_text = "Freeze: stop a zombie for 5s. Choose a target after activating." if is_freeze else "No skill assigned to " + "QWER"[slot]
    side.get_node("Upgrade").text = "Fully upgraded" if has_tower and selected_tower.upgraded else "Upgrade · %d gold" % balance.upgrade_cost
    side.get_node("Upgrade").disabled = is_paused or step not in [Step.UPGRADE, Step.PRACTICE] or not has_tower or selected_tower.upgraded or gold < balance.upgrade_cost
    side.get_node("Sell").text = "Sell · %d gold" % floori((balance.tower_cost + (balance.upgrade_cost if has_tower and selected_tower.upgraded else 0)) * 0.5)
    side.get_node("Sell").disabled = is_paused or step != Step.PRACTICE or not is_instance_valid(selected_tower)
    for tower: DefenseTower in board.towers:
        if is_instance_valid(tower):
            tower.selected = tower_popup_open and tower == selected_tower
            tower.queue_redraw()
    _update_tutorial_cue()


func _update_tutorial_cue() -> void:
    var cue: Control = $TutorialCue
    if step == Step.WON:
        cue.focus("")
        return
    var target: Control = null
    var point: Vector2 = Vector2.ZERO
    var world_id: String = ""
    if is_paused:
        target = $SettingsOverlay/Card/Contents/Restart if step == Step.LOST else $SettingsOverlay/Card/Contents/Resume
    elif shop.visible:
        if step == Step.BUY:
            target = shop.get_node("Card/Contents/Buy")
    elif step in [Step.SHOP, Step.BUY]:
        target = $HUD/TopBar/Shop
    elif step == Step.PLACE:
        var cell: int = board.placement_cue_cell()
        if cell >= 0:
            cue.focus("BuildCell", Rect2(board.position + board.cell_rect(cell).position, board.CELL_SIZE))
        else:
            cue.focus("")
        return
    elif step == Step.UPGRADE and tower_popup_open:
        target = side.get_node("Upgrade")
    elif step in [Step.TOWER, Step.UPGRADE, Step.FREEZE] or (step == Step.PRACTICE and is_instance_valid(board.zombie) and board.zombie.is_semiboss and board.zombie.freeze_left <= 0.0):
        if board.freeze_aiming and is_instance_valid(board.zombie):
            point = board.zombie.position + Vector2(0, -24)
            world_id = "Zombie"
        elif tower_popup_open and step in [Step.FREEZE, Step.PRACTICE]:
            if freeze_cooldown <= 0.0:
                var slot: int = selected_tower.skills.find(&"freeze")
                if slot >= 0 and slot < DefenseTower.MAX_SKILLS:
                    target = side.get_node("Skills/" + "QWER"[slot])
        else:
            for tower: DefenseTower in board.towers:
                if is_instance_valid(tower) and not tower.settled:
                    point = tower.position
                    world_id = "Tower"
                    break
    elif step == Step.LOST:
        target = $HUD/TopBar/Settings
    if target != null and target.is_visible_in_tree() and not (target is Button and target.disabled):
        cue.focus(str(target.name), target.get_global_rect(), target)
    elif not world_id.is_empty():
        cue.focus(world_id, Rect2(board.position + point - Vector2(40, 48), Vector2(80, 96)))
    else:
        cue.focus("")


func _restart() -> void:
    get_tree().reload_current_scene()


func _back_to_menu() -> void:
    get_tree().change_scene_to_file("res://scenes/main.tscn")
