/**
@ignore

@param	{String}	str		String with the details of the error
@param	{Bool}		_end	If the game must end

@desc	Generates a message of error, and then, if _end is true, closes the game
*/
function __UI_generate_error(str, _end = true) {
	str = string($"ERROR:\n-----------------\n{str}\n-----------------\n")
	
	show_debug_message(str)
	show_message(str)
	if _end game_end()
}

/**
@ignore

@param	{Real}		error	The error type to show
@param	{Struct}	_ctx	Context to help in the error message construction

@desc	Shows an UINode error message
*/
function __UI_error_element(_error, _ctx) {
	var _must_end	= true
	var _txt		= ""
	
	switch(_error) {
		#region INVALID VALUE
		case UIErrorDetail.INVALID_VALUE:
			_txt += "Invalid UINode value\n\n"
			_txt += $"Element: {_ctx.part}\n"
			
			_txt += $"Property: \"{_ctx.variable}\"\n\nExpecting: "
			_txt += $"{string_join_ext(" | ", _ctx.possible)}\n"
			
			_txt += $"Received: {_ctx.gave} >{_ctx.value}<"
		break
		#endregion
	}
	__UI_generate_error(_txt, _must_end)
}

/**
@ignore

@param	{Real}		error	The error type to show
@param	{Struct}	_ctx	Context to help in the error message construction

@desc	Shows an expression error message
*/
function __UI_error_expression(_error, _cxt) {
	var _must_end	= true
	var _txt		= $"Malformed expression: "
	
	switch(_error) {
		case UIErrorDetail.MISS_OPEN_PARENTHESES:
			_txt += $"{_cxt.str}\nMissing open parenthese"
		break;
		case UIErrorDetail.MISS_CLOSE_PARENTHESES:
			_txt += $"{_cxt.str}\nMissing close parenthese"
		break;
		case UIErrorDetail.DIVISION_BY_ZERO:
			_txt += $"{_cxt.str}\nDivision by zero"
		break;
		
		case UIErrorDetail.MALFORMED:
			_txt += $"{_cxt.str}\nThe expression is malformed"
		break;
		case UIErrorDetail.INVALID_TOKEN:
			_txt += $"{_cxt.str}\nThe expression has a invalid token"
		break;
	}
	
	__UI_generate_error(_txt, _must_end)
}

/**
@ignore

@param	{Real}		error_type	The error type ("UIError" ENUM)
@param	{Real}		error_name	The specific error type ("UIErrorDetail" ENUM)
@param	{Struct}	complement	The context to help in the error text creation

@desc	Shows an UIError message, with the UIError and UIErrorDetail shows the error message
*/
function _show_UI_message_error(error_type, error_name, complement) {
	
	switch(error_type) {
		case UIError.MALFORMED_EXPRESSION:
			__UI_error_expression(error_name, complement)
		break
		case UIError.MALFORMED_UINODE:
			__UI_error_element(error_name, complement)
		break
	}
}