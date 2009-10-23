package LinuxRulz::Bot::Plugin::DCCPlugin;

use Moses::Plugin;
use namespace::autoclean;
use Data::Dumper;

sub S_dcc_request {
	my ($self, $irc, $nickstr, $type, $port, $cookie, $file, $size, $addr) = @_;	

	return PCI_EAT_NONE if $$type ne 'CHAT';
	
    $irc->yield( dcc_accept => $$cookie);
	
	return PCI_EAT_NONE;
}

sub S_dcc_start {
    my ($self, $irc, $wheelid, $nickstr, $type, $port, $file, $size, $addr) = @_;

    $irc->yield( dcc_chat => $$wheelid => "LinuxRulz::Bot DCC Interface");
	$irc->yield( dcc_chat => $$wheelid => "Please enter your Username(you have 60 seconds):");

	$poe_kernel->state( 'DCCPlugin_auth_timeout', $self );
	$self->{connections}->{$$wheelid}->{auth_timeout} = $poe_kernel->delay_add("DCCPlugin_auth_timeout", 60, $$wheelid);
    return PCI_EAT_NONE;
}


sub S_dcc_chat {
	my ($self, $irc, $wheelid, $nickstr, $port, $text, $addr) = @_;

	$irc->yield( dcc_chat => $$wheelid => "test");

	return PCI_EAT_NONE;
}

sub S_dcc_error {
	my ($self, $irc, $wheelid, $error, $nickstr, $type, $port, $cookie, $file, $size, $addr) = @_;

	print "\n\nDCC ERROR:$$error on Wheel $$wheelid!\n\n";

	return PCI_EAT_NONE;
}

sub DCCPlugin_auth_timeout {
	my ($kernel, $self, $irc, $wheelid ) = @_[KERNEL, OBJECT, HEAP, ARG0];
	
	$irc->yield( dcc_chat  => $wheelid => "Sorry please try again!");
	$irc->yield( dcc_close => $wheelid);
	delete($self->{connections}->{$wheelid});
}

1;
