#region BASIC STUFFS
#region ARRAY
/**
@public
@pure
@self

@param	{Array}	array	Array to use
@return {Bool}	True if the array is empty, and false if it has something

@desc	Sees if the array is empty or not. Returns true if the array is empty, and false if not.
*/
/*
@example
	var a = [1, 2, 3]
	var b = []
	
	var isEmptyA = empty_array(a)	// return FALSE
	var isEmptyB = empty_array(b)	// return TRUE
*/

function empty_array(array) {
	return (array_length(array) == 0)
}

/**
@public
@pure
@self global

@param	{Any}	value	The value to compare
@param	{Array}	array	The array to check values

@desc	Checks how many arrays values are equals to the value
*//*
@example
array_count("SIM", ["SIM", "NAO", "NAO", SIM", "NAO"])	// RETURN 2
array_count(10, [2, 4, 6, 3, 5])						// RETURN 0
*/
function array_count(value, array) {
	var many	= 0
	var length	= array_length(array)
	
	for (var i = 0; i < length; i ++) {
		many += (value == array[i])
	}
	return many
}

/**
@public
@pure
@self global

@param	{Array<Real>}	array	Array to get the greater value
@return	{Real}	The greater value found

@desc	Gets the greater value in an array and returns it. If array is empty, returns 0
*/
function array_max(array) {
	var length	= array_length(array)
	if length <= 0 {
		return undefined
	}
	
	var max_val = array[0]
	for (var i = 1; i < length; i++) {
		max_val = max(max_val, array[i])
	}

	return max_val
}

/**
@public
@pure
@self global

@param	{Array<Real>}	array	Array to get the lowest value
@return	{Real}	The lowest value found

@desc	Gets the lowest value in an array and returns it. If array is empty, returns 0
*/
function array_min(array) {
	var length	= array_length(array)
	if length <= 0 {
		return undefined
	}
	
	var min_val = array[0]
	for (var i = 1; i < length; i++) {
		min_val = min(min_val, array[i])
	}

	return min_val
}
#endregion


#region STRUCT
/**
@public
@pure
@self global

@param	{Struct}	struct	Struct to get it length
@return	{Real}		The struct length
*/
function struct_length(struct) {
	var _ret = is_struct(struct) ? array_length(variable_struct_get_names(struct)) : undefined
	return _ret
}


/**
@public
@pure
@self global

@param	{Struct}	struct	Struct to check
@return {Bool}		True if the struct is empty, and false if it has something

@desc	Sees if the struct is empty or not. Returns true if the struct is empty, and false if not.
*/
/*
@example
	var a = {value1: 0, value2: 10}
	var b = {}
	
	var isEmptyA = empty_struct(a)	// return FALSE
	var isEmptyB = empty_struct(b)	// return TRUE
*/
function empty_struct(struct) {
	return (is_struct(struct) && struct_length(struct) == 0)
}
#endregion



/**
@public
@pure
@self global

@param	{Constant.Color}	col		Color to apply factor
@param	{Real}				factor	The vaue to change the color ( < 1 darker | > 1 brighter )

@desc	Applys an factor into a color, returning a new one
*/
function color_multiply(col, factor) {
    var r = color_get_red(col)		* factor
    var g = color_get_green(col)	* factor
    var b = color_get_blue(col)		* factor
	
    return make_color_rgb(r, g, b)
}

#region Get the entrie word in a position
/**
@ignore
*/
function _get_entire_word(_text, _caret, _direction) {
    var _word = ""
    var _ret_length = 0
    var _ret_start = 1

    var _len = string_length(_text)
    var _separators = " .,!?;:-()[]{}\"'"

    switch (_direction) {
        case "left": {
            var _start = _caret

            // Skip any separators to the left of the caret
            while (_start > 0 && string_pos(string_copy(_text, _start, 1), _separators) > 0) {
                _start--
				_ret_length++
            }

            // Move left until a separator or beginning of text is found
            while (_start > 0) {
                var _char = string_copy(_text, _start, 1)
                if string_pos(_char, _separators) > 0 break
                _start--
                _ret_length++
            }

            var _end = _caret
            _ret_start = _start + 1
            _word = string_copy(_text, _ret_start, _end - _start)
        } break;

        case "right": {
            var _end = _caret + 1

            // Skip any separators to the right of the caret
            while (_end <= _len && string_pos(string_copy(_text, _end, 1), _separators) > 0) {
                _end++
				_ret_length++
            }

            var _start = _end

            // Move right until a separator or end of text is found
            while (_end <= _len) {
                var _char = string_copy(_text, _end, 1)
                if string_pos(_char, _separators) > 0 break
                _end++
                _ret_length++
            }

            _ret_start = _start
            _word = string_copy(_text, _ret_start, _end - _start)
        } break
    }

    return { word: _word, start: _ret_start, length: _ret_length }
}

#endregion
#endregion

/**
@public

@param	{Real}	x1	The first X coordinate (Left)
@param	{Real}	y1	The first Y coordinate (Top)
@param	{Real}	x2	The second X coordinate (Right)
@param	{Real}	y2	The second Y coordinate (Bottom)

@param	{Constant.Color}	col1	The main rectangle color
@param	{Constant.Color}	col2	The secondary rectangle color

@param	{Real}	direction	The colors flow ( "GRADIENT_DIRECTION" enum)

@desc	Draws a gradient rectangle with colors flow
*/
function draw_gradient_rect_ext(x1, y1, x2, y2, col1, col2, direction) {
	
	switch(direction) {
		case GRADIENT_DIRECTION.VERTICAL:
			draw_rectangle_colour(x1, y1, x2, y2, col1, col2, col2, col1, false)
		break
		case GRADIENT_DIRECTION.HORIZONTAL:
			draw_rectangle_colour(x1, y1, x2, y2, col1, col1, col2, col2, false)
		break
		case GRADIENT_DIRECTION.DIAGONAL:
			draw_rectangle_colour(x1, y1, x2, y2, col1, col2, col1, col2, false)
		break
	}
}

/**
@public
@pure

@param	{String}	folder_path	The folder path
@param	{String}	extension	The accepeted extensions (optional)
@return	{Real}		The folder's length

@desc	Sees the length of a folder
*/
function folder_length(folder_path, extension = "") {
	var _true_path = string("{0}*.{1}", folder_path, extension)
	
	var fname = file_find_first(_true_path, fa_archive)
	var count = 0

	while (fname != "") {
		count++
		fname = file_find_next()
	}

	file_find_close()
	return count
}

/**
@public
@pure 

@param	{String}	file_name	file name to be checked
@return	{Bool}		Returns true if is valid and false if not

@desc	Checks if a name can be a file name
*/
/*
@example
var name_1	= "normal name"
var name_2	= "/<Strange NaMe*\"
var name_3	= "" // Empty

var IsAccepct_1	= file_name_validator(name_1) // TRUE
var IsAccepct_2	= file_name_validator(name_2) // FALSE
var IsAccepct_3	= file_name_validator(name_3) // FALSE
*/
function file_name_validator(file_name) {
	
	if (string_trim(file_name) == "") return false

    static banned_simbles = "<>:\"/\\|?*"
    for (var i = 1; i <= string_length(banned_simbles); i++) {
		if (string_pos(string_char_at(banned_simbles, i), file_name) > 0)
			return false
	}

	return true
}

/**
@public
@pure
@self

@param	{Any}	n	Something to check
@return	{Bool}	If is asset or not

@desc	Checks if a value is an asset. If it is, returns true, else returns false
*/
function is_asset(n) {
	return asset_get_type(n) != asset_unknown
}