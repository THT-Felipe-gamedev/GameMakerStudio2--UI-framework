#region MACROS
#macro MAC_HAS_MY_DATA (variable_instance_exists(self, "my_data"))
#macro MAC_NO_MY_DATA_EXIT if (!MAC_HAS_MY_DATA) exit

#macro UI_ROOT_ID "ref node -1"
#endregion

#region BASIC CREATOR

#region PURE

#region AUTO calculator
/**
@ignore
@pure

@param	{Struct}	node			UINode to sum all children
@param	{String}	metric			Which metric use ( "width" or "height" )
@param	{Real}		gap				Value between children
@param	{Bool}		is_main_axis	If is the main axis
@param	{Bool}		ignore_gap		If it's to ignore gap ( optional )
*/
function __UINode_sum_child_flex(node, metric, gap, is_main_axis, ignore_gap = false) {
	var children		= node.core.children
	var many_children	= array_length(children)
	var total			= 0
	var many_rela		= 0

	var min_s	= 0
	var max_s	= -1
	var txt_s	= 0
	
	// If is not root
	if node.core.id != UI_ROOT_ID {
		txt_s	= node.text.size[$ metric]
		min_s	= node.size[$ $"min_{metric}"]
		max_s	= node.size[$ $"max_{metric}"]
	}
	
	// If don't have children, just returns minimum size or text size
	if (many_children == 0) || !node.internal.allowed_children {
	    return max(min_s, txt_s)
	}
	
	for(var i = 0; i < many_children; i ++) {
		var child_id	= children[@ i]					// Child id
		var child		= get_UINode_by_id(child_id)	// Child struct
		
		if child.layout.position == UINodePosition.ABSOLUTE {continue}
		
		// Get outer value (value + padding + margin)
		var outer = child.size[$ metric].outer
		many_rela ++	// Add to many relatives
		
		// If is the main axis
		if is_main_axis {
			// add it to total value
			total	+= outer
		} else {
			// Else, see the bigger
			total = max(total, outer)
		}
	}
	
	// If it's the main axis and ignore gaps is false
	if is_main_axis && !ignore_gap {
		var gaps_s	= (many_rela-1) * gap	// All gap size
		total		+= gaps_s				// Add gaps
	}
	
	// Gets the text if inst root node
	if metric == "width" && node.core.id != UI_ROOT_ID {
		// Sees if main text is bigger than children sum
		total =  max(total, txt_s)
	}
	
	return total
}

/**
@ignore
@pure

@param	{Struct}	node	UINode to sum all children width
@param	{Real}		gap		Value between children
@param	{Real}		type	UINode flex direction type ( ENUM "UINodeFlexDirection" )

@desc	Sum a UINode children width ( WITHOUT GAPS )
*/
function _sum_children_width(node, gap, type) {
	// All values that are considered row
	static row_values	= [UINodeFlexDirection.ROW, UINodeFlexDirection.ROW_REVERSE]
	
	var is_row		= array_contains(row_values, type)						// If is a row value
	var total_width	= __UINode_sum_child_flex(node, "width", gap, is_row)	// Final size (return) 
	
	return total_width
}

/**
@ignore
@pure

@param	{Struct}	node	UINode to sum all children height
@param	{Real}		gap		Value between children
@param	{Real}		type	UINode flex direction type ( ENUM "UINodeFlexDirection" )

@desc	Sum a UINode children height ( WITHOUT GAPS )
*/
function _sum_children_height(node, gap, type) {
	// All values that are considered column
	static row_values	= [UINodeFlexDirection.COLUMN, UINodeFlexDirection.COLUMN_REVERSE]
	
	var is_column		= array_contains(row_values, type)							// If is a column value
	var total_height	= __UINode_sum_child_flex(node, "height", gap, is_column)	// Final size (return) 
	
	return total_height
}
#endregion

