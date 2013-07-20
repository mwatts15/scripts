#!/usr/bin/env perl
use strict;
sub bar
{
    my ($width, $max, $value) = @_;
    $width = $width - 2;
    my $bar = "[";
    $bar .= C_start("#12ab30");
    for (0 .. $width * $value / $max)
    {
        $bar .= "=";
    }
    for ($width * $value / $max .. $width)
    {
        $bar .= ' ';
    }
    $bar .= C_end();
    $bar .= "]";
}
sub C_start
{
    "<fc=$_[0]>";
}

sub C_end
{
    "</fc>";
}

sub C
{
    C_start($_[0]) . $_[1] . C_end();
}

my $mixer = shift;

my $volume = `amixer sget $mixer | tail -n 1 | sed 's/.*\\[\\([[:digit:]]\\+\\)%\\].*/\\1/'`;
chomp $volume;
print "$mixer: $volume " . bar(20,100,$volume);
