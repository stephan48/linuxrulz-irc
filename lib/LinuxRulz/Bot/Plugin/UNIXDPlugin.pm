package LinuxRulz::Bot::Plugin::UNIXDPlugin;

use Moses::Plugin;
use namespace::autoclean;
use Data::Dumper;

use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;
use Socket;

with "LinuxRulz::Bot::Role::Plugin";

has _socketfactory => (
    isa        => 'Any',
    accessor   => 'socketfactory',
    lazy_build => 1,
);

has _clients  => (
    isa => 'HashRef',
    is  => 'rw',

);

sub _build__socketfactory {
    my $self = shift;
    unlink "/home/linuxrulz/bots/linuxrulz/var/bot.socket" if -e "/home/linuxrulz/bots/linuxrulz/var/bot.socket";
    my $socketfactory;

    POE::Session->create(
        inline_states => {
            _start     => sub {
                $socketfactory = POE::Wheel::SocketFactory->new(
                    SocketDomain => PF_UNIX,
                    BindAddress  => '/home/linuxrulz/bots/linuxrulz/var/bot.socket',
                    SuccessEvent => 'got_client',
                    FailureEvent => 'got_error',

                );
                POE::Kernel->alias_set("socketfactoy_session");
            },
            shutdown => sub {
                $self->_clients({});
                $self->socketfactory(undef);
                POE::Kernel->alias_remove("socketfactoy_session");
            },
            got_client => sub { $self->got_client(@_[ARG0..$#_]); },
            got_error  => sub { $self->got_error(@_[ARG0..$#_]); },
            on_client_input  => sub { $self->got_client_input(@_[ARG0..$#_]); },
            on_client_error  => sub { $self->got_client_error(@_[ARG0..$#_]); },
        },
    );

    $self->_clients({});
    $self->socketfactory($socketfactory);
    $socketfactory = undef;

    return $self->socketfactory;
}

sub got_client {
    my ( $self, $client_socket ) = @_;

    my $io_wheel = POE::Wheel::ReadWrite->new(
        Handle => $client_socket,
        InputEvent => "on_client_input",
        ErrorEvent => "on_client_error",
    );
	
	$self->bot->privmsg("#linuxrulz.bots" => "Got Connection!");	

    $self->_clients->{ $io_wheel->ID() } = $io_wheel;
}

sub got_error {
    my ($self, $syscall, $errno, $error) = @_;
    $error = "Normal disconnection." unless $errno;
    warn "Server socket encountered $syscall error $errno: $error\n";
    $self->socketfactory(undef);
}

sub got_client_error  {
    my ( $self, $wheel_id ) = @_;
    delete $self->_clients->{$wheel_id};
}

sub got_client_input {
    my ($self, $input, $wheel_id) = @_;

    if($input =~ /^QUIT (.*)$/)
    {
		$self->bot->irc->yield( quit => "$1");
    }
	elsif($input =~ /^BYE$/)
	{
		delete $self->_clients->{$wheel_id};
	}
	elsif($input =~ /^TEST$/)
	{
		$self->_clients->{$wheel_id}->put("TEST");
	}
	elsif($input =~ /^CHANNELS$/)
	{
		$self->_clients->{$wheel_id}->put("CHANNELS ".(join " ",$self->bot->get_channels));
	}
	elsif($input =~ /^SAY\|(.+)\|(.+)\|$/)
    {
		$self->bot->logger->get_logger("unixd")->trace("$1 $2");
        $self->bot->privmsg($1 => $2);
    }
    else
    {
        $self->_clients->{$wheel_id}->put("UNKNOWN_COMMAND");
    }
}



after "PCI_register" => sub  {
	my ( $self, $irc ) = @_;

	$self->socketfactory();
	
	return 1;
};

after "PCI_unregister" => sub  {
    my ( $self, $irc ) = @_;

	POE::Kernel->post("socketfactoy_session", "shutdown");

    return 1;
};

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

	if($message =~ /^!testhttpd$/)
	{
		$self->send_msg($irc, $nickstr, $where, $source, "Test");
	}

	return PCI_EAT_NONE;
}

__PACKAGE__->meta->add_method( S_public => \&S_bot_addressed );

1;
