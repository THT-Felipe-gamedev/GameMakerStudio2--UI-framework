#region EACH OBJECT LOGIC
#region RADIO BUTTON
/**
@ignore

@param	{Struct}	node	UINode to do the step
@desc	Do the main steps lines of a radio button
*/
/*
@see	_UINode_get_same_group
*/
function __UI_radio_button_step_main(node) {
	// See if was clicked in it
	if mouse_check_button_pressed(mb_left) {
		if node.core.hovered {
			
			var _group		= node.group					// Gets group name
			var _group_same	= UINode_get_same_group(_group)	// Gets all radio in this group
			
			// Turns of all elements of the group
			for(var i = 0; i < array_length(_group_same); i ++) {
				var node_id		= _group_same[i]			// Gets the node id
				var node_stc	= get_UINode_by_id(node_id)	// Gets the node
				
				// Evaluate it
				node_stc.active				= (node_id == node.core.id)	// If haven't id turn it off
				node_stc.assets.image_index	= node_stc.active			// image index equals active
			}
		}
	}
}


#endregion

#region CHECKBOX
/**
@ignore

@param	{Struct}	node	UINode to do the main logic of a checkbox
@desc	Executes the main parts for a UINode checkbox works
*/
function __UI_checkbox_step_main(node) {
	if node == global.UI.hover {
		if global.UI.input.pointer.released {
			
			node.internal.changed	= true
			node.value				= !node.value
			
			if !node.internal.has.on_change {
				node.assets.image_index	= node.value
			}
		}
	}
}
#endregion

#region SLIDER
/**
@ignore
@self	global

@param	{Struct}	node	slider UINode or it id
@desc	Executes the main logic of a slider UINode
*/
function __UI_slider_step_main(node) {
	// If ins't visible, exit
	if !node.core.visible {exit}
	
	// If mouse is clicking on knob or was already clicked
	if node.is_holding || (_mouse_on_konb(node) && global.UI.input.pointer.pressed) {
		node.is_holding = global.UI.input.pointer.down	// Atualizes is_hoding var
		_move_knob(node)								// Moves knob
	}
}

/**
@ignore

@param	{Struct}	node	Slider UINode to draw
@desc	Draws a slider UINode
*/
function _slider_draw(node) {
	var _step_s	= node.step_size			// Absolute value between steps
	var _img	= node.assets.image_index	// Image index
	var size	= node.size					// Node size struct

	var _spr_empty	= node.assets.sprite_set.empty	// Empty bar
	var _spr_full	= node.assets.sprite_set.full	// Full bar
	var _spr_knob	= node.assets.sprite_set.knob	// Knob (holder)
	
	// Positions
	var node_x = node.position.x.render
	var node_y = node.position.y.render
	
	// Aboslute value behind knob
	var _bar_draw_perc = (_step_s * node.slider_values.raw)
	
	// Draws empty bar
	draw_sprite_stretched_ext(_spr_empty, _img, node_x, node_y, size.width.resolved, size.height.resolved, c_white, node.core.alpha)

	var _pos_x = node_x + _bar_draw_perc	// Get Knob position
	var _pos_y = node_y						// Y position
		
	// Knob width
	var _knob_w = sprite_get_width(_spr_knob)

	// Draw full bar (cut)
	draw_sprite_stretched_ext(_spr_full, _img, node_x, node_y, _bar_draw_perc, size.height.resolved, node.core.color, 1)
	
	// Draw Knob
	draw_sprite_ext(_spr_knob, _img, _pos_x - _knob_w / 2, _pos_y, 1, 1, 0, node.core.color, node.core.alpha)
}
#endregion

#region DROPDOWN
/**
@ignore

@param	{Struct}	node_or_id	UINode to do the main dropdown logic

@desc	Make the basic for a dropdown logic
*/
function __UI_dropdown_step_main(node) {
	dropdown_open_configurate(node)		// Configurates open settings
	_change_dropdown_stage_auto(node)	// Change stage
}

/**
@ignore

@param	{Struct}	node		UINode dropdown to draw
@param	{Real}		_halign		the enum (UI_HALIGN) that set the text origin
@param	{Real}		_valign		the enum (UI_VALIGN) that set the text origin

@desc	Draw everything of a UINode dropdown
*/
function _dropdown_main_draw(node, _halign, _valign) {
	draw_UINode_sprite(node)							// Draw bg
	__dropdown_draw_selected(node, _halign, _valign)	// Draw selected option
	
	// If node is closed, exit
	if !node.is_open exit
	
	var _sizes	= node.size	// UINode sizes
	var _open	= node.open	// UINode positions
	
	// Get open metrics
	var _x = node.position.x.render
	var _y = node.position.y.render + _sizes.height.resolved
	
	var _l_scissor = gpu_get_scissor()								// Last scissor
	gpu_set_scissor(_x, _y, _sizes.width.resolved, _open.height)	// Apply scissor
	
	// Draw open sprite bg
	_dropdown_draw_open_sprite(node)
	
	// Draw open sprite options
	_dropdown_draw_options(node, _halign, _valign)
	
	gpu_set_scissor(_l_scissor)	// Set scissor back to normal
}
#endregion

#region TEXTBOX

/**
@ignore
@param	{Struct}	node	Textbox UINode to execute the main logic
@desc	Executes the main logic that a textbox UINode needs
*/
function __UI_textbox_step_main(node) {
	if global.UI.input.pointer.released {
		node.focus = node.core.hovered
	}
	
	_textbox_keyboard_get(node)
}

