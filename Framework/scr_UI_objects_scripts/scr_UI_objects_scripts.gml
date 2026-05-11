#region SLIDER
function slider_draw(_data){
	var _img = _data.assets.image

	var _spr_empty = _data.sprite_empty
	var _spr_full = _data.sprite_full
	var _spr_knob = _data.sprite_knob

	var _data_x = _data.position.x.final
	var _data_y = _data.position.y.final
	var _bar_draw_perc = (inter_per_one * _data.value)

	draw_sprite_stretched_ext(_spr_empty, _img, _data_x, _data_y,
	_data.size.width.outer, _data.size.height.outer, c_white, _data.core.alpha)

	var _pos_x = _data_x + _bar_draw_perc
	var _pos_y = _data_y

	var _knob_w = sprite_get_width(_spr_knob)


	draw_sprite_stretched_ext(_spr_full, _img, _data_x, _data_y, _bar_draw_perc, _data.size.height.outer, _data.core.color, 1)
	draw_sprite_ext(_spr_knob, _img, _pos_x - _knob_w / 2, _pos_y, 1, 1, 0, _data.core.color, _data.core.alpha)
}

function mouse_on_konb (_data) {
	var _knob_w = sprite_get_width(_data.sprite_knob)
	var _knob_h = sprite_get_height(_data.sprite_knob)
	
	var _pos_x = _data.position.x.final + (inter_per_one * _data.value)
	var _pos_y = _data.position.y.final + _knob_h / 2
	
	return point_in_circle(mouse_UI_x(), mouse_UI_y(), _pos_x, _pos_y, _knob_w / 2)
}

function move_knob(_tol, _add_value, _operator, _data) {
	var _safe	= 0
	var _x		= _data.position.x.final
	
	var _calc = (_x + inter_per_one * _data.value) + _tol
	
	if (string_operate_bi(_calc, mouse_UI_x(), _operator)) {		
		while (string_operate_bi(_calc, mouse_UI_x(), _operator)) && (_safe < 25) {
			_data.value += _add_value
			_safe ++
			
			_calc = (_x + inter_per_one * _data.value) + _tol
		}	
	}
}
#endregion

#region DROPDOWN
function dropdown_get_item_rect(_stc, index) {
    var _w	= _stc.size.width.outer
	var _h	= _stc.size.height.outer
	
    var _x = _stc.position.x.final
    var _y = _stc.position.y.final + _h + (_h * index)
	
	var _x2 = _x + _w
	var _y2 = _y + _h

    return point_in_rectangle(mouse_UI_x(), mouse_UI_y(), _x, _y, _x2, _y2)
}

function change_selected_dropdown(_stc) {
	if _stc.stage != "open" exit
	
	for (var i = 0; i < array_length(_stc.options); i ++) {
		var _hover_bloco = dropdown_get_item_rect(_stc, i)

		if _hover_bloco {
			if mouse_check_button_pressed(mb_left) {
				_stc.selected_index = i
			}
		}
	}
}

function change_dropdown_stage_auto(_stc) {
	var _mb_left_clicked = mouse_check_button_pressed(mb_left)
	
	if UI_mouse_hover_rect(_stc) {
		if _mb_left_clicked {
			_stc.stage = dropdown_chance_stage(_stc)
		}
	} else {
		if _mb_left_clicked && _stc.stage == "open" {
			_stc.stage = "closed"
		}
	}
}

