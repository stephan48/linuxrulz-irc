package Test;
use Moose;

use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;
use Socket;

has _socketfactory => (
    isa        => 'Any',
    accessor   => 'socketfactory',
	builder    => '_build__socketfactory',
    lazy_build => 1,
);

has _clients  => (
    isa	=> 'HashRef',
	is	=> 'rw',        
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
			},
      		got_client => sub { $self->got_client(@_); },
      		got_error  => sub { $self->got_error(@_); },
			on_client_input  => sub { $self->got_client_input(@_); },
            on_client_error  => sub { $self->got_client_error(@_); },
    	},
	   	heap => {self => $self},
  	);
	
	return $socketfactory;
}

sub got_client {
	my ( $self, $client_socket ) = @_;

    my $io_wheel = POE::Wheel::ReadWrite->new(
    	Handle => $client_socket,
        InputEvent => "on_client_input",
        ErrorEvent => "on_client_error",
	);

	$self->_clients->{ $io_wheel->ID() } = $io_wheel;
}

sub got_error {
	my ($self, $syscall, $errno, $error) = @_;
	$error = "Normal disconnection." unless $errno;
	warn "Server socket encountered $syscall error $errno: $error\n";
	$self->socketfactory(undef);
}

sub on_client_error  {
	my ( $self, $wheel_id ) = @_;
    delete $self->_clients->{$wheel_id};
}

sub on_client_input {
	my ($self, $input, $wheel_id) = @_;
	$input =~ tr[a-zA-Z][n-za-mN-ZA-M]; # ASCII rot13
    $self->_clients->{$wheel_id}->put($input);
}

1;
