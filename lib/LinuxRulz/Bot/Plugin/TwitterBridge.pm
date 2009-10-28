package LinuxRulz::Bot::Plugin::TwitterBridge;

use Moses::Plugin;
use namespace::autoclean;
use Data::Dumper;

use LWP::UserAgent;
use URI;
use Carp;

use JSON::Any;

sub S_plugin_add {
	my ( $self, $irc ) = @_;

}

sub S_msg {
    my ( $self, $irc, $nickstr, $target, $msg ) = @_;
	my ($nick) = split /!/, $$nickstr;

    return PCI_EAT_NONE;
}

sub S_bot_addressed {
    my ( $self, $irc, $nickstr, $channel, $msg ) = @_;


    if ( $$msg =~ /^!following/ ) {
		print Dumper($self->{following});
	
		if($self->{following})
		{
			my @names;
		
			for my $h (@{ $self->{following} })
			{
				push(@names, $h->{name});
			}
			
        	$self->privmsg("#linuxrulz.bots" => "Ich folge:".( ($self->{following}) ? join(",", @names) : "Keinem!" ));
		}

        return PCI_EAT_ALL;
    }
	
    if ( $$msg =~ /^!follow (.*)$/ ) {
	 	push(@{$self->{following}}, { name=>$1, url=>""});
	    return PCI_EAT_ALL;
    }

	if ( $$msg =~ /^!unfollow (.*)$/ ) {
		
        return PCI_EAT_ALL;
    }


    if ( $$msg =~ /^!checktweets$/ ) {
		if(!$self->{following})
		{
			$self->privmsg("#linuxrulz.bots" => "No Tweets to lock for!");
			return PCI_EAT_ALL;
		}

		if(@{$self->{following}} > 25)
		{
			$self->privmsg("#linuxrulz.bots" => "Too much followings!");
			return PCI_EAT_ALL;
		}

		my $ua = LWP::UserAgent->new;

		foreach my $entry(@{$self->{following}}) {
			my $name       = $entry->{name};
			my $refreshuri = $entry->{url};
			
			my $uri = URI->new("http://search.twitter.com/search.json");
							
			if($refreshuri)
			{
				$uri->query($refreshuri);
			}
			else
			{
				$uri->query_form(
					q => "from:$name",
        		);
			}
			
	        my $r = $ua->get($uri);

        	$r->is_success or croak join("\n", $uri, $r->status_line, $r->as_string);

        	my $statuses = JSON::Any->from_json($r->content);
        	print Dumper($statuses);
			
			my @results = @{$statuses->{results}};
        	
			if(!@results)
        	{
            	$self->privmsg("#linuxrulz.bots" => "No (New) Tweets for $name found!");
				next;
        	}

        	foreach my $status (@results) {
				
            	my $from_user = $status->{from_user};
            	my $text = $status->{text};
            	my $line = "[TWITTER]$from_user: $text";
            	$self->privmsg("#linuxrulz.bots" => "$line");
        	}
			$statuses->{refresh_url} =~ /^\?(.+)/;
			$entry->{url} = $1;
		}
		
        return PCI_EAT_ALL;
    }

	return PCI_EAT_NONE;
}
 
__PACKAGE__->meta->add_method( S_public => \&S_bot_addressed );

1;