/**
@ignore
@pure

@param	{String}	simble	The simble ("m" or "p") to get parameters
@param	{Struct}	config	Where the raw values will be taken

@desc	Creates the padding/margin main structure
*/
function __create_padmar_UINode(simble, config) constructor {
		var all_s = $"{simble}_all"
		
		var l_s = $"{simble}_l"
		var r_s = $"{simble}_r"
		var t_s = $"{simble}_t"
		var b_s = $"{simble}_b"
		
		var x_s	= $"{simble}_x"
		var y_s	= $"{simble}_y"
		
		raw = {
			top:	config[$ all_s] ?? config[$ y_s] ?? config[$ t_s] ?? 0,
			bottom: config[$ all_s] ?? config[$ y_s] ?? config[$ b_s] ?? 0,
			left:	config[$ all_s] ?? config[$ x_s] ?? config[$ l_s] ?? 0,
			right:	config[$ all_s] ?? config[$ x_s] ?? config[$ r_s] ?? 0
		}
	    bytecode = {
	        top:    [],
	        bottom: [],
	        left:   [],
	        right:  []
	    }
		inner = {
			top:	0,
			bottom: 0,
			left:	0,
			right:	0
		}
		dirty	= {
			top:	true,
			bottom: true,
			left:	true,
			right:	true
		}
		
		eval	= simble == "m" ? _UINode_margin_eval : _UINode_padding_eval
		set		= simble == "m" ? _UINode_set_margin  : _UINode_set_padding
}

/**
@ignore

@param	{Struct}	node	UINode toget values
@param	{Real}		flag	Which part to verify (UINodeDirtyFlag)
@return	{Bool}	Whether the nodeis safe or not

@desc	Checks if a node is safe to start calculating in that flag
*/
function __node_is_safe(node, flag) {
	static safe_values = [UINodeValue.AUTO, UINodeValue.REAL]
	
	switch(flag) {
		case UINodeDirtyFlag.SIZE:
			var s = node.s
			node.internal.is_safe[$ flag] =
			array_contains(safe_values, s.width.type) && array_contains(safe_values, s.height.type)
		break
		case UINodeDirtyFlag.LAYOUT:
			var p = node.position
			node.internal.is_safe[$ flag] =
			array_contains(safe_values, p.x.type) && array_contains(safe_values, p.y.type)
		break
	}
}
#endregion

#region HELPERS
/**
@ignore
@param	{Struct}	config	Struct with parameters
@desc	Creates the basic for a UINode text style
*/
function _create_UI_text_style(config) {
	return {
		font:	config[$ "font"]		?? -1,
		color:	config[$ "font_color"]	?? c_white,
		
		xscale:	config[$ "font_xscale"]	?? 1,
		yscale:	config[$ "font_yscale"]	?? 1,
		alpha:	config[$ "font_alpha"]	?? 1,
	}
}

/**
@ignore
@param	{Struct}	config	Struct with parameters
@desc	Creates the basic for a UINode text layout
*/
function _create_UI_text_layout(config) {
	return {
		halign:		config[$ "halign"]		?? fa_left,
		valign:		config[$ "valign"]		?? fa_top,
		letters:	config[$ "letters"]		?? string_width(config[$ "text"] ?? ""),

		draw_mode:	config[$ "draw_mode"]	?? UINodeDrawMode.WRAP,
	}
}

/**
@ignore

@param	{Struct}		node		UINode to set margin or padding
@param	{String}		pad_or_mar	Which one is to change
@param	{String}		direction	The direction to change
@param	{Real, String}	value		The new value to set

@desc	Sets a new value to a UINOde margin or padding
*/
function __MarPad_setter(node, pad_or_mar, direction, value) {
	var place = node.size[$ pad_or_mar].raw
	var dirty = node.size[$ pad_or_mar].dirty

	var faces = undefined

	switch(direction) {
	    case "all":
			faces = ["left", "right", "top", "bottom"]
		break

		case "x":
			faces = ["left", "right"]
		break

		case "y":
			faces = ["top", "bottom"]
		break

		case "left":
		case "right":
		case "top":
		case "bottom":
			faces = [direction]
		break

		default:
			exit
	}

	for (var i = 0; i < array_length(faces); i++) {
		var face = faces[@ i]

		dirty[$ face] = place[$ face] != value
		place[$ face] = value
	}
	_add_dirty(node, UINodeDirtyFlag.SIZE)
}

