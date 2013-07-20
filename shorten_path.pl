#!/usr/bin/env perl
use strict;

use File::Basename;
use Env qw(HOME USER);

# debug printer
my $g_debug = 0;
sub dprint
{
    if ($g_debug)
    {
        print @_;
    }
}

# The full path
my $path = $ARGV[0];
# The last directory in the path.
my $basename = basename($path);

# The maximum length of the result string
my $max_length = int($ARGV[1]);

# Strings that we will never shorten
my %important_strings = ($USER => 1, $basename => 1, ".." => 1);

# The last path length seen in the OUTER loop
my $last_length = length($path);

# Used in the algorithm below
my @path_items = split(m{/},$path);

# Get the longest path element length
my $max_elem_length = 0;
for my $dir (@path_items)
{
    if (($max_elem_length < length($dir)) and (not $important_strings{$dir}))
    {
        $max_elem_length = length($dir);
    }
}

# We want to *shorten* strings, so the maximum has to come down
$max_elem_length -= 1;
dprint "maximum element length = $max_elem_length\n";

OUTER:
while (1)
{
    my @path_items = split(m{/},$path);
    # Shorten every element in the path 
    # to one less than the longest. Checking on EACH element if the string is
    # short enough now.
    my @new_path_items = @path_items;
    my $i = 0;
    for my $dir (@path_items)
    {
        dprint "important string? $important_strings{$dir}\n";
        if (not $important_strings{ $dir })
        {
            $new_path_items[$i] = substr($dir, 0, $max_elem_length);
        }
        $path = join("/", @new_path_items);
        if (length($path) < $max_length)
        {
            last OUTER;
        }
        $i += 1;
        dprint "length(path) =" . length($path) . "\n";
        dprint "path = $path\n";
        dprint "\n";
    }

    if ($last_length != length($path))
    {
        $last_length = length($path);
    }
    else
    {
        dprint "Short as we get!\n";
        last OUTER;
    }
    $max_elem_length -= 1;
}
print "$path\n";
