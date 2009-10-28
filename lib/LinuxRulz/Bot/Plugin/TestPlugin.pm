package LinuxRulz::Bot::Plugin::TestPlugin;

use Moses::Plugin;
use namespace::autoclean;
use Data::Dumper;
use UNIVERSAL;


with "LinuxRulz::Bot::Role::Plugin";

after "PCI_register" => sub  {
	my ( $self, $irc ) = @_;

	
	return 1;
};

after "PCI_unregister" => sub  {
    my ( $self, $irc ) = @_;


    return 1;
};

sub S_plugin_add {
	my ( $self, $irc, $desc, $plugin ) = @_;

	return PCI_EAT_NONE;
}


sub S_msg {
    my ( $self, $irc, $nickstr, $target, $msg ) = @_;

	return $self->handle_message($irc, $$nickstr, $$target, "priv", $$msg);

    return PCI_EAT_NONE;
}

sub S_bot_addressed {
    my ( $self, $irc, $nickstr, $channel, $msg ) = @_;
	
	return $self->handle_message($irc, $$nickstr, $$channel, "chan", $$msg);
	
    return PCI_EAT_NONE;
}

sub handle_message {
	my ( $self, $irc, $nickstr, $where, $source, $message ) = @_;

    my ($nick) = split /!/, $nickstr;

	if($message =~ /^!testplugin$/)
	{
		$self->send_msg($irc, $nickstr, $where, $source, "Test");
	}

	return PCI_EAT_NONE;
}

__PACKAGE__->meta->add_method( S_public => \&S_bot_addressed );

1;
