ToS Compliance Checklist
Requirement	Implementation
No public video hosting	All streams behind Access gate
Authentication required	Email OTP for every stream request
Not a general CDN	Content tied to specific blog project
Limited audience	Manual approval of readers
No hotlinking	Cookie-based auth prevents direct links
Security Considerations
1. Access Token Validation
Always verify JWT signature against Cloudflare Access public keys
Check token expiration (typically 24 hours)
Validate audience claim matches your application
2. Content Path Validation
Sanitize requested paths to prevent directory traversal
Never proxy arbitrary URLs
Whitelist allowed file extensions: .m3u8, .ts, .mp4, .mp3, .vtt
3. Rate Limiting (Optional)
javascript

Copy
// Add rate limiting per user
const rateLimit = new Map(); // Or use Cloudflare Cache API

function checkRateLimit(userEmail) {
  const now = Date.now();
  const window = 60 * 60 * 1000; // 1 hour
  const maxRequests = 100;
  
  // Implementation details...
}
4. CORS Configuration
Restrict Access-Control-Allow-Origin to your blog domain
Never use * wildcard with credentials
