#region HELPERS
/**
@ignore

@param	{Array}		names	Array with all variables name
@param	{Array}		group	The type group that all variables belong
@param	{struct}	schema	The struct do add the variables

@desc	Add in a struct variables, each one with it respective allowed type
*/
function __UI_register_props(names, group, schema) {
	// Get the amount of variables
	var length	= array_length(names)
	for(var i = 0; i < length; i ++) {
		var item		= names[@ i]	// Get one name
		schema[$ item]	= group			// Add it with it possible values

	}
}

/**
@ignore
@pure
@self __check_wrong_value

@param	{Struct}	struct	Struct to get value
@param	{String}	key		Path to the variable

@desc	Returns a variable with a shema key
*/
function __get_value_from_schema(struct, key) {
    
	// Se for string → acesso direto
	if !string_contains(".", key) {
		return struct[$ key]
	}
	
	// If has dots, break it and saves the struct into a var
	var path	= string_split(key, ".")
	var current = struct
	
	for (var i = 0; i < array_length(path); i++) {
		current = current[$ path[@ i]]
		if current == undefined {
			return undefined
		}
	}
	
	return current
}

/**
@ignore
@param	{Any}		_value	The value received by the user
@param	{String}	name	Error place specification
@param	{Array}		allowed	Array with all allowed types (ENUMs)
*/
function __evaluate_error(_value, name, allowed, _part) {
	static look_up_type	= [
		"ANY",
		"REAL",
		"STRING",
		"BOOL",
		"ARRAY",
		"STRUCT",
		"ASSET",
		"CALLABLE",
		
		"EXPRESSION",
		"PERCENTAGE",
		"AUTO",
		"NODE_REFERENCE",
		
		"UNDEFINED",
		"UNKNOWN"
	]
	
	
	var type = UI_get_value_type(_value)	// Get type
	var possible_names	= []				// Get all possible names
	
	for(var j = 0; j < array_length(allowed); j ++) {
		var el	= allowed[j]			// Get a enum (number)
		var str	= look_up_type[@ el]	// Get the respective word
		
		// Pushes into the bank
		array_push(possible_names, str)
	}
	
	var _ctx	= {
		variable:	name,
		possible:	possible_names,
		gave:		look_up_type[@ type],
		value:		_value,
		part:		_part
	}
		
	// Call error
	_show_UI_message_error(UIError.MALFORMED_UINODE, UIErrorDetail.INVALID_VALUE, _ctx)
}

/**
@ignore

@param	{Struct}	schema		Variables with their allowed types
@param	{Struct}	to_check	Variables passed by the user (that will be checked)
@param	{String}	part		Actual part of processing ( "base", "dropdown", "label", ... )

@desc	Checks if all variables passed by the user are correct. If one is wrong, shows a error message
*/
function __check_wrong_value(schema, to_check, _part) {
	var schema_names	= struct_get_names(schema)		// Get variables names
	var schema_length	= array_length(schema_names)	// Get the amount
	
	
	for (var i = 0; i < schema_length; i ++) {
		var schama_var_name	= schema_names[@ i]
		var schema_value	= schema[$ schama_var_name]
		
		var check_value		= __get_value_from_schema(to_check, schama_var_name)
		var check_type		= UI_get_value_type(check_value)
		
		// If value is undefined AKA doesn't didn't existed, continues
		if check_value == undefined {continue}
		
		// Check if actual value is in the possible value 
		if array_contains(schema_value, check_type) {continue} 
		
		// If not see if actual value is a string and it accept string
		if array_contains(schema_value, UINodeValue.STRING) { 
			// If actual value is string, continues 
			if is_string(check_value) {continue}
		}
		
		// Show the error
		__evaluate_error(check_value, schama_var_name, schema_value, _part)
		break
	}
}
#endregion

