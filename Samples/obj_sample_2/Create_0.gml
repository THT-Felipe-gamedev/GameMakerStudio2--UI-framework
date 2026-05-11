// This example demonstrates how reusable creators/helpers
// can be used to scale UI creation efficiently.

var man_p = {
	// Sets the sprite
	sprite: spr_painel,
	
	// Sets the content to space around
	justify_content:	JUSTIFY_CONTENT.START,
	flex_direction:		UINodeFlexDirection.COLUMN,
	
	// Set size and padding
	width:	"90%",
	height:	"90%",
	p_all: 20,
}

main_panel			= UINode_create(UINodeType.PANEL, man_p)
var main_panel_id	= UINode_get_id(main_panel)

// Helper to easily create an slider
var slider_creator	= function(my_parent, my_lbl, type) constructor {
	
	// GENERIC ON CHANGE FUNCTION
	var on_slider_change	= function(node) {
		var label_id	= node.inner.context.label	// Gets the label's id
		var sound_type	= node.inner.context.type	// Get it sound type (Ex: "SFX")
	
		// Change the respective sound to the slider value
		global[$ sound_type]	= node.slider_values.final
	
		// Gets the label
		var my_label	= get_UINode_by_id(label_id)
	
		// Changes the label text
		my_label.text.set_content($"{sound_type}: {global[$ sound_type]}")
	}
	
	var lbl_id	= UINode_get_id(my_lbl)		// Get the respective label's id
	var par_id	= UINode_get_id(my_parent)	// Get the parent's id
	
	// Sprite set (Empty, Full and Knob)
	sprite_set	= {empty: spr_sliderEmpty, full: spr_sliderFull, knob: spr_knob}
	
	// Sizes
	width	= "20%"
	height	= "10%"
	
	// Minimum sizes
	min_width	= 100
	min_height	= 10
	
	// How many steps the slider has and it start value
	steps	= 100
	value	= global[$ type]
	
	// Parent and context
	parent	= par_id
	context	= {label: lbl_id, type: type}
	
	on_change	= on_slider_change	// On change
}

// Label helper
var label_creator	= function(my_parent, type) constructor {
	var par_id	= UINode_get_id(my_parent)
	
	// Sizes
	width	= "10%"
	height	= "100%"
	
	// Fonts configure
	text		= $"{type}: {global[$ type]}"
	font		= fnt_default
	font_color	= c_black
	
	// Inner halign and valign configure
	inner_valign	= UI_VALIGN.MIDDLE
	inner_halign	= UI_HALIGN.RIGHT
	valign			= fa_middle
	halign			= fa_right
	
	// Parent
	parent = par_id
}

var place_helper = function(_parent) constructor {
	m_t		= "2%"
	width	= "100%"
	height	= "15%"
	
	justify_content		= JUSTIFY_CONTENT.SPACE_BETWEEN
	flex_direction		= UINodeFlexDirection.ROW_REVERSE
	parent				= UINode_get_id(_parent)
}

sfx_place	 = UINode_create(UINodeType.PANEL, new place_helper(main_panel))
bgm_place	 = UINode_create(UINodeType.PANEL, new place_helper(main_panel))
bgs_place	 = UINode_create(UINodeType.PANEL, new place_helper(main_panel))

#region SFX
label_sfx	 = UINode_create(UINodeType.LABEL, new label_creator(sfx_place, "SFX"))
slider_sfx = UINode_create(UINodeType.SLIDER,  new slider_creator(sfx_place, label_sfx, "SFX"))
#endregion

#region BGM
label_bgm	 = UINode_create(UINodeType.LABEL, new label_creator(bgm_place, "BGM"))
slider_bgm = UINode_create(UINodeType.SLIDER,  new slider_creator(bgm_place, label_bgm, "BGM"))
#endregion

#region BGS
label_bgs	 = UINode_create(UINodeType.LABEL, new label_creator(bgs_place, "BGS"))
slider_bgs = UINode_create(UINodeType.SLIDER,  new slider_creator(bgs_place, label_bgs, "BGS"))
#endregion
