package LinuxRulz::Bot::Plugin::AuthPlugin;

use utf8;

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
	my $qauth  = lc($irc->is_nick_authed( $nick ));
	my $logger = $self->bot->logger->get_logger("auth");
	
	#$logger->trace("Nickstr: $nickstr QAuth: $qauth");
    $message = irc_to_utf8($message);
    
	if($message =~ /^!((?:[a-z][a-z0-9_\.]*))\s?(.+)?$/)
	{
		my $command = $1;
		my $args    = ( ($2) ? $2 : undef );
	
		if(!($self->bot->ldap && $self->bot->database))
		{
			$self->send_msg($irc, $nickstr, $where, $source, "Sorry but I wasn't able to handle the command! DATABASE OR LDAP OFFLINE! ($command)");
			return PCI_EAT_NONE;
		}
	
		my ($command_entry, $alias_entry, $command_plugin_object);
		
		if($command =~ /^((?:[a-z][a-z0-9_]*))\.((?:[a-z][a-z0-9_]*))$/)
		{
			$command_entry = $self->bot->database->resultset('Commands')->find_by_plugin_cmd(lc($1),lc($2));
			
			if(!$command_entry)
			{
				$self->send_msg($irc, $nickstr, $where, $source, "No Command found! ($command)");
				return PCI_EAT_NONE;
			}
		}
		elsif($command =~ /^((?:[a-z][a-z0-9_]*))$/)
		{
			$alias_entry = $self->bot->database->resultset('CommandsAliases')->find_by_alias(lc($1));
			
			if(!$alias_entry)
            {
                $self->send_msg($irc, $nickstr, $where, $source, "No Alias found! ($command)");
                return PCI_EAT_NONE;
            }

			$command_entry = $alias_entry->command;
		}
		else
        {
           	$self->send_msg($irc, $nickstr, $where, $source, "Command Line not decodeable ($command)(This error was logged!)!");
			$logger->fatal("Commandline not Decodeable! NickStr:$nickstr QAuth: $qauth CommandLine: $command");
			return PCI_EAT_NONE;
        }
		
		if(!($command_plugin_object = $irc->plugin_get($command_entry->plugin)))
        {
			$self->send_msg($irc, $nickstr, $where, $source, "Found the Command! But the Plugin which should handle it is not loaded! ($command)");
			return PCI_EAT_NONE;
		}
			
		if($command_entry->permission)
		{
			if(!$qauth)
			{
				$self->send_msg($irc, $nickstr, $where, $source, "You need an QAUTH to use the Command!(Please try again in 30 seconds! Maybe your nick isnt tracked yet!)");
            	return PCI_EAT_NONE;
			}
			
			if(!($self->bot->ldap->user_exist($qauth)))
            {
                $self->send_msg($irc, $nickstr, $where, $source, "You need to be registrated(on HP) to use this Command!");
                return PCI_EAT_NONE;
            }
		
			if(!($self->bot->ldap->user_isin_group($qauth,$command_entry->permission)))
			{
				$self->send_msg($irc, $nickstr, $where, $source, "You are not authorized to use this Command!");
                return PCI_EAT_NONE;
			}
		}
	
		$logger->info("User \"$nickstr\" (QAuth: \"$qauth\") issued Command: \"".$command_entry->cmd."\" for Plugin \"".$command_entry->plugin."\" with args: \"".($args ? $args : "(no args)")."\" in ".(($source eq "chan") ? "Channel \"".@{$where}[0]."\"" : "\"Query\"" )."!");  

		return $command_plugin_object->handle_command($irc, $nickstr, $where, $source, $qauth, $command_entry->cmd, $args);

	}

	return PCI_EAT_NONE;
}

__PACKAGE__->meta->add_method( S_public => \&S_bot_addressed );

1;
