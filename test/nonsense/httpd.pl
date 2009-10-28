use lib "lib/";

use POE::Component::Server::HTTP;
use HTTP::Status;

my $aliases = POE::Component::Server::HTTP->new(
     Port => 8000,
     ContentHandler => {
           '/' => \&handler,
     },
     Headers => { Server => 'My Server' },
);

  sub handler {
      my ($request, $response) = @_;
      $response->code(RC_OK);
      $response->content("Hi, you fetched ". $request->uri);
      return RC_OK;
  }

POE::Kernel->run;
POE::Kernel->call($aliases->{httpd}, "shutdown");
POE::Kernel->call($aliases->{tcp}, "shutdown")
