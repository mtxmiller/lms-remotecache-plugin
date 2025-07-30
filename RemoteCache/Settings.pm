package Plugins::RemoteCache::Settings;

use strict;
use base qw(Slim::Web::Settings);
use Slim::Utils::Prefs;

my $prefs = preferences('plugin.remotecache');

sub name {
    return 'PLUGIN_REMOTECACHE';
}

sub page {
    return 'plugins/RemoteCache/settings.html';
}

sub prefs {
    return ($prefs, qw(enabled debug));
}

sub handler {
    my ($class, $client, $params) = @_;
    
    if ($params->{'saveSettings'}) {
        $prefs->set('enabled', $params->{'enabled'} || 0);
        $prefs->set('debug', $params->{'debug'} || 0);
    }
    
    return $class->SUPER::handler($client, $params);
}

1;