#region SPECIFIC ELEMENTS EVALUATE
/**
@ignore
@param	{Struct}	config	Variables to evaluate
@desc	Evaluates the variables of a UINode icon
*/
function _evaluate_UINode_icon(config) {
	static schema	= {}
	if empty_struct(schema) {
		__UI_register_props(["x_scale", "y_scale"], [UINodeValue.REAL], schema)
	}
	__check_wrong_value(schema, config, "icon")
}

/**
@ignore
@param	{Struct}	config	Variables to evaluate
@desc	Evaluates the variables of a UINode button
*/
function _evaluate_UINode_button(config) {
	static schema 	= {}
	
	if empty_struct(schema) {
		__UI_register_props(["on_click"], [UINodeValue.CALLABLE], schema)
	}
	//__check_wrong_value(schema, config, "button")
}

/**
@ignore
@param	{Struct}	config	Variables to evaluate
@desc	Evaluates the variables of a UINode checkbox
*/
function _evaluate_UINode_checkbox(config) {
	static schema 	= {}
	if empty_struct(schema) {
		__UI_register_props(["on_click"], [UINodeValue.CALLABLE], schema)
	}
	__check_wrong_value(schema, config, "checkbox")
}

/**
@ignore
@param	{Struct}	config	Variables to evaluate
@desc	Evaluates the variables of a UINode radio button
*/
function _evaluate_UINode_radio_button(config) {
	static schema 	= {}
	if empty_struct(schema) {
		__UI_register_props(["on_click"],	[UINodeValue.CALLABLE],	schema)
		__UI_register_props(["group"],		[UINodeValue.STRING],	schema)
		__UI_register_props(["value"],		[UINodeValue.BOOL],		schema)
	}
	__check_wrong_value(schema, config, "radio_button")
}

/**
@ignore
@param	{Struct}	config	Variables to evaluate
@desc	Evaluates the variables of a UINode slider
*/
function _evaluate_UINode_slider(config) {
	static schema 	= {}
	if empty_struct(schema) {
		__UI_register_props(["value", "steps", "min_value"], [UINodeValue.REAL], schema)
	}
	__check_wrong_value(schema, config, "slider")
}

/**
@ignore
@param	{Struct}	config	Variables to evaluate
@desc	Evaluates the variables of a UINode dropdown
*/
function _evaluate_UINode_dropdown(config) {
	static schema 	= {}
	if empty_struct(schema) {
		__UI_register_props(["textbox_type"],	[UINodeValue.REAL],	schema)
		__UI_register_props(["hide_text"],		[UINodeValue.BOOL],	schema)
	}
	__check_wrong_value(schema, config, "dropdown")
}

/**
@ignore
@param	{Struct}	config	Variables to evaluate
@desc	Evaluates the variables of a UINode textbox
*/
function _evaluate_UINode_textbox(config) {
	static schema 	= {}
	if empty_struct(schema) {
		__UI_register_props(["value", "steps", "min_value"], [UINodeValue.REAL], schema)
	}
	__check_wrong_value(schema, config, "textbox")
}
#endregion

