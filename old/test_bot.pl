use utf8;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::IRC::Client;

use Carp;
use Perl6::Junction qw/ all any none one /;
use Config::JFDI;
use Data::Dumper;
use lib '/home/linuxrulz/libs/perl/';
use lib '/home/linuxrulz/catalyst/LinuxRulz/lib/';
use LinuxRulz::Schema;
use LinuxRulz::LDAP;

#my $nicks_qauth;
my $commands_right

my $c = AnyEvent->condvar;
my $timer;

my $con = new AnyEvent::IRC::Client;
my $config = Config::JFDI->new(name => "linuxrulz", path => "/home/linuxrulz/catalyst/LinuxRulz/");

my $database    = LinuxRulz::Schema->connect($config->get->{'Model::DataBase'}->{'connect_info'});
my $ldap_config = $config->get->{'Model::LDAP'};
my $ldap        = $ldap_config->{connection_class}->new(%{$ldap_config});
my $mesg        = $ldap->bind(%{$ldap_config});
croak 'LDAP error: ' . $mesg->error if $mesg->is_error;

$con->reg_cb (connect => sub {
	my ($con, $err) = @_;
	if (defined $err) {
        	warn "connect error: $err\n";
       		return;
      	}
});

$con->reg_cb (registered => sub { 
	print "I am registred!!\n";
	$con->send_srv( JOIN => '#linuxrulz.bots');
	$con->send_srv ( PRIVMSG => '#linuxrulz.bots',  "Okey i am Ready!" );
});

$con->reg_cb (disconnect => sub { 
	print "Bye!!\n";
	$c->broadcast;
});

$con->reg_cb (read => sub {
        my ($con,$packet) = @_;
#	if($packet->{command} eq 354 || $packet->{command} eq 352)
#	{
#		#print "Read:",Dumper($packet),"\n";
#	}
});


$con->reg_cb (irc_privmsg => sub {
	my ($con,$packet) = @_;

	my $from    = $packet->{prefix};
	my $to      = $packet->{params}[0];
	my $content = $packet->{params}[1];

	
	my ($nick, $ident, $host);
	
	if($from =~ /(.*)!(.*)@(.*)/)
	{
		$nick    = $1 or undef;
		$ident   = $2 or undef;
		$host    = $3 or undef;
	}
	else
	{
		$host  = $from or undef;
		$ident = undef;
		$host  = undef;
	}

	if($content =~ m|^!(\S+)\s?(.*)?$|)
	{
		if(check_permission_nick($nick,"linuxrulz-user"))
		{
			my $command = $1;
			my $args    = $2 or undef;
			my $command_hash = { to => $to, to_channel => (($to =~ /^#/) ? 1 : 0), from => $from, from_nick => $nick, from_ident => $ident, from_host => $host, command=> $command, args => $args};
			$con->event("linuxrulz_privmsg_command",$command_hash);
		}
		else
		{
                	$con->send_srv ( PRIVMSG => $to, "No Permission!");
		}
	}
	
	if($content eq "!login")
	{
        	$con->send_raw ( "who $nick %nat,1"  );
	}

  #      if($content eq "!printqauths")
 #       {
#		while (my ($nick, $qauth) = each %$nicks_qauth)
#		{
#			$con->send_srv ( PRIVMSG => $to, "Nick $nick has QAuth $qauth");
#		}
#       }
#
#	if($content eq "!quit")
#	{
#		if(check_permission(get_qauth($nick),"owner"))
#		{ 
#			$con->send_srv ( QUIT => "bye!" );
#		}
#		else
#		{
#	                $con->send_srv ( PRIVMSG => $to, "No Permission!");
#		}
#	}
#	
#	if($content =~ m|\!glossar (.*)|)
#	{
#		my $title = $1;
#		#my $title_result = $database->resultset('Glossar')->find_by_title($title);
#		if(1)
#		{
#	                $con->send_srv ( PRIVMSG => $to, "Glossar Eintrag $title gefunden!");
#		}
#		else
#		{
#			$con->send_srv ( PRIVMSG => $to, "Glossar Eintrag $title nicht gefunden!");
#		}
#	}
});

$con->reg_cb (linuxrulz_privmsg_command => sub {
	my ($con, $command) = @_;
	$con->send_srv ( PRIVMSG => $command->{to}, "Passed Auth!");
});

sub get_qauth {
	my $nick = shift;
	return $con->heap->{'nicks_qauth'}->{$nick} or undef;
}

sub check_permission 
{
	my $qauth      = shift or return 0;
	my $permission = shift;
	return $ldap->user_isin_group($qauth,$permission);
#return (any(@{$qauths->{$qauth}}) eq $permission);
}

sub check_permission_nick
{
	my $nick = shift;
	my $permission = shift;
	return check_permission(get_qauth($nick), $permission);
}

$con->reg_cb (irc_352 => sub {
	my ($con, $packet) = @_;

	my $params       = $packet->{params};
        my $to           = @$params[0];
	my $params_count = scalar @$params;


	if($params_count eq 8)
	{
		my $nick  = @$params[5];
                $con->send_raw ( "who $nick %nat,1"  );
	}
});

$con->reg_cb (irc_354 => sub {
        my ($con, $packet) = @_;

	my $params       = $packet->{params};
	my $to           = @$params[0];
	my $queryparam   = @$params[1];

	if ( $queryparam =~ m/\A\d{1,3}\z/ and $queryparam >= 0 and $queryparam < 1000 )
	{
		if($queryparam eq 1)
		{
			my $nick  = @$params[2];
			my $qauth = @$params[3];
			return unless !($qauth eq 0);
	        	$con->heap->{'nicks_qauth'}->{$nick} = $qauth;
			print "Nick $nick has Qauth $qauth\n";
		}
	}
	else
	{
		return;
	}
});

$con->reg_cb (irc_join => sub {
        my ($con, $packet) = @_;

        my $from    = $packet->{prefix};
        my $nick    = ( split /!/, $from )[0];
        $con->send_raw ( "who $nick %nat,1"  );
});


$con->connect ("irc.quakenet.org", 6667, { nick => 'linuxrulz|alpha' });
$c->wait;
$con->disconnect;
