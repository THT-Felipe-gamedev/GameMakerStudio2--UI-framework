function apply_span_effects(parse) {
    var _all_ef = parse.style.span
	var kind	= parse.kind
	
	if kind == TextSpanKind.DEFAULT {exit}
	
	
    for (var i = 0; i < array_length(_all_ef); i++) {
        var _effect_at	= _all_ef[i]
		var _info		= _effect_at.info
		
        switch (_effect_at.effect) {
            case SpanType.COLOR:
                draw_set_color(_info.color)
            break

            case SpanType.ALPHA:
                draw_set_alpha(_info.alpha)
            break
			
			default: exit
        }
    }

	/*
    // Font logic
    if (effects.bold && effects.italic) {
        draw_set_font(_stc.text.font_bold_italic);
    } else if (effects.bold) {
        draw_set_font(_stc.text.font_bold);
    } else if (effects.italic) {
        draw_set_font(_stc.text.font_italic);
    } else {
        draw_set_font(_stc.text.font);
    }
	*/
}

/**
@ignore
@pure
*/
function UI_parse_create_part(ev_index, text_index, txt, span_list, span_kind, def_info) {
	var line_length	= (ev_index - text_index)					// Line length
	var line		= string_copy(txt, text_index, line_length)	// Line content
	
	var fnt	= def_info.font
	var xsc	= def_info.xscale
	var ysc	= def_info.yscale
	
	for(var	i = 0; i < array_length(span_list); i ++) {
		var _span = span_list[i]	// Actual span
		
		switch(_span.effect) {
			case SpanType.FONT:		fnt	= _span.info.font	break;
			case SpanType.XSCALE:	xsc	= _span.info.scale	break;
			case SpanType.YSCALE:	ysc	= _span.info.scale	break;
		}
	}
	
	draw_set_font(fnt)
	
	// Span and default informations
	var _style	= {span: variable_clone(span_list), font: fnt, xscale: xsc, yscale: ysc}
	
	// The width and height of the line
	var _met	= {width: string_width(line) * xsc, height: string_height(line) * ysc}
	
	// Parse line
	return {text: line, style: _style, kind: span_kind, metrics: _met}
}

/**
@public

@param	{String}		txt			String to be parsed
@param	{Array}			spans		Array of spans to be used (see spans creators)
@param	{Asset.GMFont}	def_font	font set by default (changed if has a font span)
@param	{Real}			def_xscale	text's default xscale (changed if has a xscale span)
@param	{Real}			def_yscale	text's default yscale (changed if has a yscale span)

@return {Array<Struct>}
@desc	Creates an array with informations of spans, width and type of text used in each index
*/

