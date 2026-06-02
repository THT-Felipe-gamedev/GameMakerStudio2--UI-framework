#region PURE FUNCTIONS
/**
@ignore

@param	{Struct}	node	UINode to count relatives children
@return	{Real}		Amount of relative children

@desc	Counts how many children are relatives
*/
function __many_relative_children(node) {
	var amount	= 0
	var many_c	= array_length(node.core.children)
	
	for(var i = 0; i < many_c; i ++) {
		var child	= get_UINode_by_id(node.core.children[@ i])
		amount		+= (child.layout.position == UINodePosition.RELATIVE)
	}
	
	return amount
}

/**
@ignore
@pure

@param	{String}	coord	coordenate to return derivatives ("x" or "y")
@return	{Struct}	Struct with all names of things in that axis
*/
function _sizes_get_directions(_coord) {
	static x_names	= {metric: UISizeAxis.WIDTH,  dir1: "left", dir2: "right", coord: UIPositionAxis.X}
	static y_names	= {metric: UISizeAxis.HEIGHT, dir1: "top", dir2: "bottom", coord: UIPositionAxis.Y}
	
	switch(_coord) {
		case UIPositionAxis.X: return x_names
		case UIPositionAxis.Y: return y_names
	}
	return undefined
}

/**
@ignore
@pure

@param	{Struct}			node		UINode struct to use as reference
@param	{Array<Function>}	rpn			RPN array to calculate
@param	{Real}				inner_value Enum (UIPositionAxis or UISizeAxis)
@desc	Reads a RPN specific for an UINode
*/
/*
@see string_to_rpn
*/
function _UI_rpn_reader(node, rpn, value_type) {
	var length	= array_length(rpn)	// RPN length
	if length <= 0 {return 0}		// Early return
	
	// Node's parent struct
	var pare_val	= 0
	var pare_id		= node.core.parent
	var flag_p		= false
	var parent		= undefined
	
	// Create the ds stack
	var stack	= ds_stack_create()		// ds_stack were the values will be
	
	// Runs for the rpn
	for (var i = 0; i < length; i ++) { // Runs for all rpn numbers/simbles
		var rpn_part = rpn[@ i]
		
		if rpn_part.op == UIOperator.PERCENTAGE {
			if !flag_p {
				flag_p	= true
				parent	= get_UINode_by_id(pare_id)
				
				// Parent value
				switch(value_type) {
					case UIPositionAxis.X:	pare_val = parent.position.x.inner	break
					case UIPositionAxis.Y:	pare_val = parent.position.y.inner	break
				
					case UISizeAxis.WIDTH:	pare_val = parent.size.width.inner	break
					case UISizeAxis.HEIGHT:	pare_val = parent.size.height.inner	break
				}
			}
			
			// Gets the value and pushes it into the stack
			var value	= ds_stack_pop(stack) * pare_val * 0.01
			ds_stack_push(stack, value)
			continue
		}
		
		// Execute the actual rpn function
		rpn_part.exec(stack, node)
	}
	var final_value	= ds_stack_top(stack)	// Get the final value
	ds_stack_destroy(stack)					// Destroy the stack
	
	// Return final value
	return final_value
}

/**
@ignore
@pure

@param	{Struct}	node			UINode to get the free space
@param	{Boolean}	is_row			If it's to see in row direction
@param	{Boolean}	is_main_axis	If it is in the main axis
@param	{Boolean}	is_main_axis	If it is to ignore gaps

@desc	Returns the free space that a UINode has
*/
function _content_get_free_space(node, is_row, is_main_axis, ignore_gap) {
	var coord  = is_row ? "x" : "y"				// Get coordenate
	var metric = is_row ? "width" : "height"	// Get metric
	
	var gap  = is_row ? node.layout.gap_x : node.layout.gap_y	// Get gap
	var size = node.size[$ metric].inner						// Get size struct
	
	var occu_size	= __UINode_sum_child_flex(node, metric, gap, is_main_axis, ignore_gap)
	
	// Return free space (total - occupied)
	return (size - occu_size)
}

/**
@ignore
@pure

@param	{Real}	main_axis		The main axis (JUSTIFY_CONTENT enum) used
@param	{Real}	free_space		How much free space the node has
@param	{Real}	cursor value	The cursor actual value (before appying offset)

@desc	Applys offset in the children creation cursor
*/
function _adjust_position_cursor(main_axis, free_space, cursor_value) {
	switch(main_axis) {
		// CENTER = adjust to the CENTER of the UINode (AKA plus half of free space)
		case JUSTIFY_CONTENT.CENTER:
			cursor_value += free_space/2
		break
		
		// END = adjust to the END of the UINode (AKA plus free space)
		case JUSTIFY_CONTENT.END:
			cursor_value += free_space
		break
		// Left doesn't need it
	}
	return cursor_value
}

/**
@ignore
@pure

@param	{Real}	cross_axis		The cross axis ("ALIGN_ITEMS" ENUM) used
@param	{Real}	start_pos		The children start position
@param	{Real}	free_space		How much free space the node has

@desc	Applys offset in the children creation cursor
*/
function _adjust_cross_axis_children(cross_axis, start_pos, free_space) {
	switch(cross_axis) {
		case ALIGN_ITEMS.CENTER:
			start_pos += free_space * 0.5
		break
		case ALIGN_ITEMS.END:
			start_pos += free_space
		break
	}
	return start_pos
}

