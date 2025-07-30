package Plugins::RemoteCache::Plugin;

# RemoteCache Plugin for Lyrion Music Server
# Enables remote caching for LyrPlay iOS app and other 'loc' capable clients
# Sends file:// URLs with embedded HTTP URLs for remote download and caching

use strict;
use base qw(Slim::Plugin::Base);

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Player::ProtocolHandlers;

my $log = logger('plugin.remotecache');
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

# Web settings page integration
sub webPages {
	my $class = shift;
	
	my %pages = (
		'plugins/RemoteCache/settings.html' => \&settingsHandler,
	);
	
	return \%pages;
}

sub settingsHandler {
	my ($client, $params) = @_;
	
	if ($params->{'saveSettings'}) {
		$prefs->set('enabled', $params->{'enabled'} || 0);
		$prefs->set('debug', $params->{'debug'} || 0);
	}
	
	$params->{'prefs'} = $prefs;
	
	return Slim::Web::HTTP::filltemplatefile('plugins/RemoteCache/settings.html', $params);
}

1;