package LinuxRulz::Bot::Logger;

use Moose;
use Log::Log4perl;

with qw( Adam::Logger::API );

has configfile => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has checktime => (
    isa      => 'Int',
    is       => 'ro',
    required => 1,
);

has namespace => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has _logger => (
    isa        => 'Log::Log4perl::Logger',
    accessor   => 'logger',
    lazy_build => 1,
    handles    => {
#	alert     => 'fatal',
#	critical  => 'fatal',
#      debug     => 'debug',
#       emergency => 'fatal',
#	error     => 'error',
#       info      => 'info',
#       notice    => 'info',
#       warning   => 'warn',
#	lod		  => 'info',
#	warn      => 'warn',
#	fatal     => 'fatal',
    }
);


sub _build__logger {
	my $self = shift;
	Log::Log4perl::init_and_watch($self->configfile, $self->checktime);
	return Log::Log4perl->get_logger($self->namespace);
}

sub BUILD {
	my $self = shift;
	$self->logger();
}

sub get_logger {
	my $self      = shift;
	my $namespace = shift;
	return Log::Log4perl->get_logger($namespace || $self);
}

sub alert {
	shift->logger->fatal(@_);
}

sub critical {
    shift->logger->fatal(@_);
}

sub debug {
    shift->logger->debug(@_);
}

sub emergency {
    shift->logger->fatal(@_);
}

sub error {
    shift->logger->error(@_);
}

sub info {
    shift->logger->info(@_);
}

sub notice {
    shift->logger->info(@_);
}

sub warning {
    shift->logger->warn(@_);
}

sub log {
    shift->logger->log(@_);
}


1;
__END__