/**
@ignore
@pure

@param	{Struct}	child			UINode to calculate gaps
@param	{Real}		cursor			The actual value of the cursor
@param	{Real}		flex			The flex direction ("UINodeFlexDirection" ENUM)
@param	{real}		gap				The normal gap that a layout has
@param	{Bool}		is_last_child	If this is the last child

@desc	Calculates the next value of the cursor
@return	{Real}	The new cursor value
*/
function __UINode_resolve_gap_layout(child, cursor, flex, gap, is_last_child) {
	// Cursor update
	if (child.layout.position != UINodePosition.RELATIVE) {return cursor}
	
	switch(flex) {
		#region FLEX DIRECTION
		case UINodeFlexDirection.ROW:
		case UINodeFlexDirection.ROW_REVERSE:
			cursor += child.size.width.outer
		break
		case UINodeFlexDirection.COLUMN:
		case UINodeFlexDirection.COLUMN_REVERSE:
			cursor += child.size.height.outer
		break
		#endregion
	}
		
	if (!is_last_child) {
		cursor += gap
	}
	
	return cursor
}

#region DIRTY FLAGS
/**
@pure
@self _add_dirty

@param	{struct}	node	UINode to start seaking
@param	{Real}		flag	The flag (UINodeDirtyFlag) to seak

@desc	Search a safe parent to start an update based on the flag
*/
function __parent_in_dirty(node, flag) {
	if node.core.id == UI_ROOT_ID {return false}
	var UI		= global.UI
	var int		= global.UI.internal
	var p_id	= node.core.id

	do {
		p_id = get_UINode_by_id(p_id).core.parent
		if ds_map_exists(int.lookup_dirty, p_id) {
			var index	= int.lookup_dirty[? p_id]
			var dirty_p	= UI.dirty_nodes[@ index]
			
			if dirty_p.deprecated {continue}
			if dirty_p.importance >= flag {return true}
		}
	} until (p_id == UI_ROOT_ID)
	
	return false
}

/**
@ignore
@self global

@param	{Struct}	node	UINode to mark dirty
@param	{Real}		type	The type of dirty flag ( "UINodeDirtyFlag" ENUM )

@desc	It marks the dirty flag passed true. If passed ALL, marks every flag true
*/
function _mark_dirty(_node, type) {
	var dirty	= global.UI.internal.dirty
	var safe	= undefined
	
	switch(type) {
		case UINodeDirtyFlag.SIZE:
			_register_dirty_flag(_node, UINodeDirtyFlag.SIZE)
			dirty.size	= true

		case UINodeDirtyFlag.LAYOUT:
			_register_dirty_flag(_node, UINodeDirtyFlag.LAYOUT)
			dirty.layout	= true
			
		case UINodeDirtyFlag.WORLD:
			_register_dirty_flag(_node, UINodeDirtyFlag.WORLD)
			dirty.world	= true
		break
			
		case UINodeDirtyFlag.GEN_FUNCTION:
			_register_dirty_flag(_node, UINodeDirtyFlag.GEN_FUNCTION)
		break
	}
	dirty.any	= true
}

/**
@ignore
@self global

@param	{Struct}	node	The UINode to declare dirty
@param	{Real}		flag	Type of value to update

@desc	Declares the UINode dirty
*/
function _add_dirty(node, flag) {
	__eval_update_UINode(node, flag)
	if flag == UINodeDirtyFlag.GEN_FUNCTION {return}
	if __parent_in_dirty(node, flag) {return}
	
	_mark_dirty(node, flag)
	__dirty_deprecated_resolver(node, flag)
}
#endregion

#endregion

#region CALCULATORS HELPERS
/**
@ignore
@desc Update GUI
*/
function _update_GUI() {
	static prev_width	= GUI_width()
	static prev_height	= GUI_height()
	
    var w = GUI_width()
    var h = GUI_height()

	// If screen size changed and new sizes aren't 0, resize GUI display
    if (w != prev_width || h != prev_height) && w > 0 && h > 0 {	
		display_set_gui_size(w, h)
		
		prev_width  = w
	    prev_height = h
    }
}

/**
@ignore

@param	{Any}	value	Value to correct to function
@return	{Any}	The value corrected

@desc Corrects a value
*/
function __UINode_type_corrector(value) {
	var val_type	= UI_get_value_type(value)
	switch(val_type) {
		case UINodeValue.EXPRESSION:
			value	= string_delete(value, 1, 1)
		break
	}
	
	return	value
}

/**
@ignore
@desc	Updates UI inputs
*/
function _input_update() {
	var inp = global.UI.input
	
	// mouse position
	var new_x = mouse_UI_x()
	var new_y = mouse_UI_y()
	var wheel = mouse_wheel_down() - mouse_wheel_up()
	
	inp.pointer.delta_x = new_x - inp.pointer.x
	inp.pointer.delta_y = new_y - inp.pointer.y
	
	inp.pointer.x = new_x
	inp.pointer.y = new_y
	
	// buttons
	inp.pointer.down		= mouse_check_button(mb_left)
	inp.pointer.pressed		= mouse_check_button_pressed(mb_left)
	inp.pointer.released	= mouse_check_button_released(mb_left)
	
	// scroll
	inp.scroll.y = wheel
	inp.scroll.x = keyboard_check(vk_shift) ? (wheel) : 0
	
	// Keyboard
	inp.keyboard.char	= keyboard_lastchar
	inp.keyboard.key	= keyboard_lastkey
	
	keyboard_lastchar	= ""
	keyboard_lastkey	= -1
}

