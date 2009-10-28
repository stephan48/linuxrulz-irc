package HTTPDPlugin;

use Moose;
use namespace::autoclean;
use Data::Dumper;

use POE;
use POE::Component::Server::HTTP;
use HTTP::Status;

has _httpdaliases => (
    isa        => 'HashRef',
    accessor   => 'httpdaliases',
    lazy_build => 1,
);

sub _build__httpdaliases {
	POE::Component::Server::HTTP->new(
    	Port => 8000,
    	ContentHandler => {
        	'/' => \&handler,
		},
		Headers => { Server => 'My Server' },
	);
}

sub handler {
	my ($request, $response) = @_;
    $response->code(RC_OK);
    $response->content("Hi, you fetched ". $request->uri);
    return RC_OK;
}



#LinuxRulz::Bot::Plugin::HTTPDPlugin->new();
1;
