#!/usr/bin/perl
use strict;
use warnings;
use POE qw(Component::IRC::State);
use POE::Component::IRC::Common qw( :ALL );
use POE::Component::IRC::Plugin::Connector;
use POE::Component::IRC::Plugin::NickReclaim;
use POE::Component::IRC::Plugin::AutoJoin;
use DBI;

my $nickname = 'LinuxRulzLog';
my $ircname = 'LinuxRulzLog V2';
my $server = 'irc.quakenet.org';

my @channels = ('#linuxrulz.dev', '#linuxrulz');

my $dbh = get_dbh();
my $q   = prepare($dbh);

# We create a new PoCo-IRC object
my $irc = POE::Component::IRC::State->spawn( 
   nick => $nickname,
   ircname => $ircname,
   server => $server,
) or die "Oh noooo! $!";

POE::Session->create(
    package_states => [
        main => [ qw(_default _start irc_001 irc_public irc_join irc_nick irc_quit irc_part irc_kick irc_topic irc_ctcp_action irc_chan_mode lag_o_meter) ],
    ],
    heap => { irc => $irc },
);

$poe_kernel->run();

sub _start {
	my ($kernel, $heap) = @_[KERNEL ,HEAP];

    # retrieve our component's object from the heap where we stashed it
    my $irc = $heap->{irc};

    $irc->yield( register => 'all' );

	$heap->{connector} = POE::Component::IRC::Plugin::Connector->new( reconnect => 20, delay => 20);
    $irc->plugin_add( 'Connector' => $heap->{connector} );
    $kernel->delay( 'lag_o_meter' => 20 );

	$irc->plugin_add('AutoJoin', POE::Component::IRC::Plugin::AutoJoin->new( Channels => \@channels ));
	$irc->plugin_add( 'NickReclaim' => POE::Component::IRC::Plugin::NickReclaim->new( poll => 30 ) );

	$irc->yield( connect => { } );

    return;
}

sub irc_001 {
    my $sender = $_[SENDER];

    # Since this is an irc_* event, we can get the component's object by
    # accessing the heap of the sender. Then we register and connect to the
    # specified server.
    my $irc = $sender->get_heap();

    print "Connected to ", $irc->server_name(), "\n";

    return;
}

sub irc_public {
    my ($sender, $who, $where, $what) = @_[SENDER, ARG0 .. ARG2];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

	$what = irc_to_utf8($what);

	dbwrite($channel, $nick, $what);
    return;
}

sub irc_join {
    my ($sender, $who, $where) = @_[SENDER, ARG0 .. ARG1];
    my $nick = ( split /!/, $who )[0];

    dbwrite($where, '', "$nick joined $where");

    return;
}

sub irc_nick {
    my ($sender, $who, $newnick, $where) = @_[SENDER, ARG0 .. ARG2];
    my $nick = ( split /!/, $who )[0];

	foreach my $channel(@{$where})
	{
		dbwrite($channel, '', "$nick is now known as $newnick");
	}
    return;
}

sub irc_quit {
    my ($sender, $who, $message, $where) = @_[SENDER, ARG0 .. ARG2];
	$message = ($message?$message:'No Reason given!');
    my $nick = ( split /!/, $who )[0];

    foreach my $channel(@{$where})
    {
        dbwrite($channel, '', "$nick left irc: $message");
    }

    return;
}

sub irc_part {
    my ($sender, $who, $where, $message) = @_[SENDER, ARG0 .. ARG2];
	$message = ($message?$message:'No Reason given!');
    my $nick = ( split /!/, $who )[0];

    dbwrite($where, '', "$nick left $where ($message)");

    return;
}

sub irc_kick {
    my ($sender, $who, $where, $target, $message) = @_[SENDER, ARG0 .. ARG3];
    $message = ($message?$message:'No Reason given!');
    my $nick = ( split /!/, $who )[0];

    dbwrite($where, '', "$nick was kicked by $who: $message");

    return;
}

sub irc_topic {
    my ($sender, $who, $where, $message) = @_[SENDER, ARG0 .. ARG2];
    $message = ($message?$message:'');
    my $nick = ( split /!/, $who )[0];

	$message = irc_to_utf8($message);

    dbwrite($where, '', "Topic set by $nick for $where is now: $message");

    return;
}

sub irc_ctcp_action {
    my ($sender, $who, $where, $message) = @_[SENDER, ARG0 .. ARG2];
    $message = ($message?$message:'');
    my $nick = ( split /!/, $who )[0];
	my $channel = $where->[0];

	$message = irc_to_utf8($message);

    dbwrite($channel, "* $nick", "$message");

    return;
}

sub irc_chan_mode {
	my ($sender, $who, $where, $mode, $arg) = @_[SENDER, ARG0 .. ARG3];
	$arg = ($arg ? " $arg" : '');

	my $nick;
	if($who =~ /(.+)!.+/)
	{
		$nick = $1;	
	}
	else
	{
		$nick = "Server";
	}

	dbwrite($where, "", "$nick changed mode $mode$arg");	
}

sub lag_o_meter {
     my ($kernel,$heap) = @_[KERNEL,HEAP];
     print 'Time: ' . time() . ' Lag: ' . $heap->{connector}->lag() . "\n";
     $kernel->delay( 'lag_o_meter' => 30 );
     return;
}

# We registered for all events, this will produce some debug info.
sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
    my @output = ( "$event: " );

    for my $arg (@$args) {
        if ( ref $arg eq 'ARRAY' ) {
            push( @output, '[' . join(', ', @$arg ) . ']' );
        }
        else {
            push ( @output, "'$arg'" );
        }
    }
    print join ' ', @output, "\n";
    return 0;
}

sub prepare {
    my $dbh = shift;
    return $dbh->prepare("INSERT INTO irclog (channel, nick, line) VALUES(?, ?, ?)");
}

sub dbwrite {
    my ($channel, $who, $line) = @_;


    # mncharity aka putter has an IRC client that prepends some lines with
    # a BOM. Remove that:
    $line =~ s/\A\x{ffef}//;
    my @sql_args = (lc($channel), $who, $line);
    if ($dbh->ping){
        $q->execute(@sql_args);
    } else {
        $q = prepare(get_dbh());
        $q->execute(@sql_args);
    }
    return;
}

sub get_dbh {
    my $db_dsn = "DBI:Pg:database=linuxrulz;";
    my $dbh = DBI->connect($db_dsn, "linuxrulz", "", {RaiseError=>1, AutoCommit => 1, pg_enable_utf8 => 1});
}

