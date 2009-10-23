package LinuxRulz::Bot::Plugin::TestPlugin;

use Moses::Plugin;
use namespace::autoclean;
use Data::Dumper;

sub S_msg {
    my ( $self, $irc, $nickstr, $target, $msg ) = @_;
	my ($nick) = split /!/, $$nickstr;

	$self->privmsg($nick => "Test via PRIVMSG");

    return PCI_EAT_ALL;
}

sub S_bot_addressed {
    my ( $self, $irc, $nickstr, $channel, $msg ) = @_;

    if ( $$msg =~ /^!test/ ) {
        $self->privmsg("#linuxrulz.bots" => "Test via Channel PLUGIN");
        return PCI_EAT_ALL;
    }

    if ( $$msg =~ /^!index/ ) {
        $self->privmsg("#linuxrulz.bots" => "TestPlugin Index:".$irc->pipeline->get_index($self));
        return PCI_EAT_NONE;
    }

    return PCI_EAT_NONE;
}
 
__PACKAGE__->meta->add_method( S_public => \&S_bot_addressed );

1;
