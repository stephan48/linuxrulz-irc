package LinuxRulz::Bot::Plugin::AuthPlugin;

use Moses::Plugin;
use namespace::autoclean;
use Data::Dumper;
use Config::INI::Reader;

with "LinuxRulz::Bot::Role::Plugin";

sub S_plugin_add  {
	my ( $self, $irc, $desc, $plugin ) = @_;

	if($desc eq "auth")
	{
		$irc->pipeline->bump_up($self, $irc->pipeline->get_index($self));
	}

		
	#arn "\n\n".Dumper($irc->plugin_get($$desc)->can("S_msg"))."\n";
	 
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
	
#my $qauth = $irc->is_nick_authed( $nick );
	
	#$ldap->user_isin_group($qauth,$permission);

    return PCI_EAT_NONE;
}

sub handle_message {
	my ( $self, $irc, $nickstr, $where, $source, $message ) = @_;

    my ($nick) = split /!/, $nickstr;

	if($message =~ /^!((?:[a-z][a-z0-9_\.]*))\s?(.+)?$/)
	{
		my $command = $1;
		my $args    = ( ($2) ? $2 : undef );
	
		if(!($self->bot->ldap && $self->bot->database))
		{
			$self->send_msg($irc, $nickstr, $where, $source, "Sorry but I wasn't able to handle the command! DATABASE OR LDAP OFFLINE! ($command)");
			return PCI_EAT_NONE;
		}
		
		my $command_plugin;
        my $command_string;

		if($command =~ /^((?:[a-z][a-z0-9_]*))\.((?:[a-z][a-z0-9_]*))$/)
		{
			$command_plugin = $1;
           	$command_string = $2;
		}
		elsif($command =~ /^((?:[a-z][a-z0-9_]*))$/)
		{
			if(!($self->{alias}->{$1}))
			{
				$self->send_msg($irc, $nickstr, $where, $source, "Sorry but I wasn't able to handle the command! Alias not found! ($command)");
            	return PCI_EAT_NONE;
			}
			
			$command_plugin = $self->{alias}->{$1}->{plugin};
            $command_string = $self->{alias}->{$1}->{cmd};
		}
		else
        {
           	$self->send_msg($irc, $nickstr, $where, $source, "Sorry but I wasn't able to handle the command! Command Line not decodeable ($command)");
			return PCI_EAT_NONE;
        }
		
		my $command_plugin_object;	
	
		if(!($command_plugin_object = $irc->plugin_get(lc($command_plugin))))
        {
			$self->send_msg($irc, $nickstr, $where, $source, "Sorry but I wasn't able to handle the command! Plugin Not Found! ($command)");
			return PCI_EAT_NONE;
		}
			
		if(!$command_plugin_object->DOES("LinuxRulz::Bot::Role::Plugin"))
        {
           	$self->send_msg($irc, $nickstr, $where, $source, "Sorry but I wasn't able to handle the command! Not A LinuxRulz Plugin! ($command)");
			return PCI_EAT_NONE;
        }
            
		$self->send_msg($irc, $nickstr, $where, $source, "ok");
	}

	#print "\n\n".(join ',', map { $_->isa } @{$self->{plugins}})."\n\n";

	return PCI_EAT_NONE;
}

sub commands_register {
	my ( $self, $plugin ) = @_;
	
	warn "\n\n\n\n\n\nTEST\n\n\n\n\n";

	push @{$self->{plugins}}, $plugin;
}





__PACKAGE__->meta->add_method( S_public => \&S_bot_addressed );

1;
