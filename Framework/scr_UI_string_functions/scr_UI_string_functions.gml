#region PURE FUNCTIONS
/**
@ignore
@pure

@param	{String}	char	Character to see the type
@return	{Real}		TextToken (ENUM)
*/
/*
@see _wrap_make_array

@example
	__char_get_wrap_token(" ")	// RETURN: TextToken.SPACE
	__char_get_wrap_token("A")	// RETURN: TextToken.WORD
	__char_get_wrap_token("\n")	// RETURN: TextToken.BREAK
*/
function __char_get_wrap_token(char) {
	var key = ord(char)
	
	// If is spacebar
	if key == 32 {
		return TextToken.SPACE
	}
	
	// Breakline
	if key == 10 {
		return TextToken.BREAK
	}
	
	// WORD
	return TextToken.WORD
}


	
/**
@ignore
@pure

@param	{String}	text	String to be parsed to a wrap
@return	{Array<Structs>}	Parsed array

@desc	Make a parsed array of a string to the wrap system
*/
function _wrap_make_array(text) {
	var rich	= []
	
	var char	= ""
	var length	= string_length(text)
	var index	= 1
	
	while (index <= length) {
		char = string_char_at(text, index)
		
		var _token	= __char_get_wrap_token(char)
		
		switch(_token) {
			case TextToken.SPACE:
				var space_amount	= 0
				// While index token be SPACE
				while(ord(string_char_at(text, index)) == 32) {
					space_amount	++	// Increase space amount
					index			++	// Increase char index
				}
				
				// Says how many space that segment has
				array_push(rich, {token: _token, amount: space_amount})
			continue
			//break
			
			case TextToken.WORD:
				var _word	=  string__get_entire_word(text, index)
				index		+= string_length(_word)
				
				// Says that has a word
				array_push(rich, {token: _token, word: _word})
			break
			
			case TextToken.BREAK:
				index ++
				// Says that needs to break
				array_push(rich, {token: _token})
			break
			default:
				index ++
			break
		}
		
	}
	return rich
}
#endregion

#region HELPERS
/**
@public

@param	{String}	word		String to find the break index
@param	{Real}		max_width	The max width that a line can have
@return	{Real}		Break index

@desc	Find how many letters fits in an certain width
*/
function binary_word_seach(word, max_width) {
	var left	= 1
	var right	= string_length(word)
	
	var best	= 0
	
	while(left <= right) {
		var mid		= (left + right) div 2
		var segment	= string_copy(word, 1, mid)
		
		// If word fits
		if string_width(segment) <= max_width {
			left	= mid + 1
			best	= mid
		} else {
			// If don't
			right	= mid - 1
		}
	}
	// Return the break index
	return	best
}

/**
@ignore

@param	{String}	word			String to break
@param	{Real}		max_width		Maximum width that a line can have
@param	{Real}		first_offset	First line offset (if already had content on the previous one)
@return	{Struct}	Struct with {Word (broken word) and last_width (last line width)}

@desc	Break a giant word into lines
*/
/*
@see _read_wrap_array
*/
function __break_big_word(word, max_width, first_offset) {
	var broke_word		= ""
	var final_line_w	= 0
	
	while(string_length(word) > 0) {
		var available_width	= (max_width - first_offset)				// Available width
		var break_index		= binary_word_seach(word, available_width)	// Get part that fits
		first_offset		= 0
		
		// If break index is 0 or less, turn into one
		if break_index <= 0 {
			break_index	= 1
		}
		
		var segment	= string_copy(word, 1, break_index)		// Get segment
		word		= string_delete(word, 1, break_index)	// Delete previous text from the word
		
		broke_word	+= segment	// Add it to final text
		
		// If still has text, add a break
		if string_length(word) > 0 {
			// Add break
			broke_word	+= "\n"
		} else {
			// If is final line, set the width of its
			final_line_w = string_width(segment)
		}
		
	}
	
	return {text: broke_word, last_width: final_line_w}
}

