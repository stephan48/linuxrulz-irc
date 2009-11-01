use lib '.';

use POE;
use Test;

my $test = Test->new;
$test->_clients;
$test->socketfactory();
POE::Kernel->run();
