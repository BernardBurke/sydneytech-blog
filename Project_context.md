# Project Context: Hugo + Cloudflare Pages & R2 Media Setup

## 1. Overview & Architecture
* **Static Site Generator:** Hugo (with `PaperMod` theme).
* **Hosting / CI/CD:** Cloudflare Pages repository (`BernardBurke/sydneytech-blog`).
* **Media Storage:** Cloudflare R2 bucket (`shared-media-bucket`) exposed via custom subdomain `media.sydneytech.org`.
* **Primary Domain:** `https://www.sydneytech.org`
* **Planned Additional Sites (sharing the same R2 bucket):** `benburke.org`, `leonardkoan.net`.
* **Access Control:** Cloudflare Access (Zero Trust email OTP) secures `sydneytech.org`. The R2 domain `media.sydneytech.org` is excluded from Access policies to allow direct cross-origin HTML5 media streaming.

---

## 2. Implemented Configurations & Shortcodes

### `hugo.toml`
```toml
[params.media]
  r2BaseUrl = "[https://media.sydneytech.org](https://media.sydneytech.org)"
```

# R2 Bucket CORS Policy
Configured in Cloudflare R2 Settings to allow browser-based media streaming from live sites, preview environments, and local testing:

[
  {
    "AllowedOrigins": [
      "[https://sydneytech.org](https://sydneytech.org)",
      "[https://www.sydneytech.org](https://www.sydneytech.org)",
      "[https://benburke.org](https://benburke.org)",
      "[https://www.benburke.org](https://www.benburke.org)",
      "[https://leonardkoan.net](https://leonardkoan.net)",
      "[https://www.leonardkoan.net](https://www.leonardkoan.net)",
      "http://localhost:1313",
      "https://*.pages.dev"
    ],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["Accept-Ranges", "Content-Range", "Content-Length"]
  }
]

# Layouts & Styling (PaperMod)
{{ $mediaCss := resources.Get "css/media-embeds.css" | minify | fingerprint }}
<link rel="stylesheet" href="{{ $mediaCss.RelPermalink }}" integrity="{{ $mediaCss.Data.Integrity }}">

#Shortcodes (layouts/shortcodes/)
yt.html: YouTube embed with id, start, end, and title parameters using youtube-nocookie.com.

r2-video.html: HTML5 <video controls playsinline preload="metadata"> targeting $baseUrl/$src.

r2-audio.html: HTML5 <audio controls preload="metadata"> targeting $baseUrl/$src.

3. Cloudflare Pages Deployment Pipeline
GitHub Integration: Connected via GitHub App to BernardBurke/sydneytech-blog.

Preview Build Command: hugo build --gc --minify -b $CF_PAGES_URL (ensures preview branches map internal links to *.pages.dev instead of the production domain).

Production Branch: main auto-deploys to www.sydneytech.org.

4. Operational Workflow
Optimize Media: ffmpeg -i input.mp4 -c copy -movflags +faststart output.mp4

Sync to R2: rclone sync ~/Videos/blog-media/ cloudflare-r2:shared-media-bucket/test/ -P

Draft Post: Embed media via {{< r2-video src="test/filename.mp4" >}} or {{< yt id="ID" start="10" end="30" >}}.

Deploy: Commit and push to main on GitHub to trigger Cloudflare Pages build.

5. Current Status
Local testing and production build pipelines are fully operational.

Video playback and responsive shortcodes verified live on sydneytech.org.

Ready for routine content creation, media uploads, or multi-site scaling.