/**
@ignore
@param	{Struct}		node	UINode to apply and return scissor metrics
@return	{Struct, Bool}	Returns the struct of the previous or false if doesn't need to set scissors
@desc	Apply the UINode scissor and returns the previous scissor metric
*/
function __UI_apply_scissor(node) {
	var last	= global.UI.internal.last_scissor
	var scissor	= node.scissor.rect.inner
	
	if last.x == scissor.x && last.y == scissor.y 
	&& last.w == scissor.w && last.h == scissor.h {
		return;
	}
	
	gpu_set_scissor(scissor)
	global.UI.internal.last_scissor = scissor
}
#endregion

#region SETTERS
/**
@ignore

@param	{String}		direction	The direction to change
@param	{Real, String}	value		The new value to set ( "all", "x", "left", ... )

@desc	Sets a new value to a UINode margin
*/
function _UINode_set_margin(direction, value){
	__MarPad_setter(self, "margin", direction, value)
}

/**
@ignore

@param	{String}		direction	The direction to change
@param	{Real, String}	value		The new value to set ( "all", "x", "left", ... )

@desc	Sets a new value to a UINode padding
*/
function _UINode_set_padding(direction, value){
	__MarPad_setter(self, "padding", direction, value)
}

/**
@ignore
*/
function _UINode_set_scissor(stc_or_node_ref) {
	static order	= ["x", "y", "w", "h"]
	static order_l	= array_length(order)
	
	var mark		= []
	var _type		= UI_get_value_type(stc_or_node_ref)
	var value		= stc_or_node_ref
	
	switch(_type) {
		case UINodeValue.NODE_REFERENCE: {
			self.scissor.rect.raw	= value
			mark					= ["x", "y", "w", "h"]
		}
		case UINodeValue.STRUCT: {
			for(var i = 0; i < order_l; i ++) {
				var stc_val = order[@ i]
				if value[$ stc_val] != self.scissor.rect.raw[$ stc_val] {
					self.scissor.rect.raw[$ stc_val] = value
					array_push(mark, stc_val)
				}
			}
		}
	}
	
	for(var j = 0; j < array_length(mark); j ++) {
		self.scissor.rect.dirty[$ mark[@ j]] = true
	}
}
#endregion

#region EVALS
/**
@ignore
*/
function __translate_UINode_calculator(value, side, node) {
	var trans	= node.offset.translate
	var type	= -1
	var byte	= undefined
	var p_val	= 0
	
	switch(side) {
		case UISizeAxis.WIDTH:
			if trans.x.dirty {
				trans.x.type		= UI_get_value_type(value)
				trans.x.raw			= __UINode_type_corrector(value)
				trans.x.bytecode	= string_to_rpn(value)
				trans.x.dirty		= false
			}
			type	= trans.x.type
			byte	= trans.x.bytecode
			p_val	= trans.x.inner
		break
		case UISizeAxis.HEIGHT:
			if trans.y.dirty {
				trans.y.type		= UI_get_value_type(value)
				trans.y.raw			= __UINode_type_corrector(value)
				trans.y.bytecode	= string_to_rpn(value)
				trans.y.dirty		= false
			}
			type	= trans.y.type
			byte	= trans.y.bytecode
			p_val	= trans.y.inner
		break
	}
	
	switch(type) {
		case UINodeValue.PERCENTAGE:
			var dirty = global.UI.internal.dirty
			if (!dirty.size && !dirty.layout) {
				return p_val
			}
		case UINodeValue.EXPRESSION: 
		return _UI_rpn_reader(node, byte, side)
		
		default:
		case UINodeValue.REAL: return value
	}
}

