#region RPN PUSHES FUNCTIONS
function RPN_pushNumber(_value) {
	return {
		value: _value,				// Number value
		exec: function(stack, _ctx) {
			// Pushes into the stack
			ds_stack_push(stack, value)
		}
	}
}

function RPN_pushVar(_path) {
    var _len = array_length(_path)
    var _is_global = (_path[0] == "global")

    return {
		path: _path,			// Path to the value
		len: _len,				// length of the part
		is_global: _is_global,	// if its global

		exec: function(stack, _ctx) {
			var _val = is_global ? global : _ctx	// Sees if it's global or not
			
			// Runs for all path
			for (var i = is_global ? 1 : 0; i < len; i++) {
				_val = _val[$ path[i]]
			}

			// Pushes into the stack
			ds_stack_push(stack, _val)
			
		}
	}
}

function RPN_opBinary(_op, _str) {
	return {
		op:		_op,
		__str:	_str,
		
		exec: function(stack, _ctx) {
			var _num2 = ds_stack_pop(stack)	// Number after operator
			var _num1 = ds_stack_pop(stack)	// Number before operator
			
			// If it is a division by zero, shows error
			if _num2 == 0 && op == "/" {
				
				_show_UI_message_error(UIError.MALFORMED_EXPRESSION, UIErrorDetail.DIVISION_BY_ZERO,
				{str: __str})
			}
			
			// Operate
			var _val = operate_bi(_num1, _num2, op)
			ds_stack_push(stack, _val) // Pushes the value into the stack
		}
	}
}
function RPN_opUnitary(_op) {
	return {
		op: _op,
		exec: function(stack, _ctx) {
			var _num1 = ds_stack_pop(stack) // Value to operate
			
			// Gets the value and push in the stack
			var _val = operate_uni(_num1, op)
			ds_stack_push(stack, _val)
		}
	}
}

#endregion

#region EVALS AND TYPES
function equation_get_token_type(_str) {
	var _c = string_char_at(_str, 1)

    // Numbers (0–9)
    if ((_c >= "0" && _c <= "9") || _c == ",") {
        return TokenType.NUMBER
    }
	
    // Operators
    if (string_pos(_c, "+-*/^") > 0) {
        return TokenType.OPERATOR
    }
	
	// Dots
	if (_c == ".") {
		return TokenType.DOT
	}
	
	if (_c == " ") {
		return TokenType.IGNORE
	}
	
	if (_c == "%") {
		return TokenType.PERCENTAGE
	}
	
    // Parentheses
    if (_c == "(") return TokenType.PARENTHESES_OPEN
    if (_c == ")") return TokenType.PARENTHESES_CLOSE
	
    // Letter (Variable): A–Z, a–z  and "_"
    var code = ord(_c)
    if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122) || _c == "_") {
        return TokenType.VARIABLE
    }

    // Unknow simble
    return TokenType.UNKNOWN
}

function string_equation_eval(_expected, _val_type, _unitary, _final, _equation) {
	if _val_type == TokenType.UNKNOWN return true
	
	if (_unitary) {
		if (_final) return false
		return (_expected == "value")
	}
	
	if (_final) {
		// If the final is avalue OR a close parentheses
		var parenteses_case = (_expected == "value"		|| _val_type == TokenType.PARENTHESES_CLOSE)
		var percentage_case = (_expected == "operator"	&& _val_type == TokenType.PERCENTAGE)

		
		return  parenteses_case || percentage_case
	}
	
	static expect_value	= [
		TokenType.NUMBER,
		TokenType.PARENTHESES_OPEN,
		TokenType.VARIABLE
	]
	
	static expect_opera	= [
		TokenType.PARENTHESES_CLOSE,
		TokenType.OPERATOR,
		TokenType.PERCENTAGE
	]
	
	var expect_now = []
	switch(_expected) {
		case "value":
			expect_now = expect_value
		break;
		
		case "operator":
			expect_now = expect_opera
		break;
	}

	for (var i = 0; i < array_length(expect_now); i ++) {
		var _exp = expect_now[i]
		
		if _val_type == _exp return true
	}
	return false
}
#endregion

