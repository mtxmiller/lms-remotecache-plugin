package Plugins::RemoteCache::Plugin;

# RemoteCache Plugin for Lyrion Music Server
# Enables remote caching for LyrPlay iOS app and other 'loc' capable clients
# Sends file:// URLs with embedded HTTP URLs for remote download and caching

use strict;
use base qw(Slim::Plugin::Base);

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Player::ProtocolHandlers;

my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.remotecache',
	'defaultLevel' => 'ERROR',
	'description'  => 'PLUGIN_REMOTECACHE'
});
my $prefs = preferences('plugin.remotecache');

# Plugin metadata
sub getDisplayName { 'Remote Cache' }

sub initPlugin {
	my $class = shift;
	
	$log->info("RemoteCache Plugin initializing...");
	
	# Initialize preferences
	$prefs->init({
		enabled => 1,
		debug => 0,
	});
	
	# Register Settings page
	if (main::WEBUI) {
		require Plugins::RemoteCache::Settings;
		Plugins::RemoteCache::Settings->new();
	}
	
	# Register our custom LocalFile handler (only if enabled)
	# This follows the same pattern as LocalPlayer plugin
	if ($prefs->get('enabled')) {
		require Plugins::RemoteCache::LocalFile;
		Slim::Player::ProtocolHandlers->registerHandler('file', 'Plugins::RemoteCache::LocalFile');
		
		# Verify what handler is actually registered
		my $handler = Slim::Player::ProtocolHandlers->handlerForURL('file:///test');
		$log->warn("RemoteCache: Registered file:// handler");
		$log->warn("RemoteCache: Current file handler is: " . (ref($handler) || 'none'));
		
		# Test if our handler has the expected methods
		if ($handler && $handler->can('canDirectStream')) {
			$log->warn("RemoteCache: Handler supports canDirectStream - GOOD");
		} else {
			$log->warn("RemoteCache: Handler does NOT support canDirectStream - BAD");
		}
		
		if ($handler && $handler->can('canDirectStreamSong')) {
			$log->warn("RemoteCache: Handler supports canDirectStreamSong - GOOD");
		} else {
			$log->warn("RemoteCache: Handler does NOT support canDirectStreamSong - BAD");
		}
	} else {
		$log->warn("RemoteCache: Plugin disabled, file:// handler not registered");
	}
	
	$log->info("RemoteCache Plugin initialization complete");
	
	$class->SUPER::initPlugin(@_);
}

sub shutdownPlugin {
	my $class = shift;
	
	$log->info("RemoteCache Plugin shutting down...");
	
	# Note: We don't unregister the handler as LMS doesn't provide that functionality
	# The handler will remain until server restart
}

1;