/**
@ignore
@pure

@param	{Struct}	node	UINode to get metrics
@return	{Struct}	Struct with direction, gap, cursor_x/y and first index

@desc	Setup gap, cursor values, direction and more to the layout main pipeline
*/
function __UINode_layout_setup_axis(node) {
	var flex_direction	= node.layout.flex_direction	// Flex direction (ROW, COLUMN...)
	var main_axis		= node.layout.justify_content	// Main-axis
	
	var many_children	= __many_relative_children(node)	// Amount of children (relatives)
	var dir		= 1											// direction (normal or reverse)
	var f_index	= 0											// first index (first children)
	
	// Sees if it's in row flow
	var is_row	= (flex_direction == UINodeFlexDirection.ROW) || (flex_direction == UINodeFlexDirection.ROW_REVERSE)
	
	// gap value
	var _gap = is_row ? node.layout.gap_x : node.layout.gap_y
	
	// If is reverse, start from the last, if not, start from the first
	if (flex_direction == UINodeFlexDirection.COLUMN_REVERSE) || (flex_direction == UINodeFlexDirection.ROW_REVERSE) {
		f_index	= many_children - 1		// Array length minus one
		dir		= -1					// Goes backwards
	}
	
	// Sees if has to ignore gaps
	var ignore_gap = (
		main_axis == JUSTIFY_CONTENT.SPACE_BETWEEN ||
		main_axis == JUSTIFY_CONTENT.SPACE_AROUND  ||
		main_axis == JUSTIFY_CONTENT.SPACE_EVENLY
	)
	
	var metric_free	= _content_get_free_space(node, is_row, true, ignore_gap)	// Free space in UINode
	var main_c_add	= 0															// value to add in some cases
	
	#region ADJUST AXIS
	switch(main_axis) {
		case JUSTIFY_CONTENT.SPACE_BETWEEN:
			if (many_children > 1) {
				_gap = metric_free / (many_children - 1)
			} else {
				_gap = 0 // Especial case: 1 child
			}
		break
		// If it's SPACE-AROUND, calculate new gap
		case JUSTIFY_CONTENT.SPACE_AROUND:
			_gap		= metric_free / many_children
			main_c_add	= _gap/2
		break

		// If it's SPACE-EVENLY, calculate new gap
		case JUSTIFY_CONTENT.SPACE_EVENLY:
			_gap		= metric_free / (many_children + 1)
			main_c_add	= _gap
		break
	}
	#endregion
	
	#region ADJUST CURSORS
	var _cur_x = node.position.x.outer + node.size.padding.inner.left
	var _cur_y = node.position.y.outer + node.size.padding.inner.top
	
	if node.core.id != UI_ROOT_ID {
		_cur_x -= node.offset.pivot.x
		_cur_y -= node.offset.pivot.y
	}
	
	// Adjust cursor (x or y)
	if ignore_gap {
		if (is_row) {
			_cur_x += main_c_add
		} else {
			_cur_y += main_c_add
		}
	} else {
		if (is_row) {
			_cur_x = _adjust_position_cursor(main_axis, metric_free, _cur_x) + main_c_add
		} else {
			_cur_y = _adjust_position_cursor(main_axis, metric_free, _cur_y) + main_c_add
		}
	}
	#endregion
	
	return {
		direction:		dir, 
		gap:			_gap,
		first_index:	f_index,
		cursor_x:		_cur_x,
		cursor_y:		_cur_y
	}
}

/**
@ignore

@param	{Struct}	node	Child parent
@param	{Struct}	child	Child struct

@param	{Real}		gap			Value between UINodes
@param	{Real}		cursor_x	Child x
@param	{Real}		cursor_y	Child y

@desc	Resolve child layout (both absolute and relative)
*/
function __UINode_layout_child_resolve(node, child, cursor_x, cursor_y) {
	var flex_direction	= node.layout.flex_direction
	var cross_axis		= node.layout.align_items
	
	var child_w = child.size.width.outer
	var child_h = child.size.height.outer
	
	var node_w = node.size.width.inner
	var node_h = node.size.height.inner
	
	#region CHILDREN RESOLVE
	switch(child.layout.position) {
		case UINodePosition.ABSOLUTE:
			__UINode_position_absolute_resolve(child)	// Update the layout
		exit
		//"break"
	}
	#endregion
		
	switch(flex_direction) {
		case UINodeFlexDirection.ROW:
		case UINodeFlexDirection.ROW_REVERSE:
			var _y_position	= _adjust_cross_axis_children(cross_axis, cursor_y, (node_h - child_h))	// Adjust cross axis (Y)
			__UINode_position_relative_resolve(child, node, cursor_x, _y_position)					// Resolve child
		break
		
		case UINodeFlexDirection.COLUMN:
		case UINodeFlexDirection.COLUMN_REVERSE:
			var _x_position	= _adjust_cross_axis_children(cross_axis, cursor_x, (node_w - child_w))	// Adjust cross axis (X)
			__UINode_position_relative_resolve(child, node, _x_position, cursor_y)					// Resolve child
		break
	}
}

