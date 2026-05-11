#region PURE FUNCTIONS
/**
@ignore
@pure
@self global

@param	{Struct | String}	node_or_id	The UINode or their Id
@return	{Struct}			returns the UINode

@desc	Makes sure that you will work with the UINode struct
*/
function _UINode_resolve(node_or_id) {
    if (is_struct(node_or_id)){
		// Returns the UINode itself
		return node_or_id
	} else {
		// Gets the UINode struct and then returns it
		return get_UINode_by_id(node_or_id)
	}
}
#endregion

#region HELPER

#region Destroyer helper
/**
@ignore

@param	{Struct}	node	The node to be destroy
@param	{Bool}		main	If is the main (greatest parent) node. If yes, it parent is marked dirty

@desc	Destroy an UINode
*/
function __UINode_destroyer(node, main) {
	static	UI	= global.UI
	
	var _id		= node.core.id							// UINode id
	var parent	= get_UINode_by_id(node.core.parent)	// UINode parent
	
	// UINode layer
	var _layer_g	= UI.layers[$ node.UI_layer.id][$ node.UI_layer.group]
	
	var _fat_ind	= array_get_index(parent.core.children,	_id)	// parent index
	var _group_ind	= array_get_index(_layer_g.nodes,	_id)	// Layer group index
	var node_index	= array_get_index(UI.nodes,	node)
	
	array_delete(parent.core.children,	_fat_ind,	1)		// Delets itself from parent
	array_delete(UI.nodes,				node_index,	1)		// Delets from the nodes
	array_delete(_layer_g.nodes,		_group_ind,	1)		// Delete index
	
	
	// Delets from the lookup
	ds_map_delete(UI.internal.lookup_map, _id)
	
	if main {
		if parent != undefined {
			if parent.core.id == UI_ROOT_ID {
				_mark_dirty(parent, UINodeDirtyFlag.LAYOUT)
			} else {
				_mark_dirty(parent, UINodeDirtyFlag.ALL)
			}
		}
	}

	return undefined
}

/**
@ignore

@param	{Struct}	node	UINode to destroy (and it children)

@desc	Helper function to destroy UINodes and it childrens
*/
function _destroy_UINode_children(node) {
	var _children	= node.core.children	// Children array
	var many_c		= array_length(_children)
	
	// Destroy all children with itself
	while(array_length(_children)) {
		// Gets the children id
		var child = get_UINode_by_id(array_last(_children))
		
		// calls itself on childrens to destroy them too
		child	= _destroy_UINode_children(child)
	}
		
	node.core.children = []

	return __UINode_destroyer(node, false)
}
#endregion

#region draw UIText helpers

/**
@ignore

@param	{Struct}	node		The UINode to use
@param	{Struct}	parsed_text	Parsed text struct
@param	{Real}		_x			X coordinate of the text
@param	{Real}		_y			Y coordinate of the text

@desc Function to draw a text with spans
*/
/*
@see	draw_text_span
*/
function draw_text_read_span(node, parsed_text, _x, _y) {
	
	// Set the base aligns
	draw_set_halign(fa_left)
	draw_set_valign(fa_top)

	var _style		= parsed_text.style	// Parse style
	var _txt		= parsed_text.text	// Text in the parsde struct

	var px = _x	// Position x
	var py = _y	// Position y
	
	// Sets text color and alpha
	draw_set_colour(node.style.color)
	draw_set_alpha(node.style.alpha)
	
	draw_set_font(_style.font)
	
	apply_span_effects(parsed_text)	// Apply any effects that text has
	
	// Draw text with the transformations
	draw_text_transformed(px, py, _txt, _style.xscale, _style.yscale, 0)
	
	// Returns draw to the normal
	draw_set_color(c_white)
	draw_set_alpha(1)
}

