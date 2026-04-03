#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This is for custom waybar idle inhibitor toggle on niri.

PROCESS="swayidle"
START_CMD=(swayidle -w "timeout 300 loginctl lock-session timeout 420 'niri msg action power-off-monitors' resume 'niri msg action power-on-monitors' timeout 600 'systemctl suspend'")

if [[ "$1" == "status" ]]; then
  sleep 1
  if pgrep -x "$PROCESS" >/dev/null; then
    echo '{"text": "RUNNING", "class": "active", "tooltip": "Idle timeout is enabled\nLeft Click: Disable\nRight Click: Lock Screen"}'
  else
    echo '{"text": "NOT RUNNING", "class": "notactive", "tooltip": "Idle timeout is disabled\nLeft Click: Enable\nRight Click: Lock Screen"}'
  fi
elif [[ "$1" == "toggle" ]]; then
  if pgrep -x "$PROCESS" >/dev/null; then
    pkill "$PROCESS"
  else
    "${START_CMD[@]}" >/dev/null 2>&1 &
  fi
else
  echo "Usage: $0 {status|toggle}"
  exit 1
fi
