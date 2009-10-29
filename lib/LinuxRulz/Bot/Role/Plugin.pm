package LinuxRulz::Bot::Role::Plugin;

use Moose::Role;

use Data::Dumper;

has _cmds => (
    isa        => 'HashRef',
    accessor   => 'cmds',
    traits     => [ 'Hash' ],
    lazy       => 1,
    auto_deref => 1,
    builder    => 'build_cmds',
    handles    => {
        cmd_names  => 'keys',
        get_cmd    => 'get',
        has_cmds   => 'count'
    }
);

sub send_msg {
    my ( $self, $irc, $nickstr, $where, $source, $message ) = @_;

    my ($nick) = split /!/, $nickstr;

    if($source eq "priv")
    {
        return $self->privmsg($nick => $message);
    }
    elsif($source eq "chan")
    {
		if($where eq "!!allchans!!")
		{
		    foreach my $chan ($self->bot->get_channels)
        	{
				$self->privmsg($chan => $message);
        	}
		}
		else
		{
			$self->privmsg($where => $message);
		}
    }
}

1;