/**
@ignore

@param	{Struct} node UINode to use
@desc	Apply the linebreaks math in a UINode text
*/
/*
@see draw_text_read_span
*/
function draw_text_with_span(node) {
	
	#region DECLARE VARIABLES
	#region SHIFT POSITIONS
	static shift_x	= function(hal, line_width, base_x) {
		switch(hal) {
			// Move the x pos by half of line's width
			case fa_center: return base_x - line_width * 0.5
		
			// Move the x pos by biggest line width
			case fa_right:  return base_x - line_width
		}
		
		return base_x
	}
	#endregion
	
    var parsed		= node.parsed			// parsed text
	var parsed_l	= array_length(parsed)	// Parse length
	
	var _halign		= node.layout.halign	// text halign
	var _valign		= node.layout.valign	// text valign

    var _x = node.inner.x	// internal x position
    var _y = node.inner.y	// internal y position
	
	// Last kind of span (SPAN, DEFAULT, BREAK and undefined)
	var last_kind	= undefined
	
	// Actual line (0-based)
	var line_index = 0
	
	var lines_width		= []	// Each line width
	var lines_height	= []	// Each line height
	
	var accum_w		= 0		// Accumulated width in a line
	var line_height	= 0		// Line biggest height found
	
	var txt_height	= 0	// Text's height
	#endregion
	
	#region GET METRICS
	// get all the lines metrics
	for(var i = 0; i < parsed_l; i ++) {
		
		// Get parse part and it metrics
		var frag = parsed[@ i]
		
		// Add width and get bigger height
		accum_w		+= frag.metrics.width
		line_height	=  max(line_height, frag.metrics.height)
		
		// if is a break
		if (frag.kind == TextSpanKind.BREAK) {
			array_push(lines_width, accum_w)		//	Push width to array
			array_push(lines_height, line_height)	//	Push width to array
			txt_height	+= line_height				//	Add line height
			
			//	Restart process
			line_height	= 0
			accum_w		= 0
			continue
		}
	}
	
	// If text doesn't ends in a break
	if (line_height > 0 || accum_w == 0) {
		array_push(lines_width, accum_w)		// Add last line width after loop ends
		array_push(lines_height, line_height)	// Push width to array
		txt_height += line_height				// Add line height to text height
	}
	#endregion

	switch(_valign) {
		case fa_middle:
			// Move the text half of it height up
			_y	-= txt_height / 2
		break;
		case fa_bottom:
			// Move the text it height up
			_y	-= txt_height
		break;
	}
	
	_x	= shift_x(_halign, lines_width[0], node.inner.x)	// real start
	
	#region RUNS FOR PARSE ARRAY
	// Runs for all piece of text parsed
    for (var i = 0; i < parsed_l; i++) {
		var parse_part	= parsed[@ i]		// fragment of parsed text
		
		
		// Draw the lines and update the x position
        draw_text_read_span(node, parse_part, _x, _y)
		_x	+= parse_part.metrics.width
		
		// If kind is BREAK
		if parse_part.kind == TextSpanKind.BREAK {
			_y	+= lines_height[line_index]	// Go to next Y value (using actual line index)
			line_index	++					// Next line index
			
			var line_w	= lines_width[line_index]					// Get line width (new line)
			_x			= shift_x(_halign, line_w, node.inner.x)	// get the new x position
		}

    }
	#endregion
}

/**
@ignore

@param	{Struct}			text_stc	Text's struct with: parsed text, style and layout
@param	{Struct}			rect		The struct with the rectangle's metrics (x, y, width, height)

@param	{Constant.HAlign}	halign		The halign of the text in the rect
@param	{Constant.VAlign}	valign		The valign of the text in the rect
*/
function _draw_UI_text_in_rect(text_stc, rect, halign, valign) {
	var w = rect.width
	var h = rect.height

	var x_inc = (halign == UI_HALIGN.LEFT)   ? 0 : (halign == UI_HALIGN.CENTER ? w/2 : w)
	var y_inc = (valign == UI_VALIGN.TOP)    ? 0 : (valign == UI_VALIGN.MIDDLE ? h/2 : h)

	var px = rect.x + x_inc
	var py = rect.y + y_inc

	var stc2 = {
		parsed:	text_stc.parsed,
		style:	text_stc.style,
		layout:	text_stc.layout,
		
		inner:	{ x: px, y: py, width: w, height: h }
	}
	
	draw_text_with_span(stc2)
}
#endregion

