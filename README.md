# display-manager

Simple macOS display layout manager. Save and restore your multi-monitor configurations.

## Installation

```bash
# Compile
swiftc -O -o display-manager display-manager.swift -framework CoreGraphics -framework Foundation

# Install
sudo cp display-manager /usr/local/bin/
```

## Usage

```bash
# List current displays
display-manager list

# Save current layout
display-manager save work

# List saved layouts
display-manager layouts

# Apply a saved layout
display-manager apply work

# Delete a layout
display-manager delete work
```

## How it works

Layouts are stored in `~/.display-manager.json` as JSON.

## Requirements

- macOS
- Swift (included with Xcode Command Line Tools)