# RemoteCache Plugin for Lyrion Music Server

## Overview

The RemoteCache plugin enables remote caching functionality for mobile clients like LyrPlay iOS app. It allows clients with 'loc' capability to download and cache music files for offline playback while maintaining compatibility with all existing LMS functionality.

## How It Works

1. **Detects 'loc' capable clients** - Identifies mobile apps that support local caching
2. **Converts file paths to HTTP URLs** - Transforms local server file paths into downloadable HTTP streams  
3. **Wraps URLs for caching** - Sends `file://127.0.0.1:3483/http://...` URLs that signal remote caching capability
4. **Maintains compatibility** - Falls back to normal streaming for clients without 'loc' capability

## Installation

### Method 1: Manual Installation

1. **Copy plugin files** to your LMS Plugins directory:
   ```bash
   # Copy the entire RemoteCache folder to:
   # - Linux: /usr/share/squeezelite-server/Plugins/
   # - Docker: /config/Plugins/
   # - macOS: /Library/Application Support/SqueezeCenter/Plugins/
   ```

2. **Restart LMS server**

3. **Enable the plugin**:
   - Go to LMS Web Interface → Settings → Plugins
   - Find "Remote Cache" and enable it
   - Click "Apply"

### Method 2: Development Installation

1. **Place in LMS Plugins directory**:
   ```bash
   cd /path/to/lms/Plugins/
   # Copy RemoteCache folder here
   ```

2. **Set proper permissions**:
   ```bash
   chown -R lms:lms RemoteCache/
   chmod -R 755 RemoteCache/
   ```

## Configuration

1. **Access settings**: Settings → Advanced → Remote Cache
2. **Enable Remote Cache**: Check the "Enable Remote Cache" option
3. **Debug logging**: Optionally enable for troubleshooting
4. **Save settings**

## Compatible Apps

- **LyrPlay for iOS** - Primary target app with full caching support
- **Custom Squeezelite builds** - Any player that reports 'loc' capability and can handle file:// URLs

## Technical Details

### URL Transformation

**Before (Local File):**
```
file:///music/Artist/Album/Track.flac
```

**After (Remote Cache):**
```
file://127.0.0.1:3483/http://server:9000/stream.mp3?player=MAC
```

### Client Requirements

For a client to receive remote cache URLs, it must:
1. Report 'loc' as the last format in its capabilities string
2. Not be part of a sync group
3. Not be seeking into a track
4. Be playing a non-virtual track (not from CUE sheet)

## Troubleshooting

### Enable Debug Logging

1. Go to Settings → Advanced → Remote Cache
2. Check "Enable Debug Logging"
3. Check LMS server logs for detailed output

### Common Issues

**Plugin not working:**
- Verify plugin is enabled in Settings → Plugins
- Check LMS server logs for plugin initialization messages
- Ensure LMS server was restarted after plugin installation

**Still receiving HTTP URLs:**
- Verify your client reports 'loc' capability
- Check that client is not in a sync group  
- Ensure you're starting tracks from beginning (not seeking)
- Enable debug logging to see decision logic

**File not found errors:**
- Check that the HTTP stream URLs are accessible
- Verify LMS server network configuration
- Test stream URLs directly in a browser

## Development

This plugin overrides the built-in `Slim::Player::Protocols::LocalFile` handler to provide remote caching functionality while maintaining full compatibility with existing LMS features.

## License

This plugin is provided under the same license as Lyrion Music Server (GPL v2).

## Support

For issues specific to this plugin, please check:
1. LMS server logs with debug logging enabled
2. Client application logs
3. Network connectivity between client and server

For LyrPlay iOS app support, visit: https://github.com/mtxmiller/LyrPlay