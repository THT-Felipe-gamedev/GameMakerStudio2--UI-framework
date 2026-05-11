enum UINodeUpdateStep{
	TOPDOWN,
	DOWNTOP
}

enum UINodeDirtyFlag {
	SIZE,
	LAYOUT,
	WORLD,
	GEN_FUNCTION,
	
	TEXT,
	ALL
}