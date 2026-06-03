extends Node
## Wraps known card/item names in quest text with RichTextLabel BBCode link tags.
## Registered as the `QuestTextParser` autoload.
##
## Usage:
##   rich_label.bbcode_enabled = true
##   rich_label.text = QuestTextParser.parse(quest["description"])
##   rich_label.meta_clicked.connect(_on_keyword_clicked)
##
##   func _on_keyword_clicked(meta: String):
##       if meta.begins_with("card:"):
##           pass  # open the card in your deck/card viewer
##
## To highlight more names, add entries to CARD_KEYWORDS below. Keys are matched
## case-insensitively on whole words; the value is the BBCode meta passed to
## meta_clicked (convention: "card:<ability_id>").

const HIGHLIGHT_COLOR := "#ffd866"

# lowercase display name -> meta id
const CARD_KEYWORDS := {
	"arrow": "card:arrow",
	"axe": "card:axe",
	"balloon": "card:balloon",
	"bear swipe": "card:swipe",
	"shotgun": "card:shotgun",
	"revolver": "card:revolver",
	"grenade": "card:grenade",
	"bear trap": "card:bear_trap",
	"lantern": "card:lantern",
}


## Returns the input text with every known keyword wrapped in a [url][color] tag.
## Single-pass so already-wrapped text is never re-wrapped.
func parse(text: String) -> String:
	if text.is_empty() or CARD_KEYWORDS.is_empty():
		return text

	# Longest keys first so multi-word names (e.g. "bear swipe") win over "bear".
	var keys: Array = CARD_KEYWORDS.keys()
	keys.sort_custom(func(a, b): return a.length() > b.length())

	var alternation := ""
	for key in keys:
		if alternation != "":
			alternation += "|"
		alternation += _escape_regex(key)

	var re := RegEx.new()
	# (?i) case-insensitive, \b word boundaries.
	if re.compile("(?i)\\b(" + alternation + ")\\b") != OK:
		return text

	var out := ""
	var last := 0
	for m in re.search_all(text):
		out += text.substr(last, m.get_start() - last)
		var matched := text.substr(m.get_start(), m.get_end() - m.get_start())
		var meta: String = CARD_KEYWORDS.get(matched.to_lower(), "")
		if meta == "":
			out += matched
		else:
			out += "[url=%s][color=%s]%s[/color][/url]" % [meta, HIGHLIGHT_COLOR, matched]
		last = m.get_end()
	out += text.substr(last)
	return out


func _escape_regex(s: String) -> String:
	var specials := "\\.^$*+?()[]{}|"
	var result := ""
	for c in s:
		if specials.contains(c):
			result += "\\"
		result += c
	return result
