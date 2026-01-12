#!/bin/bash
set -euo pipefail

uptime_human="$(uptime -p)"
load="$(cat /proc/loadavg | awk '{print $1" "$2" "$3}')"
mem="$(free -h | awk '/Mem:/ {print $3 "/" $2 " used"}')"
disk="$(df -h / | awk 'NR==2 {print $3 "/" $2 " used (" $5 ")"}')"

# Try to grab a CPU temp if sensors is available
temp="(temp N/A)"
if command -v sensors >/dev/null 2>&1; then
  # Works on many systems; if your label differs, we can adjust.
  t="$(sensors 2>/dev/null | awk '/Core 0/ {gsub("\\+|°C","",$3); print int($3); exit}')"
  if [ -n "${t:-}" ]; then temp="${t}°C"; fi
fi

#status
/home/mpy2005/discord_notify.sh "
Uptime: ${uptime_human}  
Load: ${load}  
RAM: ${mem}  
Disk(/): ${disk}  
CPU Temp: ${temp}"
