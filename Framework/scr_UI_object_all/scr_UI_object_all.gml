/**
@public
@pure
@self global

@param	{Real}		x		X coordinate value
@param	{Real}		y		Y coordinate value
@param	{Real}		w		Width value
@param	{Real}		h		Height value
@param	{Struct}	limits	The limits { x, y, w, h } of the rect ( optional )
@return	{Bool}		If mouse is hover the rect

@desc	Returns if mouse is hover rect considering limits of the rectangle
*/
function mouse_hover_rect_ext(x, y, w, h, limits) {
	static pointer	= global.UI.input.pointer

	
	var _bound_x = limits.x + limits.w
	var _bound_y = limits.y + limits.h
	
	// If x is ahead the bound's x or the x plus width is behind the start cut x
	var pass_complete_x = ((x > _bound_x) || (x + w < limits.x))
	
	// If y is ahead the bound's y or the y plus height is behind the start cut y
	var pass_complete_y = ((y > _bound_y) || (y + h < limits.y))
	
	// If any up value was false, returns false
	if pass_complete_x || pass_complete_y {
		return false
	}
	
	#region SET THE POINTS OF THE HITBOX

	// Set the points of the rectangle hitbox
	var p1 = max(x, limits.x)	// X1
	var p2 = max(y, limits.y)	// Y1
	
	var p3 = min(p1	+ w, _bound_x)	// X2
	var p4 = min(p2	+ h, _bound_y)	// Y2
	#endregion
	
	var _hover = point_in_rectangle(pointer.x, pointer.y, p1, p2, p3, p4)
	return _hover
}



#region RECTANGLE REGION THAT MOUSE CAN GO HOVER
/**
@public
@pure
@self global

@param	{Struct}	node	UINode structure
@return	{Bool}		If mouse is hover the UINode

@desc	Returns if mouse is hover the UINode
*/
function UI_mouse_hover_rect(node) {
	static pointer	= global.UI.input.pointer
	var _sizes		= node.size
	
	#region SET THE POINTS OF THE HITBOX

	// Set the points of the rectangle hitbox
	var _point_1 = node.position.x.final	// X1
	var _point_2 = node.position.y.final	// Y1
	
	var _point_3 = _point_1 + _sizes.width.resolved		// X2
	var _point_4 = _point_2 + _sizes.height.resolved	// Y2
	#endregion
	
	// Region that if the mouse go hover something happen
	var _hover = point_in_rectangle(pointer.x, pointer.y, _point_1, _point_2, _point_3, _point_4)
	return _hover
}

#endregion

#region MAIN FUNCTIONS

/**
@ignore

@param	{Struct | String}	node_or_id	The UINode or it id

@desc	draws a UINode basic things
*/
function _draw_preset_UI_element(node_or_id) {
	var node			= _UINode_resolve(node_or_id)
	var inner_render	= node.internal.inner_render
	
	var isNormal = false
	
	switch(node.element) {
		case UINodeType.TEXTBOX:
			_textbox_draw_main(node)
		break;
		
		case UINodeType.DROPDOWN:
			_dropdown_main_draw(node, node.inner.halign, node.inner.valign)
		break;
		
		case UINodeType.SLIDER:
			_slider_draw(node)
		break;
		
		case UINodeType.BUTTON:
			draw_UINode_sprite(node)
			_draw_UI_text_in_rect(node.text, inner_render, node.inner.halign, node.inner.valign)
		break;
		
		case UINodeType.LABEL:
			_draw_UI_text_in_rect(node.text, inner_render, node.inner.halign, node.inner.valign)
		break;
		
		default:
			isNormal = true
		break;
	}
	
	if isNormal {
		draw_UINode_sprite(node)
	}
}
#endregion

#region CREATORS

#region DROPDOWN OPEN STYLE
/**
@public
@pure
@self global

@param	{Constant.Color}	_color		The color of the backgorund of the open panel
@param	{Real}				_bord_px	Thickness of the border
@return	{Struct}			Returns the color style structure

@desc	Creates a dropdown color style structure to use in a dropdown UINode
*/
function dropdown_color_style(_color, _bord_px) {
	return {
		mode: UINodeDropdownStyle.COLOR,
		
		settings: {
			color:		_color,
			bord_px:	_bord_px
		}
	}
}

/**
@public
@pure
@self global

@param	{Asset.GMSprite}	_sprite		Sprite to use in the background
@param	{Real}				_image		SubImage to get in the sprite
@param	{Constant.Color}	_color		The color to apply in the sprite

@return	{Struct}			Returns the sprite style structure
@desc	Creates a dropdown sprite style structure to use in a dropdown UINode
*/
function dropdown_sprite_style(_sprite, _image, _color = c_white) {
	return {
		mode: UINodeDropdownStyle.SPRITE,
		
		settings: {
			sprite:	_sprite,
			image:	_image,
			color:	_color
		}
	}
}

/**
@public
@pure
@self global

@param	{Constant.Color}	_col1		The main color
@param	{Constant.Color}	_col2		The secondary color
@param	{Real}				_bord_px	Thickness of the border
@param	{Real}				_direction	Direction of colors ("GRADIENT_DIRECTION" ENUM)

@return	{Struct}			Returns the sprite style structure
@desc	Creates a dropdown sprite style structure to use in a dropdown UINode
*/
function dropdown_gradient_style(_col1, _col2, _bord_px, _direction) {
	return {
		mode: UINodeDropdownStyle.GRADIENT,
		
		settings: {
			color:		{col1: _col1, col2: _col2},
			bord_px:	_bord_px,
			direction:	_direction
		}
	}
}
#endregion

#region DROPDOWN OPEN LAYOUT
/**
@public
@pure
@self global

@param	{Real}	_amount		The amount of options to show
@param	{Real}	_force		The scroll force os the wheel
@param	{Real}	_drag		The force that stops the scroll (MAKE SURE IS LESS THAN 1)

@return	{Struct}			Creates the dropdown scroll layout
@desc	Creates a dropdown scroll layout structure to use in a dropdown UINode
*/
function dropdown_scroll_layout(_amount, _force, _drag) {
	return {
		mode: UINodeDropdownLayout.SCROLL,
		
		settings: {
			amount: _amount,
			
			scroll: {
				force:	_force,
				drag:	_drag,
				
				velocity:	0,
				limit:		0,
				value:		0
			}
		}
	}
}

/**
@public
@pure
@self global

@return	{Struct}			Creates the dropdown all layout
@desc	Creates a dropdown all layout structure to use in a dropdown UINode
*/
function dropdown_all_layout() {
	return {
		mode: UINodeDropdownLayout.ALL,
		settings: {}
	}
}
#endregion

#endregion