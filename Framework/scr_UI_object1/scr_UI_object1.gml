#region SLIDER
/**
@ignore

@param	{Struct}	node	UINode to check knob
@desc	Checks if mouse is hover knob
*/
function _mouse_on_konb(node) {
	var _knob_w = sprite_get_width(node.assets.sprite_set.knob)		// Get knob width
	var _knob_h = sprite_get_height(node.assets.sprite_set.knob)	// Get knob height
	
	// Plus absolute value behind knob
	var _pos_x = node.position.x.final + (node.step_size * node.slider_values.raw)
	var _pos_y = node.position.y.final + _knob_h / 2
	
	// Sees if is in the knob hitbox
	return point_in_circle(mouse_UI_x(), mouse_UI_y(), _pos_x, _pos_y, _knob_w / 2)
}

/**
@ignore

@param	{Struct}	node	UINode to move knob
@desc	Moves the knob and updates the values
*/
function _move_knob(node) {
	var _px		= node.position.x.final		// Position X
	var _bet	= node.step_size			// Absolute value between steps
	
	// Sees the deslocation
	var new_val	= (global.UI.input.pointer.x - _px) / _bet
	var stc_val	= node.slider_values
	
	// Just really updates if value moves completly
	//new_val		= new_val < stc_val.raw ? ceil(new_val) : floor(new_val)
	new_val		= round(new_val)
	new_val		= clamp(new_val, 0, node.steps)	// Clamp it
	
	if new_val != stc_val.raw {
		node.internal.changed	= true
		
		// Set the values
		stc_val.raw		= new_val
		stc_val.final	= stc_val.raw + stc_val.min_value // With minimum value
	}
	
}
#endregion

#region DROPDOWN

#region LOGIC
#region PURE
/**
@ignore
@pure

@param	{Struct}	node	UINode to se if mouse if hover it item
@param	{Real}		index	Item index in options array
@param	{Real}		offset	It scroll offset
@return	{Bool}		Returns if mouse is hover item

@desc	Sees if mouse is hover a dropdown item (considering scissor)
*/
function dropdown_mouse_hover_item(node, index, _offset = 0) {
    var _w	= node.size.width.resolved	// Node width
	var _h	= node.size.height.resolved	// Node height
	
	// Dropdown open height
	var _ho	= node.open.height
	
    var _x = node.position.x.final	// Node x
	var _y = node.position.y.final	// Node y
	
	// Item Y (with offset)
    var _ynow = (node.position.y.final + _h + (_h * index)) - _offset
	
	// If mouse is hover item (considering scissor)
    return mouse_hover_rect_ext(_x, _ynow, _w, _h, {x: _x, y: _y + _h, w: _w, h: _ho})
}
#endregion

#region HELPERS
/**
@ignore

@param	{Struct}	node		UINode to change actual option
@param	{Real}		new_index	New ption index

@desc	Changes the UINode dropdown selected option to a new one (based on the index)
*/
function __change_option(node, new_index) {
	// New index
	node.selected.index		= new_index
	
	// Set everything
	node.selected.raw		= node.options.raw[@ new_index]
	node.selected.display	= node.options.display[@ new_index]
	node.selected.parsed	= node.options.parsed[@ new_index]
	
	// Set changed to true
	node.internal.changed	= true
}

/**
@ignore

@param	{Struct}	node	UINode dropdown to check
@param	{Real}		offset	UINode open scroll offset

@desc	UINode dropdown part to change it selected value if clicked
*/
function _change_selected_dropdown(node, offset = 0) {
	// If node is closed or haven't a click in this frame, exit
	if !node.is_open || !global.UI.input.pointer.pressed {exit}
	
	// Check all items
	for (var i = 0; i < array_length(node.options.display); i ++) {
		
		var _hover_bloco = dropdown_mouse_hover_item(node, i, offset)
		// Sees if mouse is hover change actual option
		if _hover_bloco {
			__change_option(node, i)
		}
	}
}

#endregion

#region MAIN HELPER
/**
@ignore

@param	{Struct}	node	UINode to change stage

@desc	Changes the variable is_open in a dropdown node
*/
function _change_dropdown_stage_auto(node) {
	
	var _mb_left_clicked = global.UI.input.pointer.pressed
	
	// If in this frame had a click
	if _mb_left_clicked {
		// Change state
		node.is_open = (!node.is_open && node.core.hovered)
	}
}

