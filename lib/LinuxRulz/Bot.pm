package LinuxRulz::Bot;
use utf8;

use Moses;
use namespace::autoclean;

use Carp;
use Config::JFDI;
use Data::Dumper;
use YAML qw(LoadFile) ;

use lib '/home/linuxrulz/libs/perl/';
use lib '/home/linuxrulz/catalyst/LinuxRulz/lib/';

use LinuxRulz::Schema;
use LinuxRulz::LDAP;
use LinuxRulz::Bot::Logger;

use POE::Component::IRC::Qnet::State;
use POE::Component::IRC::Plugin qw( :ALL );

binmode STDIN, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $config = LoadFile("etc/config.yaml");

server   '127.0.0.1';
port     '9000';
password $config->{bncpw};
username 'linuxrulz';
nickname 'Linuxrulz';

channels   (
	"#linuxrulz.bots",
	"#linuxrulz",
);

poco_irc_args ( Debug => 1, plugin_debug=>1 );

plugins (
	'auth'  => 'LinuxRulz::Bot::Plugin::AuthPlugin',
	'test'  => 'LinuxRulz::Bot::Plugin::TestPlugin',
	'admin' => 'LinuxRulz::Bot::Plugin::AdminPlugin',
	'glossar' => 'LinuxRulz::Bot::Plugin::GlossarPlugin',
	'unixd'   => 'LinuxRulz::Bot::Plugin::UNIXDPlugin',
#	'TwitterBridge'   => 'LinuxRulz::Bot::Plugin::TwitterBridge',
#	'TCPDPlugin' => 'LinuxRulz::Bot::Plugin::TCPDPlugin',
);

owner 'stephan48!stephanj@stephan48.users.quakenet.org';

has database => (
    isa      => 'Object',
    is       => 'rw',
    required => 0,
);

has ldap => (
    isa      => 'Object',
    is       => 'rw',
    required => 0,
);

has config => (
    isa      => 'Object',
    is       => 'rw',
    required => 0,
);

sub _build__irc {
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

sub _build_logger {
	return LinuxRulz::Bot::Logger->new(configfile => "/home/linuxrulz/bots/linuxrulz/etc/log4perl.cfg", checktime => 10, namespace => "LinuxRulzBot");
}

after 'START' => sub {
    my ($self, $heap) = @_[ OBJECT, HEAP ];
	
	my $config = Config::JFDI->new(name => "linuxrulz", path => "/home/linuxrulz/catalyst/LinuxRulz/");
	
	my $database    = LinuxRulz::Schema->connect($config->get->{'Model::DataBase'}->{'connect_info'});

	if(!$database)
	{
		croak "Connection to DataBase could not be established!";
	}
	
	my $ldap_config = $config->get->{'Model::LDAP'};
	my $ldap        = $ldap_config->{connection_class}->new(%{$ldap_config});
	my $mesg        = $ldap->bind(%{$ldap_config});

	croak 'LDAP error: ' . $mesg->error if $mesg->is_error;

	$self->ldap( $ldap );
	$self->database( $database );
	$self->config( $config );
};

event irc_001 => sub {
	my ( $self, $heap ) = @_[ OBJECT, HEAP ];
};

event irc_public => sub {
	my ( $self, $nickstr, $channel, $msg ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
	my ($nick) = split /!/, $nickstr;
	
};

event irc_msg => sub {
    my ( $self, $nickstr, $msg ) = @_[ OBJECT, ARG0, ARG1 ];
    my ($nick) = split /!/, $nickstr;

};

event irc_disconnected => sub {
   my ($self) = @_;

   POE::Kernel->post( $self->irc_session_id => unregister => 'all' );

   exit 0;
};

1;
