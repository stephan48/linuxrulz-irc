use Carp;
use Config::JFDI;
use Data::Dumper;

use lib '/home/linuxrulz/libs/perl/';
use lib '/home/linuxrulz/catalyst/LinuxRulz/lib/';

use LinuxRulz::Schema;

my $config = Config::JFDI->new(name => "linuxrulz", path => "/home/linuxrulz/catalyst/LinuxRulz/");
my $database    = LinuxRulz::Schema->connect($config->get->{'Model::DataBase'}->{'connect_info'});

if(!$database)
{
	croak "Connection to DataBase could not be established!";
}



die Dumper($database->resultset('Glossar')->find_by_title("öde"));