/**
@ignore

@desc	Separates the nodes in dirty nodes by their needs
*/
function __parse_dirty_nodes() {
	var siz_arr	= []
	var lay_arr	= []
	var wor_arr	= []
	var drw_arr = []
	var dirty	= global.UI.dirty_nodes
	
	while(!empty_array(dirty)) {
		var dirty_stc	= array_pop(dirty)
		var node_id		= dirty_stc.node
		
		// Ignores the deprecated one
		if dirty_stc.deprecated {continue}
		
		if dirty_stc.metrics[$ UINodeDirtyFlag.SIZE] {
			array_push(siz_arr, node_id)
			array_push(drw_arr, node_id)	// They update with the size update
		}
		
		if dirty_stc.metrics[$ UINodeDirtyFlag.LAYOUT] {
			array_push(lay_arr, node_id)
		}
		
		if dirty_stc.metrics[$ UINodeDirtyFlag.WORLD] {
			array_push(wor_arr, node_id)
		}
	}
	
	return {
		size:	siz_arr,
		layout:	lay_arr,
		world:	wor_arr,
		draw:	drw_arr
	}
}
#endregion

#region NODE CALCULATORS

#region TEXT
/**
@ignore
@param	{Struct}	node	UINode to measure it text
@desc	Measures a text from a UINode
*/
function __text_measure(node) {
	var textd	= node.text
	var old_f	= draw_get_font()
	var node_f	= textd.style.font
	var w		= node.size.width
	
	draw_set_font(node_f)
	var text = ""
	
	#region GET THE TEXT
	switch(node.text.layout.draw_mode) {
		case UINodeDrawMode.CONTENT:	text = textd.content	break
		default:
		
		case UINodeDrawMode.WRAP:
			var space = 0
			if w.type != UINodeValue.AUTO {
				space = w.inner
			} else {
				if node.size.max_width >= 0 {
					space = node.size.min_width
				} else {
					text = textd.content
					break
				}
			}
			text = string_wrap(textd.content, space, textd.style.font)
		break
	}
	#endregion
	
	var new_w	= string_width(text)	* textd.style.xscale
	var new_h	= string_height(text)	* textd.style.yscale
	
	node.text.size.width	= new_w
	node.text.size.height	= new_h
	
	draw_set_font(old_f)
}
#endregion

#region POSITIONS RESOLVES
/**
@ignore

@param	{Struct}	node	UINode to calculate relatives positions
@param	{Struct}	parent	UINode's parent

@param	{Real}	base_pos_x	X basic position
@param	{Real}	base_pos_y	Y basic position

@desc	Calculates and Sets the positions for a relative UINode
*/
function __UINode_position_relative_resolve(node, parent, base_pos_x, base_pos_y) {
	var p	= node.position	// Position	struct
	var o	= node.offset	// Offset	struct
	var s	= node.size		// Size		struct
	
	// Inner values
	p.x.inner = base_pos_x
	p.y.inner = base_pos_y
	
	// Outer: with margin values
	p.x.outer	= base_pos_x + s.margin.inner.left
	p.y.outer	= base_pos_y + s.margin.inner.top
}

/**

@ignore

@param	{Struct}	node	UINode to calculate absolutes positions
@desc	Calculates and Sets the positions for a absolute UINode
*/
function __UINode_position_absolute_resolve(node) {
    var s = node.size
    var p = node.position
    var o = node.offset
	var f = get_UINode_by_id(node.core.parent)
	
	var _width	= s.width
	var _height = s.height
	
	p.x.bytecode	= string_to_rpn(p.x.raw)
	p.y.bytecode	= string_to_rpn(p.y.raw)
	
	#region POSITION
	p.x.inner = _UI_rpn_reader(node, p.x.bytecode, UISizeAxis.WIDTH)  + f.position.x.outer
	p.y.inner = _UI_rpn_reader(node, p.y.bytecode, UISizeAxis.HEIGHT) + f.position.y.outer
	
	p.x.outer = p.x.inner + s.margin.inner.left	+ s.margin.inner.left
	p.y.outer = p.y.inner + s.margin.inner.top	+ s.margin.inner.top
	#endregion
}
#endregion

#region SIZE MEASURES/RESOLVES
/**
@ignore

@param	{Struct}	node		UINode to measure sizes
@param	{String}	coordinate	coordenate to measure ("x" or "y")

@desc	Measures the size inner and resolved values (only for absolute and AUTO types)
*/
function __generic_measure_size(node, coordinate) {
	var mar		= node.size.margin.inner
	var pad		= node.size.padding.inner
	var is_x	= coordinate == UIPositionAxis.X
	
	var pad1, pad2, mar1, mar2, txt_s, min_s, max_s, measure;
	
	if is_x {
		measure	= node.size.width
		min_s	= node.size.min_width
		max_s	= node.size.max_width
		txt_s	= node.text.size.width
		
		pad1	= pad.left
		pad2	= pad.right
		mar1	= mar.left
		mar2	= mar.right
	} else {
		measure	= node.size.height
		min_s	= node.size.min_height
		max_s	= node.size.max_height
		txt_s	= node.text.size.height
		
		pad1	= pad.top
		pad2	= pad.bottom
		mar1	= mar.top
		mar2	= mar.bottom
	}
	
	var value	= measure.raw
	var type	= measure.type
	
	switch(type) {
		case UINodeValue.REAL:
			measure.bytecode	= [RPN_pushNumber(value)]
			measure.inner		= value
		break
		case UINodeValue.AUTO:
			if is_x {
				measure.inner = _sum_children_width(node, node.layout.gap_x, node.layout.flex_direction)
			} else {
				measure.inner = _sum_children_height(node, node.layout.gap_y, node.layout.flex_direction)
			}
			measure.inner = max(measure.inner, txt_s)
		break
		
		default: break
	}
	
	measure.inner = max_s >= 0 ? max(min_s, min(measure.inner, max_s)) : max(min_s, measure.inner, 0)
	
	measure.resolved	= measure.inner    + pad1 + pad2
	measure.outer		= measure.resolved + mar1 + mar2
}

