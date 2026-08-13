# Cloudflare Hugo Blog Setup Guide

> **Status**: Live on https://www.sydneytech.org  
> **Created**: August 13, 2026  
> **Stack**: Hugo + PaperMod + Cloudflare Pages + Cloudflare Access (Email Gate)

---

## Objective

Set up a daily blogging platform that feels as easy as WhatsApp clips, with embedded media (video/audio) and email-gated access. Used sydneytech.org as a sandbox before deploying to personal domains.

---

## Phase 1: Cloudflare Cleanup

### 1.1 Delete Old Projects
- **Workers and Pages**: Deleted self_rss Pages project
  - Removed custom domains first (required before deleting project)
  - Then deleted the project itself via Settings
- **Zero Trust Access**: Deleted old applications (Pod Rss Access, Friend Wall)
- **Policies**: Removed orphaned policies

### 1.2 Clean DNS Records for sydneytech.org

| Record | Action | Reason |
|--------|--------|--------|
| MX records (Google) | KEEP | Email routing |
| TXT SPF/DKIM | KEEP | Email authentication |
| NS records | KEEP | Nameservers |
| A record (192.53.168.59) | DELETE | Old hosting |
| AAAA record | DELETE | Old IPv6 |
| CNAME _domainconnect (Squarespace) | DELETE | Leftover from registration |
| CNAME www | DELETE | Will replace with Pages |

---

## Phase 2: Hugo Blog Setup (Local)

### 2.1 Prerequisites
- Linux Mint 22 Cinnamon
- Hugo 0.146.0+ (upgraded from 0.123.7)
  - Installed via .deb package from GitHub releases
  - After install, run: `hash -r` (to clear shell path cache)
- Git with multi-account .gitconfig setup
- SSH key at ~/.ssh/sydneytech for GitHub

### 2.2 Create Hugo Site
```bash
hugo new site sydneytech-blog
cd sydneytech-blog
git init

# Add PaperMod theme
git submodule add https://github.com/adityatelange/hugo-PaperMod themes/PaperMod
```

Create hugo.toml:
```toml
baseURL = 'https://www.sydneytech.org'
languageCode = 'en-us'
title = 'Sydney Tech Blog'
theme = 'PaperMod'

[params]
  ShowReadingTime = true
  ShowPostNavLinks = true
  ShowBreadCrumbs = true
```

### 2.3 Create Posts
```bash
# Always use hugo new to generate correct front matter
hugo new posts/YYYY-MM-DD-title.md
```

Hugo generates TOML front matter (+++ delimiters) by default:
```toml
+++
title = 'My Post'
date = 2026-08-13T10:51:04+10:00
draft = false
+++

Post content goes here...
```

**IMPORTANT**: Always use `hugo new` (not a text editor) to create posts.
Mixing YAML (---) and TOML (=) syntax causes build errors.

### 2.4 Test Locally
```bash
hugo server -D
# Visit http://localhost:1313
```

### 2.5 Git and GitHub Setup

Multi-account SSH setup in ~/.ssh/config:
```
Host github.com-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/sydneytech
  IdentitiesOnly yes
```

Per-project identity in ~/projects/personal/.gitconfig:
```toml
[user]
  email = your@gmail.com
  name = Your Name
```

Push to GitHub:
```bash
git add .
git commit -m 'Initial Hugo + PaperMod setup'
git branch -M main
git remote add origin git@github.com:BernardBurke/sydneytech-blog.git
git push -u origin main
```

Note: Create the GitHub repo first (github.com/new) as an empty private repo.

---

## Phase 3: Deploy to Cloudflare Pages

### 3.1 Navigate to Pages (not Workers)
1. Go to Cloudflare Dashboard -> Workers and Pages
2. Click **Create application**
3. **QUIRK**: You land on the Workers screen by default
4. Look for tiny text at bottom: 'Looking to deploy Pages? Get started'
5. Click **Get started** to enter the Pages flow

### 3.2 Connect GitHub Repository
1. Click **Pages -> Connect to Git**
2. Select GitHub account (BernardBurke)
3. **QUIRK**: New repos don't auto-appear in the dropdown
4. Use the **search bar** and type the repo name (sydneytech-blog)
5. It will appear with a checkmark - select it
6. Click **Begin Setup**

### 3.3 Configure Build Settings
- **Project name**: sydneytech-blog
- **Production branch**: main
- **Build command**: `hugo build --gc --minify`
- **Build output directory**: `public`
- Click **Save and Deploy**

### 3.4 Add Custom Domain
1. In Pages project -> **Settings -> Domains and Routes**
2. Click **Add custom domain**
3. Enter: `www.sydneytech.org`
4. Cloudflare auto-creates DNS CNAME record
5. Wait 1-2 minutes, then visit https://www.sydneytech.org

