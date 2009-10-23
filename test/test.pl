((?:[a-z][a-z0-9_]*))#!/usr/bin/perl

# URL that generated this code:
# http://txt2re.com/index.php3?s=!test%20abv&2

$txt='!test abv';

$re1='.*?';	# Non-greedy match on filler
$re2='((?:[a-z][a-z0-9_]*))';	# Variable Name 1

$re=$re1.$re2;
if ($txt =~ m/!((?:[a-z][a-z0-9_]*))/is)
{
    $var1=$1;
    print "($var1) \n";
}

#-----
# Paste the code into a new perl file. Then in Unix:
# $ perl x.pl 
#-----

