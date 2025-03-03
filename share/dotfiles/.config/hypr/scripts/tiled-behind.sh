#!/bin/bash

# Get the current focused window and workspace
focused_window=$(hyprctl activewindow -j | jq -r '.address')
current_workspace=$(hyprctl activewindow -j | jq -r '.workspace.name')
echo "Focused window address: $focused_window, Workspace: $current_workspace" >&2

# Check if the focused window is maximized
maximized=$(hyprctl activewindow -j | jq -r '.fullscreen')
echo "Focused window is maximized: $maximized" >&2

# Get all windows in the current workspace
windows=$(hyprctl clients -j | jq -c --arg workspace "$current_workspace" '.[] | select(.workspace.name == $workspace)')
echo "Windows in current workspace: $windows" >&2

# Check if there are tiled windows behind the focused window
tiled_windows_behind=0
while IFS= read -r window; do
    window_state=$(echo "$window" | jq -r '.floating')
    window_address=$(echo "$window" | jq -r '.address')
    echo "Window address: $window_address, Floating: $window_state" >&2
    if [[ "$window_state" == "false" && "$window_address" != "$focused_window" ]]; then
        tiled_windows_behind=1
        break
    fi
done <<< "$windows"

echo "Tiled windows behind: $tiled_windows_behind" >&2

# If maximized and there are tiled windows behind, show indicator
if [[ "$maximized" -eq 1 && "$tiled_windows_behind" -eq 1 ]]; then
    echo '{"text": " ", "class": "tiled-behind"}'  # Nerdfont  
else
    echo '{"text": ""}'
fi
