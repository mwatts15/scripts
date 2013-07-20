#!/usr/bin/env perl
my @killarray = (0..70);
for my $i (@killarray)
{
    $killarray[$i] = 1;
}

foreach $n (reverse(0..20))
{
    printf('${color %02x%02x%02x}', 6*$n, $n, 4*$n);
    foreach $cat (0..70)
    {
       if ($killarray[$cat] == 1)
       {
           print '|';
       } else {
           print ' ';
       }
    }
    print "\n";
    $killarray[rand(70)] = 0;
#    print %killarray;
}
