Deployment Steps
Phase 1: Infrastructure

 Set up Jellyfin on local server/VPS

 Create Cloudflare Tunnel with cloudflared

 Verify tunnel connectivity (test with temporary public access)

 Disable public DNS record for tunnel hostname
Phase 2: Access Configuration

 Create Access application for blog (blog.sydneytech.org)

 Create Access application for stream (stream.sydneytech.org)

 Configure email policies for member/insider tiers

 Test authentication flow
Phase 3: Worker Development

 Create Worker project: wrangler init ident-stream-proxy

 Implement JWT validation logic

 Implement Jellyfin proxy logic

 Test with curl: curl -H "CF-Access-Audience: <token>" <worker-url>
Phase 4: Hugo Integration

 Create layouts/shortcodes/stream.html

 Test embedded player on member post

 Verify adaptive streaming works (check network tab for .ts segments)
Phase 5: Production

 Set custom domain for Worker (stream.sydneytech.org)

 Configure production environment variables

 Add initial member/insider emails to Access policies

 Write "Request Access" page for public
Troubleshooting
Issue: "This One-Time PIN has already been used"
Cause: Email security scanner consumed the link Fix: Allowlist noreply@notify.cloudflare.com in email settings

Issue: Video loads but doesn't play
Cause: CORS headers missing or incorrect Fix: Verify Worker adds Access-Control-Allow-Origin header

Issue: 403 Forbidden from Jellyfin
Cause: Worker not forwarding authentication headers correctly Fix: Jellyfin should not require auth (Access handles it). Disable Jellyfin auth requirement.

Issue: Adaptive streaming not working
Cause: .m3u8 manifest returns but segments fail Fix: Ensure Worker proxies all manifest-relative URLs correctly (path rewriting)

Future Enhancements

 Signed URLs: Add time-limited signed URLs for sharing specific content

 Analytics: Log stream starts via Worker to track engagement

 WebSub: Notify readers of new insider content

 Download Option: Allow offline access for insider tier

 Live Streaming: Add RTMP endpoint for live author readings
Related Documents
blog_architecture.md - Hugo site structure
access_policy.md - Detailed Access configuration
jellyfin_setup.md - Media server configuration
