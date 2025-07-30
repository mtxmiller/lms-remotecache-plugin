package Plugins::RemoteCache::LocalFile;

# Custom LocalFile protocol handler for RemoteCache plugin
# Sends file:// URLs with embedded HTTP URLs for remote caching clients
# Based on Slim::Player::Protocols::LocalFile but modified for remote caching

use strict;
use base qw(Slim::Player::Protocols::File);

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Utils::Misc;

my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.remotecache.localfile',
	'defaultLevel' => 'ERROR',
	'description'  => 'PLUGIN_REMOTECACHE_LOCALFILE'
});
my $prefs = preferences('plugin.remotecache');

sub canDirectStreamSong {
	my ($class, $client, $song) = @_;
	
	# Check if RemoteCache is enabled
	return 0 unless $prefs->get('enabled');
	
	# Debug logging
	if ($prefs->get('debug')) {
		$log->debug("Checking canDirectStreamSong for client: " . ($client->name || 'unknown'));
		$log->debug("Client formats: " . join(',', @{$client->myFormats || []}));
		$log->debug("Song URL: " . ($song->track->url || 'unknown'));
	}
	
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
		
		$log->info("RemoteCache: Client has 'loc' capability, creating cache URL");
		$log->info("  Original URL: $originalURL");
		
		# For local files, convert to HTTP streaming URL first
		if ($originalURL =~ m{^file:///}) {
			$log->debug("Converting local file to HTTP stream URL for remote caching");
			my $httpURL = $class->convertLocalFileToHTTP($client, $originalURL);
			
			if ($httpURL) {
				my $remoteCacheURL = "file://127.0.0.1:3483/" . $httpURL;
				$log->info("  Cache URL: $remoteCacheURL");
				return $remoteCacheURL;
			} else {
				$log->warn("Failed to convert local file to HTTP URL: $originalURL");
				return 0;
			}
		} 
		# For any other URL (HTTP, HTTPS, etc.), wrap it for remote caching
		else {
			my $remoteCacheURL = "file://127.0.0.1:3483/" . $originalURL;
			$log->info("  Cache URL: $remoteCacheURL");
			return $remoteCacheURL;
		}
	} else {
		if ($prefs->get('debug')) {
			my @reasons;
			push @reasons, "no 'loc' capability" unless ($client->can('myFormats') && 
				@{$client->myFormats || []} > 0 && $client->myFormats->[-1] eq 'loc');
			push @reasons, "client synced" if $client->isSynced;
			push @reasons, "has seek data" if $song->seekdata;
			push @reasons, "virtual track" if $song->track->virtual;
			push @reasons, "RemoteCache disabled" unless $prefs->get('enabled');
			
			$log->debug("RemoteCache not applicable: " . join(', ', @reasons));
		}
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
	
	$log->debug("Converted local file to HTTP: $localFileURL -> $httpURL");
	
	return $httpURL;
}

sub requestString {
	# Handle the file:// URL sent to remote clients
	my ($class, $client, $url, undef, $seekdata) = @_;
	
	$log->debug("RemoteCache requestString called with URL: $url");
	
	# Extract the embedded HTTP URL from our file:// wrapper
	if ($url =~ m{^file://127\.0\.0\.1:3483/(.+)$}) {
		my $httpURL = $1;
		
		$log->info("RemoteCache: Extracted HTTP URL for client download: $httpURL");
		
		# Return the HTTP URL for the client to download
		return $httpURL;
	}
	
	# Fallback: treat as regular file URL
	$url =~ s{^file://127\.0\.0\.1:3483/}{};
	my $filepath = Slim::Utils::Misc::pathFromFileURL($url);
	
	$log->debug("RemoteCache: Fallback to file path: $filepath");
	
	return $filepath;
}

1;