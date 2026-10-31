#!/bin/bash
# First-Time Launcher for AltKeysLite.app
# Clears macOS download quarantine attribute so Gatekeeper does not block opening, then launches AltKeysLite.app.

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/AltKeysLite.app"

if [ ! -d "$APP" ]; then
    echo "Error: Could not find AltKeysLite.app in $DIR"
    exit 1
fi

echo "Preparing AltKeysLite.app..."
xattr -cr "$APP" 2>/dev/null || true
chmod +x "$APP/Contents/MacOS/AltKeysLite" 2>/dev/null || true

echo "Launching AltKeysLite.app — look for ⌥ in your top macOS menu bar!"
open "$APP"
