#!/usr/bin/perl
use warnings;
use strict;
use POE;
use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;

# Start a server, and run it until it's done.
Server::spawn('/tmp/poe-unix-socket');
$poe_kernel->run();
exit 0;
###############################################################################
# The UNIX socket server.
package Server;
use POE::Session;    # For KERNEL, HEAP, etc.
use Socket;          # For PF_UNIX.

# Spawn a UNIX socket server at a particular rendezvous.  jinzougen
# says "rendezvous" is a UNIX socket term for the inode where clients
# and servers get together.  Note that this is NOT A POE EVENT
# HANDLER.  Rather it is a plain function.
sub spawn {
  my $rendezvous = shift;
  POE::Session->create(
    inline_states => {
      _start     => \&server_started,
      got_client => \&server_accepted,
      got_error  => \&server_error,
    },
    heap => {rendezvous => $rendezvous,},
  );
}

# The server session has started.  Create a socket factory that
# listens for UNIX socket connections and returns connected sockets.
# This unlinks the rendezvous socket
sub server_started {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  unlink $heap->{rendezvous} if -e $heap->{rendezvous};
  $heap->{server} = POE::Wheel::SocketFactory->new(
    SocketDomain => PF_UNIX,
    BindAddress  => $heap->{rendezvous},
    SuccessEvent => 'got_client',
    FailureEvent => 'got_error',
  );
}

# The server encountered an error while setting up or perhaps while
# accepting a connection.  Register the error and shut down the server
# socket.  This will not end the program until all clients have
# disconnected, but it will prevent the server from receiving new
# connections.
sub server_error {
  my ($heap, $syscall, $errno, $error) = @_[HEAP, ARG0 .. ARG2];
  $error = "Normal disconnection." unless $errno;
  warn "Server socket encountered $syscall error $errno: $error\n";
  delete $heap->{server};
}

# The server accepted a connection.  Start another session to process
# data on it.
sub server_accepted {
  my $client_socket = $_[ARG0];
  ServerSession::spawn($client_socket);
}
###############################################################################
# The UNIX socket server session.  This is a server-side session to
# handle client connections.
package ServerSession;
use POE::Session;    # For KERNEL, HEAP, etc.

# Spawn a server session for a particular socket.  Note that this is
# NOT A POE EVENT HANDLER.  Rather it is a plain function.
sub spawn {
  my $socket = shift;
  POE::Session->create(
    inline_states => {
      _start           => \&server_session_start,
      got_client_input => \&server_session_input,
      got_client_error => \&server_session_error,
    },
    args => [$socket],
  );
}

# The server session has started.  Wrap the socket it's been given in
# a ReadWrite wheel.  ReadWrite handles the tedious task of performing
# buffered reading and writing on an unbuffered socket.
sub server_session_start {
  my ($heap, $socket) = @_[HEAP, ARG0];
  $heap->{client} = POE::Wheel::ReadWrite->new(
    Handle     => $socket,
    InputEvent => 'got_client_input',
    ErrorEvent => 'got_client_error',
  );
  $heap->{client}->put("Welcome to the Unix Socket Server.",
    "I will reverse what you type and echo it back.");
}

# The server session received some input from its attached client.
# Echo it back.
sub server_session_input {
  my ($heap, $input) = @_[HEAP, ARG0];
  $input = reverse($input);
  $heap->{client}->put($input);
}

# The server session received an error from the client socket.  Log
# the error and shut down this session.  The main server remains
# untouched by this.
sub server_session_error {
  my ($heap, $syscall, $errno, $error) = @_[HEAP, ARG0 .. ARG2];
  $error = "Normal disconnection." unless $errno;
  warn "Server session encountered $syscall error $errno: $error\n";
  delete $heap->{client};
}

