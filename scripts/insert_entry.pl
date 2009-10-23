use strict;
use warnings;

#use lib '/home/linuxrulz/catalyst/LinuxRulz/lib/';
use lib '/home/linuxrulz/libs/perl/';

use LinuxRulz::Schema;
use Config::JFDI;
use Data::Dumper;

my $config = Config::JFDI->new(name => "linuxrulz", path => "/home/linuxrulz/catalyst/LinuxRulz/");

print Dumper(\$config->get->{'Model::DataBase'}->{'connect_info'});
my $db = LinuxRulz::Schema->connect(@{$config->get->{'Model::DataBase'}->{'connect_info'}});

$db->resultset('Glossar')->create_entry("Test","Test");
