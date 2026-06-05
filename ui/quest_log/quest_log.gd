extends Control
## Quest log UI. Builds quest entry cards procedurally from QuestDatabase +
## QuestManager, grouped into the Main / Side / Challenge tabs. Refreshes live
## when quests update. Opened/closed by QuestManager (the "open_quest_log" action).

@onready var _tabs: TabContainer = %QuestTabs
@onready var _lists := {
	"main": %MainList,
	"side": %SideList,
	"challenge": %ChallengeList,
}
@onready var _back_button: Button = %BackButton

const HIGHLIGHT_DISABLED := Color(0.6, 0.6, 0.6)


func _ready() -> void:
	GameEvents.menu_entered.emit()
	_back_button.pressed.connect(close)
	QuestManager.quest_updated.connect(_on_quest_changed)
	QuestManager.quest_completed.connect(_on_quest_changed)
	QuestManager.check_all()
	_rebuild()
	# Focus something so the log is navigable by keyboard/gamepad on open.
	_back_button.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	GameEvents.menu_exited.emit()
	queue_free()


# ── Building ──────────────────────────────────────────────────────────────────

func _rebuild() -> void:
	for list in _lists.values():
		for child in list.get_children():
			child.queue_free()

	for quest_id in QuestDatabase.QUESTS.keys():
		if not QuestManager.is_unlocked(quest_id):
			continue
		var def: Dictionary = QuestDatabase.QUESTS[quest_id]
		var category: String = def.get("category", "main")
		var list: VBoxContainer = _lists.get(category, _lists["main"])
		list.add_child(_build_entry(quest_id, def))

	# A rebuild (e.g. after claiming) frees the focused button; restore focus so
	# keyboard/gamepad navigation isn't left dead.
	if is_inside_tree() and get_viewport().gui_get_focus_owner() == null:
		_back_button.grab_focus.call_deferred()


func _build_entry(quest_id: String, def: Dictionary) -> Control:
	var p := QuestManager.get_progress(quest_id)
	var target := int(def.get("target", 1))

	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	# Title
	var title := Label.new()
	title.text = def.get("title", quest_id)
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)

	# Description (keyword-highlighted)
	var desc := RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.fit_content = true
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.scroll_active = false
	desc.custom_minimum_size = Vector2(360, 0)
	desc.text = QuestTextParser.parse(def.get("description", ""))
	desc.meta_clicked.connect(_on_keyword_clicked)
	box.add_child(desc)

	# Progress bar + count
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)

	var bar := ProgressBar.new()
	bar.max_value = target
	bar.value = p["progress"]
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(220, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)

	var count := Label.new()
	count.text = "%d / %d" % [p["progress"], target]
	row.add_child(count)

	# Claim button
	var claim := Button.new()
	claim.size_flags_horizontal = Control.SIZE_SHRINK_END
	if p["claimed"]:
		claim.text = "Claimed"
		claim.disabled = true
	elif p["completed"]:
		var coins := int(def.get("reward_coins", 0))
		claim.text = "Claim (%d)" % coins if coins > 0 else "Claim"
		claim.pressed.connect(_on_claim_pressed.bind(quest_id))
	else:
		claim.text = "In Progress"
		claim.disabled = true
	box.add_child(claim)

	return panel


# ── Signals ───────────────────────────────────────────────────────────────────

func _on_claim_pressed(quest_id: String) -> void:
	QuestManager.claim_reward(quest_id)
	# claim_reward emits quest_updated, which triggers _rebuild via _on_quest_changed.


func _on_quest_changed(_quest_id: String) -> void:
	_rebuild()


func _on_keyword_clicked(meta: Variant) -> void:
	var m := str(meta)
	if m.begins_with("card:"):
		# TODO: open the referenced card in the deck/card viewer.
		# The ability id is m.substr(5). Hook this up to your card detail popup.
		print("[QuestLog] keyword clicked: ", m)
