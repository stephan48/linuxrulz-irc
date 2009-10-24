package TestPlugin;

use Moses::Plugin;
use namespace::autoclean;
use Data::Dumper;

sub S_public {
	my $self = shift;
	$self->bot->debug("\n\nTestPlugin got Public MSG! This confirms that plugin loading worked and we have a valid bot attrib content(i hope so)\n\n");
}

1;