/**
@ignore
@param	{Struct}	node	UINode to eval pivot
@desc	Evaluates a UINode offset pivot
*/
function _offset_pivot_eval() {
	var o = self.offset
	
	var w = self.size.width.resolved
	var h = self.size.height.resolved
	
	// LEFT == 0; CENTER == half width; RIGHT == width
	o.pivot.x = o.x == UI_HALIGN.CENTER ? w/2 : (o.x == UI_HALIGN.RIGHT ? w : 0)
	// TOP == 0; MIDDLE == half height; BOTTOM == height
	o.pivot.y = o.y == UI_HALIGN.CENTER ? h/2 : (o.y == UI_HALIGN.RIGHT ? h : 0)
	
	o.translate.x.inner	= __translate_UINode_calculator(o.translate.x.raw, UISizeAxis.WIDTH,  self)
	o.translate.y.inner	= __translate_UINode_calculator(o.translate.y.raw, UISizeAxis.HEIGHT, self)
}

/**
@ignore

@param	{Struct}	node	UINode to eval margin or padding
@param	{String}	type	Which one is ( "padding" or "margin" )

@desc	Evaluates a UINode margin or padding
*/
function _UI_eval_MarPad(node, type) {
	var _size = node.size[$ type]
		
	static _x_faces	= ["left", "right"]
	static _y_faces	= ["top", "bottom"]
			
	static all_dir		= [UIPositionAxis.X, UIPositionAxis.Y]
	static all_metrics	= [UISizeAxis.WIDTH, UISizeAxis.HEIGHT]
			
	for(var i = 0; i < array_length(all_dir); i ++) {
				
		// Gets the direction and face type
		var dir			= all_dir[@ i]
		var metric		= all_metrics[@ i]
		var _what_face	= dir == UIPositionAxis.X ? _x_faces : _y_faces
			
				
		// Runs all "_what_face"
		for(var j = 0; j < array_length(_what_face); j ++) {
			var _face	= _what_face[@ j]
			var _raw_v	= _size.raw[$ _face]
				
			// If value changed
			if _size.dirty[$ _face] {
				_size.dirty[$ _face] = false
				
				// Set bytecode
				_size.bytecode[$ _face]	= string_to_rpn(_raw_v)		
			}
			var _byt = _size.bytecode[$ _face]
				
			// Set inner value reading the rpn
			_size.inner[$ _face] = _UI_rpn_reader(node, _byt, metric)
		}
	}
}

/**
@ignore
@desc	Evaluate an UINode padding
*/
function _UINode_padding_eval() {
	_UI_eval_MarPad(self, "padding")
}

/**
@ignore
@desc	Evaluate an UINode margin
*/
function _UINode_margin_eval() {
	_UI_eval_MarPad(self, "margin")
}

/**
@ignore
@param	{Struct}	node	UINode to evaluate scroll
@desc	Evaluates a UINode scroll's struct
*/
function UI_eval_scroll(node) {
	
	var scroll = node.scroll
	
	// EARLY RETURN
	if (!node.scroll.enabled.x && !node.scroll.enabled.y) && node.element != UINodeType.TEXTBOX {
		return
	}
	
	var content_w	= 0
	var content_h	= 0
	
	// Get the content size (place occupied by childrens)
	if node.internal.allowed_children {
		content_w	= _sum_children_width(node, node.layout.gap_x, node.layout.flex_direction)
		content_h	= _sum_children_height(node, node.layout.gap_y, node.layout.flex_direction)
	} else {
		content_w	= node.text.size.width
		content_h	= node.text.size.height
	}
	
	
	var over_w = content_w - node.size.width.inner	// Overflow on x
	var over_h = content_h - node.size.height.inner	// Overflow on y
	
	scroll.overflow.x	= max(over_w, 0)
	scroll.overflow.y	= max(over_h, 0)
}