/**
@ignore
@pure

@param	{Struct}	node	UINode to draw text
@desc	Draws the text of a UINode
*/
function draw_UINode_text(node) {
	var style		= node.text.style	// Gets the text struct
	var _last_bound	= {}				// Scissors bound
		
	// If scissors is enabled, cut it and returns normal bounds
	if node.scissor.enabled {
		_last_bound = node.scissor.apply(node)	// Apply
	}
	
	// Function to draw text
    _draw_UI_text_in_rect(node.text, node.inner, style.halign, style.valign)
	
	// Sets the scissor to normal
	if node.scissor.enabled {
		gpu_set_scissor(_last_bound) // Reset
	}
		
	// Set color and alpha to normal
    draw_set_alpha(1)
	draw_set_colour(c_white)
}

/**
@ignore

@param	{Struct}	scroll_stc		The UINode scroll struct
@param	{Struct}	scroll_input	The inputs of the scroll ( x, y )

@desc	Apply the scroll force if inputs are saying too
*/
function _scroll_apply_force(scroll_stc, scroll_input) {
	var vel_x	= scroll_stc.force * scroll_input.x
	var vel_y	= scroll_stc.force * scroll_input.y

	if (scroll_stc.enabled.x) {
		scroll_stc.velocity.x	+= vel_x	// Apply in x if is holding shift
	}
	if (scroll_stc.enabled.y) {
		scroll_stc.velocity.y	+= vel_y	// Apply in y if not
	}
}
#endregion

#region MAIN
#region LAYERS FUNCTIONS

/**
@ignore

@param	{UILayer} layer_id	the enum (UILayer) of the UI layer
@desc	organize the groups in a UILayer in crescent order
*/
function _eval_UI_layer_groups(layer_id) {
	var _layer = global.UI.layers[$ layer_id]
	
	if !_layer.dirty {exit}
	_layer.dirty = false
	
	var _lay_order = _layer.groups
	array_sort(_lay_order, function(ele1, ele2) {return (ele1.priority -  ele2.priority)})
}

/**
@ignore

@param	{struct, Real} layer_idOrgroup_struct	pass the UILayer enum OR the group in the UI layer
@param	{string}	group_name	Name of the group in the UI layer
@return	{array}		Returns the organized array

@desc	Arrange the list of UIElement in a group inside a UILayer in crescent order
*/
function _eval_UI_group_elements(layer_id, group_name = "default_group") {
	var group = layer_id	// set the grup or UILayer id
	
	// If isn't the group already (is the ENUM)
	if !is_struct(layer_id) {
		group = global.UI.layers[$ layer_id][$ group_name] // Gets the group
	}
	
	// If the value isn't dirty
	if !group.dirty {exit}	// Exits
	group.dirty = false		// Else start organize
	
	// Get the list of UINodes from the group
	var _group_eles = group.nodes
	
	// Organize in crescent order
	array_sort(_group_eles, function(ele1, ele2) {
		return (ele1.UI_layer.z_index - ele2.UI_layer.z_index)
	})
}
#endregion

#region DRAWER AND CREATOR
/**
@public
@pure

@desc	Draw all main parts of the UINodes in order
*/
function draw_all_UI_elements(){
	static order = [UILayer.BACKGROUND, UILayer.NORMAL, UILayer.FOREGROUND, UILayer.OVERLAY]
	
	// LAYER ORDER
	for (var i = 0; i < array_length(order); i++) {	
		var _groups = global.UI.layers[$ order[i]].groups	// Get groups of that layer
		
		// GROUP ORDER
		for(var j = 0; j < array_length(_groups); j ++) {
			var nodes = _groups[j].nodes					// Get the list of UINodes of a group
			
			// ELEMEMENTS ORDER
			for (var k = 0; k < array_length(nodes); k ++) {
				var node = nodes[k]							// Get one UINode of the list
				
				// Excecute the main preset drawer
				if node.core.visible
				_draw_preset_UI_element(node)
			}
		}
	}
}
#endregion

