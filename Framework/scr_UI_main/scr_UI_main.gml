var root_node	= {
	core:	{
		children:	[],
		parent:		undefined,
		dirty:		{},
		
		id:	UI_ROOT_ID
	},
	
	inner: new __UI_create_inner({}),
	
	size: {
		width:	{inner: 0},
		height:	{inner: 0},
		
		margin:		new __create_padmar_UINode("m", {}),
		padding:	new __create_padmar_UINode("p", {})
	},
	position: {
		x: {outer: 0},
		y: {outer: 0}
	},
	
	scroll: {value: {x: 0, y: 0}},
	
	layout: new __UI_create_layout_base({}),
	
	internal: {
		allowed_children:		true,
		depends_on_children:	false
	},
		
	root:		true
}

var _inputs	= {
	scroll: {
		x: 0,
		y: 0
	},
	
	pointer: {
		x: 0,
		y: 0,
	
		down:		false,
		pressed:	false,
		released:	false,
		
		delta_x: 0,
		delta_y: 0
	},
	
	keyboard: {
		char:	"",
		key:	0,
	}
}

global.UI = {
	nodes:			[],
	dirty_nodes:	[],
	screen:	root_node,
	
	id_actual: 0,
	input: _inputs,
	
	internal: {
		lookup_map:		ds_map_create(),
		prev_hover:		undefined,
		prev_focus:		undefined,
		dirty: {
			layout:	true,
			size:	true,
			text:	true,
			world:	true
		}
	},
	
	focus:	undefined,
	hover:	undefined,
	
	layers: {
		dirty: false
	}
}

global.UI.screen.core.dirty[$ UINodeDirtyFlag.LAYOUT]	= true

var _Lay_const = function () constructor {
	default_group	= {priority: 0, nodes: [], z_counter: 0, dirty: true}
	groups			= [default_group]
	dirty			= true
}

global.UI.layers[$ UILayer.BACKGROUND]	= new _Lay_const()
global.UI.layers[$ UILayer.NORMAL]		= new _Lay_const()
global.UI.layers[$ UILayer.FOREGROUND]	= new _Lay_const()
global.UI.layers[$ UILayer.OVERLAY]		= new _Lay_const()

#region UPDATORS
/**
@ignore
@desc	Updates the UIlayers and their groups
*/
function _UI_uptade_layer() {
	static order = [UILayer.BACKGROUND, UILayer.NORMAL, UILayer.FOREGROUND, UILayer.OVERLAY]
	
	for(var i = 0; i < array_length(order); i ++) {
		_eval_UI_layer_groups(order[i])
		
		var groups = global.UI.layers[$ order[i]].groups
		
		for(var j = 0; j < array_length(groups); j ++) {
			var group = groups[j]
			_eval_UI_group_elements(group)
		}
	}
}

#endregion

#region CREATES AN IMAGEGE/ICON ON THE UI (just an image)
/**
@ignore
@param	{Struct}	config	The parameters to create the icon UINode
@desc	Creates an icon UINode struct
*/
function _create_icon(config) : _create_UI_element(config) constructor {
    scale_x		= config[$ "x_scale"]  ?? 1
    scale_y		= config[$ "y_scale"]  ?? 1
	
	core.interactive	= config[$ "interactive"]	?? false

	var _w	= sprite_get_width(config[$ "sprite"]	?? -1) * scale_x
	var _h	= sprite_get_height(config[$ "sprite"]	?? -1) * scale_y
	
	size.width.raw	= _w
	size.height.raw	= _h
}
#endregion

#region CREATE A PANEL (or something like it, a sprite) ON THE UI
/**
@ignore
@param	{Struct}	config	The parameters to create the panel UINode
@desc	Creates a panel UINode struct
*/
function _create_panel(config) : _create_UI_element(config) constructor {
	internal.allowed_children = true
}
#endregion

#region CREATE A BUTTON (or something pressable) ON THE UI
/**
@ignore
@param	{Struct}	config	The parameters to create the button UINode
@desc	Creates a button UINode struct
*/
function _create_button(config) : _create_UI_element(config) constructor {}
#endregion

#region CREATE A TEXT ON THE UI
/**
@ignore
@param	{Struct}	config	The parameters to create the label UINode
@desc	Creates a label UINode struct
*/
function _create_label(config) : _create_UI_element(config) constructor {
	core.interactive	= config[$ "interactive"]	?? false
    draw_txt = 1
}
#endregion

#region CREATE A CHECKBOX ON THE UI
/**
@ignore
@param	{Struct}	config	The parameters to create the checkbox UINode
@desc	Creates a checkbox UINode struct
*/
function _create_checkbox(config) : _create_UI_element(config) constructor {
	value	= config[$ "value"]	?? false
}
#endregion

#region CREATE A RADIUS BUTTON ON THE UI
/**
@ignore
@param	{Struct}	config	The parameters to create the radio button UINode
@desc	Creates a radio button UINode struct
*/
function _create_radio_button(config) : _create_UI_element(config) constructor {
	group		= config[$ "group"]	?? "default"
	value		= config[$ "value"]	?? false

    draw_spr	= 1
}
#endregion

