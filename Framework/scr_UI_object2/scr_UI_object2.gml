#region TEXTBOX

#region Digits
/**
@ignore
@self textbox_step_main

@param	{Struct}	node	UINode to add/delete characters
@desc	Get keboards inputs and add it to a textbox UINode
*/
function _textbox_keyboard_get(node) {
	var input = {
		char:	global.UI.input.keyboard.char,
		key:	global.UI.input.keyboard.key,
		ctrl:	keyboard_check(vk_control),
		shift:	keyboard_check(vk_shift)
	}

	if !node.focus || (input.char == "" && input.key <= 0) {
		exit
	}
	
	var last_txt	= node.text.content
	var txt			= last_txt
	var pos			= string_length(txt)
	
	_mark_dirty(node, UINodeDirtyFlag.WORLD)

	#region INPUTS
	// CTRL
	if input.ctrl {
		switch(input.key) {
			// BACKSPACE
			case vk_backspace:
				var removed = _get_entire_word(txt, pos, "left")
				txt = string_delete(txt, pos - removed.length, removed.length + 1)
			break
		}

	}
	// SHIFT
	else if input.shift {
		// ENTER (manual break)
		if input.key == vk_enter && node.textbox_type == UINodeTextboxType.VERTICAL {
			txt = string_insert("\n", txt, pos + 1)
		}
		else {
			// Normal text
			if input.char != "" && input.key != vk_enter {
				txt = string_insert(input.char, txt, pos + 1)
			}
		}

	}
	// NORMAL
	else {

		switch(input.key) {
			// BACKSPACE
			case vk_backspace:
				if pos > 0 {
					txt = string_delete(txt, pos, 1)
				}
			break
			case vk_enter: break
			
			// NORMAL INPUT
			default:
				if input.char != "" {
					txt = string_insert(input.char, txt, pos + 1)
				}
			break
		}
	}
	#endregion
	
	if txt != last_txt {
		node.text.set_content(txt)
		node.internal.changed = true
	}
}
#endregion

#region draw text
/**
@ignore

@param	{Struct}	node	Textbox UINode to draw text

@desc	Draws a textbox text
*/
function _textbox_draw_text(node) {
	var _pos_x	= 0
	var _pos_y	= 0
	
	var inner	= node.inner		// Inner informations
	var type	= node.textbox_type	// textbox type
	var scrl	= node.scroll		// scroll struct
	
	// Rectangle (inner)
	var rect = {x: inner.x, y: inner.y, width: inner.width, height: inner.height}
	
	
	switch(type) {
		case UINodeTextboxType.LINEAR:		rect.x	-= scrl.value.x	break
		case UINodeTextboxType.VERTICAL:	rect.y	-= scrl.value.y	break
	}
	
	// Draw text
	_draw_UI_text_in_rect(node.text, rect, inner.halign, inner.valign)
}

#endregion

#region Config text
/**
@ignore
@param	{Struct}	node	Textbox UINode
@desc	Configurates the textbox UINode text
*/
function _textbox_draw_set(node) {
	
	var _text = node.text	// Text struct
	var _hide = node.hide	// Hide struct (text, enabled and dirty)
	
	// Set font
	draw_set_font(node.text.style.font)
	
	if !_hide.dirty {exit}	// If isn't dirty, exit it
	_hide.dirty = false		// Else set it normal and get new elements
	
	switch(_text.layout.draw_mode) {
		case UINodeDrawMode.CONTENT:
		// Just repeat it in hidden form
			_hide.text = string_repeat("•", string_length(_text.content))
		break
		case UINodeDrawMode.WRAP:
			var _hided_t	=	string_repeat("•", string_length(_text.content))			// Make it hidden
			var _nw_t		=	string_wrap(_hided_t, node.inner.width, _text.style.font)	// Get wraped form
			
			// Atualize it
			_hide.text = _nw_t
		break
	}
}	




function _textbox_draw_parts(node) {
	var _last_b = gpu_get_scissor()
	var in		= node.inner
	
	draw_UINode_sprite(node)
	gpu_set_scissor(in.x, in.y, in.width, in.height)
	
	_textbox_draw_text(node)

	gpu_set_scissor(_last_b)
}
#endregion

#endregion