#region STRING, ARRAY AND PARSING
function string_equation_to_array(_str) {
	var _array		= []						// The array with the tokens separated
	var _equation	= string_trim(_str)			// Removes the blanks edges
	var _str_length	= string_length(_equation)	// Equation's length
	var _char_index	= 1							// Actual index to take/use
	
	// Go arround all the string
	while(_char_index <= _str_length) {
		var _c		= string_char_at(_equation, _char_index)	// Get the character
		var _c_type	= equation_get_token_type(_c)				// Get the type of the character
		
		
		switch(_c_type) {
			
			#region NUMBER (and dots)
			case TokenType.DOT:
			case TokenType.NUMBER:
			var _whole_number = ""
				#region GETS THE WHOLE NUMBER
				while ((_c_type == TokenType.NUMBER) || (_c_type == TokenType.DOT)) {
					_whole_number	+= _c
					_char_index		++
					
					_c		= string_char_at(_equation, _char_index)	// Get the new character
					_c_type	= equation_get_token_type(_c)				// Get the new type
				}
				#endregion
				
				array_push(_array, _whole_number)
			break;
			#endregion
			
			#region OPERATOR, PERCENTAGE and PARENTHESES CLOSE/OPEN
			case TokenType.PARENTHESES_CLOSE:
			case TokenType.PARENTHESES_OPEN:
			case TokenType.PERCENTAGE:
			case TokenType.OPERATOR:
			
				array_push(_array, _c)	// Add the char to the array
				_char_index ++			// Increase the index
			break;
			#endregion
			
			#region VARIABLE
			case TokenType.VARIABLE:
				var _whole_var = ""
				#region GETS THE WHOLE VARIABLE
				while ((_c_type == TokenType.VARIABLE) || (_c_type == TokenType.DOT)) {
					_whole_var	+= _c
					_char_index	++
					
					_c		= string_char_at(_equation, _char_index)	// Get the new character
					_c_type	= equation_get_token_type(_c)				// Get the new type
				}
				#endregion
				array_push(_array, _whole_var)
				
			break;
			#endregion
			
			#region IGNORE
			case TokenType.IGNORE:
				_char_index ++ // Just ignores
			break;
			#endregion
			
			#region UNKOWN
			case TokenType.UNKNOWN:
			
				#region GETS THE WHOLE UNKNOWN
				var _whole_unk = ""
				while (_c_type == TokenType.UNKNOWN) {
					_whole_unk	+= _c
					_char_index	++
					
					_c		= string_char_at(_equation, _char_index)	// Get the new character
					_c_type	= equation_get_token_type(_c)				// Get the new type
				}
				#endregion
				
				array_push(_array, _whole_unk)
			break;
			#endregion
		}
	}
	
	return _array
}

