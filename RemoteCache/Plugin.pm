package Plugins::RemoteCache::Plugin;

# RemoteCache Plugin for Lyrion Music Server
# Enables remote caching for LyrPlay iOS app and other 'loc' capable clients
# Sends file:// URLs with embedded HTTP URLs for remote download and caching

use strict;
use base qw(Slim::Plugin::Base);

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Utils::Timers;
use Slim::Player::ProtocolHandlers;
use Time::HiRes;

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
		
		# Add debug log page
		Slim::Web::Pages->addPageFunction("^remotecache.log", \&debugLogHandler);
	}
	
	# Register our custom LocalFile handler (only if enabled)
	# This follows the same pattern as LocalPlayer plugin
	if ($prefs->get('enabled')) {
		require Plugins::RemoteCache::LocalFile;
		
		$log->warn("=== BEFORE Registration ===");
		my $beforeHandler = Slim::Player::ProtocolHandlers->handlerForURL('file:///test');
		$log->warn("Before: " . ($beforeHandler || 'none'));
		
		# Register both protocol and URL pattern for maximum coverage
		Slim::Player::ProtocolHandlers->registerHandler('file', 'Plugins::RemoteCache::LocalFile');
		Slim::Player::ProtocolHandlers->registerURLHandler(qr{^file://}, 'Plugins::RemoteCache::LocalFile');
		
		$log->warn("=== AFTER Registration ===");  
		my $afterHandler = Slim::Player::ProtocolHandlers->handlerForURL('file:///test');
		$log->warn("After: " . ($afterHandler || 'none'));
		
		# Check direct protocol lookup
		my $directHandler = Slim::Player::ProtocolHandlers->handlerForProtocol('file');
		$log->warn("Direct protocol handler: " . ($directHandler || 'none'));
		
		# Check if our class is actually being used
		if ($afterHandler && $afterHandler eq 'Plugins::RemoteCache::LocalFile') {
			$log->warn("SUCCESS: Our handler is registered and active");
		} else {
			$log->warn("FAILED: Handler is still: " . ($afterHandler || 'none'));
		}
	} else {
		$log->warn("RemoteCache: Plugin disabled, file:// handler not registered");
	}
	
	# Re-register handler after server initialization to ensure we stay registered
	Slim::Utils::Timers::setTimer(undef, Time::HiRes::time() + 5, sub {
		$log->warn("=== DELAYED RE-REGISTRATION ===");
		my $beforeReReg = Slim::Player::ProtocolHandlers->handlerForURL('file:///test');
		$log->warn("Before re-registration: " . ($beforeReReg || 'none'));
		
		# Re-register our handler
		Slim::Player::ProtocolHandlers->registerHandler('file', 'Plugins::RemoteCache::LocalFile');
		Slim::Player::ProtocolHandlers->registerURLHandler(qr{^file://}, 'Plugins::RemoteCache::LocalFile');
		
		my $afterReReg = Slim::Player::ProtocolHandlers->handlerForURL('file:///test');
		$log->warn("After re-registration: " . ($afterReReg || 'none'));
		
		if ($afterReReg && $afterReReg eq 'Plugins::RemoteCache::LocalFile') {
			$log->warn("SUCCESS: Handler re-registration worked!");
		} else {
			$log->warn("FAILED: Re-registration failed, still: " . ($afterReReg || 'none'));
		}
	});
	
	$log->info("RemoteCache Plugin initialization complete");
	
	$class->SUPER::initPlugin(@_);
}

sub debugLogHandler {
	my ($httpClient, $response) = @_;
	
	my $logFile = Slim::Utils::OSDetect::dirsFor('cache') . '/remotecache_debug.log';
	my $content = '';
	
	if (-f $logFile && open(my $fh, '<', $logFile)) {
		$content = join('', <$fh>);
		close($fh);
	} else {
		$content = "No debug log found at: $logFile\n";
	}
	
	$response->header('Content-Type' => 'text/plain; charset=utf-8');
	$response->content($content);
}

sub shutdownPlugin {
	my $class = shift;
	
	$log->info("RemoteCache Plugin shutting down...");
	
	# Note: We don't unregister the handler as LMS doesn't provide that functionality
	# The handler will remain until server restart
}

1;