function UI_parse_text(txt, spans, def_font, def_xscale, def_yscale) {
	var prev_font	= draw_get_font()
	var final_parse = [] // the final parse to return
	
	var active = [] // Where active spans will be
	var events = [] // List of start/end index of spans
	
	var txt_l		= string_length(txt)	// Text length
	var break_index	= string_pos("\n", txt)	// break index
	
	// Defalut informations
	var def_info	= {
		font:	def_font,
		xscale:	def_xscale,
		yscale:	def_yscale
	}
	
	#region ORGANIZE ALL EVENTS
	// Runs for all spans
	for(var i = 0; i < array_length(spans); i ++) {
		var s = spans[@ i] // Actual span
		
		//range array
		var _range	= s.range
		
		var _start	= max(_range[0], 1)		// Start index
		var _end	= min(_range[1], txt_l)	// End index
		
		array_push(events, {index: _start,	type: TextIndexType.START,	span: s})	// Start
		array_push(events, {index: _end+1,	type: TextIndexType.END,	span: s})	// end
	}
	
	// Gets the linebreaks and add to the events
	while(break_index > 0) {
		array_push(events, {index: break_index, type: TextIndexType.BREAK, span: []})	// Pushes
		break_index = string_pos_ext("\n", txt, (break_index + 1))						// New linebreak
	}
	
	// Organize the array in a crescent order based on the indexs
	array_sort(events, function(a, b) {
		return (a.index - b.index)
	})
	#endregion
	
	// Index where the text copy will be based
	var text_index = 1

	// Runs for all events
	for(var i = 0; i < array_length(events); i ++) {
		var event		= events[@ i]	// actual event
		var ev_type		= event.type	// It type (TextIndexType START, END, BREAK)
		var ev_index	= event.index	// It index
		var ev_span		= event.span	// Event's span
		
		#region Adds the actual parse
		// If is not the same index from de last break, creates a new part to the parse
		if (ev_index > text_index) {
			
			var span_kind	= TextSpanKind.DEFAULT
			
			//if it'is ampty, is default, else has/is a span
			span_kind = empty_array(active) ? TextSpanKind.DEFAULT : TextSpanKind.SPAN
			
			// If is a break type, instantly makes into a break kind
			if ev_type == TextIndexType.BREAK {
				span_kind = TextSpanKind.BREAK
			}
			
			// Gets the parsed line (With the text and the style)
			var parsed_line	= UI_parse_create_part(ev_index, text_index, txt, active, span_kind, def_info)
			
			//if txt == "Hello world!"
			// Parse line
			array_push(final_parse, parsed_line)
			
			// Makes the last text index be the actual one
			text_index = ev_index
			
			// If is the type break, add one too jump the \n
			if ev_type == TextIndexType.BREAK {
				text_index ++
			}
		}
		#endregion

		#region TYPE RESOLUTION
		switch(ev_type) {
			
			case TextIndexType.START:
				// Add to the activated ones
				array_push(active, ev_span)
			break;
			
			case TextIndexType.END:
				// Delete the span from the activate ones
				for (var j = 0; j < array_length(active); j ++) {
					if active[j] == ev_span {			// If has de same struct
						array_delete(active, j, 1)		// Removes it
						break;
					}
				}
			break;
			
			case TextIndexType.BREAK:
				// Nothing to do
			break;
		}
		#endregion
	}
	
	// If the last text_index wasn't the last index
	if text_index < string_length(txt)+1  {
		// Adds the final kind
		var l_kind	= TextSpanKind.DEFAULT
		var last_parse = UI_parse_create_part(string_length(txt)+1, text_index, txt, active, l_kind, def_info)
		array_push(final_parse, last_parse)
	}
	draw_set_font(prev_font)
	return final_parse
}

function _UI_parse_text_resolver(content, wrap, spans, style, draw_mode) {
	var parse	= []
	
	switch(draw_mode) {
		case UINodeDrawMode.CONTENT:
			parse	= UI_parse_text(content, spans, style.font, style.xscale, style.yscale)
		break;
		case UINodeDrawMode.WRAP:
			parse	= UI_parse_text(wrap, spans, style.font, style.xscale, style.yscale)
		break;
		default:
			parse	= UI_parse_text(wrap, spans, style.font, style.xscale, style.yscale)
		break;
	}
	
	return parse
}


#region SPANS CREATORS
/**
@public
@pure

@param	{Constant.Color}	color	span text's color
@param	{Array<Real>}		range	range of effect (first value the begin and second the end)
@return	{Struct}			span struct

@desc Creates a color span struct
*/
function create_color_span(color, range) {
	return {
		effect:	SpanType.COLOR,
		info:	{
			color: color
		},
		range: range
	}
}

/**
@public
@pure

@param	{Real}			alpha	Text's alpha (0 to 1)
@param	{Array<Real>}	range	range of effect (first value the begin and second the end)
@return	{Struct}		span struct

@desc Creates a alpha span struct
*/
function create_alpha_span(alpha, range) {
	return {
		effect:	SpanType.ALPHA,
		info:	{
			alpha: alpha
		},
		range: range
	}
}
/**
@public
@pure

@param	{Asset.GMFont}	font	Segment font
@param	{Array<Real>}	range	range of effect (first value the begin and second the end)
@return	{Struct}		span struct

@desc Creates a font span struct
*/
function create_font_span(font, range) {
	return {
		effect:	SpanType.FONT,
		info:	{
			font: font
		},
		range: range
	}
}
#endregion
