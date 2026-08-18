#!/usr/bin/env bash
set -e

MEDIA_DIR="$HOME/Videos/blog-media"
R2_REMOTE="cloudflare-r2:shared-media-bucket/test"

echo "==> Syncing media to R2..."
rclone sync "$MEDIA_DIR" "$R2_REMOTE" -P

echo "==> Committing and pushing blog..."
git add .
git commit -m "${1:-content update}"
git push origin main

echo "==> Done! Cloudflare build triggered."