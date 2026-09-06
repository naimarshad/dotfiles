#!/usr/bin/env bash
# Rotating wallpaper via Unsplash API + awww.
# Cycles randomly through: space, technology, nasa, nature, city
#
# Setup:
#   1. Get a free key at https://unsplash.com/developers (New Application)
#   2. mkdir -p ~/.config/secrets && echo "YOUR_ACCESS_KEY" > ~/.config/secrets/unsplash-key
#      (deliberately OUTSIDE ~/.config/niri, which is a stow symlink into the public dotfiles repo)
#
# Log: ~/.cache/wallpapers/wallpaper.log

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpapers"
KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/secrets/unsplash-key"
LOG="$CACHE_DIR/wallpaper.log"
LOCK_FILE="/tmp/wallpaper-niri.lock"
mkdir -p "$CACHE_DIR"

log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

# Single-instance guard — kill any previous instance before starting
if [ -f "$LOCK_FILE" ]; then
    OLD_PID=$(cat "$LOCK_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        log "replacing old instance (PID $OLD_PID)"
        kill "$OLD_PID" 2>/dev/null
        sleep 0.5
    fi
fi
echo $$ > "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

TOPICS=("space" "technology" "nasa" "nature" "city")

log "wallpaper.sh started (PID $$)"

if [ ! -f "$KEY_FILE" ]; then
    log "ERROR: $KEY_FILE not found — create it with your Unsplash access key"
    exit 1
fi
UNSPLASH_KEY=$(cat "$KEY_FILE" | tr -d '[:space:]')

# Wait for awww daemon to be ready (up to 60s)
for i in $(seq 1 120); do
    awww query &>/dev/null && break
    sleep 0.5
done

if ! awww query &>/dev/null; then
    log "ERROR: awww-daemon not ready after 60s, exiting"
    exit 1
fi

log "awww-daemon ready"

fetch_and_set() {
    local topic="${TOPICS[$RANDOM % ${#TOPICS[@]}]}"
    local file="$CACHE_DIR/wallpaper-$(date +%s).jpg"

    log "fetching: topic=$topic"

    local response
    response=$(curl -fsSL --max-time 30 \
        "https://api.unsplash.com/photos/random?query=${topic}&orientation=landscape&client_id=${UNSPLASH_KEY}")

    if [ -z "$response" ]; then
        log "ERROR: empty response from Unsplash API"
        return 1
    fi

    local raw_url
    raw_url=$(printf '%s' "$response" | jq -r '.urls.raw // empty' 2>/dev/null)

    if [ -z "$raw_url" ]; then
        log "ERROR: could not parse Unsplash response (bad key or rate limit?)"
        log "response: $(echo "$response" | head -c 200)"
        return 1
    fi

    if curl -fsSL --max-time 60 \
        -o "$file" \
        "${raw_url}&w=3440&h=1440&fit=crop&fm=jpg&q=85"; then
        awww img "$file" \
            --transition-type fade \
            --transition-duration 1.5 \
            --transition-fps 100
        log "set: $file  (topic: $topic)"
        ls -t "$CACHE_DIR"/wallpaper-*.jpg 2>/dev/null | tail -n +11 | xargs -r rm
    else
        log "ERROR: image download failed"
        rm -f "$file"
    fi
}

fetch_and_set
while true; do
    sleep 300  # 5 minutes
    fetch_and_set
done
