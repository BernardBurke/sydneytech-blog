---
title: "Sovereign Publishing Architecture: A Guide to the Static Web"
date: 2026-08-18T09:30:00+10:00
draft: false
tags: ["architecture", "hugo", "cloudflare", "self-hosting", "un-platforming"]
---

## Introduction: Why I Created This Project

The modern web has become a landscape of walled gardens, bloated content management systems, and fragile platforms. For years, the default advice for anyone wanting to share their thoughts online was to spin up a WordPress instance or pay a monthly subscription for a platform like Ghost. 

While these platforms offer convenience, that convenience comes at a steep cost:

1. **Security:** Dynamic platforms require databases, PHP runtimes, and a never-ending cycle of plugin updates. This creates a massive attack surface. A forgotten update often leads to a compromised site.
2. **Data Ownership and Portability:** Your content is trapped in proprietary databases. Moving your digital life elsewhere often requires complex database dumps and migrations.
3. **Recurring Costs:** Hosting dynamic sites, paying for premium platform tiers, or renting specialized media servers adds up quickly.

This project is a blueprint for **un-platforming**. It is a return to a resilient, independent, and secure web. By decoupling the content generation from the hosting infrastructure, we can build a publishing framework that is almost infinitely scalable, deeply secure, and costs virtually nothing beyond the annual price of a domain name. 

This architecture uses a Static Site Generator (Hugo) combined with modern edge-computing (Cloudflare Pages) and object storage (Cloudflare R2). The result is a lightning-fast, zero-maintenance blog with robust media embedding capabilities. Your words are stored as plain text. Your media is stored independently. You own the stack.

---

## High-Level Architecture

This framework operates on a continuous deployment model. You write on your local machine, and the cloud handles the global distribution automatically.

* **Content Generation (Hugo):** All posts are written in standard Markdown. Hugo compiles these text files into raw, static HTML/CSS in milliseconds.
* **Version Control (Git/GitHub):** The entire website serves as a Git repository. Every post, edit, and configuration change is tracked, versioned, and securely backed up.
* **Hosting and Edge Delivery (Cloudflare Pages):** Pushing a commit to GitHub automatically triggers a build on Cloudflare's edge network. The static HTML is distributed globally. Because there is no database or runtime server, the attack surface is effectively zero.
* **Media Storage (Cloudflare R2):** Video and audio files are heavy and historically difficult to host cheaply. Cloudflare R2 provides AWS S3-compatible object storage with zero egress fees. Media is hosted independently of the text and streamed directly to the user.

---

## Core Features

### 1. Performant, Responsive Media Embedding
Traditional static sites struggle with large media files. This framework solves this by leveraging custom Hugo shortcodes that inject fluid, 16:9 responsive HTML5 video and audio players. 
* **Self-Hosted Media:** MP4 and MP3 files are fetched directly from the R2 bucket using byte-range requests, allowing instant playback and scrubbing without downloading the entire file.
* **YouTube Timestamps:** A lightweight YouTube embed shortcode allows authors to specify precise `start` and `end` times for curated external clips, utilizing privacy-enhanced domains.

### 2. Multi-Tenant Media Storage
A single Cloudflare R2 bucket can serve multiple independent blogs simultaneously. By segregating media into folders (e.g., `/sydneytech/`, `/benburke/`) and configuring a unified CORS policy, a single centralized media repository can power an entire portfolio of websites.

### 3. Command-Line Media Sync
Media files are managed locally and pushed to the cloud using `rclone`. A single terminal command syncs local directories directly to the R2 bucket, keeping the Git repository lightweight while ensuring media is perfectly mapped to the web infrastructure.

### 4. Zero-Trust Access (Optional)
Because the core site is hosted on Cloudflare, specific domains or sub-paths can be placed behind Cloudflare Access. This allows for email-based One-Time Passwords (OTP) to restrict access to the blog, while the R2 media subdomain remains unauthenticated to allow seamless HTML5 media streaming to authorized viewers.