function array_equation_parser(_array, _string) {
	var _parse		= []	// Return parsed
	
					
	var _l_val	= "+"			// Last character
	var _l_type	= "operator"	// Last type
	
	var _arr_length	= array_length(_array)	// Array length
	var _expect		= "value"				// The next expected value
	
	#region SEES IF THERES AN ERROR
	var _complement = {str: _string}
	
	#region PARENTHESES
	var _many_open_p  = array_count("(", _array)
	var _many_close_p = string_count(")", _array)
		
	if _many_open_p < _many_close_p {
		_show_UI_message_error(UIError.MALFORMED_EXPRESSION, UIErrorDetail.MISS_OPEN_PARENTHESES,
		_complement)
	}
	if _many_open_p > _many_close_p {
		_show_UI_message_error(UIError.MALFORMED_EXPRESSION, UIErrorDetail.MISS_CLOSE_PARENTHESES,
		_complement)
	}
	#endregion
	#endregion
	
	// If is an empty array, returns 0
	if _arr_length == 0 return [{token: TokenType.NUMBER, number: 0}]
	
	// Runs all the array
	for (var i = 0; i < _arr_length; i ++) {
		
		var _val	= _array[i]							// string value
		var _type	= equation_get_token_type(_val)		// Type of the value
		
		// Sees if is a unitary
		var _is_unitary = ((i == 0 || _l_val == "(") || _l_type == TokenType.OPERATOR)
		&& string_pos(_val, "+-") > 0
	
		// Sees if is the final part
		var _final	= (i+1 == _arr_length)
		
		// If it is malformed, shows an error message
		if !string_equation_eval(_expect, _type, _is_unitary, _final, _string) {
			_show_UI_message_error(UIError.MALFORMED_EXPRESSION, UIErrorDetail.MALFORMED, _complement)
		}
		
		switch(_type) {
			
			#region NUMBERS (and dots)
			case TokenType.DOT:
			case TokenType.NUMBER:
				var _num = string_digits_dec(_val) // transforms string to real
				
				// Adds the struct
				array_push(_parse, {token: TokenType.NUMBER, number: _num})
				_expect = "operator"
			break;
			#endregion
			
			#region OPERATOR
			case TokenType.OPERATOR:
				var true_val = _val	// Save the value
				
				// If it's unitary
				if _is_unitary {
					// Ges the truly value
					true_val = true_val == "+" ? "POS" : "NEG"
				}
				
				array_push(_parse, {token: TokenType.OPERATOR, op: true_val})	// Adds the struct
				_expect = "value"
			break;
			#endregion
			
			#region PERCENTAGE
			case TokenType.PERCENTAGE:
				array_push(_parse, {token: TokenType.PERCENTAGE})
				_expect = "operator"
			break;
			#endregion
			
			#region VARIABLE
			case TokenType.VARIABLE:
				var _path = string_split(_val, ".") // Gets the path
				
				// Adds the struct
				array_push(_parse, {token: TokenType.VARIABLE, path: _path})
				_expect = "operator"
			break;
			#endregion
			
			#region PARENTHESES
			case TokenType.PARENTHESES_OPEN:
				// Adds the struct
				array_push(_parse, {token: TokenType.PARENTHESES_OPEN, type: "open"})
				_expect = "value"
			break;
			
			case TokenType.PARENTHESES_CLOSE:
				// Adds the struct
				array_push(_parse, {token: TokenType.PARENTHESES_CLOSE, type: "close"})
				_expect = "operator"
			break;
			#endregion
			
			#region UNKNOWN
			case TokenType.UNKNOWN:
				// Show a error message
				_show_UI_message_error(UIError.MALFORMED_EXPRESSION, UIErrorDetail.INVALID_TOKEN,
				_complement)
			break;
			#endregion
		}
		
		// Update the last values
		_l_val	= _val
		_l_type	= _type
	}

	return _parse
}
#endregion

