# UINode

Flexible UI framework for GameMaker.

UINode is a modular UI system focused on flexibility, reusable layouts, and scalable UI architecture. The framework was designed to simplify the creation of interfaces while still allowing advanced customization and organization.

---

# Features

- Flex layout system
- Relative and absolute positioning
- Nested UI hierarchy
- Scroll support
- Buttons
- Labels
- Textboxes
- Sliders
- Checkboxes
- Dropdowns
- Layer system
- UI grouping/classes
- Auto sizing
- Padding and margins
- Alignment system
- Translate/render offsets
- Reusable creators/helpers
- Callback/event system
- Context data support
- Modular architecture

---

# Current Components

## Containers
- Panel

## Inputs
- Button
- Textbox
- Slider
- Checkbox
- Dropdown

## Display
- Label

---

# Layout System

UINode includes a flex-inspired layout system.

Supported features include:

- Row and column layouts
- Reverse flow
- Gap support
- Justify content
- Align items
- Automatic sizing
- Relative sizing using percentages
- Nested layouts

Example:

```gml
var panel = {
    justify_content: JUSTIFY_CONTENT.SPACE_AROUND,
    flex_direction: UINodeFlexDirection.COLUMN,

    width: "80%",
    height: "80%",
    p_all: 10
}
```

---

# Positioning

The framework supports both relative and absolute positioning.

## Relative
Elements follow the layout flow.

## Absolute
Elements can be positioned freely using:

```gml
x
y
x_offset
y_offset
```

Example:

```gml
x: "50%",
y: "50%",

x_offset: UI_HALIGN.CENTER,
y_offset: UI_VALIGN.MIDDLE
```

---

# Translate System

The framework includes a translate system used for visual movement without affecting layout calculations.

This allows:

- UI animations
- Hover effects
- Menu transitions
- Shake effects
- Visual adjustments

Example:

```gml
translate_x = -20
translate_y = 10
```

---

# Callbacks

UINodes support event callbacks.

Examples:

```gml
on_click
on_change
on_submit
```

Example:

```gml
on_click = function(node) {
    show_debug_message("Button clicked")
}
```

---

# Context Data

Each UINode can store custom context data.

Example:

```gml
context = {
    label: my_label_id,
    type: "SFX"
}
```

This is useful for reusable UI creators and generic callbacks.

---

# Samples

The project includes multiple samples demonstrating how the framework can be used.

## Sample 1
Scrollable button list.

Demonstrates:
- Parent/child hierarchy
- Scroll areas
- Dynamic button creation
- Context usage

## Sample 2
Audio settings example.

Demonstrates:
- Reusable creators/helpers
- Sliders
- Labels
- Generic callbacks
- Scalable UI architecture

## Sample 3
Complete pause/settings menu.

Demonstrates:
- Nested layouts
- Multiple panels
- Buttons
- Textboxes
- Checkboxes
- Dropdowns
- Visibility groups/classes
- Real-world UI organization

---

# Philosophy

This framework was created with modularity and scalability in mind.

The goal is to make UI creation:

- Reusable
- Readable
- Flexible
- Easy to organize
- Easy to expand

The framework encourages the use of:

- Generic creators
- Reusable callbacks
- UI composition
- Hierarchical layouts

---

# Installation

1. Import the framework into your GameMaker project.
2. Import the sample assets if desired.
3. Create UINodes using `UINode_create()`.

---

# Basic Example

```gml
var panel = {
    sprite: spr_painel,

    width: "50%",
    height: "50%",

    justify_content: JUSTIFY_CONTENT.CENTER,
    align_items: ALIGN_ITEMS.CENTER,

    p_all: 10
}

main_panel = UINode_create(UINodeType.PANEL, panel)
```

---

# Notes

- This project is currently in early development.
- APIs and internal behavior may change in future versions.
- Some features may still contain bugs or inconsistencies.

---

# License

This project is open for use and modification.

You may:
- Use the framework in personal projects
- Use the framework in commercial projects
- Modify the framework
- Share modified versions

Credits to the original project are appreciated.

---

# Version

Current Version: `0.1.0`

---

# Contact

For feedback, bug reports, or suggestions:

- GitHub Issues
- Email contact

---

# Credits

Created by Felipe Augusto.

