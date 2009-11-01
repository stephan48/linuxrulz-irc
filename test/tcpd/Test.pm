package Test;
use MooseX::POE;

use POE::Session;
use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;
use Socket;

use Data::Dumper;

has _socketfactory => (
    isa        => 'Any',
    accessor   => 'socketfactory',
    lazy_build => 1,
);

has _clients  => (
    isa	=> 'HashRef',
	is	=> 'rw',        
	
);

sub _build__socketfactory {
	my $self = shift;
	unlink "/home/linuxrulz/bots/linuxrulz/var/bot.socket" if -e "/home/linuxrulz/bots/linuxrulz/var/bot.socket";

	$self->_clients({});
	return POE::Wheel::SocketFactory->new(
       				SocketDomain => PF_UNIX,
			        BindAddress  => '/home/linuxrulz/bots/linuxrulz/var/bot.socket',
        			SuccessEvent => 'got_client',
        			FailureEvent => 'got_error',

	);
}

sub START  {
	POE::Kernel->alias_set("socketfactoy_session");
	warn "start";
}

event shutdown => sub {
	die(1);
	my $self = @_;
	$self->_clients({});
	$self->socketfactory(undef);
	POE::Kernel->alias_remove("socketfactoy_session");
};

event got_client => sub { 

	my ( $self, $client_socket ) = @_;

    my $io_wheel = POE::Wheel::ReadWrite->new(
    	Handle => $client_socket,
        InputEvent => "on_client_input",
        ErrorEvent => "on_client_error",
	);

	$self->_clients->{ $io_wheel->ID() } = $io_wheel;
};

event got_error => sub {
	my ($self, $syscall, $errno, $error) = @_;
	$error = "Normal disconnection." unless $errno;
	warn "Server socket encountered $syscall error $errno: $error\n";
	$self->socketfactory(undef);
};

event got_client_error => sub {
	my ( $self, $wheel_id ) = @_;
    delete $self->_clients->{$wheel_id};
};

event got_client_input => sub {
	my ($self, $input, $wheel_id) = @_;
	
	if($input eq "quit")
	{
		POE::Kernel->post("socketfactoy_session", "shutdown");
		return;
	}
	else
	{
		$input =~ tr[a-zA-Z][n-za-mN-ZA-M]; # ASCII rot13
    	$self->_clients->{$wheel_id}->put($input);
	}
};




1;
