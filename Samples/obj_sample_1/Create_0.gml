// This example demonstrates:
// - Parent/child hierarchy
// - Vertical flex layouts
// - Scroll containers
// - Button callbacks
// - Context data usage

var generic_on_click = function(node) {
	node.inner.context.label.text.set_content($"last button: {node.core.id}")
}

var man_p = {
	// Sets the sprite
	sprite: spr_painel,
	
	// Sets the content to space around
	justify_content:	JUSTIFY_CONTENT.SPACE_AROUND,
	
	// Set size and padding
	width: "90%",
	height: "90%",
	p_all: 10,
}

main_panel	= UINode_create(UINodeType.PANEL, man_p)	// Creates de panel
var main_id	= UINode_get_id(main_panel)					// Gets it ID

var scr_area = {
	width: "20%",
	height: "100%",
	
	// Turns it into a column
	justify_content:	JUSTIFY_CONTENT.START,
	flex_direction:		UINodeFlexDirection.COLUMN,
	gap_y:				5,
	
	// Enable vertical scrolling for overflowing content
	// (doesn't need to be the hovered, only ith me pointer in the bounds is enough)
	scroll_flow:		UINodeScrollFlow.VERTICAL,
	scroll_must_hover:	false,
	
	// Set parent (main_panel)
	parent:	main_id
}

var lbl = {
	width:	175,
	height:	"auto",
	
	halign: fa_left,
	
	// Set text and font
	text:		"last button: noone",
	font:		fnt_default,
	font_color:	c_black,
	
	// Set parent (main_panel)
	parent:	main_id
}

scroll_area		= UINode_create(UINodeType.PANEL, scr_area)	// Creates the scroll area
label			= UINode_create(UINodeType.LABEL, lbl)		// Creates the label
var scroll_id	= UINode_get_id(scroll_area)				// Get it id

var sub_p = {
	sprite: spr_dropdown,
	
	width: "80%",
	height: 50,
	
	p_x:		"10%",
	on_click:	generic_on_click,
	
	parent:		scroll_id,
	context:	{label: label},
	
	scissor_rect:	scroll_id,
	enable_scissor:	true
}

// Creates n Buttons
repeat(20) {
	UINode_create(UINodeType.BUTTON, sub_p)
}