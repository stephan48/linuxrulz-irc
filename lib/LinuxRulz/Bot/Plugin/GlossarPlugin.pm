package LinuxRulz::Bot::Plugin::GlossarPlugin;

use utf8;

use Moses::Plugin;
use namespace::autoclean;
use Data::Dumper;

with "LinuxRulz::Bot::Role::Plugin";

sub build_cmds {
	my $self = shift;
	
	return { 
		"glossar" =>
			{
				permission => "linuxrulz-user",
			},
		"glossaradd" =>
            {
                permission => "linuxrulz-op",
            },
	};
}

sub handle_command {
	my ( $self, $irc, $nickstr, $where, $source, $qauth, $command, $args ) = @_;

    my ($nick) = split /!/, $nickstr;

	if($command =~ /^glossar$/ && $args)
	{
		if((my $entry = $self->bot->database->resultset('Glossar')->find_by_title(lc($args))))
		{
			$self->send_msg($irc, $nickstr, $where, "chan", $entry->title.":".$entry->content);
		}
		else
		{
			$self->send_msg($irc, $nickstr, $where, "chan", "Kein Glossar eintrag mit dem Namen \"$args\" gefunden!");
		}

		return PCI_EAT_ALL;
	}

	if($command =~ /^glossaradd$/ && $args)
    {
		if( $args =~ /(.+):(.*)/ )
		{
			my $entry = $self->bot->database->resultset('Glossar')->create_entry(lc($1),$2);
			if($entry)
			{
				$self->send_msg($irc, $nickstr, $where, "chan", "Entry with ID:".$entry->id." ".$entry->title.":".$entry->content);
			}
			else
			{
				$self->send_msg($irc, $nickstr, $where, "chan", "Creation of Entry: $args");
			}
		}

        return PCI_EAT_ALL;
    }

	return PCI_EAT_NONE;
}

sub S_msg {
	return PCI_EAT_NONE;
}


1;
