#!/usr/bin/env perl
#
use Term::ANSIColor;

my $color = 'red';
if ($ARGV[0]) {
    $color = $ARGV[0];
}
print $color;

while (<STDIN>) {
    s<(((ht|f)tp(s?))\://)?(www.|[a-zA-Z].)[a-zA-Z0-9\-\.]+\.(com|edu|gov|mil|net|org|biz|info|name|museum|us|ca|uk)(\:[0-9]+)*(/($|[a-zA-Z0-9\.\,\;\?\'\\\+&%\$#\=~_\-]+))*><color($color) . $& . color('reset')>eg;
    print;
}