/**
@ignore
@param	{Struct}	node	UINode to evaluate scissor
@desc	Evaluates a UINode scissor's struct
*/
function _UI_eval_scissor(node) {
	var glb_dirty	= global.UI.internal.dirty
	var _sci		= node.scissor
	var rect		= _sci.rect
	
	switch(rect.type) {
		case UINodeValue.NODE_REFERENCE:
			var n = get_UINode_by_id(rect.raw)
			
			var x1 = n.position.x.final + n.size.padding.inner.left
			var y1 = n.position.y.final + n.size.padding.inner.top
			var w1 = n.size.width.inner
			var h1 = n.size.height.inner
			
			if x1 != rect.inner.x {rect.bytecode.x	= [RPN_pushNumber(x1)]}
			if y1 != rect.inner.y {rect.bytecode.y	= [RPN_pushNumber(y1)]}
			if w1 != rect.inner.w {rect.bytecode.w	= [RPN_pushNumber(w1)]}
			if h1 != rect.inner.h {rect.bytecode.h	= [RPN_pushNumber(h1)]}
		break
		
		case UINodeValue.STRUCT:
			if rect.dirty.x {rect.bytecode.x = string_to_rpn(rect.raw.x)}
			if rect.dirty.y {rect.bytecode.y = string_to_rpn(rect.raw.y)}
			if rect.dirty.w {rect.bytecode.w = string_to_rpn(rect.raw.w)}
			if rect.dirty.h {rect.bytecode.h = string_to_rpn(rect.raw.h)}
		break
	}
	
	// CALCULATES EVERY PART
	if glb_dirty.layout || glb_dirty.size {
		rect.inner.x = _UI_rpn_reader(node, rect.bytecode.x, UIPositionAxis.X)
		rect.inner.y = _UI_rpn_reader(node, rect.bytecode.y, UIPositionAxis.Y)
		rect.inner.w = _UI_rpn_reader(node, rect.bytecode.w, UISizeAxis.WIDTH)
		rect.inner.h = _UI_rpn_reader(node, rect.bytecode.h, UISizeAxis.HEIGHT)
	}

	rect.dirty.x = false
	rect.dirty.y = false
	rect.dirty.w = false
	rect.dirty.h = false
}
#endregion

#endregion

#region CORE, ASSETS AND POSITION
/**
@ignore
@param	{Struct}	config	Parameters to use in the core of a UINode
@desc	Creates the core struct with: parent, id, class, children, visible, etc
*/
function __UI_create_core(config) constructor {

    parent	= config[$ "parent"]	?? UI_ROOT_ID
    name	= config[$ "name"]		?? "noname"
    class	= config[$ "class"]		?? "noone"
    tag		= config[$ "tag"]		?? ""
	
	id		= $"ref node {global.UI.id_actual}"
	global.UI.id_actual ++

    color	= config[$ "color"] ?? c_white
    alpha	= config[$ "alpha"] ?? 1
	
	interactive	= config[$ "interactive"]	?? true
	children	= []
    visible		= config[$ "visible"]	?? true
}

/**
@ignore
@param	{Struct}	config	Parameters to create the asset struct for a UINode
@desc	Creates the size struct with: object, sprite, image and sprite_set
*/
function __UI_create_assets(config) constructor {
	sprite_index	= config[$ "sprite"]		?? undefined

    image_index		= config[$ "image"]			?? 0
	sprite_set		= config[$ "sprite_set"]	?? {}
}

