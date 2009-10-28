package LinuxRulz::Bot::Plugin::HTTPDPlugin;

use Moses::Plugin;
use namespace::autoclean;
use Data::Dumper;

use POE::Component::Server::HTTP;
use HTTP::Status;

with "LinuxRulz::Bot::Role::Plugin";

has _httpdaliases => (
    isa        => 'HashRef',
    accessor   => 'httpdaliases',
	builder    => '_build__httpdaliases',
    lazy_build => 1,
);

sub _build__httpdaliases {
	my $self = shift;
	POE::Component::Server::HTTP->new(
    	Port => 8000,
    	ContentHandler => {
        	'/' => sub { $self->handler(@_) },
		},
		Headers => { Server => 'My Server' },
	);
}

sub handler {
	my ($self, $request, $response) = @_;
    $response->code(RC_OK);
    $response->content("Welcome! This site is powered by POE::Component::Server::HTTP which was created in LinuxRulz::Bot::Plugin::HTTPDPlugin and inherits LinuxRulz::Bot::Role::Plugin via Moose with() function!");

	$self->send_msg($self->bot->irc, "" , "#linuxrulz.bots", "chan", "Got HTTP Connection!");

    return RC_OK;
}

after "PCI_register" => sub  {
	my ( $self, $irc ) = @_;

	$self->httpdaliases();
	
	return 1;
};

after "PCI_unregister" => sub  {
    my ( $self, $irc ) = @_;

	POE::Kernel->call($self->httpdaliases->{httpd}, "shutdown");

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