/**
@ignore

@param	{Struct}	node		UINode to resolve sizes
@param	{String}	coordinate	coordenate to measure ("x" or "y")

@desc	Resolves the size inner, resolved and outer values
*/
function __generic_resolve_size(node, coordinate) {
	var mar		= node.size.margin.inner
	var pad		= node.size.padding.inner
	var is_x	= coordinate == UIPositionAxis.X
	
	var pad1, pad2, mar1, mar2, min_s, max_s, s_axis, resolve;
	
	if is_x {
		resolve	= node.size.width
		min_s	= node.size.min_width
		max_s	= node.size.max_width
		s_axis	= UISizeAxis.WIDTH
		
		pad1	= pad.left
		pad2	= pad.right
		mar1	= mar.left
		mar2	= mar.right
	} else {
		resolve	= node.size.height
		min_s	= node.size.min_height
		max_s	= node.size.max_height
		s_axis	= UISizeAxis.HEIGHT
		
		pad1	= pad.top
		pad2	= pad.bottom
		mar1	= mar.top
		mar2	= mar.bottom
	}
	
	var value	= resolve.raw
	var type	= resolve.type
	switch(type) {
		
		case UINodeValue.EXPRESSION:
		case UINodeValue.PERCENTAGE:
			
			resolve.bytecode	= string_to_rpn(value)
			resolve.inner		= _UI_rpn_reader(node, resolve.bytecode, s_axis)
		break
		
		default: break
	}
	
	resolve.inner = max_s >= 0 ? max(min_s, min(resolve.inner, max_s)) : max(resolve.inner, min_s, 0)
	
	resolve.resolved	= resolve.inner    + pad1 + pad2
	resolve.outer		= resolve.resolved + mar1 + mar2
}
/**
@ignore

@param	{Struct}	node	UINode to resolve size struct
@desc	Measures the size of a UINode (TOP-DOWN, reading percentages)
*/
function _UINode_size_resolve(node) {
    var s = node.size
	
	// Calls the evals in TOP-DOWN mode
	if s.width.type == UINodeValue.AUTO {
		__text_measure(node)
		s.width.eval(node, UINodeUpdateStep.TOPDOWN)
	} else {	
		s.width.eval(node, UINodeUpdateStep.TOPDOWN)
		__text_measure(node)
		
	}
	
	s.height.eval(node, UINodeUpdateStep.TOPDOWN)
	
	var _width	= s.width
	var _height = s.height

    // Inner calculation (where the children must be placed)
	node.inner.width	= s.width.inner
	node.inner.height	= s.height.inner
	
	node.scissor.eval(node)
	node.offset.pivot_eval(node)
}
#endregion

#region WORLD RESOLVES
/**
@ignore

@param	{Struct}	node	UINode to update specific aspects
@desc	Updates an UINode specifics aspects
*/
function __UINode_update_aspects(node) {
	var width	= node.size.width
	var height	= node.size.height
	
	switch(node.element) {
		case UINodeType.DROPDOWN:
			var layout		= node.open.layout
			var show_set	= layout.settings
			var options_l	= array_length(node.options.raw)
			
			if variable_struct_exists(show_set, "scroll") {
				node.open.height		= height.resolved * show_set.amount
				show_set.scroll.limit	= (height.resolved * options_l) - node.open.height
			} else {
				node.open.height	= height.resolved * options_l
			}

		break
		
		case UINodeType.SLIDER:
			node.step_size = width.resolved / node.steps
		break;
	}
}

/**
@ignore

@param	{Struct}	node UINode to resolve world values

@desc	Resolves a UINode world values
*/
function __UINode_world_resolve(node) {
	var p	= node.position
	var f	= get_UINode_by_id(node.core.parent)
	var o	= node.offset
	var s	= node.size
	var int	= node.internal
	
	node.offset.pivot_eval(node)
	node.scroll.eval(node)
	node.scissor.eval(node)
	
    // Aply pivot and parent scroll
    p.x.final = p.x.outer - o.pivot.x - f.scroll.value.x
    p.y.final = p.y.outer - o.pivot.y - f.scroll.value.y
	
	p.x.render	= p.x.final + o.translate.x.inner
	p.y.render	= p.y.final + o.translate.y.inner
	
	#region INNER VALUES
	// PUBLIC INNER
	node.inner.x = p.x.final + s.padding.inner.left
	node.inner.y = p.y.final + s.padding.inner.top
	
	node.inner.width	= s.width.inner
	node.inner.height	= s.height.inner
	
	// INTERNAL INNER (render)
	int.inner_render.x = p.x.render + s.padding.inner.left
	int.inner_render.y = p.y.render + s.padding.inner.top
	
	int.inner_render.width	= s.width.inner
	int.inner_render.height	= s.height.inner
	#endregion
	
	_out_of_bound_eval(node)
	// Update node specific aspects (like slider/dropdown variables)
	__UINode_update_aspects(node)
}
#endregion

