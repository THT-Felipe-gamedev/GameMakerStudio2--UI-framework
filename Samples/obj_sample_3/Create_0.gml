/*
FEATURES

- Flex layout system
- Reusable UI creators/builders
- Buttons
- Labels
- Textboxes
- Checkboxes
- Dropdowns
- UI classes/groups
- Visibility control
- Context data
- Callbacks/events
- Auto sizing
- Alignment system
- Layer system

ARCHITECTURE

This sample also demonstrates how
generic creators/helpers can be used
to scale UI creation efficiently and
keep interfaces modular and reusable.

NOTES
----------------------------------------
This sample was designed to demonstrate
real-world UI organization and reusable
UI patterns using the UINode framework.
*/


#region MAIN PANELS
// Main pause menu panel
var man_p = {
	sprite:	spr_painel,
	class:	"main_panel",
	
	// Layout configuration
	justify_content:	JUSTIFY_CONTENT.SPACE_AROUND,
	flex_direction:		UINodeFlexDirection.COLUMN,
	UI_layer:			UILayer.BACKGROUND,
	
	// Size and padding
	width:	"25%",
	height:	"55%",
	p_all:	10,
}

// Settings panel (starts hidden)
var set_p = {
	position:	UINodePosition.ABSOLUTE,
	
	// Center the panel on screen
	x: "50%",
	y: "50%",
	
	x_offset:	UI_HALIGN.CENTER,
	y_offset:	UI_VALIGN.MIDDLE,
	
	UI_layer:	UILayer.BACKGROUND,
	
	// Layout configuration
	justify_content:	JUSTIFY_CONTENT.SPACE_AROUND,
	align_items:		ALIGN_ITEMS.START,
	flex_direction:		UINodeFlexDirection.COLUMN,
	gap_y:				5,
	
	// Visual configuration
	sprite:		spr_painel,
	class:		"settings",
	visible:	false,
	
	// Size and padding
	width:	"80%",
	height:	"80%",
	p_all:	10,
}

// Create main panels
main_panel			= UINode_create(UINodeType.PANEL, man_p)
settings_panel		= UINode_create(UINodeType.PANEL, set_p)

var settings_id		= UINode_get_id(settings_panel)
var main_panel_id	= UINode_get_id(main_panel)
#endregion


#region SETTINGS SUB PANELS
// Header area
var hea_set = {
	width:	"100%",
	height:	"auto",
	
	justify_content:	JUSTIFY_CONTENT.SPACE_BETWEEN,
	
	class:		"settings",
	visible:	false,
	parent:		settings_id
}

// Generic row area
var nam_p = {
	width:	"96%",
	height:	"10%",
	p_x:	"2%",
	
	justify_content:	JUSTIFY_CONTENT.SPACE_BETWEEN,
	align_items:		ALIGN_ITEMS.CENTER,
	flex_direction:		UINodeFlexDirection.ROW_REVERSE,
	
	class:		"settings",
	visible:	false,
	parent:		settings_id
}

// Create areas
header_settings		= UINode_create(UINodeType.PANEL, hea_set)

name_area			= UINode_create(UINodeType.PANEL, nam_p)
screen_area			= UINode_create(UINodeType.PANEL, nam_p)
language_area		= UINode_create(UINodeType.PANEL, nam_p)
#endregion


#region BUTTON CREATOR
// Generic button creator
var _btn_creator = function(_parent, tag_name, _class) constructor {
	sprite	= spr_button
	
	// Automatic sizing
	width	= "auto"
	height	= "auto"
	min_width = 50
	
	// Metadata
	class	= _class
	tag		= tag_name
	
	// Main panel buttons start visible
	visible = (_class == "main_panel")
	
	// Padding
	p_all = 5
	
	// Text configuration
	text		= tag_name
	font		= fnt_button
	font_color	= c_black
	
	// Alignment
	inner_halign	= UI_HALIGN.CENTER
	inner_valign	= UI_VALIGN.MIDDLE
	
	halign			= fa_center
	valign			= fa_middle
	
	// Parent and callback
	parent		= UINode_get_id(_parent)
	on_click	= button_on_click
}

// Main menu buttons
var main_panel_btn_name = ["resume", "settings", "exit"]

