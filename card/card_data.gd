extends Resource
class_name Card

enum TriggerType {
	ACTIVATE,    ## Manual — player presses the ability button, costs energy.
	ON_FACE_UP,  ## Passive — fires automatically when this face rolls to the top. No energy cost.
	BOTH,        ## Dual — rolls to top fires passive_ability_id, button press fires ability_id.
	LINKED,      ## Synergy — activated by another card that references this slot.
}

@export var card_name : String = "Card Name"
## Ability fired when the player manually activates this card (ACTIVATE or BOTH).
@export var ability_id : String = ""
## Puzzle-semantic value for deck sides (e.g. "blue", "hearts", "up"). Empty for
## normal ability cards. Read by puzzles via CardSystem.get_top_face_value().
@export var face_value : String = ""
## Ability fired automatically when this face rolls to the top (ON_FACE_UP or BOTH).
@export var passive_ability_id : String = ""
@export_multiline var card_description : String = "This is where the card description goes."
@export var card_artwork : Texture2D
## How the ability is triggered.
@export var trigger_type: TriggerType = TriggerType.ACTIVATE
## Energy cost for manual activation. Ignored for ON_FACE_UP and passive half of BOTH.
@export var cost : int = 0
## How long the player commits after activating. Applies to manual activation only.
@export var commit_value : float = 0.1
## How much this card is sold for.
@export var value : int = 0