#region DRAW event
#region UI open options
function UI_dw_open_color(_stc) {
	var _create_bg_dropdown = function (_stc, _type) {
			var _col = _type.color
			var _bor = _type.bord_px
			
			_col = is_string(_col) ? str_to_color(_col) : _col
			
			var _bord_color = darken_color(_col, 0.8)
			draw_set_color(_bord_color)
			
			var x1 = _stc.position.x.final
			var y1 = _stc.position.y.final + (_stc.size.height.outer)
					
			var x2 = x1 + _stc.size.width.outer - 1
			var y2 = y1 + _stc.open.height

			// Draw bg dropdown
			draw_rectangle(x1, y1, x2, y2, false)
			draw_set_color(_col)
			draw_rectangle(x1 + _bor, y1, x2 - _bor, y2 - _bor, false)
			draw_set_color(c_white)
	}
	
	var _open	= _stc.open
	var _list	= _stc.options
	
	var _pos_x	= _stc.position.x.final
	var _pos_y	= _stc.position.y.final
	
	var _bord	= _open.style.param.bord_px
	var _col	= _open.style.param.color
	
	_create_bg_dropdown(my_data, _open.style.param)
	if _open.split_option {
		var _bord_color = darken_color(_col, 0.8)
		draw_set_colour(_bord_color)
		
		for (var i = 0; i < array_length(_list); i ++) {
			var _y = _pos_y + _stc.size.height.outer + (_stc.size.height.outer * i)
			var _x = _pos_x
				
			draw_rectangle(_x, _y - _bord/2, _x + _stc.size.width.outer-1, _y + _bord/2, false)
		}
		draw_set_colour(c_white)
	}
}

function UI_dw_open_sprite(_stc) {
	var _style	= _stc.open.style
	var _list	= _stc.options
	
	var spr		= _style.param.sprite
	var img		= _style.param[$ "image"]	?? 0
	var perln	= _stc.open.split_option	?? false
	
	var _w	= _stc.size.width.outer
	var _h	= _stc.size.height.outer
	
	var	_x	= _stc.position.x.final
	var	_y	= _stc.position.y.final + _h
	
	var _op_h = _stc.open.height
	
	if (!perln) {
		// One big sprite
		draw_sprite_stretched_ext(spr, img, _x, _y, _w, _op_h, c_white, 1)
	} else {
		// Split sprites
		for (var i = 0; i < array_length(_list); i ++) {
			var iy = _y + (_h * i)
			draw_sprite_stretched_ext(spr, img, _x, iy, _w, _h, c_white, 1)
		}
	}
}


function UI_dw_open_gradient(_stc) {
	var _open	= _stc.open
	var _list	= _stc.options
	
	var _w = _stc.size.width.outer
	var _h = _stc.size.height.outer
	
	var _param = _open.style.param
	
	var _bpx		=  _param.bord_px
	var _col		=  _param.color
	
	#region DEFINING POSITIONS
	var x1 = _stc.position.x.final
	var y1 = _stc.position.y.final + _h
	var x2 = x1 + _w - 1
	var y2 = y1 + _open.height
	
	var in_x1 = x1 + _bpx
	var in_y1 = y1
	var in_x2 = x2 - _bpx-1
	var in_y2 = y2 - _bpx
	#endregion
	var _dir = _param.direction
	
	var _dkr_cols	= {col1: darken_color(_col.col1, 0.8), col2: darken_color(_col.col2, 0.8)}
			
	draw_gradient_rect_ext(x1, y1, x2, y2, _dkr_cols.col1,	 _dkr_cols.col2, _dir)
	draw_gradient_rect_ext(in_x1, in_y1, in_x2, in_y2, _col.col1, _col.col2, _dir)
	
	if _open.split_option {
		for (var i = 0; i < array_length(_list); i ++) {
			var ye1 = y1 + _h + (_h * i) - floor(_bpx/2)
			var ye2 = ye1 + floor(_bpx/2)
			
			draw_gradient_rect_ext(in_x1, ye1, in_x2, ye2, _dkr_cols.col1, _dkr_cols.col2, _dir)
		}
	}
}
#endregion

function dropdown_draw_open_sprite(_stc) {

	switch (_stc.open.style.mode) {
		#region COLOR
		case "color": 	
			UI_dw_open_color(_stc)
		break
		#endregion
		
		#region SPRITE
		case "sprite":
			UI_dw_open_sprite(_stc)
		break
		#endregion
		
		#region GRADIENT
		case "gradient": 
			UI_dw_open_gradient(_stc)
		break
		#endregion
	}
}


