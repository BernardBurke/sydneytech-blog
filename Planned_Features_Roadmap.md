---
title: "Planned Features Roadmap: Unified Static Site Architecture"
date: 2026-08-18T10:00:00+10:00
draft: false
tags: ["architecture", "roadmap", "hugo", "cloudflare", "r2"]
---

Building a unified architecture for a portfolio of static sites drastically reduces maintenance overhead and keeps the codebase DRY (Don't Repeat Yourself). 

The most robust way to handle shared code across multiple Hugo blogs (SydneyTech, BenBurke, LeonardKoan) is by utilizing **Hugo Modules**, paired with a centralized local media ingestion folder managed by standard Linux bash scripting.

Here is the architectural blueprint to establish this baseline, along with strategies for future feature implementations.

---

## 1. The Media Baseline: Local Structure & Unified Ingest

Instead of managing media uploads from within each blog's repository, the media workflow is entirely decoupled. One master directory on the local machine exactly mirrors the R2 bucket.

### The Directory Structure
```text
~/projects/media-master/
├── .scripts/
│   └── ingest-and-sync.sh
├── sydneytech/
│   └── 2026/
├── benburke/
│   └── 2026/
└── leonardkoan/
    └── 2026/




Yes, absolutely. To make it as seamless as possible, I have formatted the architectural blueprint into a complete, standalone Markdown document with standard Hugo frontmatter.

You can copy the block below and paste it directly into a new file named `planned_features_roadmap.md` (for example, in a `/content/docs/` or `/content/posts/` folder, depending on where you want to keep your documentation).

```markdown
---
title: "Planned Features Roadmap: Unified Static Site Architecture"
date: 2026-08-18T10:00:00+10:00
draft: false
tags: ["architecture", "roadmap", "hugo", "cloudflare", "r2"]
---

Building a unified architecture for a portfolio of static sites drastically reduces maintenance overhead and keeps the codebase DRY (Don't Repeat Yourself). 

The most robust way to handle shared code across multiple Hugo blogs (SydneyTech, BenBurke, LeonardKoan) is by utilizing **Hugo Modules**, paired with a centralized local media ingestion folder managed by standard Linux bash scripting.

Here is the architectural blueprint to establish this baseline, along with strategies for future feature implementations.

---

## 1. The Media Baseline: Local Structure & Unified Ingest

Instead of managing media uploads from within each blog's repository, the media workflow is entirely decoupled. One master directory on the local machine exactly mirrors the R2 bucket.

### The Directory Structure
```text
~/projects/media-master/
├── .scripts/
│   └── ingest-and-sync.sh
├── sydneytech/
│   └── 2026/
├── benburke/
│   └── 2026/
└── leonardkoan/
    └── 2026/

```

### The Ingest & Sync Script (`ingest-and-sync.sh`)

This script crawls the master folder, finds any raw `.mp4` or `.mp3` files that haven't been processed, optimizes them for web streaming, and pushes the exact folder tree to the shared R2 bucket in a single command.

```bash
#!/usr/bin/env bash
set -e

MEDIA_DIR="$HOME/projects/media-master"
R2_REMOTE="cloudflare-r2:shared-media-bucket"

echo "==> Optimizing new video files for web streaming..."
# Finds mp4s without the faststart flag and processes them inplace
find "$MEDIA_DIR" -type f -name "*.mp4" | while read -r file; do
    if ! ffmpeg -v trace -i "$file" 2>&1 | grep -q "moov.*before mdat"; then
        echo "Processing: $file"
        ffmpeg -i "$file" -c copy -movflags +faststart "${file}.tmp.mp4" -hide_banner -loglevel error
        mv "${file}.tmp.mp4" "$file"
    fi
done

echo "==> Syncing all media to Cloudflare R2..."
rclone sync "$MEDIA_DIR" "$R2_REMOTE" --exclude ".scripts/**" -P

echo "==> Sync complete!"

```

---

## 2. The Code Baseline: Shared Hugo Modules

To share shortcodes, CSS, and partials across all three blogs without copying and pasting files, the architecture utilizes **Hugo Modules**. A separate Git repository handles all shared components.

### The Shared Repo Structure (`hugo-shared-components`)

```text
hugo-shared-components/
├── assets/
│   └── css/
│       └── media-embeds.css
├── layouts/
│   └── shortcodes/
│       ├── r2-video.html
│       ├── r2-audio.html
│       └── yt.html
└── go.mod

```

### Connecting the Blogs

In the `hugo.toml` of `sydneytech`, `benburke`, and `leonardkoan`, the shared media base URL is defined for that specific site, and the shared repository is imported:

```toml
[params.media]
  # For BenBurke.org, this points to its specific folder in the bucket
  r2BaseUrl = "[https://media.sydneytech.org/benburke](https://media.sydneytech.org/benburke)"

[module]
  [[module.imports]]
    path = "[github.com/BernardBurke/hugo-shared-components](https://github.com/BernardBurke/hugo-shared-components)"

```

During the Cloudflare Pages build process, the latest centralized shortcodes are automatically pulled from GitHub and injected into the build.

---

## 3. Future-Proofing: Members vs. Public Content

Handling two tiers of content (Public vs. Authenticated Members) on a static site requires executing logic at the edge using Cloudflare Workers.

1. **Hugo Generation:** Hugo is configured to output two versions of a post: a public teaser (`/posts/my-article/index.html`) and the full member version (`/members/posts/my-article/index.html`).
2. **Cloudflare Pages Middleware (Functions):** A `_middleware.ts` file acts as a gateway in the repository.
3. **The Logic:** When a visitor requests `/posts/my-article/`, the middleware checks for a valid Cloudflare Access JWT cookie.
* If the cookie exists (logged in via email OTP), the middleware silently fetches the file from the hidden `/members/` path and serves the full text.
* If there is no cookie, it serves the public teaser.



---

## 4. Future-Proofing: Comments

To implement comments without a traditional backend server, the architecture will utilize **Cloudflare D1** (Serverless SQLite built into the edge network).

* A **Cloudflare Pages Function** (e.g., `/api/comments`) is mapped to a D1 database.
* Blog posts contain a simple HTML form for logged-in members.
* Submitting the form triggers an asynchronous JavaScript call to the `/api/comments` endpoint, writing the comment to the SQLite database.
* Upon page load, a script fetches the comments from the API and renders them dynamically.

---

## 5. Media Archiving Strategy (10GB Threshold)

Cloudflare R2's free tier allows 10GB/month of storage. Overage costs are highly economical ($0.015 per GB per month). However, to maintain a strict zero-cost architecture:

1. Identify high-bandwidth, older videos.
2. Upload them to a free video hosting service (like YouTube) as "Unlisted".
3. Update the `{{< r2-video >}}` shortcode in those older markdown posts to the `{{< yt >}}` shortcode.
4. Delete the local `.mp4` file and run `ingest-and-sync.sh` to mirror the deletion to the R2 bucket.

```

```