#region MAIN
/**
@ignore

@param	{Struct}	config	Evaluates if any variable has a wrong type

@desc	Verify if a UINode is with his variables correctly declared
*/
function _evaluate_UINode(config) {
	#region TYPE LIST
	static metrics_accept	= [
		UINodeValue.REAL,
		UINodeValue.PERCENTAGE,
		UINodeValue.EXPRESSION,
		UINodeValue.AUTO
	]
	
	static	absolute_and_relative	= [
		UINodeValue.REAL,
		UINodeValue.EXPRESSION,
		UINodeValue.PERCENTAGE
	]
	
	static	identification	= [
		UINodeValue.REAL,
		UINodeValue.STRING
	]
	
	static	callable_type	= [
		UINodeValue.CALLABLE,
		UINodeValue.UNDEFINED
	]
	#endregion
	
	#region VARIABLE LIST
	static	METRIC	= [
		"width", "height",
		"p_all", "p_x", "p_y", "p_l", "p_r", "p_t", "p_b",
		"m_all", "m_x", "m_y", "m_l", "m_r", "m_t", "m_b"
	]
	
	static NUMBERS_METRIC = ["x_offset", "y_offset", "max_width", "min_width", "font_xscale", "font_yscale", "gap_x", "gap_y"];
	static NUMBERS_COLOR  = ["color", "alpha", "font_color", "font_alpha"];
	static NUMBERS_ALIGN  = ["halign", "valign", "inner_halign", "inner_valign", "justify_content"];
	static NUMBERS_MISC   = ["image", "UI_layer", "draw_mode", "letters", "scroll_force", "scroll_drag", "scroll_max_x", "scroll_max_y", "position", "gap"];
	
	static	ABS_AND_RELA	= ["x", "y"]
	
	static ASSETS	= ["object", "sprite", "font"]
	static BOOL		= ["visible", "enable_scissor"]
	static STRING	= ["layer_group", "text"]
	static STRUCT	= ["sprite_set", "context"]
	static ARRAY	= ["span"]
	static CALL		= ["on_click", "on_hover", "on_unhover", "can_click", "on_change", "on_input", "on_submit"]
	#endregion
	
	#region DEFINE VARIABLES
	static schema	= {}
	
	if empty_struct(schema) {
		__UI_register_props(["parent"],		  [UINodeValue.NODE_REFERENCE], schema)
		__UI_register_props(["scissor_rect"], [UINodeValue.STRUCT, UINodeValue.NODE_REFERENCE], schema)
		
		__UI_register_props(["name", "tag", "class"], identification, schema)
		__UI_register_props(METRIC, metrics_accept, schema)
		__UI_register_props(ABS_AND_RELA, absolute_and_relative, schema)
		
		__UI_register_props(ASSETS,  [UINodeValue.ASSET],	schema)
		__UI_register_props(STRING,  [UINodeValue.STRING],	schema)
		__UI_register_props(STRUCT,  [UINodeValue.STRUCT],	schema)
		
		
		__UI_register_props(BOOL,	[UINodeValue.BOOL],		schema)
		__UI_register_props(ARRAY,	[UINodeValue.ARRAY],	schema)
		__UI_register_props(CALL,	callable_type,			schema)
		
		__UI_register_props(NUMBERS_METRIC, [UINodeValue.REAL],	schema)
		__UI_register_props(NUMBERS_COLOR,  [UINodeValue.REAL],	schema)
		__UI_register_props(NUMBERS_ALIGN,  [UINodeValue.REAL],	schema)
		__UI_register_props(NUMBERS_MISC,   [UINodeValue.REAL],	schema)
	}
	#endregion
	
	__check_wrong_value(schema, config, "creation")
}

/**
@ignore

@param	{Struct}	config	Values passed by user (to be checked)
@param	{Real}		type	The UINode type of element (UINodetype ENUM)

@desc Evaluates if ther's any error in a special UINode type variable. If has, shows an error message
*/
function _evaluate_UINode_element(config, type) {
	switch(type) {
		case UINodeType.ICON:
			_evaluate_UINode_icon(config)
		break;
		case UINodeType.BUTTON:
			_evaluate_UINode_button(config)
		break;
		case UINodeType.CHECKBOX:
			_evaluate_UINode_checkbox(config)
		break;
		case UINodeType.RADIO_BUTTON:
			_evaluate_UINode_radio_button(config)
		break;
		
		case UINodeType.SLIDER:
			_evaluate_UINode_slider(config)
		break;
		case UINodeType.DROPDOWN:
			_evaluate_UINode_dropdown(config)
		break;
		case UINodeType.TEXTBOX:
			_evaluate_UINode_textbox(config)
		break;
	}
}
#endregion

