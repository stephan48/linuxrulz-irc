package LinuxRulz::Random;
use LWP::UserAgent;
use URI;
use Carp;

sub generate_integer {
    my ( $min, $max, $count ) = @_;
    my $uri = URI->new("http://www.random.org/integers/");
    $uri->query_form(
                     num => $count,
                     min => $min,
                     max => $max,
                     base => 10,
                     col => $count,
                     "format" => "plain",
                     rnd => "new",
                     );

    my $ua = LWP::UserAgent->new;
    my $r = $ua->get($uri);
	
    $r->is_success or croak join("\n", $uri, $r->status_line, $r->as_string);
    chomp( my $number = $r->content );
	
    return $number;
}

1;
