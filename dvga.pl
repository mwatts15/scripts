#!/usr/bin/perl
# author: Mark Watts <mark.watts@utexas.edu>
# date: Tue Dec 29 06:35:37 CST 2015

use strict;

use Env;
use CStore qw/parse/;
use Dmenu qw/show_menu/;

sub stringify_confs {
    my $h = shift;
    my %hash = %{$h};
    my @res = ();
    for my $k (sort(keys(%hash))) {
        my %dat = %{$hash{$k}};
        push @res, "$k [$dat{conf}] $dat{desc}";
    }
    @res;
}

sub main {

    my $LIST = $ENV{'DVGA_LIST'};
    my $VGAON = $ENV{'DVGA_VGAON'};

    if (! defined $LIST) {
        $LIST = "$ENV{'HOME'}/.vgaconf-list";
    }

    if (! defined $VGAON) {
        $VGAON = "$ENV{'HOME'}/bin/vgaon";
    }
    open my $F, "+<", $LIST;
    my $h = parse($F);
    my @arr = stringify_confs($h);
    my $choice = show_menu "dmenu", @arr;
    if (defined $choice) {
        my ($key, undef) = split / /, $choice, 2;
        my $conf = $h->{$key}{conf};
        my $cmd = "VGA_CONFIG=$conf $VGAON";
        print($cmd . "\n");
        system($cmd);
    }
}
main;