function dropdown_draw_selected(_stc, _hal_on_drop, _val_on_drop) {
	var _main_text = {
		text:	{
			style:	_stc.text.style,
			layout:	_stc.text.layout,
			
			content:	_stc.selected_value,
			wrap:		_stc.selected_value,
			span:		_stc.text.span,
			parsed:		UI_parse_text(_stc.selected_value, _stc.text.span)
		},
		inner:	_stc.inner,
		
		core: {
			visible: _stc.core.visible
		},
		scissor: _stc.scissor
	}

	draw_UI_text_button(_main_text, _hal_on_drop, _val_on_drop)
}

function dropdown_draw_options(_stc, _hal_on_drop, _val_on_drop) {
	var _options	= _stc.options
	var _pivot		= _stc.offset.pivot
	
	var _open		= _stc.open
	var _h_per_line	= _stc.size.height.outer
	var _textd		= _stc.text
	
	var _x = _stc.position.x.final + _stc.size.padding.inner.left
	
	for (var i = 0; i < array_length(_options); i ++) {
		var _y = _stc.position.y.final + _h_per_line + (_h_per_line * i)
		
		_y += _stc.size.padding.inner.top
	
		var _stc_text = {
			text:	{
				style:		_textd.style,
				layout:		_textd.layout,
				
				content:	_stc.options[@ i],
				wrap:		_stc.options[@ i],
				
				span:		_textd.span,
				parsed:		UI_parse_text(_stc.options[@ i], _textd.span)
			},
			
			inner:	{
				width:	_stc.inner.width,
				height:	_stc.inner.height,
				
				x: _x,
				y: _y
			},
		
			core: {
				visible: _stc.core.visible
			},
		scissor: _stc.scissor
		}	
		draw_UI_text_button(_stc_text, _hal_on_drop, _val_on_drop)
	}

}
#endregion
#endregion

#region TEXTBOX

#region Digits
function textbox_keyboard_get(_stc) {
	if !_stc.focus || (keyboard_lastchar == "" && keyboard_lastkey <= 0) {
		_stc.state = "nothing"
		exit
	}
	
	var ch			= keyboard_lastchar
	var c_ord		= ord(ch)
	var _normal		= false
	
	var _pos_raw	= _stc.caret.position
	
	var _txt		= _stc.text.content
	
	_stc.hide.dirty				= true
	_stc.caret.dirty			= true
	_stc.scroll.limits.dirty	= true
	
	if (keyboard_check(vk_control)) {
		#region CONTROL INPUTS
		switch(keyboard_lastkey) {
			case vk_left:
				if _pos_raw > 0 {
					var _lw_l = get_entire_word(_txt, _pos_raw, "left").length
					_pos_raw -= _lw_l
				}
			break
			case vk_right:
				if _pos_raw < string_length(_txt) {
					var _lw_r = get_entire_word(_txt, _pos_raw, "right").length
					_pos_raw += _lw_r
				}
			break
			
			case vk_backspace:
				if _pos_raw > 0 {
					var _en_w = get_entire_word(_txt, _pos_raw, "left")
					var _lw_l = _en_w.length
					var _st_w = _en_w.start
					
					_stc.text.set_content(string_delete(_txt, _pos_raw-_lw_l, _lw_l+1))
					_pos_raw -= _lw_l
				}
			break
			case vk_delete:
				if _pos_raw < string_length(_txt) {
					var _lw_r = get_entire_word(_txt, _pos_raw, "right").length
					_stc.text.set_content(string_delete(_txt, _pos_raw, _lw_r))
				}
			break
		}
		_stc.state = $"control \{{keyboard_lastkey}\}"
		#endregion
	
	} else if (keyboard_check(vk_shift)) {
		#region SHIFT INPUTS
		switch (keyboard_lastkey) {			
		    case vk_enter: 
				_stc.text.set_content(string_insert("\n", _txt, _pos_raw+1))
				_pos_raw ++
			break
			
			default:	_normal	= true	break
		}
		_stc.state = $"control \{{keyboard_lastkey}\}"
		#endregion
		
	} else {
		#region BASICS INPUTS
		switch (keyboard_lastkey) {
		    case vk_left:	_pos_raw --	_stc.state = $"typed \{vk:{vk_left}\}"	break
			case vk_right:	_pos_raw ++	_stc.state = $"typed \{vk:{vk_right}\}"	break
			
			case vk_delete:
				if _pos_raw < string_length(_txt)
				_stc.text.set_content(string_delete(_txt, _pos_raw+1, 1))
				_stc.state = $"typed \{vk:{vk_delete}\}"
			break
			case vk_backspace:
				if _pos_raw > 0
				_stc.text.set_content(string_delete(_txt, _pos_raw, 1))
				_pos_raw --
				_stc.state = $"typed \{vk:{vk_backspace}\}"
			break
			
			
			default:	_normal	= true	break
		}
		#endregion
		
	}
	if _normal && ch != "" && (ord(ch) >= 32 && ord(ch) <= 128) {
		_stc.text.set_content(string_insert(keyboard_lastchar, _txt, _pos_raw+1))
		_stc.state = $"typed \{{keyboard_lastchar}\}"
		_pos_raw ++
	}
	
	
	_stc.caret.position = clamp(_pos_raw, 0, string_length(_stc.text.content))
	var _last_wrap	= _stc.text.wrap
	
	_stc.text.eval_wrap(_stc)
	
	keyboard_lastchar	= ""
	keyboard_lastkey	= -1
}
#endregion

