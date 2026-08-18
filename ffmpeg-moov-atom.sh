# Fast-start flag allows instant web playback/seeking without re-encoding
ffmpeg -i raw_video.mp4 -c copy -movflags +faststart ~/Videos/blog-media/demo-clip.mp4