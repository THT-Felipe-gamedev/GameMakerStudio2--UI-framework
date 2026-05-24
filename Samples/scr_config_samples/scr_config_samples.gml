// FOR SAMPLE 2
global.SFX	= 80
global.BGM	= 80
global.BGS	= 80

// FOR SAMPLE 3
function button_on_click(node) {
	switch(node.core.tag) {
		case "resume":
			hide_all_UINodes()
		break
		case "settings":
			hide_UINode_except("settings")
		break
		case "exit":
			game_end()
		break
		
		case "back":
			hide_UINode_except("main_panel")
		break
	}
}

global.name			= "SAMPLE 3"
global.fullscreen	= false