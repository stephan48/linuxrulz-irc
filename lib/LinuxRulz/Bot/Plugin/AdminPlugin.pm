package LinuxRulz::Bot::Plugin::AdminPlugin;

use Moses::Plugin;
use namespace::autoclean;
use Data::Dumper;

with "LinuxRulz::Bot::Role::Plugin";

sub build_cmds {
	my $self = shift;
	
	return { 
		"quit" =>
			{
				permission => "linuxrulz-owner",	
			},
		"saychan" =>
            {
                permission => "linuxrulz-op",
            },
		"sayuser" =>
            {
                permission => "linuxrulz-op",
            },
	};
}

sub handle_command {
	my ( $self, $irc, $nickstr, $where, $source, $qauth, $command, $args ) = @_;

    my ($nick) = split /!/, $nickstr;

	if($command =~ /^quit$/ && $args)
	{
		$self->send_msg($irc, $nickstr, "!!allchans!!", "chan", "The Bot Goes Offline Now! Initiated by $nick! Reason: $args");
		$irc->yield( quit => "$args");
		return PCI_EAT_ALL;
	}
	elsif($command =~ /^quit$/)
	{
		$self->send_msg($irc, $nickstr, $where, $source, "You need to supply an QUIT reason!");
		return PCI_EAT_ALL;
	}

    if($command =~ /^saychan$/ && $args =~ /^(#.*|all) (.*)$/)
    {
		my $chan = $1;
		my $msg  = $2;

		if($chan eq "all")
		{
			$chan = "!!allchans!!";
		} 		
		
        $self->send_msg($irc, $nickstr, $chan, "chan", $msg);
        return PCI_EAT_ALL;
    }

	if($command =~ /^sayuser$/ && $args =~ /^(.*) (.*)$/)
    {
        my $user = $1;
        my $msg  = $2;

        $self->send_msg($irc, $nickstr, $user, "priv", $msg);
        return PCI_EAT_ALL;
    }

	return PCI_EAT_NONE;
}

sub S_msg {
	return PCI_EAT_NONE;
}


1;
