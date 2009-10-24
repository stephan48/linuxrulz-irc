package LinuxRulz::Bot;
use lib '.';
use Moses;
use namespace::autoclean;

use Data::Dumper;

use POE::Component::IRC::Qnet::State;

server   'irc.quakenet.org';
port     '6667';
password '';
username 'linuxrulz';
nickname 'Linuxrulz';

channels   ("#linuxrulz.bots");

poco_irc_args ( Debug => 1, plugin_debug=>1 );

owner 'stephan48!stephanj@stephan48.users.quakenet.org';

sub _build_irc {
	POE::Component::IRC::Qnet::State->spawn(
        Nick     => $_[0]->get_nickname,
        Server   => $_[0]->get_server,
        Port     => $_[0]->get_port,
        Ircname  => $_[0]->get_nickname,
        Options  => $_[0]->get_poco_irc_options,
        Flood    => $_[0]->can_flood,
        Username => $_[0]->get_username,
        Password => $_[0]->get_password,
        %{ $_[0]->get_poco_irc_args },
    );
}

after 'START' => sub {
    my ($self, $heap) = @_[ OBJECT, HEAP ];
};

event irc_001 => sub {
	my ( $self, $heap ) = @_[ OBJECT, HEAP ];
};

event irc_public => sub {
	my ( $self, $nickstr, $channel, $msg ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
	my ($nick) = split /!/, $nickstr;
	
	my $qauth = $self->irc->is_nick_authed("stephan48");
	$self->privmsg("#linuxrulz.bots" => (($qauth) ? $qauth : "stephan48 is not authed!") );
};

event irc_msg => sub {
    my ( $self, $nickstr, $msg ) = @_[ OBJECT, ARG0, ARG1 ];
    my ($nick) = split /!/, $nickstr;

};

LinuxRulz::Bot->run unless caller;