/**
@ignore

@param	{Array}		array		Parsed array (see "_read_wrap_array" function)
@param	{Real}		max_width	Maximum width that a line can have
@return	{String}	Wraped string
*/
/*
@see string_wrap
*/
function _read_wrap_array(array, max_width) {
	var final_text	= ""					// Final text (return)
	var length		= array_length(array)	// parsed array length
	var space_w		= string_width(" ")		// Space width
	var line_width	= 0						// Actual line width
	var last_token	= TextToken.WORD		// Last token
	
	for(var i = 0; i < length; i ++) {
		var segment	= array[@ i]	// Parsed segment
		var token	= segment.token	// Segment's token
		
		switch(token) {
			#region SPACES
			case TextToken.SPACE:
				// If last token was BREAK break out of switch
				if last_token == TextToken.BREAK {break}
				var space_amount	= segment.amount			// Space amount
				
				var empty_space	= max_width - line_width		// Free space in the line
				var space_fits	= floor(empty_space / space_w)	// amount of space that fits in
				
				// Clamps it on the space amount
				space_fits	= min(space_fits, space_amount)
				
				// If line_width puls spaces width pass limit, sets to limit
				line_width	+= space_fits * space_w
				
				// If any space can fit, add it
				if space_fits > 0 {
					final_text	+= string_repeat(" ", space_fits)
				}
			break
			#endregion
			
			#region WORDS
			case TextToken.WORD:
				var word	= segment.word
				var word_w	= string_width(word)
				
				// If line width plus word width is greater then max width
				if line_width + word_w > max_width {
					
					// If word itself is bigger then max width
					if word_w > max_width {
						
						// Break word in lines with breaks
						var broke_data	= __break_big_word(word, max_width, line_width)
						
						final_text	+= broke_data.text			// Add line with breaks
						line_width	=  broke_data.last_width	// Last line width
					} else {
						
						// If word is lower then max width
						final_text += $"\n{word}"			// Break the line and then add the word	
						line_width	= string_width(word)	// Sets the line width into word width
					}
				} else {
					// If fits, just add
					final_text	+=	word	// Add the word
					line_width	+=	word_w	// Add the word width
				}
			break
			#endregion
			
			#region BREAK
			case TextToken.BREAK:
				final_text	+=	"\n"
				line_width	=	0
			break
			#endregion
		}
		
		// Update last token
		last_token	= token
	}
	
	return final_text
}

#endregion

#region PUBLIC FUNCTIONS
/**
@public

@param	{String}		text		The text to be breaked
@param	{Real}			max_width	The maximum width that a line can have
@param	{Asset.GMFont}	font		Font that the text will be used
@return {String}		The text with the linebreaks (\n)

@desc	Transforms a text in a new one that fits in a certain width
*/
function string_wrap(text, max_width, font) {
	if (asset_get_type(font) != asset_font) {
		return ""
	}
	if max_width == -1 {
		return text
	}
	var prev_font	= draw_get_font()
	draw_set_font(font)
	
	var rich_text	= _wrap_make_array(text)
	var wraped_text	= _read_wrap_array(rich_text, max_width)
	
	draw_set_font(prev_font)
	// Return wraped text
	return wraped_text
}

/**
@public
@pure

@param	{String}	substr	The word to look for
@param	{String}	str		The main string to look
@return	{Bool}		Returns true if contains, false if not

@desc	Check if a string contains a certain word
*/
function string_contains(substr, str) {
    return (string_pos(substr, str) > 0)
}

/**
@public
@pure

@param	{String}	str	String to be reversed
@return	{String}	String reversed

@desc	Return the reverse string
*/
function string_reverse(str) {
	var length	= string_length(str)
	var reverse	= ""
	
	for(var i = length; i >= 1; i --) {
		reverse += string_char_at(str, i)
	}
	return reverse
}