/**
@ignore

@param	{Struct}	node_or_id	The UINode textbox to do the main logic
@desc	Do the main logic of a UINode textbox
*/
function _textbox_draw_main(node) {
	_textbox_draw_set(node)
	_textbox_draw_parts(node)
}

#endregion

#endregion

/**
@ignore
@param	{Struct}	node	UINode to set internal vars and some core ones
@desc	Sets every internal vars that are needed and some of core ones
*/
function __UINode_set_internal_vars(node) {
	var prev			= node.core.hovered
	node.core.hovered	= global.UI.hover == node
	
	node.internal.prev_hovered	= prev
}

#region MAIN
/**
@ignore
@desc	Updates the hover and focus variables in global.UI
*/
function __update_UI_focus() {
	static layers		= [UILayer.OVERLAY, UILayer.FOREGROUND, UILayer.NORMAL, UILayer.BACKGROUND]
	static UI			= global.UI
	
	UI.internal.prev_hover	= UI.hover		// Set last hover to actual
	UI.hover				= undefined		// Set actual to undefined
	
	// For each layer
	for (var i = 0; i < array_length(layers); i++) {
		var _layer	= UI.layers[$ layers[i]]	// Get layer struct
		var groups	= _layer.groups				// Get layer groups
		
		// For each group
		for(var k = array_length(groups)-1; k >= 0; k --) {
			var nodes	= groups[@ k].nodes	// Get nodes
			
			// For each node
			for (var j = array_length(nodes)-1; j >= 0; j --) {
				var node = nodes[j]	// Get a UINode
				
				// If it isn't visible or interactive
				if (!node.core.visible || !node.core.interactive) continue
				
				var p	= node.position
				var s	= node.size
				var l	= node.scissor.rect.inner
					
				// If mouse is hover, set hover to it UINode
				if mouse_hover_rect_ext(p.x.final, p.y.final, s.width.resolved, s.height.resolved, l) {
					UI.hover = node
					break
				}
			}
			// If founded one, breaks
			if UI.hover != undefined {
				break
			}
		}
		// If founded one, breaks
		if UI.hover != undefined {
			break
		}
	}
	
	UI.internal.prev_focus	= UI.focus	// Set last focus to actual
	
	// IF mouse clicked, set focus to hover
	if UI.input.pointer.released {
		UI.focus	= UI.hover	// Sets the new focus
	}
}

/**
@ignore
@param	{Struct}	node	UINode to execute the generics functionss
@desc	Executes the generics functions of a UINode ( on_click, on_change, on_unhover, ... )
*/
function __UI_events_run() {
	static UI	= global.UI							// UI structure
	var main_hover		= UI.hover					// Now hover
	var prev_main_hover	= UI.internal.prev_hover	// Previous hover
	
	if main_hover != prev_main_hover {
		
		// ON UNHOVER
		if prev_main_hover != undefined && prev_main_hover.internal.has.on_unhover {
			prev_main_hover.events.on_unhover(prev_main_hover)
		}
		
		// ON HOVER
		if main_hover != undefined && main_hover.internal.has.on_hover {
			main_hover.events.on_hover(main_hover)
		}
	}
	
	if main_hover != undefined {
		var main_f_has	= main_hover.internal.has
		var main_f_ev	= main_hover.events
		
		// If has a click and UINode has on_click
		if UI.input.pointer.released && main_f_has.on_click {
			
			// CAN CLICK
			var can_c_pass = main_f_has.can_click ? main_f_ev.can_click(main_hover) : true
			
			// ON CLICK
			if can_c_pass {
				main_f_ev.on_click(main_hover)
			}
		}
	}
}

/**
@ignore
@desc	Updates the focus and hover UINode main and executes the generics functions
*/
function _UINode_update_generic_and_focus() {
	__update_UI_focus()
	__UI_events_run()
}

/**
@ignore
@param	{Struct}	node	UINode to make the main step logic
@param	{Real}		type	The element type ( Do a step based on the element )

@desc	Sets the necessary internal information of a UINode and executes the main step ( element
	logic ) and the generic step ( every node logic, like on_click, on_hover, ... )
*/
function __UINode_main_step(node, type) {
	static inp	= global.UI.input
	
	__UINode_set_internal_vars(node)
	if !node.core.visible	{exit}
	
	var has	= node.internal.has
	switch(type) {
		case UINodeType.RADIO_BUTTON:
			__UI_radio_button_step_main(node)
		break;
		case UINodeType.CHECKBOX:
			__UI_checkbox_step_main(node)
		break;
		case UINodeType.SLIDER:
			__UI_slider_step_main(node)
		break;
		case UINodeType.TEXTBOX:
			__UI_textbox_step_main(node)
		break;
		case UINodeType.DROPDOWN:
			__UI_dropdown_step_main(node)
		break;
	}
	
	// ON CHANGE
	if has.on_change && node.internal.changed {
		node.events.on_change(node)
	}
	
	if node == global.UI.focus || node == global.UI.internal.prev_focus {
		
		// Last was the UINode
		var last_me	= node != global.UI.focus
		
		// If has an input
		var had_inp	= (inp.keyboard.char != "" || inp.keyboard.key > 0)
		
		// ON INPUT
		if node == global.UI.focus && had_inp && has.on_input {
			node.events.on_input(node)
		}
		
		// ON SUBMIT
		if (last_me || inp.keyboard.key == vk_enter) && has.on_submit {
			node.events.on_submit(node)
		}
	}
	
	node.internal.changed	= false
}
#endregion