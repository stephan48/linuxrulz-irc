package LinuxRulz::Bot::Plugin::TestPlugin;

use Moses::Plugin;
use namespace::autoclean;
use Data::Dumper;

with "LinuxRulz::Bot::Role::Plugin";

sub build_cmds {
	my $self = shift;
	
	return { 
		"test" =>
			{
				permission => "linuxrulz-user",	
			},
	};
}

sub handle_command {
	my ( $self, $irc, $nickstr, $where, $source, $qauth, $command, $args ) = @_;

    my ($nick) = split /!/, $nickstr;

	if($command =~ /^test$/)
	{
		$self->send_msg($irc, $nickstr, $where, $source, "Test");
		return PCI_EAT_ALL;
	}

	return PCI_EAT_NONE;
}

sub S_msg {
	return PCI_EAT_NONE;
}


1;