for (var i = 0; i < array_length(main_panel_btn_name); i++) {
	var name = main_panel_btn_name[@ i]
	
	UINode_create(UINodeType.BUTTON, new _btn_creator(main_panel, name, "main_panel"))
}

// Settings "back" button
UINode_create(UINodeType.BUTTON, new _btn_creator(header_settings, "back", "settings"))
#endregion


#region LABEL CREATOR
// Generic label creator
var lbl_set_creator = function(_parent, in_hal, _text, _margin_right = 0) constructor {
	width	= "auto"
	height	= "auto"
	m_r		= _margin_right
	
	class	= "settings"
	visible	= false
	
	// Text configuration
	text		= _text
	font		= fnt_default
	font_color	= c_black
	
	// Alignment
	halign			= fa_center
	valign			= fa_middle
	
	inner_valign	= UI_VALIGN.MIDDLE
	inner_halign	= in_hal
	
	// Highlight "project_name"
	if string_contains("project_name: ", _text) {
		span = [create_color_span(c_red, [1, string_length("project_name: ")])]
	}
	
	parent = UINode_get_id(_parent)
}

// Settings title label
UINode_create(
	UINodeType.LABEL,
	new lbl_set_creator(
		header_settings,
		UI_HALIGN.LEFT,
		"SETTINGS",
		"25%"
	)
)
#endregion


#region CHECKBOX CREATOR
// Generic checkbox creator
var checkb_creator = function(_parent, glob_val) constructor {
	sprite	= spr_checkbox
	
	width	= 32
	height	= 32
	
	class	= "settings"
	visible	= false
	
	// Initial value
	value = global[$ glob_val]
	
	// Store global variable name
	context = {
		my_global: glob_val
	}
	
	// Sync global variable on change
	on_change = function(node) {
		node.assets.image_index					= node.value
		global[$ node.inner.context.my_global]	= node.value
	}
	
	parent = UINode_get_id(_parent)
}
#endregion


#region NAME AREA
// Label displaying current project/player name
label_name = UINode_create(
	UINodeType.LABEL,
	new lbl_set_creator(
		name_area,
		UI_HALIGN.CENTER,
		$"project_name: {global.name}"
	)
)

// Textbox used to change the project/player name
var txtb_nam = {
	sprite:	spr_dropdown,
	
	width:	"20%",
	height:	"50%",
	
	class:	"settings",
	visible: false,
	
	min_height: 25,
	max_height: 100,
	
	text:	global.name,
	font:	fnt_default,
	
	parent:	UINode_get_id(name_area),
	
	context: {
		label: UINode_get_id(label_name)
	},
	
	// Update label after submitting text
	on_submit: function(node) {
		global.name = node.text.content
		
		var my_lbl = get_UINode_by_id(node.inner.context.label)
		
		my_lbl.text.set_content(
			$"project_name: {global.name}"
		)
	}
}

UINode_create(UINodeType.TEXTBOX, txtb_nam)
#endregion


#region SCREEN AREA
// Fullscreen label
UINode_create(UINodeType.LABEL, new lbl_set_creator(screen_area, UI_HALIGN.LEFT, "... FULLSCREEN"))

// Fullscreen checkbox
UINode_create(
	UINodeType.CHECKBOX,
	new checkb_creator(screen_area, "fullscreen")
)
#endregion


#region LANGUAGE AREA
// Dropdown configuration
var drop_lan = {
	sprite:	spr_dropdown,
	
	width:	"20%",
	height:	"70%",
	
	class:	"settings",
	visible:	false,
	
	min_width:	100,
	min_height:	20,
	
	// Dropdown options
	options: [
		"English",
		"Portugues",
		"Deutsch",
		"Français"
	],
	
	selected: 0,
	
	open_style:		dropdown_sprite_style(spr_dropdown, 0),
	open_layout:	dropdown_scroll_layout(2, 2, 0.9),
	
	// Alignment
	halign:			fa_center,
	valign:			fa_middle,
	
	inner_valign:	UI_VALIGN.MIDDLE,
	inner_halign:	UI_HALIGN.CENTER,
	
	parent:	UINode_get_id(language_area)
}

// Language label
UINode_create(UINodeType.LABEL, new lbl_set_creator(language_area, UI_HALIGN.LEFT, "... LANGUAGE"))

// Language dropdown
UINode_create(UINodeType.DROPDOWN, drop_lan)
#endregion