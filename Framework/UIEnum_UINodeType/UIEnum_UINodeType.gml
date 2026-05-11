enum UINodeType {
	PANEL,
	ICON,
	RADIO_BUTTON,
	CHECKBOX,
	
	LABEL,
	BUTTON,
	SLIDER,
	TEXTBOX,
	DROPDOWN
}

enum UINodePosition {
	ABSOLUTE,
	RELATIVE
}

enum UINodeValue {
	ANY,
	REAL,
	STRING,
	BOOL,
	ARRAY,
	STRUCT,
	ASSET,
	CALLABLE,
	
	EXPRESSION,
	PERCENTAGE,
	AUTO,
	NODE_REFERENCE,
	
	UNDEFINED,
	UNKNOWN
}

enum UINodeFlexDirection {
	ROW,
	ROW_REVERSE,
	COLUMN,
	COLUMN_REVERSE
}

enum UINodeScrollFlow {
	NOONE,
	HORIZONTAL,
	VERTICAL,
	BOTH
}

enum UINodeTextboxType {
	LINEAR,
	VERTICAL
}

enum UINodeDropdownStyle {
	COLOR,
	GRADIENT,
	SPRITE
}

enum UINodeDropdownLayout {
	ALL,
	SCROLL
}