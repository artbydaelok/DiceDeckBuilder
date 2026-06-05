extends Resource
class_name Deck
## A temporary 6-side loadout that replaces the player's dice faces for a specific
## puzzle (color matching, poker, directions, …). A Deck is NOT player inventory:
## it is swapped in via CardSystem.equip_deck() and swapped back out with clear_deck(),
## and it never touches the save file.
##
## Variants (2/3/6-color, LR-only directions, etc.) are just different Deck resources —
## data only, no code.

## Shown in UI / for debugging.
@export var deck_name: String = "Deck"

## Exactly six side cards (index 0 = face 1 … index 5 = face 6). Each card's
## `face_value` carries the puzzle-meaning of that side ("blue", "hearts", "up", …).
@export var sides: Array[Card] = []
