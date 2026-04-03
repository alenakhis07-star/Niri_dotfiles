#!/usr/bin/env bash

if pidof rofi > /dev/null; then
    pkill rofi
fi

wallpapers_dir="$HOME/Pictures/Wallpapers"

selected_wallpaper=$(for a in "$wallpapers_dir"/*; do
    echo -en "$(basename "${a%.*}")\0icon\x1f$a\n"
done | rofi -dmenu -p " ")

[[ -z "$selected_wallpaper" ]] && exit 0

image_fullname_path=""
for ext in png jpg jpeg webp gif; do
    candidate="$wallpapers_dir/$selected_wallpaper.$ext"
    if [[ -f "$candidate" ]]; then
        image_fullname_path="$candidate"
        break
    fi
done

[[ -z "$image_fullname_path" ]] && exit 1

pkill -x swaybg
swaybg -i "$image_fullname_path" &

