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
	
	# Register our custom LocalFile handler
	# This overrides the built-in LocalFile handler
	Slim::Player::ProtocolHandlers->registerHandler(
		'file', 
		'Plugins::RemoteCache::LocalFile'
	);
	
	$log->info("RemoteCache Plugin initialized - registered file:// handler");
	
	$class->SUPER::initPlugin(@_);
}

sub shutdownPlugin {
	my $class = shift;
	
	$log->info("RemoteCache Plugin shutting down...");
	
	# Note: We don't unregister the handler as LMS doesn't provide that functionality
	# The handler will remain until server restart
}

1;