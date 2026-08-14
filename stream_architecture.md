# Stream Architecture: Secure Media Delivery via Cloudflare Workers + Jellyfin

> For the Ident/Hugo Blog Project on sydneytech.org
> Version: 1.0 | Date: August 2026

---

## Overview

This document describes the secure media streaming architecture for serving audio and video content to authenticated readers ("Members" and "Insiders") without violating Cloudflare Terms of Service.

The architecture leverages:
- **Cloudflare Access** for identity verification (email gate)
- **Cloudflare Workers** as a reverse proxy with Access cookie validation
- **Cloudflare Tunnel** for secure connectivity to local Jellyfin
- **Jellyfin's adaptive streaming** (HLS/DASH) for optimal playback

---

## Architecture Diagram

┌─────────────────────────────────────────────────────────────────────────────┐ │ READER (Browser) │ └─────────────────────────────────────────────────────────────────────────────┘ │ ▼ ┌─────────────────────────────────────────────────────────────────────────────┐ │ Cloudflare Edge Network │ │ ┌─────────────────────────────────────────────────────────────────────┐ │ │ │ blog.sydneytech.org (Hugo) │ │ │ │ ┌─────────────┐ │ │ │ │ │ Access Gate │ (Email OTP) │ │ │ │ └──────┬──────┘ │ │ │ └────────────────────────────────│───────────────────────────────────────┘ │ │ │ │ │ ▼ │ │ ┌─────────────────────────────────────────────────────────────────────┐ │ │ │ stream.sydneytech.org (Worker) │ │ │ │ ┌─────────────────────────────────────────────────────────────┐ │ │ │ │ │ Worker Script │ │ │ │ │ │ 1. Validate Access Cookie (CF-Access-Audience JWT) │ │ │ │ │ │ 2. Check Content Tier (Member vs Insider) │ │ │ │ │ │ 3. Proxy request to Jellyfin Tunnel │ │ │ │ │ │ 4. Stream response back with proper headers │ │ │ │ │ └─────────────────────────────────────────────────────────────┘ │ │ │ └─────────────────────────────────────────────────────────────────────┘ │ └─────────────────────────────────────────────────────────────────────────────┘ │ │ (Cloudflare Tunnel) ▼ ┌─────────────────────────────────────────────────────────────────────────────┐ │ Local Infrastructure │ │ ┌─────────────────────────────────────────────────────────────────────┐ │ │ │ Jellyfin Media Server │ │ │ │ ┌─────────────────────────────────────────────────────────────┐ │ │ │ │ │ - Adaptive Bitrate Streaming (HLS/DASH) │ │ │ │ │ │ - No per-user accounts (Access handles auth) │ │ │ │ │ │ - Content organized: /media/member/* and /media/insider/* │ │ │ │ │ └─────────────────────────────────────────────────────────────┘ │ │ │ └─────────────────────────────────────────────────────────────────────┘ │ └─────────────────────────────────────────────────────────────────────────────┘


---

## Component Breakdown

### 1. Cloudflare Access (Identity Layer)

**Purpose:** Authenticate readers without managing Jellyfin user accounts.

**Setup:**
Zero Trust → Access → Applications ├── Application: "Ident Blog" │ └── Domain: blog.sydneytech.org │ └── Policy: Allow → Email: [member emails] │ └── Application: "Ident Stream" └── Domain: stream.sydneytech.org └── Policy: Allow → Email: [member + insider emails]


**Access Levels:**
| Tier | Policy Rule | Content Access |
|------|-------------|----------------|
| **Public** | No Access required | Hugo blog text only |
| **Member** | Email in policy | /member/* streams |
| **Insider** | Email in insider list | /member/* + /insider/* |

**Manual Onboarding:**
1. Reader emails ben@sydneytech.org requesting access
2. Admin manually adds email to appropriate Access policy
3. Reader receives Access PIN on next login attempt

---

### 2. Cloudflare Worker (Proxy Layer)

**Purpose:** Validate Access tokens and proxy media requests to Jellyfin.

**Route:** `stream.sydneytech.org/*`

**Core Logic:**

```javascript
// worker.js - stream_architecture
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // ─────────────────────────────────────────
    // STEP 1: Validate Access Cookie
    // ─────────────────────────────────────────
    const accessCookie = request.headers.get('CF-Access-Audience');
    // Or parse JWT from CF-Authorization cookie
    
    const isAuthenticated = await validateAccessToken(request);
    if (!isAuthenticated) {
      return Response.redirect(
        'https://blog.sydneytech.org/cdn-cgi/access/login?redirect=' + 
        encodeURIComponent(url.toString()),
        302
      );
    }
    
    // ─────────────────────────────────────────
    // STEP 2: Extract User Claims from JWT
    // ─────────────────────────────────────────
    const userEmail = extractEmailFromJWT(request);
    const userTier = determineTier(userEmail); // 'member' | 'insider'
    
    // ─────────────────────────────────────────
    // STEP 3: Content Tier Authorization
    // ─────────────────────────────────────────
    const requestedPath = url.pathname;
    
    if (requestedPath.startsWith('/insider/') && userTier !== 'insider') {
      return new Response(
        'Forbidden: Insider content requires elevated access',
        { status: 403, headers: { 'Content-Type': 'text/plain' } }
      );
    }
    
    // ─────────────────────────────────────────
    // STEP 4: Proxy to Jellyfin
    // ─────────────────────────────────────────
    // Map URL to Jellyfin internal path
    const jellyfinPath = mapToJellyfinPath(requestedPath, userTier);
    const jellyfinUrl = env.JELLYFIN_INTERNAL_URL + jellyfinPath;
    
    // Forward request with streaming-friendly headers
    const proxyRequest = new Request(jellyfinUrl, {
      method: request.method,
      headers: {
        ...request.headers,
        'Host': env.JELLYFIN_HOST,
        // Strip Cloudflare-specific headers that might confuse Jellyfin
        'CF-Connecting-IP': null,
      },
    });
    
    const response = await fetch(proxyRequest);
    
    // ─────────────────────────────────────────
    // STEP 5: Return Stream with Proper Headers
    // ─────────────────────────────────────────
    const corsHeaders = {
      'Access-Control-Allow-Origin': 'https://blog.sydneytech.org',
      'Access-Control-Allow-Credentials': 'true',
    };
    
    return new Response(response.body, {
      status: response.status,
      headers: {
        ...Object.fromEntries(response.headers),
        ...corsHeaders,
        // Ensure range requests work for adaptive streaming
        'Accept-Ranges': 'bytes',
      },
    });
  }
};

// Helper: Validate JWT from Access
async function validateAccessToken(request) {
  // Cloudflare Access signs JWTs with keys available at:
  // https://<team-name>.cloudflareaccess.com/cdn-cgi/access/certs
  // Use a JWT library (like jose) to verify signature
  const jwt = extractJWTFromCookie(request);
  if (!jwt) return false;
  
  // Verify against Access public keys
  // Return true if valid and not expired
  return verifyJWT(jwt, env.ACCESS_CERTS_URL);
}

// Helper: Map public paths to Jellyfin paths
function mapToJellyfinPath(publicPath, userTier) {
  // Example mappings:
  // /member/episode1.m3u8 → /Videos/Member/episode1/master.m3u8
  // /insider/bonus.mp4 → /Videos/Insider/bonus/bonus.mp4
  
  if (publicPath.startsWith('/member/')) {
    return publicPath.replace('/member/', '/Videos/Member/');
  }
  if (publicPath.startsWith('/insider/')) {
    return publicPath.replace('/insider/', '/Videos/Insider/');
  }
  return publicPath;
}
Worker Environment Variables:

toml

Copy
# wrangler.toml
[env.production]
name = "ident-stream-proxy"

[env.production.vars]
JELLYFIN_INTERNAL_URL = "http://localhost:8096"  # Or tunnel internal URL
JELLYFIN_HOST = "jellyfin.internal"
ACCESS_TEAM_NAME = "sydneytech"
ACCESS_CERTS_URL = "https://sydneytech.cloudflareaccess.com/cdn-cgi/access/certs"
3. Cloudflare Tunnel (Connectivity Layer)
Purpose: Securely expose Jellyfin to Cloudflare without public IP or firewall rules.

Setup:

yaml

Copy
# config.yml for cloudflared
tunnel: <TUNNEL_ID>
credentials-file: /home/user/.cloudflared/<TUNNEL_ID>.json

ingress:
  # Route requests to Jellyfin
  - hostname: internal-media.sydneytech.org
    service: http://localhost:8096
    
  # Catch-all (required)
  - service: http_status:404
Important Security Settings:

Disable public DNS: Do not create a public DNS record for internal-media.sydneytech.org
Access Policy: Set to "Deny All" or leave unassigned - only the Worker should access this
Tunnel-Only: The Worker connects through the tunnel, not direct public access
4. Jellyfin Media Server (Content Layer)
Purpose: Host and transcode media with adaptive bitrate streaming.

Configuration:

Jellyfin Settings
├── Playback → Streaming
│   └── Enable: Allow transcoding
│   └── Hardware acceleration: (configure if available)
│
├── Library Structure
│   ├── /media/member/      # Member-accessible content
│   │   ├── ident-podcast/
│   │   ├── chapter-audio/
│   │   └── teasers/
│   │
│   └── /media/insider/     # Insider-only content
│       ├── early-releases/
│       ├── author-commentary/
│       └── bonus-material/
│
└── Users → No additional users needed
    └── Default admin only (for management)
    └── Access control handled at Cloudflare layer
Adaptive Streaming: Jellyfin automatically creates HLS (.m3u8) and DASH (.mpd) manifests for browser playback.
