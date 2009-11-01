use lib '.';

#sub POE::Kernel::TRACE_REFCNT () { 1 }
#sub POE::Kernel::TRACE_FILES () { 1 }
#sub POE::Kernel::TRACE_FILENAMES () { 1 }

use POE;
use Test;

my $test = Test->new;
$test->socketfactory();
POE::Kernel->run();