/**
@ignore

@param	{Struct}	node	UINode to configure open settings

@desc	Configurates a dropdown node open settings
*/
function dropdown_open_configurate(node) {
	static inp	= global.UI.input
	var layout	= node.open.layout	// Open layout struct
	var mode	= layout.mode		// Layout mode
	
	switch(mode) {
		case UINodeDropdownLayout.ALL:
			//	Shows everything without offset
			_change_selected_dropdown(node)
		break
		case UINodeDropdownLayout.SCROLL:
			// Get offset struct
			var scroll	= layout.settings.scroll

		    var _w	= node.size.width.resolved	// Node width
			var _h	= node.size.height.resolved	// Node height
			
			// Node open height
			var _ho	= node.open.height
			
			// Node positions
		    var _x1	= node.position.x.render
			var _y1	= node.position.y.render + _h
		    var _x2	= _x1 + _w
			var _y2	= _y1 + _ho
			
			#region SCROLL SETTINGS
			// If had a vertical scroll input and mouse is hover rect
			if inp.scroll.y != 0 {
				if point_in_rectangle(inp.pointer.x, inp.pointer.y, _x1, _y1, _x2, _y2) {
					// Apply force in scroll direction
					scroll.velocity	+= scroll.force * inp.scroll.y
				}
			}
			
			// If scroll velocity is above 0.01, starts to apply drag
			if abs(layout.settings.scroll.velocity) > 0.01 {
				scroll.value	+= scroll.velocity
				scroll.velocity	*= scroll.drag
			} else {
				// Else sets to 0
				scroll.velocity	*= 0
			}
			
			// Clamps scroll value
			var max_scroll	= (array_length(node.options.raw) - layout.settings.amount) * _h
			scroll.value	= clamp(scroll.value, 0, max_scroll)
			#endregion
			
			// Apply offset
			_change_selected_dropdown(node, scroll.value)
		break
	}
}
#endregion

#region API
/**
@public

@param	{Struct | String}		node_or_id	UINode or it id to create/set new options
@param	{Array}					options		Array with values (anything)

@return	{Array<Struct>}		Array with raw (literal valuepassed), display (string) and parsed (Ready to write)

@Desc	Creates a array with: raw, display and parsed options to a dropdown
*/
function create_dropdown_options(node_or_id, options) {
	var length	= array_length(options)			// Amount of options
	var node	= _UINode_resolve(node_or_id)	// Get node
	
	// Get text style
	var style	= node.text.style
	
	// Return
	var final	= {raw: options, display: [], parsed: []}
	
	// Runs for each option
	for (var i = 0; i < length; i ++) {
		var op	= options[@ i]	// A option
		var dis	= op			// Display
		
		// If is an asset, just takes the name of it
		if is_asset(op) {
			var split	= string_split(op, " ")
			dis			= split[@ 2]
		}
		
		// Pushes display
		array_push(final.display, string(dis))
		
		// Pushes display parsed into parsed ones
		array_push(final.parsed, UI_parse_text(dis, node.text.span, style.font, style.xscale, style.yscale))
	}
	
	return final
}


#endregion

#endregion

#region DRAW
#region HELPERS
/**
@ignore

@param	{Struct}	node	UINode to draw split
@param	{Real}		x1		Left coordinate of option box
@param	{Real}		y1		Top coordinate of option box
@param	{Real}		x2		Right coordinate of option box
@param	{Real}		y2		Bottom coordinate of option box
@param	{Real}		_bord	Bord thickness (in pixels)

@desc	Draws a splited dropdown option
*/
function __dw_draw_split(node, x1, y1, x2, y2, _bord) {
	var mode	= node.open.style.mode		// Get style mode
	var style_s	= node.open.style.settings	// Get style settings
	
	var w	= node.size.width.resolved	// UINode width
	var h	= node.size.height.resolved	// UINode height
	
	// Set coordinates with bord applyed
	var in_x1	= x1 + _bord	// Inner x1
	var in_x2	= x2 - _bord	// Inner y1
	var in_y1	= y1 + _bord	// Inner x2
	var in_y2	= y2 - _bord	// Inner y2
	
	switch(mode) {
		case UINodeDropdownStyle.COLOR:
			draw_set_color(style_s.color)						// Set main color
			draw_rectangle(in_x1, in_y1, in_x2, in_y2, false)	// Draws background
		break
		case UINodeDropdownStyle.SPRITE:
			var _spr = style_s.sprite	// Get sprite
			var _img = style_s.image	// Get sprite image
			var _col = style_s.color	// Get color
				
			// Draws sprite stretched
			draw_sprite_stretched_ext(_spr, _img, x1, y1, w, h, _col, node.core.alpha)
		break
		case UINodeDropdownStyle.GRADIENT:
			var _col_g	=  style_s.color	// Get colors
			var _dir	= style_s.direction	// Get direction
			
			// Draw gradient
			draw_gradient_rect_ext(in_x1, in_y1, in_x2, in_y2, _col_g.col1, _col_g.col2, _dir)
		break
	}
	
	// Set back to normal
	draw_set_colour(c_white)
}

