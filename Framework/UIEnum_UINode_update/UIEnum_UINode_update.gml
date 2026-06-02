enum UINodeUpdateStep{
	TOPDOWN,
	DOWNTOP
}

enum UINodeDirtyFlag {
	SIZE			= 3,
	LAYOUT			= 2,
	WORLD			= 1,
	GEN_FUNCTION	= 0
}