#region DIRTY
/**
@ignore

@param	{Struct}	node	UInode to start deprecate useless dirty
@param	{Real}		flag	The flag (UINodeDirtyNode) to check

@desc	Marks obsoletes dirty nodes structs as deprecated, ignoring them
*/
function __dirty_deprecated_resolver(node, flag) {
	var UI	= global.UI
	var int	= global.UI.internal
	
	var l = array_length(node.core.children)
	for(var i = 0; i < l; i ++) {
		var child_id	= node.core.children[@ i]
		
		// If find some child in dirty node, check it
		if ds_map_exists(int.lookup_dirty, child_id) {
			var index	= int.lookup_dirty[? child_id]
			var dirty_c	= UI.dirty_nodes[@ index]
			
			if flag >= dirty_c.importance {
				dirty_c.deprecated = true	// Is useless
			} else {
				for(var j = flag; j >= 0; j --) {
					dirty_c[$ j] = false	// Isn't useless
				}
			}
		}
		// Call itself in children
		__dirty_deprecated_resolver(get_UINode_by_id(child_id), flag)
	}
}
#endregion

/**
@ignore
@param	{Struct}	node	UINode to evaluate values
@desc	Evaluates the values of a UINode. If there are a wrong value, shows an error message,
		and then ends the game
*/
function __eval_update_UINode(node, flag) {
	var inter	= node.internal
	
	if flag == UINodeDirtyFlag.SIZE	{
		_evaluate_UINode_text(node)
		_evaluate_UINode_size(node)
	}
	if flag == UINodeDirtyFlag.LAYOUT	{_evaluate_UINode_layout(node)}
	
	if flag == UINodeDirtyFlag.GEN_FUNCTION {
		_evaluate_UINode_gen_func(node)
		#region UPDATE HAS GENERIC FUNCTIONS
		inter.has.can_click	= is_callable(node.events.can_click)
		inter.has.on_click	= is_callable(node.events.on_click)
		
		inter.has.on_hover		= is_callable(node.events.on_hover)
		inter.has.on_change		= is_callable(node.events.on_change)
		inter.has.on_unhover	= is_callable(node.events.on_unhover)
		
		inter.has.on_input	= is_callable(node.events.on_input)
		inter.has.on_submit	= is_callable(node.events.on_submit)
		#endregion
	}
	if flag == UINodeDirtyFlag.WORLD {_evaluate_UINode_world(node)}
}

/**
@ignore
@param	{Struct}	node	UINode to update draw values
@desc	Update every draw logic values of a UINode
*/
function _UINode_update_draw(node) {
	var t	= node.text
	t.eval_wrap(node)
	t.eval_parse(node)
}

/**
@ignore
@deprecated
@param	{Struct}	node	UINode to update
@desc	Update any normal thing that needs, like scroll
*/
function _step_normal_update(node) {
	if node.scroll.enabled.x || node.scroll.enabled.y {
		node.scroll.update(node)
	}
}
#endregion

#region PIPELINES

#region little helpers
/**
@ignore

@param	{Struct}	node	UINode to measure width
@desc	Measures the width of an UINode (DOWN-TOP)
*/
function __UINode_measure_width(node) {
	node.size.margin.eval()
	node.size.padding.eval()
	
	// In auto it first get the metrics and then calculates the size
	if node.size.width.type == UINodeValue.AUTO {
		__text_measure(node)
		__generic_measure_size(node, UIPositionAxis.X)
	} else {	
		__generic_measure_size(node, UIPositionAxis.X)
		__text_measure(node)
	}
}

/**
@ignore

@param	{Struct}	node	UINode to resolve width (and measure text)
@desc	Resolves the width of an UINode (TOP-DOWN)
*/
function __UINode_resolve_width(node) {
	node.size.margin.eval()
	node.size.padding.eval()
	
	__generic_resolve_size(node, UIPositionAxis.X)
	__text_measure(node)

}

/**
@ignore

@param	{Struct}	node	UINode to measure height
@desc	Measures the height of an UINode (DOWN-TOP)
*/
function __UINode_measure_height(node) {
	node.size.margin.eval()
	node.size.padding.eval()
	
	// In auto it first get the metrics and then calculates the size
	if node.size.height.type == UINodeValue.AUTO {
		__text_measure(node)
		__generic_measure_size(node, UIPositionAxis.Y)
	} else {	
		__generic_measure_size(node, UIPositionAxis.Y)
		__text_measure(node)
	}
}

/**
@ignore

@param	{Struct}	node	UINode to resolve height
@desc	Resolves the height of an UINode (TOP-DOWN)
*/
function __UINode_resolve_height(node) {
	node.size.margin.eval()
	node.size.padding.eval()
	
	__generic_resolve_size(node, UIPositionAxis.Y)
	__text_measure(node)
	
	// At last, evaluates the pivots
	node.offset.pivot_eval()
}