/**
@ignore

@param	{Struct}	node			UINode to draw selected option
@param	{Real}		_hal_on_drop	The enum (UI_HALIGN)
@param	{Real}		_val_on_drop	The enum (UI_VALIGN)

@desc	Draws the selected option of a dropdown UINode
*/
function __dropdown_draw_selected(node, _hal_on_drop, _val_on_drop) {
	var main_item = {
		parsed:	 node.selected.parsed,

		style:	node.text.style,
		layout:	node.text.layout
	}
	_draw_UI_text_in_rect(main_item, node.inner, _hal_on_drop, _val_on_drop)
}

/**
@ignore

@param	{Struct}	node	UINode to draw color background style

@desc	Draws a background of a open dropdown in color style
*/
function __dw_create_col_bg(node) {
	// Get style settings
	var style_s	= node.open.style.settings
	
	var _col	= style_s.color		// Color
	var _bor	= style_s.bord_px	// Bord pixels
			
	// Gets and set a darker color
	var _bord_color = color_multiply(_col, 0.8)
			
	var x1 = node.position.x.render									// first X
	var y1 = node.position.y.render + (node.size.height.resolved)	// first Y (start from the top)
					
	var x2 = x1 + node.size.width.resolved	// Final X
	var y2 = y1 + node.open.height			// Final Y (adds the open's height)

	// Draw bg dropdown
	draw_set_color(_bord_color)
	draw_rectangle(x1, y1, x2, y2, false)
	
	// If is not an open separator type, draw the main part
	if !node.open.separators {
		draw_set_color(_col)
		draw_rectangle(x1 + _bor, y1, x2 - _bor, y2 - _bor, false)
	}
	draw_set_color(c_white)
}
#endregion

#region DRAW HELPERS

/**
@ignore

@param	{Struct}	node	UINode to draw color bg

@desc	Helper to draw a background to a dropdown UINode
*/
function _UI_dw_open_color(node) {
	var _size = node.size		// Size struct
	var _pos  = node.position	// Position struct
	
	var _open	= node.open		// Open data
	
	__dw_create_col_bg(node)
}


/**
@ignore

@param	{Struct}	node	UINode to draw sprite bg

@desc	Helper to draw a background to a dropdown UINode
*/
function _UI_dw_open_sprite(node) {
	var _style	= node.open.style
	var _list	= node.options.display
	
	var spr		= _style.settings.sprite
	var img		= _style.settings[$ "image"]	?? 0
	var perln	= node.open.separators		?? false
	
	var _w	= node.size.width.resolved
	var _h	= node.size.height.resolved
	
	var	_x	= node.position.x.render
	var	_y	= node.position.y.render + _h
	
	var _op_h = node.open.height
	
	if (!perln) {
		// One big sprite
		draw_sprite_stretched_ext(spr, img, _x, _y, _w, _op_h, c_white, 1)
	}
}

/**
@ignore

@param	{Struct}	node	UINode to draw gradient bg

@desc	Helper to draw a background to a dropdown UINode
*/
function _UI_dw_open_gradient(node) {
	var _open	= node.open
	var _list	= node.options.display
	
	var _w = node.size.width.resolved
	var _h = node.size.height.resolved
	
	var setts = _open.style.settings
	
	var _bpx		=  setts.bord_px
	var _col		=  setts.color
	
	#region DEFINING POSITIONS
	var x1 = node.position.x.render
	var y1 = node.position.y.render + _h
	var x2 = x1 + _w - 1
	var y2 = y1 + _open.height
	
	var in_x1 = x1 + _bpx
	var in_y1 = y1
	var in_x2 = x2 - _bpx-1
	var in_y2 = y2 - _bpx
	#endregion
	
	var _dir = setts.direction
	
	var _dkr_cols	= {col1: color_multiply(_col.col1, 0.8), col2: color_multiply(_col.col2, 0.8)}
	
	// BORDER
	draw_gradient_rect_ext(x1, y1, x2, y2, _dkr_cols.col1,	 _dkr_cols.col2, _dir)
	
	if !_open.separators {
		// MAIN PART
		draw_gradient_rect_ext(in_x1, in_y1, in_x2, in_y2, _col.col1, _col.col2, _dir)
	}
}

