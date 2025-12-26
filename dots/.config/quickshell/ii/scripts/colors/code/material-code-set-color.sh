#!/usr/bin/env bash
COLOR_FILE_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/colors.json"

settings_paths=(
    "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Code - OSS/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Code - Insiders/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Antigravity/User/settings.json"
)

primary_color=$(jq -r '.primary' "$COLOR_FILE_PATH")
bg_color=$(jq -r '.background' "$COLOR_FILE_PATH")

for CODE_SETTINGS_PATH in "${settings_paths[@]}"; do
    if [[ -f "$CODE_SETTINGS_PATH" ]]; then
        if grep -q '"material-code.colors"' "$CODE_SETTINGS_PATH"; then
            sed -i -E \
                "s/(\"material-code.colors\"\s*:\s*\{ \"primary\"\s*:\s*\")[^\"]*(\", \"background\"\s*:\s*\")[^\"]*(\"\s*\})/\1${primary_color}\2${bg_color}\3/" \
                "$CODE_SETTINGS_PATH"
        else 
            # If the key is not already there, add the whole line at the end
            sed -i '$ s/}/,\n  "material-code.colors": { "primary": "'${primary_color}'", "background": "'${bg_color}'" }\n}/' "$CODE_SETTINGS_PATH"
            sed -i '$ s/,\n,/,/' "$CODE_SETTINGS_PATH"
        fi
    fi
done