/**
@ignore
@param	{Struct}	config	Parameters to use in the position struct
@desc	Creates the size struct with: x and y
*/
function __UI_create_position(config) constructor {
	x = {
		raw:		config[$ "x"] ?? 0,	// Raw value passed (string, real, auto...)
		type:		UI_get_value_type(config[$ "x"] ?? 0),

		inner:		0,	// X without margin
		outer:		0,	// X with margin
		final:		0,	// X with margin and offset
		render:		0,	// X with visual offset/translate
		bytecode:	[],	// RPN
		
		set:	function(_nraw) {
			if self.position.x.raw == _nraw {exit}
			self.position.x.type		= UI_get_value_type(_nraw)
			self.position.x.raw			= __UINode_type_corrector(_nraw)
			
			__node_is_safe(self, UINodeDirtyFlag.LAYOUT) 
			_add_dirty(self, UINodeDirtyFlag.LAYOUT)
		}
	}
	
	y = {
		raw:		config[$ "y"] ?? 0,	// Raw value passed (string, real, auto...)
		type:		UI_get_value_type(config[$ "y"] ?? 0),
		
		inner:		0,	// Y without margin
		outer:		0,	// Y with margin
		final:		0,	// Y with margin and offset
		render:		0,	// Y with visual offset/translate
		bytecode:	[],	// RPN
		
		set:	function(_nraw) {
			if self.position.y.raw != _nraw {exit}
			self.position.y.type		= UI_get_value_type(_nraw)
			self.position.y.raw			= __UINode_type_corrector(_nraw)
			
			__node_is_safe(self, UINodeDirtyFlag.LAYOUT) 
			_add_dirty(self, UINodeDirtyFlag.LAYOUT)
		}
	}
	
	x.raw	= __UINode_type_corrector(x.raw)
	y.raw	= __UINode_type_corrector(y.raw)
}
#endregion

#region SIZE, OFFSET AND TEXT
/**
@ignore
@param	{Struct}	config	Parameters to use in the size struct construct
@desc	Creates the size struct with: width, height, padding, margin and min and max values
*/
function __UI_create_sizes(config) constructor {
    var real_width  = config[$ "width"]		?? 0
    var real_height = config[$ "height"]	?? 0
	
	width = {
		raw:		real_width,
		bytecode:	[],
		type:		UI_get_value_type(real_width),
		
		inner:		0,
		resolved:	0,
		outer:		0,

		set:	function(_raw) {
			if self.size.width.raw = _raw {return}
			self.size.width.type	= UI_get_value_type(_raw)
			self.size.width.raw		= __UINode_type_corrector(_raw)
			
			__node_is_safe(self, UINodeDirtyFlag.SIZE)
			_add_dirty(self, UINodeDirtyFlag.SIZE)
		}
	}
	
	height = {
		raw:		real_height,
		bytecode:	[],
		type:		UI_get_value_type(real_height),
		
		inner:		0,
		resolved:	0,
		outer:		0,

		set:	function(_raw) {
			if self.size.height.raw == _raw {return}
			self.size.height.type	= UI_get_value_type(_raw)
			self.size.height.raw	= __UINode_type_corrector(_raw)
			
			__node_is_safe(self, UINodeDirtyFlag.SIZE)
			_add_dirty(self, UINodeDirtyFlag.SIZE)
		}
	}
	
	min_width  = config[$ "min_width"]	?? 0
	max_width  = config[$ "max_width"]	?? -1
	min_height = config[$ "min_height"]	?? 0
	max_height = config[$ "max_height"]	?? -1

	
	margin	= new __create_padmar_UINode("m", config)
	padding	= new __create_padmar_UINode("p", config)
	
	width.raw	= __UINode_type_corrector(width.raw)
	height.raw	= __UINode_type_corrector(height.raw)
}

/**
@ignore
@param	{Struct}	config	Parameters to use in the offset struct
@desc	Creates the size struct with: offset values and pivot
*/
function __UI_create_offset(config) constructor {
	x = config[$ "x_offset"]  ?? UI_HALIGN.LEFT
	y = config[$ "y_offset"]  ?? UI_VALIGN.TOP
	
	pivot = {
		x: 0,
		y: 0
	}
	
	translate = {
		x: {raw: config[$ "translate_x"] ?? 0, bytecode: [], inner: 0, dirty: true, type: -1},
		y: {raw: config[$ "translate_y"] ?? 0, bytecode: [], inner: 0, dirty: true, type: -1}
	}
	
	pivot_eval	= _offset_pivot_eval
}

