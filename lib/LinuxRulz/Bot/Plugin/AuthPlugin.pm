package LinuxRulz::Bot::Plugin::AuthPlugin;

use Moses::Plugin;
use namespace::autoclean;
use Data::Dumper;
use Config::INI::Reader;
use UNIVERSAL;

with "LinuxRulz::Bot::Role::Plugin";

sub S_plugin_add  {
	my ( $self, $irc ) = @_;
	
	$irc->pipeline->bump_up($self, $irc->pipeline->get_index($self));
	
	#$self->{cmds} = Config::INI::Reader->read_file('etc/cmd_rights.ini');
	die(1);
	return PCI_EAT_ALL;
}

sub S_msg {
    my ( $self, $irc, $nickstr, $target, $msg ) = @_;

	return $self->handle_message($irc, $$nickstr, $$target, "priv", $$msg);

    return PCI_EAT_NONE;
}

sub S_bot_addressed {
    my ( $self, $irc, $nickstr, $channel, $msg ) = @_;
	
	return $self->handle_message($irc, $$nickstr, $$channel, "chan", $$msg);
	
	#my $qauth = $irc->is_nick_authed( $nick );
	
	#$ldap->user_isin_group($qauth,$permission);

    return PCI_EAT_NONE;
}

sub handle_message {
	my ( $self, $irc, $nickstr, $where, $source, $message ) = @_;

    my ($nick) = split /!/, $nickstr;

	if($message =~ /^!((?:[a-z][a-z0-9_]*))\s?(.+)?$/)
	{
		my $command = $1;
		my $args    = ( ($2) ? $2 : undef );
	
		if($self->bot->ldap && $self->bot->database)
		{
			$self->send_msg($irc, $nickstr, $where, $source, "Sorry but I wasn't able to handle the command! ($command)");
		}
		else
		{
			$self->send_msg($irc, $nickstr, $where, $source, "Sorry but I wasn't able to handle the command! DATABASE OR LDAP OFFLINE! ($command)");
		}
	}

	print "\n\n".(join ',', map { $_->isa } @{$self->{plugins}})."\n\n";

	return PCI_EAT_ALL;
}

sub commands_register {
	my ( $self, $plugin ) = @_;
	
die;

	push @{$self->{plugins}}, $plugin;
}





__PACKAGE__->meta->add_method( S_public => \&S_bot_addressed );

1;