/**
@ignore

@param	{Struct}	node	UINode to measure and call children
@param	{Real}		coord	Coordinate ("UIPositionAxis" ENUM) to check

@desc	Measures a size of an UINode and then call itself on the children
*/
function __UI_sizes_measure_helper(node, coord) {
	var children		= node.core.children		// Get the children
	var many_children	= array_length(children)	// Array length
	
	// 0 = X | 1 = Y
	static measure = [__UINode_measure_width, __UINode_measure_height]
	
	// If node is allowed to have childrens
	if node.internal.allowed_children {
		// For all children, see calls same function
		for (var i = 0; i < many_children; i ++) {
			var child = get_UINode_by_id(children[@ i])
			__UI_sizes_measure_helper(child, coord)
		}
	}
	
	// After childrens update, resolve the sizes
	if node.core.id != UI_ROOT_ID {
		measure[@ coord](node)
	}
}

/**
@ignore

@param	{Struct}	node	UINode to resolve and call children
@param	{Real}		coord	Coordinate ("UIPositionAxis" ENUM) to check

@desc	resolves a size of an UINode and then call itself on the children
*/
function __UI_sizes_resolve_helper(node, coord) {
	var children		= node.core.children		// Get the children
	var many_children	= array_length(children)	// Array length
	
	var old_val	= coord == 0 ? node.size.width.inner : node.size.height.inner
	
	// 0 = X | 1 = Y
	static resolve = [__UINode_resolve_width, __UINode_resolve_height]
	
	// Before all childrens update, resolve the sizes
	if node.core.id != UI_ROOT_ID {
		resolve[@ coord](node)
	}
	
	//if old_val == (coord == 0 ? node.size.width.inner : node.size.height.inner) {return}
	
	// If node is allowed to have childrens
	if node.internal.allowed_children {
		// For all children, see calls same function
		for (var i = 0; i < many_children; i ++) {
			var child = get_UINode_by_id(children[@ i])
			__UI_sizes_resolve_helper(child, coord)
		}
	}
}

#endregion

/**
@ignore
@param	{Struct} root UINode system main root
@desc	Updates the root with the screen metrics
*/
function _UINode_root_update(root) {
	root.position.x.outer	= 0
	root.position.y.outer	= 0
	root.size.width.inner	= GUI_width()
	root.size.height.inner	= GUI_height()
	
	root.inner.x		= root.position.x.outer
	root.inner.x		= root.position.y.outer
	root.inner.width	= root.size.width.inner
	root.inner.height	= root.size.height.inner
}

/**
@ignore
@param	{Struct}	node	UINode to start width pipeline
@desc	Measures and resolves all UINodes width values
*/
function _UI_width_pipeline(node) {
	__UI_sizes_measure_helper(node, UIPositionAxis.X)
	__UI_sizes_resolve_helper(node, UIPositionAxis.X)
}

/**
@ignore
@param	{Struct}	node	UINode to start height pipeline
@desc	Measures and resolves all UINodes height values
*/
function _UI_height_pipeline(node) {
	__UI_sizes_measure_helper(node, UIPositionAxis.Y)
	__UI_sizes_resolve_helper(node, UIPositionAxis.Y)
}

/**
@ignore
@param	{Struct}	node	UINode to resolve children
@desc	resolve the layout values of children and calls itself in them
*/
function _UINode_layout_pipeline(node) {
	var justify_cont	= node.layout.justify_content
	var flex_direction	= node.layout.flex_direction
	var children		= node.core.children		// Children array
	var many_c			= array_length(children)	// Number of children

	// Get metrics and cursors values
	var right_m = __UINode_layout_setup_axis(node)
	
	var index	= right_m.first_index	// First children index
	var dir		= right_m.direction		// Direction to go (forward or backward)
	var gap		= right_m.gap			// Gap value
	
	// Cursor values (children positions)
	var cursor_x	= right_m.cursor_x
	var cursor_y	= right_m.cursor_y
	
	// If is reverse, goes until -1, if is normal, goes until many_children+1
	while(index >= 0 && index < many_c) {
		// Get children
		var child	= get_UINode_by_id(children[@ index])
		var is_last	= (index + dir < 0) || (index + dir >= many_c)
		// Resolve child position
		__UINode_layout_child_resolve(node, child, cursor_x, cursor_y)
		
		// Cursor values (children positions)
		switch(node.layout.flex_direction) {
			case UINodeFlexDirection.ROW:
			case UINodeFlexDirection.ROW_REVERSE:
				cursor_x = __UINode_resolve_gap_layout(child, cursor_x, flex_direction, gap, is_last)
			break
			
			case UINodeFlexDirection.COLUMN:
			case UINodeFlexDirection.COLUMN_REVERSE:
				cursor_y = __UINode_resolve_gap_layout(child, cursor_y, flex_direction, gap, is_last)
			break
		}
		
		_UINode_layout_pipeline(child)	// Calls itself in the children
		index += dir
	}
}

/**
@ignore
@param	{Struct}	node UINode to resolve world value
@desc	Resolves a UINode world values and calls itself on the children
*/
function _UINode_world_pipeline(node) {
	var children	= node.core.children
	var many_c		= array_length(children)
	
	if node.core.id != UI_ROOT_ID {
		__UINode_world_resolve(node)
	}
	
	for(var i = 0; i < many_c; i ++) {
		var child	= get_UINode_by_id(children[@ i])
		_UINode_world_pipeline(child)
	}
}

