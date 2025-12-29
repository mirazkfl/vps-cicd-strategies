#!/bin/bash
# /home/deploy/app/scripts/atomic_switch.sh

RELEASE_ID=$1
# Get the app root from the script's location (more reliable than $USER)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(dirname "$SCRIPT_DIR")"
NEW_RELEASE_PATH="$APP_ROOT/releases/$RELEASE_ID"

# 1. Update the Symlink
# 'ln -sfn' force-updates the link cleanly
echo "🔄 Switching 'current' symlink to $RELEASE_ID..."
ln -sfn "$NEW_RELEASE_PATH" "$APP_ROOT/current"

# 2. PM2 Reload
# We run PM2 from the 'current' folder, which now points to the new code
echo "🚀 Reloading Application..."
cd "$APP_ROOT/current"

# Ensure PM2 loads the correct environment variables
export NODE_ENV=production
pm2 reload ecosystem.config.js --update-env || pm2 start ecosystem.config.js

# 3. Cleanup Old Releases
echo "🧹 Cleaning up old releases (keeping last 5)..."
cd "$APP_ROOT/releases"
# Only cleanup if there are more than 5 releases
if [ $(ls -1t | wc -l) -gt 5 ]; then
    ls -1t | tail -n +6 | xargs -I {} rm -rf "{}"
fi

echo "✅ Atomic Deployment Complete: $RELEASE_ID"