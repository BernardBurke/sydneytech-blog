<!-- layouts/shortcodes/stream.html -->
<!-- Usage: {{< stream src="/member/episode1.m3u8" type="video" >}} -->

<video controls crossorigin="anonymous">
  <source src="https://stream.sydneytech.org{{ .Get "src" }}" 
          type="application/x-mpegURL">
  <!-- Fallback for non-HLS browsers -->
  <p>Your browser does not support adaptive streaming. 
     <a href="https://blog.sydneytech.org/login">Log in</a> to access content.</p>
</video>

<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
<script>
  document.addEventListener('DOMContentLoaded', function() {
    const video = document.querySelector('video');
    if (Hls.isSupported()) {
      const hls = new Hls();
      hls.loadSource(video.querySelector('source').src);
      hls.attachMedia(video);
    }
  });
</script>
