#!/usr/bin/env perl
use strict;
use Cwd;
use Env;
use File::Basename;
use File::Spec;
use Getopt::Std;
use feature qw/switch/;

my $CWD = cwd;
my $HOME = $ENV{'HOME'};
my $TARGETS = "$HOME/.mproj_targets";
my $BASE = basename($CWD);
my $TGF;
my %project_hash = ();

my @unalias_list = ();

sub menu
{
    my @entries = @_;
    my $num_entries = @entries;
    my $menu_index_width = log($num_entries)/log(10);
    my $selection = 0;
    printf("please select a menu entry [1-$num_entries]\n");
    while ($selection < 1 || $selection > $num_entries)
    {
        my $i = 1;
        for my $item (@entries)
        {
            printf "%${menu_index_width}s) $item\n", $i;
            $i++;
        }
        $selection = int(<STDIN>);
    }
    $selection;
}

sub process_arguments
{
    return @ARGV;
}

sub start 
{
    &process_arguments;
    open $TGF, "+<", $TARGETS;
    &parse_targets_file;
}

sub sanitize_project_data
{
    my $data = $_[0];
    # The `#' has to come first so it doesn't get replaced twice in the string
    my @badchars = ("#", ":", " ");
    for my $ch (@badchars)
    {
        my $ch_num = ord($ch);
        $data =~ s/$ch/"#" . sprintf("%05d", $ch_num)/eg;
    }
    $data;
}

sub desanitize_project_data
{
    my $data = $_[0]; 
    $data =~ s/#([0-9]{5})/chr($1)/eg;
    $data;
}

sub parse_targets_file
{
    seek $TGF, 0, 0;
    while (!eof($TGF))
    {
        chomp(my $line = readline $TGF);
        my ($pname, $rest) = split /:/, $line, 2;
        my (%pinfo) = split /:/, $rest;
        $project_hash{$pname} = ();
        for my $key (keys %pinfo)
        {
            $project_hash{$pname}{$key} = $pinfo{$key};
        }
    }
}

sub print_project_list
{
    my @field_names = qw/Directory Remote/;
    my @fields = qw/dir remote/;
    my $nfields = scalar(@fields);
    my @column_widths = (20, 30, 30);
    my $format_string = join(" ", map {"%-${_}s"} @column_widths) . "\n";

    for my $pname (keys %project_hash)
    {
        printf "=%s\n", $pname;
        for my $i (0..($nfields-1))
        {
            my $v = $project_hash{$pname}{$fields[$i]};
            if ($v)
            {
                printf "  %s:%s\n", $field_names[$i], &desanitize_project_data($v);
            }
        }
    }
}

sub save_targets_file
{
    close $TGF;
    open $TGF, ">", $TARGETS;
    for my $pname (keys %project_hash)
    {
        print $TGF "$pname";
        for my $key (keys $project_hash{$pname})
        {
            print $TGF ":$key:$project_hash{$pname}{$key}";
        }
        print $TGF "\n";
    }
}

sub print_zsh_alias_commands
{
    open FH, ">", "$HOME/.project_aliases";
    for my $pname (keys %project_hash)
    {
        my $printed_name = &desanitize_project_data($pname);
        my $dir = &desanitize_project_data($project_hash{$pname}{"dir"});
        print FH "alias go$printed_name=\"cd $dir\"\n";
        print FH "alias ls$printed_name=\"ls $dir\"\n";
        print FH "alias put$printed_name=\"cp -r -t $dir\"\n";
    }

    for my $pname (@unalias_list)
    {
        my $printed_name = &desanitize_project_data($pname);
        print FH "unalias go$printed_name";
        print FH "unalias ls$printed_name";
        print FH "unalias put$printed_name";
    }

    close FH;
}

sub remove_entry
{
    my ($name) = @_;

    delete $project_hash{$name};
}

sub add_entry
{
    my ($name, $dir) = @_;
    if (! defined $project_hash{$name})
    {
        $project_hash{$name} = ();
    }
    else
    {
        printf "The project %s already exists.\n";
        printf "Would you like to: ";
        my $choice = &menu("replace it",
            "only change the directory",
            "abort");
        if ($choice == 3)
        {
            return;
        }
        elsif ($choice == 2)
        {
            printf("replacing directory for %s\n", $name);
        }
        elsif ($choice == 1)
        {
            printf("replacing entry for %s\n", $name);
            $project_hash{$name} = ();
        }
    }

    if (! -d $dir)
    {
        mkdir &desanitize_project_data($dir);
    }
    $project_hash{$name}{"dir"} = $dir;
}

# Remote should be specified with ssh syntax like
# remote-host.com:path/relative/to/home
# or
# remote-host.com:/full-path/from/remote/root
sub add_remote
{
    my ($name, $url) = @_;
    if (defined $project_hash{$name})
    {
        printf "adding $url\n";
        $project_hash{$name}{"remote"} = $url;
    }
}

sub scp_to_remote
{
    my ($pname, $file) = @_;
    my $remote = $project_hash{$pname}{remote};
    $remote = &desanitize_project_data($remote);
    print "scp -r $file $remote/.\n";
    `scp -r $file $remote/.`;
}

sub do_action
{
    my $action = shift @_;
    given($action)
    {
        my @args = map {&sanitize_project_data($_)} @_;
        when (["def", "add"])
        {
            my ($pname, $dir) = @args;
            $dir = File::Spec->rel2abs($dir);
            if (! length($pname))
            {
                $pname = $BASE;
            }

            if (! length($dir))
            {
                $dir = $CWD;
            }
            &add_entry($pname, $dir);
        }
        when ("add-remote")
        {
            my ($pname, $url) = @args;
            &add_remote($pname, $url);
        }
        when ("put-remote")
        {
            my ($pname, $file) = @args;
            &scp_to_remote($pname, $file);
        }
        when ("rm")
        {
            my ($pname) = @args;
            &remove_entry($pname);
        }
        default
        {
            &print_project_list;
        }
    }
}

sub end
{
    &print_zsh_alias_commands;
    &save_targets_file;
    close $TGF;
}

&start;
&do_action(@ARGV);
&end;

# quick tests
#
#&menu(qw/all these fucking entries wont quit/);
#print desanitize_project_data($project_hash{crypto}{remote}) . "\n";