/**
@public
@pure

@param	{String}	str			String to get word from
@param	{Real}		index		Start index
@param	{Real}		direction	direction to go ( -1 == left | 1 == right )
@return	{String}

@desc	Gets a word in a string based in the index and direction
*/
function string_get_word_direction(str, index, direction) {
	var word	= ""
	
	var _start	= 0	// start index of the final word
	var	_end	= 0	// end index of the final word
	
	var dir		= sign(direction)		// Turns into -1 or 1
	var	length	= string_length(str)	// Gets the length of the text
	
	#region Look for something offset
	// If index is outrange (returns empty string) or ir is zero
	if (index < 1) || (index > length) || (dir == 0) {
		return ""
	}
	#endregion
	
	#region GET THE INDEXS
	#region Go the the word if starts in space
	while(string_char_at(str, index) == " ") {
		// Chance th index
		index += dir
		
		// if ended the text, return ""
		if (index < 1) || (index > length) {
			return ""
		}
	}
	#endregion
	
	// _start equals first letter index
	_start	= index
	
	#region Gets the index value
	
	// While next character don't be a space and pass the limits doesn't stop
	while((index > 1) && (index < length) && (string_char_at(str, index+dir) != " ")) {
		index += dir	// Increases the char
	}
	#endregion
	
	// _end equals final index
	_end = index
	#endregion
	
	#region GET THE WORD
	var real_start	= min(_start, _end)	// True start
	var real_end	= max(_start, _end)	// True end
		
	// Needs one more because _end won one more value in while loop
	word = string_copy(str, real_start, (real_end - real_start)+1)

	#endregion
	
	// Returns the word
	return word
}
/**
@public
@pure

@param	{String}	str			String to get word from
@param	{Real}		index		Start index
@return	{String}

@desc	Returns the word in the index
*/
/*
@see string_wrap
*/
function string__get_entire_word(str, index) {
	var word	= ""
	
	var _start	= 0						// start index of the final word
	var	_end	= 0						// end index of the final word
	var	length	= string_length(str)	// Gets the length of the text
	
	#region Look for something offset	
	// If index is outrange (returns empty string)
	if (index < 1) || (index > length) {
		return ""
	}
	#endregion
	
	#region LOOK FOR A WORD
	// If index was a space
	if string_char_at(str, index) == " " {
		var prev_ind	= index	// Save index start value
		var found_word	= true	// says when a word was find
		
		// Try to find a word
		while (string_char_at(str, index) == " ") {
			index ++ // Increases the index
			
			// If exceded the string length, break it
			if index > length {
				found_word = false
				index --
				break
			}
		}
		// If still didn't found the word
		if !found_word {
			index = prev_ind // Reset the index value
			
			// Try to find a word again
			while (string_char_at(str, index) == " ") {
				index -- // Decreases the index
			
				// Still didn't find it, returns 0
				if index < 1 {
					return ""
				}
			}
		}

	}
	#endregion
	
	#region GET THE INDEXS
	// Set index positions value
	_start	= index
	_end	= index
	
	// While is above 1 and next char ins't space
	while(_start > 1 && ord(string_char_at(str, _start - 1)) > 32)
	{
		_start --	// Decrease value
	}
	
	// While is below string length and next char ins't space
	while(_end < length && ord(string_char_at(str, _end + 1)) > 32)
	{
	    _end ++		// Increase value
	}
	#endregion
	
	// Get the word
	word = string_copy(str, _start, (_end - _start)+1) // Plus one to be inclusive
	
	// Returns the word
	return word
}
#endregion