/**
@ignore
@param	{Struct}	config	Variables to evaluate
@desc	Evaluates the update size part of a UINode
*/
function _evaluate_UINode_size(node) {
	static initialise_flag	= true
	static schema			= {}
	
	static type_metric	= [
		UINodeValue.REAL,
		UINodeValue.PERCENTAGE,
		UINodeValue.EXPRESSION,
		UINodeValue.AUTO
	]
	static pad_and_margin_type	= [
		UINodeValue.REAL,
		UINodeValue.PERCENTAGE,
		UINodeValue.EXPRESSION
	]
	
	static	METRICS		= ["width", "height"]
	static	PADDING		= ["left", "right", "top", "bottom"]
	static	MARGIN		= ["left", "right", "top", "bottom"]
	
	if initialise_flag {
		initialise_flag	= false
		
		for (var i = 0; i < array_length(METRICS); i++) {
		    METRICS[@ i] = $"size.{METRICS[i]}.raw"
		}
		for (var i = 0; i < array_length(PADDING); i++) {
		    PADDING[@ i]	= $"size.pading.inner.{PADDING[i]}"
		    MARGIN[@ i]		= $"size.pading.inner.{MARGIN[i]}"
		}
		__UI_register_props(METRICS, type_metric, schema)
		__UI_register_props(PADDING, pad_and_margin_type, schema)
		__UI_register_props(MARGIN, pad_and_margin_type, schema)
		
	}
	
	__check_wrong_value(schema, node, "size update")
}

/**
@ignore
@param	{Struct}	config	Variables to evaluate
@desc	Evaluates the update layout part of a UINode
*/
function _evaluate_UINode_layout(node) {
	static initialise_flag	= true
	static schema			= {}
	
	static type_position = [
		UINodeValue.REAL,
		UINodeValue.PERCENTAGE,
		UINodeValue.EXPRESSION
	]
	
	static	POSITION	= ["x", "y"]
	
	if initialise_flag {
		initialise_flag	= false
		
		for (var i = 0; i < array_length(POSITION); i++) {
		    POSITION[@ i] = $"position.{POSITION[i]}.raw"
		}
		__UI_register_props(POSITION, type_position, schema)
	}
	
	__check_wrong_value(schema, node, "layout update")
}

/**
@ignore
@param	{Struct}	config	Variables to evaluate
@desc	Evaluates the update layout part of a UINode
*/
function _evaluate_UINode_text(node) {
	static initialise_flag	= true
	static schema			= {}
	
	if initialise_flag {
		initialise_flag	= false
		__UI_register_props(["text.content"], [UINodeValue.STRING, UINodeValue.REAL], schema)
		__UI_register_props(["text.span"],	  [UINodeValue.ARRAY], schema)
	}
	
	__check_wrong_value(schema, node, "text update")
}

/**
@ignore
@param	{Struct}	config	Variables to evaluate
@desc	Evaluates the update generic function part of a UINode
*/
function _evaluate_UINode_gen_func(node) {
	static initialise_flag	= true
	static schema			= {}
	
	static func_values	= [UINodeValue.CALLABLE, UINodeValue.UNDEFINED]
	static ON_FUNC		= ["on_click", "on_hover", "on_unhover", "can_click", "on_change", "can_input", "on_submit"]
	
	if initialise_flag {
		initialise_flag	= false
		// EXTEND VALUE
		for(var i = 0; i < array_length(ON_FUNC); i ++) {
			ON_FUNC[@ i]	= $"events.{ON_FUNC[i]}"
		}
		
		// SAVE PROPIETRY
		__UI_register_props(ON_FUNC, func_values, schema)
	}
	
	__check_wrong_value(schema, node, "generic function update")
}

/**
@ignore
@param	{Struct}	config	Variables to evaluate
@desc	Evaluates the world update part of a UINode
*/
function _evaluate_UINode_world(node) {
	static initialise_flag	= true
	static schema			= {}
	
	static func_values	= [UINodeValue.CALLABLE, UINodeValue.UNDEFINED]
	static ON_FUNC		= [""]
	
	if initialise_flag {
		// SAVE PROPIETRY
		__UI_register_props(["scissor.rect.raw"], [UINodeValue.STRUCT, UINodeValue.NODE_REFERENCE], schema)
	}
	
	__check_wrong_value(schema, node, "world update")
}