#region CREATE A SLIDER ON THE UI
/**
@ignore
@param	{Struct}	config	The parameters to create the slider UINode
@desc	Creates a slider UINode struct
*/
function _create_slider(config) : _create_UI_element(config) constructor {
	steps	= config[$ "steps"] ?? 5
	
	step_size	= 0
	is_holding	= false
	
	slider_values	= {
		min_value:	config[$ "min_value"]	?? 0,
		raw:		clamp(config[$ "value"] ?? 0, 0, steps),
		final:		0
	}
	slider_values.final	= slider_values.raw + slider_values.min_value
}
#endregion

#region CREATE A DROPDOWN ON THE UI
/**
@ignore
@param	{Struct}	config	The parameters to create the dropdown UINode
@desc	Creates a dropdown UINode struct
*/
function _create_dropdown(config) : _create_UI_element(config) constructor {
	options			=	 create_dropdown_options(self, config[$ "options"] ?? ["noone"])	
	selected = {
		index:		config[$ "selected"] ?? 0,
		raw:		options.raw[@ (config[$ "selected"] ?? 0)],
		display:	options.display[@ (config[$ "selected"] ?? 0)],
		parsed:		options.parsed[@ (config[$ "selected"] ?? 0)]
	}
	
	is_open	= false

	open	= {
		separators:	config[$ "separators"] ?? false,
		height:		0,
		
		style:	config[$ "open_style"]	?? dropdown_color_style(c_gray, 3),
		layout:	config[$ "open_layout"]	?? dropdown_all_layout()
	}
}
#endregion

#region CREATE A TEXTBOX ON THE UI
/**
@ignore
@param	{Struct}	config	The parameters to create the textbox UINode
@desc	Creates a textbox UINode struct
*/
function _create_textbox(config) : _create_UI_element(config) constructor {
	hide = {
		enabled:	config[$ "hide_text"] ?? false,
		dirty:		true,
		text:		""
	}
	
	focus			= false
	textbox_type	= config[$ "textbox_type"] ?? UINodeTextboxType.LINEAR
	
	if is_undefined(config[$ "draw_mode"]) {
		switch (textbox_type) {
			case UINodeTextboxType.LINEAR:
				text.layout.draw_mode	= UINodeDrawMode.CONTENT
				scroll.flow				= UINodeScrollFlow.HORIZONTAL
				scroll.enabled.x		= true
			break
			case UINodeTextboxType.VERTICAL:
				text.layout.draw_mode = UINodeDrawMode.WRAP
				scroll.flow				= UINodeScrollFlow.VERTICAL
				scroll.enabled.y		= true
			break
		}
	}
	
    draw_spr	= 1
}
#endregion

/**
@public
@pure
@self global

@param	{Real}		type	The type of UINode to create (use "UINodeType" ENUM)
@param	{Struct}	config	Parameters to use in the UINode creation
@return	{Struct | undefined}

@desc	Creates a functional UINode ( Panels, Buttons, Labels, sliders, ... ), and returns it structure back
*/
function UINode_create(type, config) {
	var node = {}
	_evaluate_UINode_element(config, type)
	
    switch (type) {
		case UINodeType.ICON:   node = new _create_icon(config)		break;
        case UINodeType.PANEL:  node = new _create_panel(config)	break;
		
        case UINodeType.BUTTON:			node = new _create_button(config)		break;
        case UINodeType.CHECKBOX:		node = new _create_checkbox(config)		break;
		case UINodeType.RADIO_BUTTON:	node = new _create_radio_button(config)	break;
		
        case UINodeType.LABEL:		node = new _create_label(config)		break;
		case UINodeType.SLIDER:		node = new _create_slider(config)		break;
		case UINodeType.DROPDOWN:	node = new _create_dropdown(config)		break;
		case UINodeType.TEXTBOX:	node = new _create_textbox(config)		break;
		
        default:
            show_debug_message($"⚠ ui_helper: undefined type -> {type}")
            return undefined;
    }
	
	node[$ "element"]	= type
	
	var parent	= get_UINode_by_id(node.core.parent)
	var node_id	= node.core.id
	static UI	= global.UI
	
	#region SET METHODS
	// SIZE
	node.size.width.set		= method(node, node.size.width.set)
	node.size.height.set	= method(node, node.size.height.set)
	
	// SIZE (margin and padding)
	node.size.margin.set	= method(node, node.size.margin.set)
	node.size.padding.set	= method(node, node.size.padding.set)
	node.size.margin.eval	= method(node, node.size.margin.eval)
	node.size.padding.eval	= method(node, node.size.padding.eval)
	
	//OFFSET
	node.offset.pivot_eval	= method(node, node.offset.pivot_eval)
	
	// POSITION
	node.position.x.set	= method(node, node.position.x.set)
	node.position.y.set	= method(node, node.position.y.set)
	
	// SCISSOR/TEXT
	node.scissor.set_rect	= method(node, node.scissor.set_rect)
	node.text.set_content	= method(node, node.text.set_content)
	node.text.set_span		= method(node, node.text.set_span)
	
	node.events.set	= method(node, node.events.set)
	#endregion
	
	#region PUSHES AND ADDS
	// Pushes to the parent list
	if parent.internal.allowed_children {
		UINode_add_children(parent, node_id)
	}
	
	// Pushes it to the UI layer
	array_push(UI.layers[$ node.UI_layer.id][$ node.UI_layer.group].nodes, node)
	
	array_push(UI.nodes, node_id)						// Pushes to the global list of UINodes
	ds_map_add(UI.internal.lookup_map, node_id, node)	// Pushes to the internal look out
	#endregion
	
	_mark_dirty(node, UINodeDirtyFlag.ALL)
	
	return node
}