---

## Phase 4: Cloudflare Access (Email Gate)

### 4.1 Navigate to Access Applications
Zero Trust -> Access -> Applications

### 4.2 Add New Application
1. Click **Add an application**
2. Choose **Self-hosted**
3. You land on the Application Details screen

### 4.3 Configure Destination
Under **Public hostnames**:
- **Subdomain**: `www`
- **Domain**: `sydneytech.org` (select from dropdown)
- **Path**: leave blank

### 4.4 Create Access Policy
In the **Access policies** section:
1. Click **Create new policy**
2. **Policy name**: `Blog Access`
   - **QUIRK**: When you select Email as rule type, Cloudflare auto-renames
     the policy to your email address. This is confusing but harmless.
3. **Action**: Allow
4. Under **Include**:
   - Type: Emails
   - Value: your@email.com
5. Click **Save policy**

### 4.5 Save the Application
**QUIRK**: The final button says **Create**, not Save.
This is confusing because it sounds like creating a new app.
It actually commits and saves everything.

1. Scroll to the bottom of the page
2. Click **Create**
3. You are redirected to the Applications list
4. Your app should appear with www.sydneytech.org

### 4.6 Test the Email Gate
1. Visit https://www.sydneytech.org
2. You should see the Cloudflare Access login page
3. Enter your email -> receive magic link -> click to log in
4. You now have access to the blog

---

## Cloudflare Quirks Reference

| Quirk | What Happens | Solution |
|-------|-------------|----------|
| Pages vs Workers UI | Default screen is Workers, not Pages | Look for 'Looking to deploy Pages? Get started' at bottom |
| Repo not in dropdown | New repos don't auto-appear | Search by name in search bar |
| Policy auto-rename | Email rule renames policy to your email | Harmless, ignore it |
| Create vs Save | Final button says Create not Save | It saves everything - click it |
| No back button | Navigating away loses all changes | Complete the flow in one session |
| GitHub permissions | Cloudflare only sees previously connected repos | Search for repo name to find new ones |
| Hugo path cache | After upgrading Hugo, old path still cached | Run: `hash -r` |
| Front matter format | Hugo generates TOML (+++) not YAML (---) | Always use `hugo new` to create posts |

---

## Daily Posting Workflow

```bash
cd ~/projects/personal/sydneytech-blog

# Create new post
hugo new posts/$(date +%Y-%m-%d)-title.md

# Edit the post
nano content/posts/YYYY-MM-DD-title.md
# Set draft = false, add content

# Preview locally (optional)
hugo server -D

# Publish
git add .
git commit -m 'daily post'
git push
# Live in ~30 seconds
```

---

## File Structure

```
sydneytech-blog/
├── content/
│   └── posts/
│       └── YYYY-MM-DD-post-name.md
├── themes/
│   └── PaperMod/  (git submodule - never edit directly)
├── layouts/       (override theme files here only)
├── static/        (images, files)
├── hugo.toml
└── .gitmodules
```

---

## Next Steps: Media with Jellyfin

### Option A: Cloudflare Tunnel (Recommended)
```bash
# Install cloudflared on home machine
# Create tunnel pointing to Jellyfin (default port 8096)
cloudflared tunnel --url http://localhost:8096
# Expose as media.sydneytech.org
# Add Cloudflare Access to media subdomain
```

### Option B: Tailscale Funnel
- Create a separate Tailscale account for blog infrastructure
- Join Jellyfin machine to that tailnet
- Use Tailscale Funnel for public URL
- Clean separation from personal Tailscale network

### Embedding Media in Posts
```html
<video controls>
  <source src='https://media.sydneytech.org/Items/xxx/Download' type='video/mp4'>
</video>
```

---

## Domain Roadmap

| Domain | Purpose | Status |
|--------|---------|--------|
| sydneytech.org | Hugo blog sandbox | LIVE |
| benburke.org | Personal Hugo blog | Outdated, needs update |
| leonardkoan.net | Poetry + Hugo blog | Future |
| benburke.dev | Google Workspace | Keep |
| sydneytech.net | Tunnel experiments | Delete eventually |

---

## Useful Links

- Cloudflare Pages Docs: https://developers.cloudflare.com/pages/
- Hugo Docs: https://gohugo.io/
- PaperMod Theme: https://github.com/adityatelange/hugo-PaperMod
- Cloudflare Access Docs: https://developers.cloudflare.com/cloudflare-one/
- Cloudflare Tunnel Docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/

---

*Last updated: August 13, 2026*
*Author: Ben Burke*
