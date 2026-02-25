extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var item_icon: TextureRect = %ItemIcon
@onready var description_label: Label = %DescriptionLabel
@onready var cost_label: Label = %CostLabel
@onready var disabled_texture: TextureRect = $DisabledTexture
@onready var hidden_button: Button = $HiddenButton

var item_data : Card

var disabled : bool = false

func _ready() -> void:
	hidden_button.mouse_entered.connect(print_d)
	
func print_d():
	print("Enettereddede")

# Called on Shop UI on setup 
func setup():
	var card_system : CardSystem = get_tree().get_first_node_in_group("card_system")
	if card_system.hand.has(item_data) or card_system.deck.has(item_data):
		disabled = true
		
	name_label.text = item_data.card_name
	description_label.text = item_data.card_description
	item_icon.texture = item_data.card_artwork
	cost_label.text = str(item_data.value)
	
	if disabled:
		disabled_texture.visible = true
