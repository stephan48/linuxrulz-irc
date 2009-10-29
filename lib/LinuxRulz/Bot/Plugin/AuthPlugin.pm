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
	
	$self->{alias}->{"test"} = { plugin=> "test", cmd=> "test"};

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
	my $qauth  = $irc->is_nick_authed( $nick );


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
			my $alias = lc($1);
			if(!($self->{alias}->{$alias}))
			{
				$self->send_msg($irc, $nickstr, $where, $source, "Sorry but I wasn't able to handle the command! Alias not found! ($command)");
            	return PCI_EAT_NONE;
			}
			
			$command_plugin = $self->{alias}->{$alias}->{plugin};
            $command_string = $self->{alias}->{$alias}->{cmd};
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

		if(!$command_plugin_object->has_cmds())
		{
			$self->send_msg($irc, $nickstr, $where, $source, "Sorry but I wasn't able to handle the command! Plugin $command_plugin has no CMDS!");
            return PCI_EAT_NONE;
		}
		
		my $command_hash;

		if(!($command_hash = $command_plugin_object->get_cmd($command_string)))
		{
			$self->send_msg($irc, $nickstr, $where, $source, "Sorry but I wasn't able to handle the command! Plugin $command_plugin has no Command $command_string!");
            return PCI_EAT_NONE;
		}
	
		if($command_hash->{permission})
		{
			if(!$qauth)
			{
				$self->send_msg($irc, $nickstr, $where, $source, "You need an QAUTH to use the Command!(Please try again in 30 seconds! Maybe your nick isnt tracked yet!");
            	return PCI_EAT_NONE;
			}
			
			if(!($self->bot->ldap->user_exist($qauth)))
            {
                $self->send_msg($irc, $nickstr, $where, $source, "You need to be registrated(on HP) to use this Command!");
                return PCI_EAT_NONE;
            }
		
			if(!($self->bot->ldap->user_isin_group($qauth,$command_hash->{permission})))
			{
				$self->send_msg($irc, $nickstr, $where, $source, "You are not authorized to use this Command!");
                return PCI_EAT_NONE;
			}
		}
		elsif ($command_hash->{permission_sub})
		{
        	$self->send_msg($irc, $nickstr, $where, $source, "Permission Sub need to be implanted first!!");
            return PCI_EAT_NONE;
		}
		else
		{
			$self->send_msg($irc, $nickstr, $where, $source, "Sorry but I wasn't able to handle the command! No way to authorize user!");
            return PCI_EAT_NONE;
		}

		return $command_plugin_object->handle_command($irc, $nickstr, $where, $source, $qauth, $command_string, $args);

		$self->send_msg($irc, $nickstr, $where, $source, "ok");
	}

	return PCI_EAT_NONE;
}

sub commands_register {
	my ( $self, $plugin ) = @_;
	
	warn "\n\n\n\n\n\nTEST\n\n\n\n\n";

	push @{$self->{plugins}}, $plugin;
}

__PACKAGE__->meta->add_method( S_public => \&S_bot_addressed );

1;
