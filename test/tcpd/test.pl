use lib '.';

use POE;
use Test;

my $test = Test->new;
$test->socketfactory();
POE::Kernel->run();
