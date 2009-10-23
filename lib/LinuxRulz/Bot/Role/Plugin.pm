package LinuxRulz::Bot::Role::Plugin;

use Moose::Role;

sub send_msg {
    my ( $self, $irc, $nickstr, $where, $source, $message ) = @_;

    my ($nick) = split /!/, $nickstr;

    if($source eq "priv")
    {
        return $self->privmsg($nick => $message);
    }
    elsif($source eq "chan")
    {
        return $self->privmsg($where => $message);
    }
}

1;
