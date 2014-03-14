#!/usr/bin/env perl
use strict;
use Fcntl;
use POSIX qw(mkfifo);

my $pipe="/tmp/$ENV{'USER'}-xmobar-vol-ipc-pipe";

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

if (not(-e $pipe and -p $pipe))
{
    unlink($pipe);
    mkfifo($pipe,0777) or die "couldn't make the pipe!";
}
sysopen(OUT, $pipe, O_WRONLY | O_NONBLOCK);
my $mixer = shift;
my $volume = `amixer sget $mixer | tail -n 1 | sed 's/.*\\[\\([[:digit:]]\\+\\)%\\].*/\\1/'`;
my $muted = `amixer sget Master | tail -n 1 | grep -o off`;
if ( $muted )
{
    $volume = "<fc=red>Muted</fc>";
}
chomp $volume;
print OUT "$mixer: $volume " . bar(20,100,$volume) . "\n";
