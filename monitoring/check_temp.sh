#!/bin/bash

WEBHOOK_URL="${DISCORD_WEBHOOK_URL:?DISCORD_WEBHOOK_URL not set}"

TEMP=$(sensors | awk '/Core 0/ {gsub("\\+|°C","",$3); print int($3)}')

WARN=75
CRIT=85

TEMP=$(sensors | awk '/Core 0/ {gsub("\\+|°C","",$3); print int($3)}')

WARN=75
CRIT=85

if [ "$TEMP" -ge "$CRIT" ]; then
  curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"content\":\"🔥 **CRITICAL**: Server CPU temperature ${TEMP}°C — SHUTTING DOWN\"}" \
    "$WEBHOOK_URL"

  sudo /sbin/shutdown now

elif [ "$TEMP" -ge "$WARN" ]; then
  curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"content\":\"⚠️ **WARNING**: Server CPU temperature ${TEMP}°C\"}" \
    "$WEBHOOK_URL"
fi