#region auto scroll

function textbox_update_scroll(_stc) {
	var _scrl				= _stc.scroll
	var _wheel_direction	= mouse_wheel_down() - mouse_wheel_up()
	_scrl.force				= _wheel_direction != 0 ? _wheel_direction * _scrl.pow : _scrl.force

	_scrl.limits.eval(_stc)
	
	_scrl.offset	+= _scrl.force
	_scrl.offset	=  clamp(_scrl.offset, 0, max(0, _scrl.limits.maximum))

	var _fric = _scrl.drag * sign(_scrl.force)
	
	if (sign(_scrl.force - _fric) == sign(_scrl.force)) && (_scrl.force != 0) {
		_scrl.force	-= _fric
	} else {
		_scrl.force	= 0
	}
	
}
#endregion

#region draw text
function textbox_draw_text(_stc, _hal_on_txtb, _val_on_txtb) {
	var _pos_x	= 0
	var _pos_y	= 0
	
	var _type	= _stc.textbox_type
	var _scrl	= _stc.scroll
	var _txtd	= _stc.text
	var _hide	= _stc.hide
	
	var _txt = ""
	
	
	switch(_type) {
		case "linear":
			_txt	= _hide.enabled ? _hide.content : _txtd.content
			
			_pos_x = _stc.inner.x - _scrl.offset
			_pos_y = _stc.inner.y
		break
		
		case "vertical":
			_txt	= _hide.enabled ? _hide.wrap : _txtd.wrap
			_pos_x = _stc.inner.x
			_pos_y = _stc.inner.y - _scrl.offset
		break
	}
	
	var _placeholder_stc = {
		offset: _stc.offset,
		
		text:	{
		    content:	_txt,
			wrap:		_txt,
		    parsed:		_stc.text.parsed,
		    span:		_stc.text.span,
		    style:		_stc.text.style,
			layout:		_stc.text.layout
		},
		
		inner:	{
			width:	_stc.inner.width,
			height:	_stc.inner.height,
			x:	_pos_x,
			y:	_pos_y
		},
		
		core: {
			visible: _stc.core.visible
		},
		scissor: {
			enabled: false
		}
	}

	draw_UI_text_button(_placeholder_stc, _hal_on_txtb, _val_on_txtb)
}

#endregion