/**
@ignore

@param	{Struct}	node	UINode to update scroll
@desc	Updates the scroll structure
*/
function _UINode_uptade_scroll(node) {
	var scroll	= node.scroll							// Scroll struct
	if scroll.flow == UINodeScrollFlow.NOONE {exit}		// If flow is NOONE, exit
	
	var input_scroll	= global.UI.input.scroll
	
	// If don't have any croll inputs or scroll velocity is zero, exits
	if (input_scroll.x == 0 && input_scroll.y == 0) {
		if (scroll.velocity.x == 0 && scroll.velocity.y == 0) {exit}
	}
	
	// Mark itself dirty
	_mark_dirty(node, UINodeDirtyFlag.WORLD)
	
	#region UPTADE VELOCITY
	// If mouse is hover the UINode and wheel in moviment
	if scroll.must_hover {
		if (node.core.hovered) {
			_scroll_apply_force(scroll, input_scroll)
		}
	} else {
		var p = node.position
		var s = node.size
		var r = node.scissor.rect.inner

		if mouse_hover_rect_ext(p.x.final, p.y.final, s.width.outer, s.height.outer, r) {
			_scroll_apply_force(scroll, input_scroll)
		}
	}
	#endregion
	
	#region MATH LOGIC
	// Get max_x/y scroll
	var max_x = scroll.overflow.x
	var max_y = scroll.overflow.y
	
	if scroll.max_x > 0 {
		max_x = min(scroll.max_x, max_x)
	}
	
	if scroll.max_y > 0 {
		max_y = min(scroll.max_y, max_y)
	}
	
	// Apply drag
	scroll.velocity.x	*= scroll.drag
	scroll.velocity.y	*= scroll.drag
	
	if abs(scroll.velocity.x) < 0.01 {scroll.velocity.x = 0}
	if abs(scroll.velocity.y) < 0.01 {scroll.velocity.y = 0}
	
	// Add velocity to values
	scroll.value.x		+= scroll.velocity.x
	scroll.value.y		+= scroll.velocity.y
	
	// Clamp the values amoung min and max values
	scroll.value.x		= clamp(scroll.value.x, scroll.min_x, max_x)
	scroll.value.y		= clamp(scroll.value.y, scroll.min_y, max_y)
	#endregion
}
#endregion

#region API
#region TAKE THE X AND Y POSITIONS OF THE MOUSE ON THE SCREEN AND THE SIZE OF THE SCREEN
/**
@public

@desc Returns the mouse x position in the GUI
@return {Real}
*/
function mouse_UI_x() {return device_mouse_x_to_gui(0)}

/**
@public

@desc Returns the mouse y position in the HUI
@return {Real}
*/
function mouse_UI_y() {return device_mouse_y_to_gui(0)}

/**
@public

@desc Returns the GUI width
@return {Real}
*/
function GUI_width()	{return display_get_gui_width()}

/**
@public

@desc Returns the GUI height
@return {Real}
*/
function GUI_height()	{return display_get_gui_height()}

#endregion

/**
@public
@pure
@self	global

@param	{Real}		_id		id of a UINode
@return	{Struct}	UINode struct

@desc	Retuns the UINode with the same id
*/
function get_UINode_by_id(_id) {
	static UI	= global.UI
	if _id == UI_ROOT_ID {return UI.screen}	// If is root
	
	// Normal UINode
	return ds_map_find_value(UI.internal.lookup_map, _id)
}

/**
@public
@pure
@self	global

@param	{Struct}	node	UINode struct
@return	{Real}		UINode id

@desc	Retuns the UINode's ID
*/
function UINode_get_id(node) {
	return node.core.id
}

/**
@public
@pure

@param	{Any} group Name of the group
@return	{Array<Real>} Returns the array with the elements' ID

@desc	Gets all elements that are in the same group (only gets radios buttons)
*//*
example var easy_group = UI_get_same_group("easy")
*/
function UINode_get_same_group(group) {
	var _same		= []
	var many_node	= array_length(global.UI.nodes)
	
	for (var i = 0; i < many_node; i ++) {
		var node = get_UINode_by_id(global.UI.nodes[i]) // Get node
				
		if node.element == UINodeType.RADIO_BUTTON {	// Sees if is a radio button
			if node.group == group {					// Sees if is in the group
				array_push(_same, node.core.id)			// If it is, pushes
			}
		}
	}
	
	// Returns the array
	return _same
}