#region PARSED AND RPN
function parsed_equation_to_rpn(_array, _str) {
	var _output	= [] // the rpn order
	var _stack	= [] // symbol storage
	
	#region Anominus functions
	// Sees if the value is unitary
	static is_unitary = function(_val) {
		return (_val == "POS" || _val == "NEG")
	}
	
	// Compare about the top stack to the actual simble
	static top_bigger = function (_stack_top, _act_sim) {
		static _order = { // The order of precedence
			"NEG": 4, "POS": 4,
			"^": 3,
			"*": 2, "/": 2,
			"-": 1, "+": 1
		}
		
		static _right_order = ["^", "NEG", "POS"] // Right precedence
		
		// Gets que value (plus the right precedence)
		var _top_val	= _order[$ _stack_top]
		var _act_val	= _order[$ _act_sim]
		
		if array_contains(_right_order, _stack_top) {
			_top_val ++
		}
		
		// If actual simple is greater
		return (_top_val >= _act_val)
	}
	#endregion
	
	var _arr_l	= array_length(_array)
	
	for (var i = 0; i < _arr_l; i ++) {
		var _act_stc	= _array[i]
		var type		= _act_stc.token
		
		switch(type) {
			#region NUMBER and VARIABLE
			case TokenType.NUMBER:
				// Pushes the number to the output
				array_push(_output, RPN_pushNumber(_act_stc.number))
			break;
			case TokenType.VARIABLE:
				// Pushes the variable to the output
				array_push(_output, RPN_pushVar(_act_stc.path))
			break;
			#endregion
			
			#region OPERATORS
			case TokenType.OPERATOR:
				var _op		= _act_stc.op	// Gets the operator
				
				// While top be lower and array length be bigger than one
				while ((array_length(_stack) > 0) && (top_bigger(array_last(_stack), _op))) {
					var _top		= array_pop(_stack)					// Operator
					var enum_value	= string_operator_get_enum(_top)	// Operator's enum
					
					// Sees if is unitary
					if is_unitary(_top) {
						array_push(_output, RPN_opUnitary(enum_value))		// If its, pushes the UniFunc
					} else {
						array_push(_output, RPN_opBinary(enum_value, _str))	// If it isn't, pushes the BiFunc
					}
				}
				
				// Pushes the actual value to the stack
				array_push(_stack, _op)
			break;
			#endregion
			
			#region PARENTHESES
			case TokenType.PARENTHESES_OPEN:
				array_push(_stack, "(")
			break;
			
			case TokenType.PARENTHESES_CLOSE:
				// Top value on stack
				var _pop = array_pop(_stack)
				
				
				while(_pop != "(") {
					var enum_value	= string_operator_get_enum(_pop)	// Operator's enum
					
					// Sees if is unitary
					if is_unitary(_pop) {
						array_push(_output, RPN_opUnitary(enum_value))		// If its, pushes the UniFunc
					} else {
						array_push(_output, RPN_opBinary(enum_value, _str))	// If it isn't, pushes the BiFunc
					}
					_pop = array_pop(_stack)
				}
			break;
			#endregion
			
			#region PERCENTAGE
			case TokenType.PERCENTAGE:
				array_push(_output, RPN_opUnitary(UIOperator.PERCENTAGE))
			break;
			#endregion
		}
	}
	
	// Puts all on the output
	while(array_length(_stack) > 0) {
		var _pop		= array_pop(_stack)
		var enum_value	= string_operator_get_enum(_pop)	// Operator's enum
		
		// Sees if is unitary
		if is_unitary(_pop) {
			array_push(_output, RPN_opUnitary(enum_value))		// If its, pushes the UniFunc
		} else {
			array_push(_output, RPN_opBinary(enum_value, _str))	// If it isn't, pushes the BiFunc
		}
	}
	return _output
}

function rpn_reader(_rpn_array, _ctx = {}) {
	// Create the ds stack
	var stack	= ds_stack_create()			// ds_stack were the values will be
	var length	= array_length(_rpn_array)	// RPN length
	
	// Runs for the rpn
	for (var i = 0; i < length; i ++) { // Runs for all rpn numbers/simbles
		_rpn_array[@ i].exec(stack, _ctx)
	}
	
	var final_value	= ds_stack_top(stack)	// Get the final value
	ds_stack_destroy(stack)					// Destroy the stack
	
	// Return final value
	return final_value
}
#endregion

function string_to_rpn(_str) {
	var _equal	= string(_str)	// Makes sure it is a string
	
	var _array	= string_equation_to_array(_equal)		// Turns into array
	var _parse	= array_equation_parser(_array, _equal)	// Turns into parse
	
	return parsed_equation_to_rpn(_parse, _equal)	// Returns the RPN
}

function string_equation_reader(_str, _reference = {}) {
	var _rpn	= string_to_rpn(_str)			// Gets the RPN
	var _result	= rpn_reader(_rpn, _reference)	// Gets the result
	
	// Returns it
	return _result
}
