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

#region Secondary input (alternate use)
## Ability fired by the SECONDARY input (RMB / controller B). Empty = this item has
## only one input. Resolved through CardSystem.CARD_ABILITIES_SCENES like ability_id.
@export var secondary_ability_id : String = ""
## Tooltip text for the secondary use. Menus show this alongside card_description.
@export_multiline var secondary_description : String = ""
## Energy cost of the secondary use.
@export var secondary_cost : int = 0
## Commit time of the secondary use.
@export var secondary_commit_value : float = 0.1

## If true, this input charges while held and fires on release; the held time (in
## seconds) is passed to the ability as `charge`. False = fires instantly on press.
@export var chargeable : bool = false
@export var secondary_chargeable : bool = false
#endregion
## How much this card is sold for.
@export var value : int = 0
