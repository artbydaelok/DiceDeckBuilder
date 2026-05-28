extends Node

## DiceState — global dice snapshot
##
## The player writes here after every roll and icon update.
## The cutscene actor (and anything else that needs to mirror the dice)
## reads from here on _ready() to match rotation and face icons.

# Current mesh basis — set after every roll finishes.
var basis: Basis = Basis.IDENTITY

# Current face mapping — mirrors player.faces.
# Keys: "top", "bottom", "left", "right", "front", "back"
# Values: face number (1–6)
var faces: Dictionary = {
	"top":    2,
	"bottom": 5,
	"left":   6,
	"right":  1,
	"front":  3,
	"back":   4,
}

# Current icon textures indexed by face number (1–6).
# icons[0] = face 1, icons[1] = face 2, etc.
var icons: Array[Texture2D] = [null, null, null, null, null, null]


## Called by the player after every roll to keep state in sync.
func update_after_roll(new_basis: Basis, new_faces: Dictionary) -> void:
	basis = new_basis
	faces = new_faces.duplicate()


## Called by the player (via update_side_icon) whenever a card is assigned.
## side is 1-indexed to match the player's convention.
func update_icon(side: int, texture: Texture2D) -> void:
	if side >= 1 and side <= 6:
		icons[side - 1] = texture
