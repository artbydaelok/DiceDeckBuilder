extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var item_icon: TextureRect = %ItemIcon
@onready var description_label: Label = %DescriptionLabel
@onready var cost_label: Label = %CostLabel

var item_data : Card

# Called on Shop UI on setup 
func setup():
	name_label.text = item_data.card_name
	description_label.text = item_data.card_description
	item_icon.texture = item_data.card_artwork
	cost_label.text = str(item_data.value)
