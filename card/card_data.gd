extends Resource
class_name Card

@export var card_name : String = "Card Name"
@export var ability_id : String = ""
@export_multiline var card_description : String = "This is where the card description goes."
@export var card_artwork : Texture2D
## How much energy it takes to use this card.
@export var cost : int = 0
## How much will the player commit to be able to perform this attack
@export var commit_value : float = 0.1
## How much this card is sold for
@export var value : int = 0