/**
@ignore
@param	{Struct}	config	Parameters to use in the text data structure
@desc	Creates the size struct with: content, wrap, parsed, span, style and layout
*/
function __UI_create_text_data(config) constructor {
	content		= config[$ "text"]	?? ""
	wrap		= config[$ "text"]	?? ""
	parsed		= []
	
	style	= _create_UI_text_style(config)
	layout	= _create_UI_text_layout(config)
	
	span = config[$ "span"]	?? []
	
	size = {
		width:	0,
		height:	0
	}
	
	set_content	= function(_new_content) {
		if self.text.content == _new_content {return}
		
		_add_dirty(self, UINodeDirtyFlag.SIZE)
		self.text.content	= _new_content
		
		if self.element == UINodeType.LABEL {
			self.internal.changed = true
		}
		
		__eval_update_UINode(self, UINodeDirtyFlag.SIZE)
	}
	
	set_span	= function(new_span) {
		self.text.span	= new_span
		_add_dirty(self, UINodeDirtyFlag.SIZE)
		__eval_update_UINode(self, UINodeDirtyFlag.SIZE)
	}
	
	eval_wrap = function(node) {
		var _text		= node.text
		var s			= node.size
		
		// If is auto, get max_width, if don't, just take the inner width
		var w			= s.width.type	== UINodeValue.AUTO ? s.max_width : s.width.inner
		
		var _new_wrap	= string_wrap(node.text.content, w, node.text.style.font)
		node.text.wrap	= _new_wrap
	}
	
	eval_parse = function(node) {
		var txtd		= node.text
		var style		= txtd.style
		var spans		= txtd.span
		var draw_mode	= txtd.layout.draw_mode
			
		var parse	= _UI_parse_text_resolver(txtd.content, txtd.wrap, spans, style, draw_mode)
			
		node.text.parsed	= parse
	}
	
}
#endregion

#region SCISSOR, INNER AND LAYERS
/**
@ignore
@param	{Struct}	config	Parameters to use in scissor UINode
@desc	Creates the size struct with: enabled and rect
*/
function __UI_create_scissor(config) constructor {
	static _create_def_stc = function(def_val) constructor {
		x	= def_val
		y	= def_val
		w	= def_val
		h	= def_val
	}
	
	enabled	=	config[$ "enable_scissor"] ?? false
	rect	=	{
		raw:		config[$ "scissor_rect"] ?? {x: 0, y: 0, w: GUI_width(), h: GUI_height()},
		bytecode:	new _create_def_stc([]),
		inner:		new _create_def_stc(0),
		dirty:		new _create_def_stc(true),
		
		type:		-1
	}
	set_rect	= _UINode_set_scissor
	eval		= _UI_eval_scissor
	apply		= __UI_apply_scissor
	
	rect.type = UI_get_value_type(rect.raw)
}

/**
@ignore
@param	{Struct}	config	Parameters to use in inner struct creation
@desc	Creates the size struct with: x, y, width, height and context
*/
function __UI_create_inner(config) constructor {
    x = 0
    y = 0
    width	= 0
    height	= 0
	
	halign	= config[$ "inner_halign"] ?? UI_HALIGN.LEFT
	valign	= config[$ "inner_valign"] ?? UI_VALIGN.TOP
	
	context	= config[$ "context"] ?? {}
}

/**
@ignore
@param	{Struct}	config	Parameters to use in the UILayers
@desc	Creates the size struct with: layer id, layer group and z-index
*/
function __UI_create_layer(config) constructor {
	id		= config[$ "UI_layer"]		?? UILayer.NORMAL
	group	= config[$ "layer_group"]	?? "default_group"
	
	var _layer			= global.UI.layers[$ id]
	var _layer_group	= _layer[$ group]
	
	z_index	= _layer_group.z_counter
	
	_layer_group.z_counter ++
	
	_layer.dirty		= true
	_layer_group.dirty	= true
}

#endregion