#region MATH FUNCTIONS
/**
@public
@pure

@param	{String}	operator	The operator to get the ENUM
@return	{Real}		UIOperator value
@desc	Get the ENUM (UIOperator) of the given operator. If not identified, return UIOperator.UNKNOWN
*/
/*
@example
	var mul		= string_operator_get_enum("*")		// RETURN UIOperator.MUL
	var uni_neg	= string_operator_get_enum("NEG")	// RETURN UIOperator.UNITARY_NEG
	var unknown	= string_operator_get_enum("&aB")	// RETURN UIOperator.UNKNOWN
*/
function string_operator_get_enum(operator) {
	static enum_op_list = {
		">":	UIOperator.GT,
		"<":	UIOperator.LT,
		"==":	UIOperator.EQ,
		"!=":	UIOperator.NEQ,
		">=":	UIOperator.GTE,
		"<=":	UIOperator.LTE,
		
		// Math operators
		"+":	UIOperator.ADD,
		"-":	UIOperator.SUB,
		"/":	UIOperator.DIV,
		"*":	UIOperator.MUL,
		"^":	UIOperator.POW,
		
		// Unitary
		"NEG":	UIOperator.UNITARY_NEG,
		"POS":	UIOperator.UNITARY_POS,
		"%":	UIOperator.PERCENTAGE
	}
	
	// Return enum (If its undefined, return UNKNOWN)
	return (enum_op_list[$ operator] ?? UIOperator.UNKNOWN)
}

/**
@public
@pure

@param	{Real}	val1		The first number to use
@param	{Real}	val2		The second number to use
@param	{Real}	operator	the ENUM (UIOperator) of the operator. Use "string_operator_get_enum" to get it
@return	{Real}	Value of the equation
@desc	Do an operation between two values based on a operator. If operator not identified, return undefined
*/
/*
@see string_operator_get_enum
*/
function operate_bi(val1, val2, operator) {
    switch (operator) {
		// Comparison
        case UIOperator.GT:		return val1 >  val2
        case UIOperator.LT:		return val1 <  val2
        case UIOperator.EQ:		return val1 == val2
        case UIOperator.NEQ:	return val1 != val2
        case UIOperator.GTE:	return val1 >= val2
        case UIOperator.LTE:	return val1 <= val2
		
		// Math operators
		case UIOperator.ADD:	return val1 +  val2
		case UIOperator.SUB:	return val1 -  val2
		case UIOperator.DIV:	return val1 /  val2
		case UIOperator.MUL:	return val1 *  val2
		case UIOperator.POW:	return power(val1, val2)
        default:				return undefined;
    }
}

/**
@public
@pure

@param	{Real}	val1		The number to apply unitary
@param	{Real}	operator	the ENUM (UIOperator) of the operator. Use "string_operator_get_enum" to get it

@return	{Real}	Value of the equation
@desc	Apply a unitary in a value. If unitary not identified, return undefined
*/
/*
@see string_operator_get_enum
*/
function operate_uni(val1, operator) {
	    switch (operator) {
		// Comparison
        case UIOperator.UNITARY_NEG:	return -val1
        case UIOperator.UNITARY_POS:	return val1
        case UIOperator.PERCENTAGE:		return val1 * 0.01
        default:						return undefined;
    }
}
#endregion

#region STRING TRANSFORM
/**
@deprecated
@public
@self global

@param	{String}			color_name	Name of the color
@return	{Constant.Color}	Color

@desc	Return named color
*/
function string_to_color(color_name) {
    switch (color_name) {
        case "c_white": return c_white
        case "c_black": return c_black
        case "c_red": return c_red
        case "c_green": return c_green
        case "c_blue": return c_blue
        case "c_yellow": return c_yellow
        case "c_purple": return c_purple
        case "c_aqua": return c_aqua
        default: return make_color_rgb(255, 255, 255)
    }
}

/**
@public
@pure

@param	{String}	str	String to transform in real (even decimal)
@return	{Real}		Real value

@desc	Returns the Real value of a string
*/
function string_digits_dec(str) {
    var _s = ""
    var _dot_used = false // Just allow one dot
    var _new_str  = string_trim(str)
	
    for (var i = 1; i <= string_length(_new_str); i++) {
        var ch = string_char_at(_new_str, i)

        if (ch >= "0" && ch <= "9") {
            _s += ch
        }
        else if (ch == "." && !_dot_used) {
            _s += ch
            _dot_used = true
        }
    }
	var _ret = real(_s)
	
    if string_char_at(_new_str, 1) == "-" {
		_ret *= -1
	}	
	
    return _ret
}

function string_to_bool(_string) {
	var _str = string_upper(_string)
	
	if _str == "TRUE" return true
	return false
}
#endregion