/**
@ignore

@param	{Struct}	root	UINode or root to update draw an call itself on the children
@desc	Resolves the main draw update on the node passed and
*/
function _UINode_draw_pipeline(root) {
	var children	= root.core.children
	var many_c		= array_length(children)
	
	// Calls itself on the children
	for(var i = 0; i < many_c; i ++) {
		var child = get_UINode_by_id(children[@ i])
		_UINode_draw_pipeline(child)
	}
	
	// Resolve draw
	if root.core.id != UI_ROOT_ID {
		_UINode_update_draw(root)
	}
}

/**
@public
@desc	(NECESSARY TO SYSTEM WORK) UINode main step pipeline updates every logic values in UI system
*/
function UINode_step_pipeline(){
	static non_own_step = [
		UINodeType.ICON, UINodeType.LABEL, UINodeType.PANEL,
		UINodeType.BUTTON
	]
	
	_input_update()
	_update_GUI()
	
	var UI = global.UI
	
	// Internal update
	_UINode_root_update(UI.screen)
	_UI_uptade_layer()
	
	// Size and word update
	var nodes = UI.nodes
	var many_nodes = array_length(nodes)
	
	for (var i = 0; i < many_nodes; i++) {
		var node = UI.internal.lookup_map[? nodes[i]]
		
		if node.scroll.enabled.x || node.scroll.enabled.y {
			node.scroll.update(node)
		}
		
		if !node.core.visible {continue}
		
		if !array_contains(non_own_step, node.element) {
			__node_step_switch(node, node.element)
		}
		
		if node.internal.has.on_change && node.internal.changed {
			node.events.on_change(node)
		}
	}
	
	// Update hover/focus, executes generic functions and update dirty nodes
	_UINode_update_generic_and_focus()
	__UINode_update_dirty_node()
	
	ds_map_clear(UI.internal.lookup_dirty)
	UI.dirty_nodes = []
}
#endregion

function __resolve_auto_chain(current_safe) {
	var safe		= current_safe
	var safe_node	= get_UINode_by_id(safe)
	
	while(safe != UI_ROOT_ID) {
		var w_is_auto = get_UINode_by_id(safe_node.core.parent).size.width.type  == UINodeValue.AUTO
		var h_is_auto = get_UINode_by_id(safe_node.core.parent).size.height.type == UINodeValue.AUTO
		
		if (!w_is_auto && !h_is_auto) {break}
		
		safe		= safe_node.core.parent
		safe_node	= get_UINode_by_id(safe)
	}
	
	return safe
}

function __find_safe_parent(node, flag) {
	var safe = node.core.id
	
	if flag == UINodeDirtyFlag.WORLD {return UI_ROOT_ID}
	
	while(safe != UI_ROOT_ID) {
		var ret_stc		= get_UINode_by_id(safe)
		var is_safe		= ret_stc.internal.is_safe
			
		if !is_safe[$ flag] {
			safe = ret_stc.core.parent
		} else {
			if flag == UINodeDirtyFlag.SIZE {
				safe = __resolve_auto_chain(safe)
			}
			break
		}
	}

	return safe
}

function _register_dirty_flag(node, flag) {

	if flag == UINodeDirtyFlag.GEN_FUNCTION {return}
	
	static create_dirty_stc = function(_node) constructor {
		node	= _node
		metrics	= {}
		
		metrics[$ UINodeDirtyFlag.SIZE]		= false
		metrics[$ UINodeDirtyFlag.LAYOUT]	= false
		metrics[$ UINodeDirtyFlag.WORLD]	= false
		
		deprecated	= false
		importance	= -1
	}
	
	var UI		= global.UI
	var safe	= __find_safe_parent(node, flag)
	
	// REGISTER DIRTY ROOT
			
	var dirty_stc;
	var found = false

	for(var i = 0; i < array_length(UI.dirty_nodes); i ++) {
		dirty_stc = UI.dirty_nodes[i]
				
		if dirty_stc.node == safe {
			found = true
			break
		}
	}
			
	if !found {
		ds_map_add(UI.internal.lookup_dirty, safe, array_length(UI.dirty_nodes))
		array_push(UI.dirty_nodes, new create_dirty_stc(safe))
		dirty_stc = array_last(UI.dirty_nodes)
	}
			
	dirty_stc.metrics[$ flag]	= true
	dirty_stc.importance		= max(dirty_stc.importance, flag)
	return safe
}



/**
@ignore

@desc	Updates all nodes that are dirty
*/
function __UINode_update_dirty_node() {
	if empty_array(global.UI.dirty_nodes) {return}
	var new_parse	= __parse_dirty_nodes()
	
	while(!empty_array(new_parse.size)) {
		var size_node	= get_UINode_by_id(array_pop(new_parse.size))
		_UI_width_pipeline(size_node)
		_UI_height_pipeline(size_node)
	}
	
	while(!empty_array(new_parse.layout)) {
		var layout_node = get_UINode_by_id(array_pop(new_parse.layout))
		_UINode_layout_pipeline(layout_node)
	}
	
	while(!empty_array(new_parse.world)) {
		var world_node = get_UINode_by_id(array_pop(new_parse.world))
		_UINode_world_pipeline(world_node)
	}
	
	while(!empty_array(new_parse.draw)) {
		var draw_node = get_UINode_by_id(array_pop(new_parse.draw))
		_UINode_draw_pipeline(draw_node)
	}
	
	global.UI.internal.dirty.size	= false
	global.UI.internal.dirty.layout	= false
	global.UI.internal.dirty.world	= false
	global.UI.internal.dirty.any	= false
}