#region SCROLL, LAYOUT AND EVENTS
/**
@ignore
@param	{Struct}	config	Parameters to use in the scroll system struct
@desc	Creates the size struct with: flow, value, velocity, overflow, drag, force, etc.
*/
function __UI_create_scroll(config) constructor {
	flow	= config[$ "scroll_flow"] ?? UINodeScrollFlow.NOONE
	
	value		= {x: 0, y: 0}
	velocity	= {x: 0, y: 0}
	overflow	= {x: 0, y: 0}
	
	force	= config[$ "scroll_force"]	?? 10
	drag	= config[$ "scroll_drag"]	?? 0.85
	max_x	= config[$ "scroll_max_x"]	?? -1
	max_y	= config[$ "scroll_max_y"]	?? -1
	
	must_hover	= config[$ "scroll_must_hover"] ?? true
	
	min_x	= 0
	min_y	= 0
	
	enabled = {
		x: (flow == UINodeScrollFlow.HORIZONTAL || flow == UINodeScrollFlow.BOTH),
		y: (flow == UINodeScrollFlow.VERTICAL   || flow == UINodeScrollFlow.BOTH)
	}
	
	eval	= UI_eval_scroll
	update	= _UINode_uptade_scroll
}

/**
@ignore
@param	{Struct}	config	Parameters to use in the layout
@desc	Creates the size struct with: position, justify_content, align_items, gaps and flex-direction
*/
function __UI_create_layout_base(config) constructor {
	position	= config[$ "position"]	?? UINodePosition.RELATIVE
	
	justify_content	= config[$ "justify_content"]	?? JUSTIFY_CONTENT.CENTER
	align_items		= config[$ "align_items"]		?? ALIGN_ITEMS.CENTER
	flex_direction	= config[$ "flex_direction"]	?? UINodeFlexDirection.ROW
	
	gap_x	= config[$ "gap"] ?? config[$ "gap_x"] ?? 0
	gap_y	= config[$ "gap"] ?? config[$ "gap_y"] ?? 0
}

/**
@ignore
@param	{Struct}	config	Parameters to use in the creation of events
@desc	Creates the events, like on_click, on_hover, on_unhover
*/
function __UI_create_events(config) constructor {
	on_click	= config[$ "on_click"]	?? undefined
	can_click	= config[$ "can_click"]	?? undefined
	
	on_hover	= config[$ "on_hover"]		?? undefined
	on_change	= config[$ "on_change"]		?? undefined
	on_unhover	= config[$ "on_unhover"]	?? undefined
	
	on_input	= config[$ "on_input"]	?? undefined
	on_submit	= config[$ "on_submit"]	?? undefined
	
	set	= function(event, func) {
		var events		= self.events
		static all_ev	= [
			"on_click", "on_hover", "on_unhover", "can_click", "on_change",
			"on_input", "on_submit"
		]
		
		if array_contains(all_ev, event) {
			events[$ event]	= func
			_add_dirty(self, UINodeDirtyFlag.GEN_FUNCTION)
		}
	}
}
#endregion

/**
@ignore
@param	{Struct}	Parameter to create the base of a UINode
@desc	Creates the main part for a UINode
*/
function _create_UI_element(config) constructor {
	_evaluate_UINode(config)
	
	core		= new __UI_create_core(config)
	UI_layer	= new __UI_create_layer(config)
	assets		= new __UI_create_assets(config)
	
	size		= new __UI_create_sizes(config)
	position	= new __UI_create_position(config)
	offset		= new __UI_create_offset(config)
	
	text		= new __UI_create_text_data(config)
	scissor		= new __UI_create_scissor(config)
	layout		= new __UI_create_layout_base(config)
	
	events		= new __UI_create_events(config)
	scroll		= new __UI_create_scroll(config)
	inner		= new __UI_create_inner(config)
	
	internal	= {
		allowed_children:	false,
		changed:			false,
		
		has: {
			can_click:	false,
			on_click:	false,
			
			on_hover:	false,
			on_change:	false,
			on_unhover:	false,
			
			on_input:	false,
			on_submit:	false,
		},
		
		is_safe: {},
		
		out_of_bound: {
			x:		false,
			y:		false,
			both:	false,
			any:	false
		},

		inner_render: {
			x: 0,
			y: 0,
			width:	0,
			height:	0
		}
	}
	internal.is_safe[$ UINodeDirtyFlag.SIZE]	= false
	internal.is_safe[$ UINodeDirtyFlag.LAYOUT]	= false
}