#endregion

#region DROPDOWN DRAWERS
/**
@ignore

@param	{Struct}	node	UINode to draw splited options

@desc	Draw a dropdown options in splited way
*/
function _dropdown_apply_split(node) {
	var _pos	= node.position	// Get UINode position
	var _size	= node.size		// Get UINode size
	
	var _open		= node.open				// Open settings
	var style_s		= _open.style.settings	// Style settings
	var layout_s	= _open.layout.settings	// Layout settings
	
	// Get the amount of options
	var list_l		= array_length(node.options.display)
	
	// Scissor before actual
	var _last_sci = gpu_get_scissor()
	
	// Apply scissors
	gpu_set_scissor(_pos.x.render, _pos.y.render + _size.height.outer, _size.width.outer, node.open.height)
	
	var pos_x = _pos.x.render	// UINode x coordinate
	var pos_y = _pos.y.render	// UINode y coordinate
	
	// UINod open height
	var _oh	= _open.height
	
	var _w	= _size.width.resolved	// UINode width
	var _h	= _size.height.resolved	// UINode height
	
	// Set a option basic position
	var x1	= pos_x
	var x2	= pos_x + _w
	var y1	= pos_y
	var y2	= pos_y + _h
	
	// If it has a border, get it
	var bd	= 0
	if variable_struct_exists(style_s, "bord_px") {
		bd	= style_s.bord_px
	}
	
	// Apply scroll (if has)
	if _open.layout.mode == UINodeDropdownLayout.SCROLL {
		y1	-= layout_s.scroll.value
		y2	-= layout_s.scroll.value
	}
	
	// Runs for all Items
	for (var i = 0; i < list_l; i ++) {
		
		// Get the Y position of the items
		y1	+= _h
		y2	+= _h
		
		// Draw it
		__dw_draw_split(node, x1, y1, x2, y2, bd)
		
	}
	// Set back to normal
	gpu_set_scissor(_last_sci)
}

/**
@ignore

@param	{Struct}	node			UINode to draw options
@param	{Real}		_hal_on_drop	The enum (UI_HALIGN)
@param	{Real}		_val_on_drop	The enum (UI_VALIGN)

@desc	Draws all options of a dropdown UINode
*/
function _dropdown_draw_options(node, _hal_on_drop, _val_on_drop) {
	var items	= node.options.parsed	// All the items in the options
	var _pivot	= node.offset.pivot		// The pivot in the node
	var inner	= node.inner			// Inner struct
	
	var _open		= node.open		// Open struct
	var _layout		= _open.layout	// Show mode
	
	// Height per item
	var item_height	= node.size.height.resolved
	
	// Y offset
	var _offset_y = 0
	
	// If y offset exists, set it
	if _layout.mode == UINodeDropdownLayout.SCROLL {
		_offset_y = _layout.settings.scroll.value
	}
	
	// Bassicaly, an auto panel with all items
	var rect = {
		x:		node.position.x.render + node.size.padding.inner.left,
		y:		inner.y - _offset_y,
		width:	inner.width,
		height:	inner.height
	}
	
	for (var i = 0; i < array_length(items); i ++) {
		var item	= items[@ i]	// Get item
		rect.y		+= item_height	// Add a height and the top
		
		var txt_data = {
			parsed:	item,				// Parsed struct
			style:	node.text.style,	// Style
			layout:	node.text.layout	// Layout
		}
		
		// Draw item
		_draw_UI_text_in_rect(txt_data, rect, _hal_on_drop, _val_on_drop)
	}
}

#endregion

#region MAIN
/**
@ignore

@param	{Struct}	node	UINode to draw the background

@desc	Draws the open background of a dropdown UINode
*/
function _dropdown_draw_open_sprite(node) {
	var is_sep	= node.open.separators
	
	switch (node.open.style.mode) {
		#region COLOR
		case UINodeDropdownStyle.COLOR: 	
			_UI_dw_open_color(node)
		break
		#endregion
		
		#region SPRITE
		case UINodeDropdownStyle.SPRITE:
			_UI_dw_open_sprite(node)
		break
		#endregion
		
		#region GRADIENT
		case UINodeDropdownStyle.GRADIENT: 
			_UI_dw_open_gradient(node)
		break
		#endregion
	}
	
	if is_sep {
		_dropdown_apply_split(node)
	}
}
#endregion

#endregion

#endregion
