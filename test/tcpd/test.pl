use lib '.';

sub POE::Kernel::TRACE_REFCNT () { 1 }

use POE;
use Test;

my $test = Test->new;
$test->_clients;
$test->socketfactory();
POE::Kernel->run();