#region set caret
function textbox_draw_caret(_stc) {
	var _caret		= _stc.caret
	var _scrl		= _stc.scroll

	if !_stc.focus || !_caret.state {exit}
	
	draw_set_color(c_white)

	var _cur_pos_x = _stc.inner.x + _caret.data.width
	var _cur_pos_y = _stc.inner.y + _caret.data.height

	// caret "x" and "y"
	switch(_stc.textbox_type) {
		case "linear":
			_cur_pos_x -= _scrl.offset
		break
		case "vertical":
			_cur_pos_y -= _scrl.offset
		break
	}

	draw_line(_cur_pos_x, _cur_pos_y, _cur_pos_x, _cur_pos_y - _caret.size)
}

function textbox_text_config(_stc) {
	
	var _text = _stc.text
	var _hide = _stc.hide
	draw_set_font(_stc.text.style.font)
	
	if !_hide.dirty {exit}
	_hide.dirty = false
	
	switch(_stc.textbox_type) {
		case "linear":
			_hide.text = string_repeat("•", string_length(_text.content))
		break
		case "vertical":
			var _hided_t	=	string_repeat("•", string_length(_text.content))
			var _nw_t		=	string_wrap(_hided_t, _stc.inner.width, _text.style.font)

			_hide.text = _nw_t
		break
	}
}

function textbox_caret_find_data(_stc) {
	var _txtd	= _stc.text
	var _caret	= _stc.caret
	
	if !_caret.dirty {exit}
	
	draw_set_font(_txtd.style.font)
	
	var _txt	= _stc.textbox_type == "linear" ? _txtd.content : _txtd.wrap
	
	var _txt_before = string_copy(_txt, 1, _caret.position)
	
	var _new_data = {
		width:	string_width(_txt_before),
		height:	string_height(_txt_before)
	}
	
	_caret.data	= _new_data
	_caret.size	= string_height("A")
}
#endregion

function textbox_draw_set(_stc) {
	adjust_caret_focus(_stc)
	textbox_update_scroll(_stc)
	textbox_caret_find_data(_stc)
	textbox_text_config(_stc)
}

function adjust_caret_focus(_stc) {
	var event = _stc.state
	
	var in_w	= _stc.inner.width
	var in_h	= _stc.inner.height
	var caret_w	= _stc.caret.data.width
	var caret_h	= _stc.caret.data.height
	
	var _scrl_off	= _stc.scroll.offset

	if !string_contains(event, "nothing") {
		
		draw_set_font(_stc.text.style.font)
		var line_w		= string_width("A")
		var line_h		= string_height("A")
		var _discount	= 0
		var _adjusted	= false
		
		switch(_stc.textbox_type) {
			case "linear":
				_discount = caret_w - _scrl_off
				
				if ((_discount + line_w) > in_w) {		// If caret is out of the right's bound
					_stc.scroll.offset = min(caret_w - in_w + line_w, _stc.scroll.limits.maximum)
					_adjusted = true
				}
				else if ((_discount - line_w) < 0) {	// If caret is out of the left's bound
					_stc.scroll.offset = max(caret_w - line_w, 0)
					_adjusted = true
				}
				
			break

			case "vertical":
				var _before_txt		= string_copy(_stc.text.wrap, 1, _stc.caret.position)
				var _space_lines	= (2 * string_count("\n", _before_txt)) // Space between lines
				
				_discount = caret_h - _scrl_off + (2 * _space_lines)

				
				if ((_discount) < 0) {			// If caret is out of the top's bound
					var _new_position	= caret_h + _space_lines
					_stc.scroll.offset	= max(_new_position, 0)
					_adjusted = true
				}
				else if ((_discount + line_h) > in_h) {	// If caret is out of the bottom's bound
					var _new_position	= caret_h + _space_lines - (in_h - line_h)
					_stc.scroll.offset	= min(_new_position, _stc.scroll.limits.maximum)
					_adjusted = true
				}
			break
	
		}
		
		if _adjusted {
			_stc.scroll.force = 0
		}
	}
}

function textbox_draw_main(_stc, _hal, _val) {
	var _last_b = gpu_get_scissor()
	gpu_set_scissor(_stc.scroll.bounds)
	
	textbox_draw_text(_stc, _hal, _val)
	textbox_draw_caret(_stc)
	
	gpu_set_scissor(_last_b)
}

#endregion

