#!/usr/bin/env perl
# transforms this:
#  <bytes> <path>
# into this:
#  <human_readable> <path> <nice_looking percentage bar>
# meant to be used with the du utility
use strict;
sub string_round
{
    if (scalar(@_) < 1)
    {
        return;
    }
    my ($float, $precision)= @_;
    if (!$precision)
    {
        $precision=2;
    }
    sprintf "%.${precision}f", $float;
}

sub prettybyte
{
    my $n = shift;
    my $precision = shift;

    my $unit = 1024;
    my @affix = qw/B KiB MiB GiB TiB/;
    my $affix_c = 0;


    while (($n > $unit) and ($affix_c < (scalar @affix)-1)) {
        $n/=$unit;
        $affix_c++;
    }
    return string_round(${n}, $precision) . " $affix[$affix_c]";
}

sub bar
{
    my ($width, $max, $value) = @_;
    $width = $width - 2;
    my $bar = "[";
    my $bar_end = $width * $value / $max;
    for (0 .. $bar_end)
    {
        $bar .= '=';
    }
    for ($bar_end + 1 .. $width)
    {
        $bar .= ' ';
    }
    $bar .= "]";
#$bar;
}

my $max_path_len = 0;
my $max_bytes = 0;
my @byteslist = ();
my @pathlist = ();
while (my $line = <STDIN>)
{
    chomp($line);
    my ($bytes, $path) = split /[[:space:]]+/, $line, 2;
    if ($max_bytes < $bytes)
    {
        $max_bytes = $bytes;
    }
    if ($max_path_len < length($path))
    {
        $max_path_len = length($path);
    }
#print $bytes . "\n";
    push @byteslist, $bytes;
    push @pathlist, $path;
}

my $i;
my $barwidth = 40;
for ($i = 0 ; $i < scalar(@byteslist); $i++)
{
    printf "%11s  %-${max_path_len}s  %${barwidth}s\n", prettybyte($byteslist[$i] * 1024, 2), $pathlist[$i],
           bar(${barwidth},  $max_bytes, $byteslist[$i]);
}