/**
@public
@self	global

@param	{Real}		UILayer_id	The enum (UILayer) of the UI layer
@param	{String}	layer_name	The name of the new group
@param	{Real}		prior		Drawing priority

@desc Creates a new group in a UILayer
*/
function UI_layer_add_group(UILayer_id, layer_name, prior) {
	global.UI[$ UILayer_id][$ layer_name] = {priority: prior, nodes: [], z_counter: 0}
}

/**
@public

@param	{Struct}		node		UINode to add children
@param	{Struct}		index		Where in the parent it shall be add
@param	{Real, struct}	child_id	child or it id to add

@desc Add children to a UINode
*/
function UINode_add_children(node, child_or_id, index = -1) {
	if !node.internal.allowed_children {exit}
	
	// Gets child id
	var child_id	= is_string(child_or_id) ? child_or_id : UINode_get_id(child_or_id)
	
	// If index is lower than 0, pushes it. Otherwise, put in that index
	if index < 0 {
		array_push(node.core.children, child_id)
	} else {
		array_insert(node.core.children, index, child_id)
	}

	_mark_dirty(node, UINodeDirtyFlag.ALL)
}

/**
@public
@pure

@param	{Any}	value	Value to get type
@return	{Real}	enum UINodeValue

@desc	Function to get a value type. It returns a enum ( UINodeValue ) of the respective type
*/
function UI_get_value_type(value) {
	// BASIC
	if is_bool(value)		{return UINodeValue.BOOL}
	if is_array(value)		{return UINodeValue.ARRAY}
	
	if is_asset(value)		{
		// If asset == script, consider it CALLABLE
		if asset_get_type(value) == asset_script {return UINodeValue.CALLABLE}
		return UINodeValue.ASSET
	}
	if is_numeric(value)	{return UINodeValue.REAL}
	
	if is_callable(value)	{return UINodeValue.CALLABLE}
	if is_struct(value)		{return UINodeValue.STRUCT}
	if is_undefined(value)	{return UINodeValue.UNDEFINED}
	
	if is_string(value) {
		var trim_upper = string_upper(string_trim(value))
		
		if trim_upper == "AUTO"					return UINodeValue.AUTO
		if string_char_at(trim_upper, 1) == "="	return UINodeValue.EXPRESSION
		if string_contains("%", trim_upper)		return UINodeValue.PERCENTAGE
		
		if string_contains("REF NODE", trim_upper)	return UINodeValue.NODE_REFERENCE
		
		return UINodeValue.STRING
	}
	
	return UINodeValue.UNKNOWN
}

#region HIDE UINODES
/**
@public
@desc Hide all UINodes
*/
function hide_all_UINodes() {
	var many_node	= array_length(global.UI.nodes)
	
	for (var i = 0; i < many_node; i++) {
		var node = get_UINode_by_id(global.UI.nodes[i])
		node.core.visible = false
	}
}

/**
@public
@param	{Any} class The class of the UINode to hide
@desc	Hide the UINodes with the class
*/
function hide_UINode_by_class(class) {
	var many_node	= array_length(global.UI.nodes)
	
	for (var i = 0; i < many_node; i ++) {
		var node = get_UINode_by_id(global.UI.nodes[i])
		if node.core.class == class {
			node.core.visible	= false
		}
	}
}

/**
@public
@param	{Any} class_exc The only class of UINode to not hide
@desc	Hide the UINodea execpt with the class
*/
function hide_UINode_except(class_exc) {
	static UI_nodes	= global.UI.nodes
	var many_node	= array_length(UI_nodes)
	
	for (var i = 0; i < many_node; i ++) {
		// struct
		var node	= get_UINode_by_id(UI_nodes[i])
		
		// class of that struct
		var class	= node.core.class

		// If have that class, show, else hide it
		node.core.visible = (class == class_exc)
	}
}
#endregion

