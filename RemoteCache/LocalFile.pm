package Plugins::RemoteCache::LocalFile;

# Custom LocalFile protocol handler for RemoteCache plugin
# Sends file:// URLs with embedded HTTP URLs for remote caching clients
# Based on Slim::Player::Protocols::LocalFile but modified for remote caching

use strict;
use base qw(Slim::Player::Protocols::File);

use Slim::Utils::Prefs;
use Slim::Utils::Misc;

my $prefs = preferences('plugin.remotecache');

# Simple file logging for debugging
sub debugLog {
	my $message = shift;
	my $timestamp = scalar localtime();
	
	# Write to a simple log file in LMS cache directory
	if (open(my $fh, '>>', Slim::Utils::OSDetect::dirsFor('cache') . '/remotecache_debug.log')) {
		print $fh "[$timestamp] $message\n";
		close($fh);
	}
}

sub canDirectStream {
	my ($class, $client, $url) = @_;
	
	debugLog("canDirectStream called with URL: $url");
	debugLog("Client: " . ($client->name() || 'unknown') . " MAC: " . ($client->macaddress() || 'unknown'));
	
	warn "RemoteCache: canDirectStream called with URL: $url\n";
	warn "RemoteCache: Client: " . ($client->name() || 'unknown') . " MAC: " . ($client->macaddress() || 'unknown') . "\n";
	
	# Create a minimal song object to call canDirectStreamSong
	# This is a workaround for when base File.pm is used instead of LocalFile.pm
	my $track = { url => $url };
	my $song = { 
		track => $track,
		seekdata => undef,
	};
	
	# Call our main logic
	my $result = $class->canDirectStreamSong($client, $song);
	warn "RemoteCache: canDirectStream returning: " . ($result || '0') . "\n";
	return $result;
}

sub canDirectStreamSong {
	my ($class, $client, $song) = @_;
	
	debugLog("=== canDirectStreamSong called ===");
	debugLog("Client: " . ($client->name || 'unknown') . " MAC: " . ($client->macaddress || 'unknown'));
	debugLog("Client formats: " . join(',', @{$client->myFormats || []}));
	debugLog("Song URL: " . ($song->{track}->{url} || 'unknown'));
	debugLog("Plugin enabled: " . ($prefs->get('enabled') ? 'YES' : 'NO'));
	
	# Check if RemoteCache is enabled
	return 0 unless $prefs->get('enabled');
	
	# Debug logging  
	warn "RemoteCache: Checking canDirectStreamSong for client: " . ($client->name || 'unknown') . "\n";
	warn "RemoteCache: Client formats: " . join(',', @{$client->myFormats || []}) . "\n";
	warn "RemoteCache: Song URL: " . ($song->{track}->{url} || 'unknown') . "\n";
	
	# Check same conditions as original LocalPlayer plugin
	# - Client supports 'loc' capability (last in format list)
	# - Client is not synced
	# - No seek data
	# - Not a virtual track (CUE sheet)
	if ($client->can('myFormats') && 
		@{$client->myFormats || []} > 0 &&
		$client->myFormats->[-1] eq 'loc' && 
		!$client->isSynced && 
		!$song->seekdata && 
		!$song->track->virtual) {
		
		# Get the original URL from the song
		my $originalURL = $song->track->url;
		
		warn "RemoteCache: Client has 'loc' capability, creating cache URL\n";
		warn "RemoteCache: Original URL: $originalURL\n";
		
		# For local files, convert to HTTP streaming URL first
		if ($originalURL =~ m{^file:///}) {
			warn "RemoteCache: Converting local file to HTTP stream URL for remote caching\n";
			my $httpURL = $class->convertLocalFileToHTTP($client, $originalURL);
			
			if ($httpURL) {
				my $remoteCacheURL = "file://127.0.0.1:3483/" . $httpURL;
				warn "RemoteCache: Cache URL: $remoteCacheURL\n";
				return $remoteCacheURL;
			} else {
				warn "RemoteCache: Failed to convert local file to HTTP URL: $originalURL\n";
				return 0;
			}
		} 
		# For any other URL (HTTP, HTTPS, etc.), wrap it for remote caching
		else {
			my $remoteCacheURL = "file://127.0.0.1:3483/" . $originalURL;
			warn "RemoteCache: Cache URL: $remoteCacheURL\n";
			return $remoteCacheURL;
		}
	} else {
		my @reasons;
		push @reasons, "no 'loc' capability" unless ($client->can('myFormats') && 
			@{$client->myFormats || []} > 0 && $client->myFormats->[-1] eq 'loc');
		push @reasons, "client synced" if $client->isSynced;
		push @reasons, "has seek data" if $song->seekdata;
		push @reasons, "virtual track" if $song->{track} && $song->{track}->{virtual};
		push @reasons, "RemoteCache disabled" unless $prefs->get('enabled');
		
		warn "RemoteCache: Not applicable: " . join(', ', @reasons) . "\n";
	}
	
	# Fall through to normal server-based playback
	return 0;
}

sub convertLocalFileToHTTP {
	my ($class, $client, $localFileURL) = @_;
	
	# Extract the file path from file:/// URL
	my $filePath = $localFileURL;
	$filePath =~ s{^file://}{};
	
	# Get server host and port from client connection
	# This is a simplified approach - you might need to adjust based on your LMS setup
	my $serverHost = $client->peeraddr() || 'localhost';  # Client's perspective of server
	my $serverPort = Slim::Utils::Network::serverPort() || 9000;
	
	# Create HTTP stream URL
	# Format: http://server:port/stream.format?player=MAC
	my $mac = $client->macaddress();
	my $httpURL = "http://${serverHost}:${serverPort}/stream.mp3?player=${mac}";
	
	warn "RemoteCache: Converted local file to HTTP: $localFileURL -> $httpURL\n";
	
	return $httpURL;
}

sub requestString {
	# Handle the file:// URL sent to remote clients
	my ($class, $client, $url, undef, $seekdata) = @_;
	
	warn "RemoteCache: requestString called with URL: $url\n";
	
	# Extract the embedded HTTP URL from our file:// wrapper
	if ($url =~ m{^file://127\.0\.0\.1:3483/(.+)$}) {
		my $httpURL = $1;
		
		warn "RemoteCache: Extracted HTTP URL for client download: $httpURL\n";
		
		# Return the HTTP URL for the client to download
		return $httpURL;
	}
	
	# Fallback: treat as regular file URL
	$url =~ s{^file://127\.0\.0\.1:3483/}{};
	my $filepath = Slim::Utils::Misc::pathFromFileURL($url);
	
	warn "RemoteCache: Fallback to file path: $filepath\n";
	
	return $filepath;
}

1;