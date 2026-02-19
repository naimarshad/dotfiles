#!/usr/bin/env bash

CACHE="/tmp/starship_cpu_cache"
NOW=$(date +%s)

# Read previous sample if exists
if [[ -f "$CACHE" ]]; then
  read -r PREV_TOTAL PREV_IDLE PREV_TIME <"$CACHE"
else
  PREV_TOTAL=0
  PREV_IDLE=0
  PREV_TIME=0
fi

# Read current CPU stats
read -r _ USER NICE SYSTEM IDLE IOWAIT IRQ SOFTIRQ STEAL _ </proc/stat

TOTAL=$((USER + NICE + SYSTEM + IDLE + IOWAIT + IRQ + SOFTIRQ + STEAL))
IDLE_ALL=$((IDLE + IOWAIT))

# Compute only if previous sample exists and at least 1s passed
if [[ $PREV_TOTAL -ne 0 && $((NOW - PREV_TIME)) -ge 1 ]]; then
  DIFF_TOTAL=$((TOTAL - PREV_TOTAL))
  DIFF_IDLE=$((IDLE_ALL - PREV_IDLE))

  if [[ $DIFF_TOTAL -gt 0 ]]; then
    CPU=$(((100 * (DIFF_TOTAL - DIFF_IDLE)) / DIFF_TOTAL))
    echo " ${CPU}%"
  fi
fi

# Store new values
echo "$TOTAL $IDLE_ALL $NOW" >"$CACHE"