#region SHOW UINODES
/**
@public

@desc Show all UINodes
*/
function show_all_UINode() {
	static UI_nodes	= global.UI.nodes
	var many_node	= array_length(UI_nodes)
	
	for (var i = 0; i < many_node; i ++) {
		var node			= UI_nodes[i]	
		node.core.visible	= true
	}
}

/**
@public

@param	{Any} class The class of the UINodes to show
@desc	Show the UINodes with the class
*/
function show_UINode_by_class(class) {
	static UI_nodes	= global.UI.nodes
	var many_node	= array_length(UI_nodes)
	
	for (var i = 0; i < many_node; i ++) {
		
		var node = UI_nodes[i]			// Get on UINode
		if node.core.class == class {	// If has the class
			node.core.visible	= true	// Shows it
		}
	}
}

/**
@public

@param	{Any} class_exc The only class of UINodes to not show
@desc	Show the UINodes execpt with the class
*/
function show_UINode_except(class_exc){
	static UI_nodes	= global.UI.nodes
	var many_node	= array_length(UI_nodes)
	
	for (var i = 0; i < many_node; i ++) {
		var node = UI_nodes[i]			// struct
		var class = node.core.class		// class of that struct
		
		// If haven't that class, show, else hide it
		node.core.visible = (class != class_exc)
	}

}
#endregion

#region DRAW A SPRITE ON THE UI
/**
@public
@pure

@param	{Struct | String} node_or_id The UINode (or it id) to draw
@desc	Draws the UIElement passed in argument
*/
function draw_UINode_sprite(node_or_id) {
	var node = _UINode_resolve(node_or_id)
	if node.assets.sprite_index == undefined {exit}
	
	#region SET VARIABLES
	// Visible, sprite and image
	var _vis = node.core.visible
	var _spr = node.assets.sprite_index
	var _img = node.assets.image_index
	
	// position x/y
	var _p_x = node.position.x.render
	var _p_y = node.position.y.render
	
	// width and height
	var _w = node.size.width.resolved
	var _h = node.size.height.resolved
	#endregion

	if _vis { // If it says to be visible
		
		var x1 = _p_x	// Position x
		var y1 = _p_y	// Position y
		
		// Normal scissors keeper
		var _last_bound = {}
		
		// Sees if scissors is enabled
		if node.scissor.enabled {
			_last_bound = node.scissor.apply(node)	// Apply
		}
		
		// Draws the sprite
		draw_sprite_stretched_ext(_spr, _img, x1, y1, _w, _h, node.core.color, node.core.alpha)
		
		// Resets scissors back to normal
		if node.scissor.enabled {
			gpu_set_scissor(_last_bound)
		}
	}
}
#endregion

#region DESTROY AN UINODE
/**
@public

@param	{Struct | String}	node_or_id			The node or it id to be destroy
@param	{Bool}				destroy_children	If it destroy the children with it (false by default)
@return	{Struct<Empty>}		Returns an empty struct

@desc	Destroy an UINode, except their object
*/
function destroy_UINode(node_or_id) {
	var node	= _UINode_resolve(node_or_id)
	
	var _children	= node.core.children		// Children array
	var many_c		= array_length(_children)	// Amount of children

	// Destroy all children with itself
	while(array_length(_children)) {
		
		// Gets the children id
		var child = get_UINode_by_id(array_last(_children))
		
		// calls helper on childrens to destroy them too
		child	= _destroy_UINode_children(child)
	}
	node.core.children = []
	
	return __UINode_destroyer(node, true)
}

/**
@public

@param	{Struct | String}	node_or_id	The node or it id to be destroy

@desc	Destroy all UINode children
*/
function UINode_destroy_children(node_or_id) {
	var node		= _UINode_resolve(node_or_id)
	var children	= node.core.children
	
	// Destroy all children with itself
	while(array_length(children)) {
		// Gets the children id
		var child	= get_UINode_by_id(array_last(children))
		
		// calls helper on childrens to destroy them too
		child		= _destroy_UINode_children(child)
	}
}
#endregion

#endregion
