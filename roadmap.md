# Project Roadmap: Ident Streaming Architecture

> **Project:** Ident (Speculative Fiction & Digital Identity Blog)  
> **Domain:** sydneytech.org (Sandbox Environment)  
> **Status:** Phase 1 Initiation  
> **Date:** August 2026

---

## Philosophy
*Validate interest and relationships before investing in infrastructure.*  
Start with a manual, low-cost setup. Upgrade only when the community demands it.  
*Thematic Alignment:* The "manual invite" process mirrors the *Ident* manuscript’s core conflict: **Fixed Bureaucratic Identity vs. Universal Relational Awareness**. We are building the network one relationship at a time.

---

## Phase 1: The "Sandbox" (Current Goal)
**Goal:** Test the concept, validate reader interest, and refine the workflow with **zero financial risk**.

### Infrastructure
- **Proxy:** Cloudflare Worker (free tier) acting as a reverse proxy for media requests.
- **Server:** Jellyfin media server running on a spare miniPC (local network).
- **Connectivity:** Cloudflare Tunnel (securely exposes Jellyfin to the Worker without public IP).
- **Authentication:** Cloudflare Access (Email OTP gate) on `sydneytech.org`.
- **Network:** No Tailscale yet. Direct connection via Cloudflare edge.

### Onboarding Workflow
1.  **Request:** Reader emails `ben@sydneytech.org` requesting access.
2.  **Verification:** Manual check (is this a real person? do they fit the "relational" criteria?).
3.  **Provisioning:**
    - Add email to **Cloudflare Access** policy (Member or Insider tier).
    - (Optional) Add to a "waiting list" for Phase 2 Tailscale invites.
4.  **Access:** Reader logs in with OTP and streams content via the Worker proxy.

### Content Strategy
- **Format:** Daily blog posts with embedded audio/video clips (Hugo shortcodes).
- **Storage:** All media hosted locally on Jellyfin.
- **Delivery:** Worker proxies requests, validates Access cookies, and streams content.

### Cost & Constraints
- **Cost:** **$0/month** (Cloudflare Free Tier).
- **Limits:** 
    - Worker request limits (generous, but monitored).
    - Jellyfin transcoding load (depends on miniPC specs).
    - **Manual overhead:** You are the "gatekeeper."

### Success Metrics (Phase 1)
- **Engagement:** Number of unique readers who successfully stream content.
- **Feedback:** Qualitative comments on video quality and ease of access.
- **Willingness:** Signs that readers value the content enough to ask for "more" or "better."

---

## Phase 2: The "Community" (Trigger: Strong Interest)
**Trigger:** You have >3 active readers, OR readers explicitly offer to contribute to hosting costs.

### Infrastructure Upgrades
- **Network:** Migrate to a dedicated **Tailscale** tailnet (`sydneytech.org`).
    - Upgrade to **Tailscale Personal** (unlimited users, ~$3–4/mo).
    - Invite readers to the tailnet for "direct mesh" streaming (bypasses Worker proxy for video).
- **Streaming:**
    - **Insider Content:** Remains on Jellyfin (secured by Tailscale ACLs).
    - **Polished Content:** Migrate finished episodes to **Bunny Stream** (pay-as-you-go, ~$0.01/GB) for better CDN performance.
- **Authentication:** Dual-layer (Cloudflare Access for blog login + Tailscale for network access).

### Onboarding Workflow
1.  **Request:** Reader emails `ben@sydneytech.org`.
2.  **Provisioning:**
    - Add to **Cloudflare Access** policy.
    - Send **Tailscale Invite** (if they are on the "Insider" list).
3.  **Access:** 
    - **Members:** Blog login only (Worker proxy).
    - **Insiders:** Blog login + Tailscale app installed (Direct P2P streaming).

### Cost & Constraints
- **Cost:** **~$3–5/month** (Tailscale + minimal Bunny usage).
- **Limits:** 
    - Tailscale user limit (removed with paid plan).
    - Bunny Stream bandwidth costs (scales with usage).

### Success Metrics (Phase 2)
- **Retention:** Do readers stay after the trial?
- **Contribution:** Willingness to pay/contribute (even $1/month per reader covers costs).
- **Automation:** Reduced manual overhead (Tailscale handles network auth, Bunny handles encoding).

---

## Phase 3: The "Network" (Future, Optional)
**Trigger:** Consistent revenue from readers or a large, stable audience.

### Infrastructure Vision
- **Automation:** Stripe/PayPal integration + automated Tailscale ACL updates.
- **Scale:** Dedicated VPS or managed Jellyfin instance for high-load transcoding.
- **Public Access:** Tailscale Funnel or Cloudflare Access for public-facing streaming (if desired).

### Onboarding Workflow
- **Self-Service:** Readers sign up, pay, and get instant access (API-driven).

### Cost & Constraints
- **Cost:** Variable (based on traffic and hosting).
- **Focus:** Shift from "manual curation" to "community scaling."

---

## Technical Architecture Summary

| Component | Phase 1 (Sandbox) | Phase 2 (Community) | Phase 3 (Network) |
|-----------|-------------------|---------------------|-------------------|
| **Auth** | Cloudflare Access (Email OTP) | Access + Tailscale ACLs | Automated (Stripe + API) |
| **Network** | Cloudflare Tunnel | Tailscale Mesh + Tunnel | Tailscale Funnel / VPS |
| **Proxy** | Cloudflare Worker (Video Proxy) | Direct P2P (Insiders) | Automated Load Balancer |
| **Storage** | Local Jellyfin | Jellyfin + Bunny Stream | Managed Storage / CDN |
| **Cost** | $0 | ~$3–5/mo | Variable |
| **Onboarding** | Manual Email | Manual Invite | Self-Service |

---

## Thematic Notes for the Author
- **The "Gatekeeper" Role:** In Phase 1, you are the manual gatekeeper. This is a deliberate design choice to reflect the *Ident* theme of **relational trust**. You are not an algorithm; you are a human curating a community.
- **Identity as a Journey:** Readers start as "Public" (text only), move to "Member" (video via proxy), and potentially to "Insider" (direct network access). This mirrors the protagonist's journey from bureaucratic identity to universal awareness.
- **The "WhoComm" Parallel:** The Tailscale tailnet is a real-world analog to the *Ident* "WhoComm" network. Inviting someone is an act of trust, not just a technical configuration.

---

## Next Steps (Immediate)
1.  [ ] **Deploy Phase 1:** Set up Cloudflare Tunnel to Jellyfin miniPC.
2.  [ ] **Configure Access:** Create `sydneytech.org` Access application with email gate.
3.  [ ] **Build Worker:** Implement the simple reverse proxy script (see `worker_proxy.md`).
4.  [ ] **Test:** Invite 1–2 trusted friends to test the flow.
5.  [ ] **Publish:** Write the first "Request Access" blog post on `sydneytech.org`.

---

*This roadmap is a living document. It evolves as the community grows, just like the Ident manuscript evolves with each draft.*
