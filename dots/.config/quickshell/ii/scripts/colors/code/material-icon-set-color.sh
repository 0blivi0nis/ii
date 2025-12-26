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

new_color=$(jq -r '.primary' "$COLOR_FILE_PATH")

for CODE_SETTINGS_PATH in "${settings_paths[@]}"; do
    if [[ -f "$CODE_SETTINGS_PATH" ]]; then
        if grep -q '"material-icon-theme.rootFolders.color"' "$CODE_SETTINGS_PATH"; then
            sed -i -E \
                "s/(\"material-icon-theme.rootFolders.color\"\s*:\s*\")[^\"]*(\")/\1${new_color}\2/" \
                "$CODE_SETTINGS_PATH"
        else
            sed -i '$ s/}/,\n  "material-icon-theme.rootFolders.color": "'${new_color}'"\n}/' "$CODE_SETTINGS_PATH"
            sed -i '$ s/,\n,/,/' "$CODE_SETTINGS_PATH"
        fi

        if grep -q '"material-icon-theme.folders.color"' "$CODE_SETTINGS_PATH"; then
            sed -i -E \
                "s/(\"material-icon-theme.folders.color\"\s*:\s*\")[^\"]*(\")/\1${new_color}\2/" \
                "$CODE_SETTINGS_PATH"
        else
            sed -i '$ s/}/,\n  "material-icon-theme.folders.color": "'${new_color}'"\n}/' "$CODE_SETTINGS_PATH"
            sed -i '$ s/,\n,/,/' "$CODE_SETTINGS_PATH"
        fi

        if grep -q '"material-icon-theme.files.color"' "$CODE_SETTINGS_PATH"; then
            sed -i -E \
                "s/(\"material-icon-theme.files.color\"\s*:\s*\")[^\"]*(\")/\1${new_color}\2/" \
                "$CODE_SETTINGS_PATH"
        else
            sed -i '$ s/}/,\n  "material-icon-theme.files.color": "'${new_color}'"\n}/' "$CODE_SETTINGS_PATH"
            sed -i '$ s/,\n,/,/' "$CODE_SETTINGS_PATH"
        fi
    fi
done
