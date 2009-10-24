package LinuxRulz::Bot;
use lib '.';
use Moses;
use namespace::autoclean;

server   'irc.quakenet.org';
port     '6667';
password '';
username 'linuxrulz';
nickname 'Linuxrulz';

channels   ("#linuxrulz.bots");

poco_irc_args ( Debug => 1, plugin_debug =>1 );

owner 'stephan48!stephanj@stephan48.users.quakenet.org';

event irc_public => sub {
	my ( $self, $heap, $nickstr, $channel, $msg ) = @_[ OBJECT, HEAP, ARG0, ARG1, ARG2 ];
	
	my ($nick) = split /!/, $nickstr;
	
	if($msg eq "!test")
	{
		eval {
			$heap->{_irc}->plugin_get("PlugMan")->load("TestPlugin" => "TestPlugin");
		};
		$self->debug($@ ? "\n\n\n\nDynamic Loading Error:\n$@\n\n" : "\n\nDynamic Loading Worked\n\n");
		$self->privmsg($channel => "Please look in bot Console for Status!");
	}

	if($msg eq "!test2")
    {
        eval {
            $heap->{_irc}->plugin_get("PlugMan")->load("TestPlugin" => "TestPlugin", "bot" => $self);
        };
        $self->debug($@ ? "\n\n\n\nDynamic Loading Error(Should Never happen!):\n$@\n\n" : "\n\nDynamic Loading Worked\n\n");
		$self->privmsg($channel => "Please look in bot Console for Status!");

		if(!$@)
		{
			$self->privmsg( $channel => "Please enter some text in public channel and then look in Console if you see a working confirmation from plugin!");
		}
    }
};

LinuxRulz::Bot->run unless caller;
