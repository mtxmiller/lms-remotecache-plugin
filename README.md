# LMS RemoteCache Plugin Repository

This repository provides the RemoteCache plugin for Lyrion Music Server (formerly Logitech Media Server).

## What is RemoteCache?

RemoteCache enables mobile apps like **LyrPlay for iOS** to download and cache music files for offline playback. It works by:

1. Detecting clients with 'loc' capability
2. Converting local file paths to downloadable HTTP URLs  
3. Sending `file://127.0.0.1:3483/http://...` URLs for remote caching
4. Maintaining full compatibility with existing LMS functionality

## Installation

### Method 1: Plugin Repository (Recommended)

1. **Add Repository to LMS**:
   - Go to LMS Web Interface → Settings → Plugins → Additional Repositories
   - Add this URL: `https://raw.githubusercontent.com/mtxmiller/lms-remotecache-plugin/main/repo.xml`
   - Click "Apply"

2. **Install Plugin**:
   - Go to Settings → Plugins → Third Party
   - Find "Remote Cache" and click "Install"
   - Restart LMS server when prompted

3. **Configure Plugin**:
   - Go to Settings → Advanced → Remote Cache  
   - Enable "Remote Cache"
   - Optionally enable debug logging
   - Save settings

### Method 2: Manual Installation

Download the latest release ZIP file and extract to your LMS Plugins directory.

## Compatible Apps

- **LyrPlay for iOS** - https://github.com/mtxmiller/LyrPlay
- Any Squeezelite-based player that reports 'loc' capability

## How It Works

**Before (Local File Access):**
```
Server: file:///music/Artist/Album/Track.flac
Client: Receives HTTP stream (no caching)
```

**After (Remote Cache):**
```  
Server: file:///music/Artist/Album/Track.flac
Plugin: Converts to file://127.0.0.1:3483/http://server:9000/stream.mp3?player=MAC
Client: Downloads and caches the file for offline playback
```

## Requirements

- Lyrion Music Server 7.5.0 or later
- Client application with 'loc' capability support

## Support

For issues with this plugin:
1. Enable debug logging in plugin settings
2. Check LMS server logs for RemoteCache messages
3. Report issues on GitHub: https://github.com/mtxmiller/lms-remotecache-plugin/issues

For LyrPlay iOS app support: https://github.com/mtxmiller/LyrPlay/issues

## License

GPL v2 (same as Lyrion Music Server)