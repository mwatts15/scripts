#!/usr/bin/env perl
use strict;
use Cwd;
use Env;
use File::Basename;
use File::Spec;
use Getopt::Std;
use feature "switch";

my $CWD = cwd;
my $HOME = $ENV{'HOME'};
my $TARGETS = "$HOME/.mproj_targets";
my $BASE = basename($CWD);
my $TGF;
my %project_hash = ();

my @unalias_list = ();

sub natatime ($@)
{
    my $n = shift;
    my @list = @_;

    return sub
    {
        return splice @list, 0, $n;
    }
}

my @actions_list = (
    "add" =>
    {
        arg=>"PROJECT_NAME PROJECT_DIRECTORY", 
        desc=>"Add an entry to the project list",
        act=>sub {
            my ($pname, $dir) = @_;
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
    },
    "add-remote" => 
    {
        arg=>"PROJECT_NAME REMOTE_DIRECTORY", 
        desc=>"Add the remote directory (e.g., upstream git) for the project", 
        act=>\&add_remote
    },
    "put-remote" => 
    {
        arg=>"PROJECT_NAME FILE_TO_TRANSFER",
        desc=>"Copy a file from the project directory to the configured remote directory over SSH",
        act=> \&scp_to_remote
    },
    "rm" => 
    {
        arg=> "PROJECT_NAME",
        desc=>"Remove the project entry",
        act=>\&remove_entry
    },
    "list" => {desc=>"List projects", act=>\&print_project_list},
    "help" => {desc=>"Print this help message", act=>\&print_help}
);

my %actions = @actions_list;

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

# Gets the maximum length of strings in each column of an array of arrayrefs of strings
sub column_widths
{
    my @a = @_;
    my @maxes = map { 0 } @{$a[0]};
    my $len = @maxes;
    for my $ent (@a)
    {
        my @arr = @$ent;
        for (my $i = 0; $i < $len; $i++)
        {
            if ($maxes[$i] < length($arr[$i]))
            {
                $maxes[$i] = length($arr[$i]);
            }
        }
    }
    @maxes;
}

sub column_widths_to_format_string
{
    my @column_widths = @_;
    join(" ", map {"%-${_}s"} @column_widths);
}

sub print_project_list
{
    my @field_names = qw/Directory Remote/;
    my @fields = qw/dir remote/;
    my $nfields = scalar(@fields);
    my @column_widths = (20, 30, 30);
    my $format_string = &column_widths_to_format_string(@column_widths). "\n";

    my @project_names = sort(keys %project_hash);
    my @data = ();

    for my $pname (@project_names)
    {
        #printf "=%s\n", &desanitize_project_data($pname);
        for my $i (0..($nfields-1))
        {
            my $v = $project_hash{$pname}{$fields[$i]};
            if ($v)
            {
                $v = &desanitize_project_data($v);
                my $x = "$pname";
                if ($i > 0)
                {
                    $x = "";
                }
                if ($fields[$i] eq 'dir')
                {
                    $v =~ s/^\Q${HOME}\E/\$HOME/;
                }
                my @l = (&desanitize_project_data($x), $field_names[$i]. ":", &desanitize_project_data($v));
                push @data, \@l;
                #printf "%s:%s\n", $field_names[$i], ;
            }
        }
    }
    my @widths = column_widths(@data);
    my $format = &column_widths_to_format_string(@widths). "\n";
    for my $ent (@data)
    {
        printf $format, @$ent;
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
        print FH "alias go$printed_name=\"cdcd $dir\"\n";
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
    my @args = map {&sanitize_project_data($_)} @_;
    
    my $action = $actions{$action};
    if (defined $action)
    {
        if (ref($action) eq 'HASH')
        {
            my %act_data = %{$action};
            $act_data{act}(@args);
        }
        elsif (ref($action) eq 'CODE')
        {
            &{$action}(@args);
        }
    }
}

sub print_help
{
    my $it = natatime 2, @actions_list;

    my @help_data = ();
    print "Usage: " . basename($0) . " COMMAND\n";
    print "Manage project data.\n"; 
    print "\n"; 
    print "Available commands:\n";
    while (my @t = $it->())
    {
        my ($key, $ent) = @t;
        my @l = ();
        push @l, $key . " ";
        my $reftype = ref($ent);
        if ($reftype eq 'HASH')
        {
            my %h = %$ent;
            my $s = "";
            if (defined $h{arg})
            {
                $l[0] .= $h{arg};
            }

            $s .= $h{"desc"};
            push @l, $s;
        }
        else
        {
            push @l, "";
        }
        push @help_data, \@l;
    }
    my @cdata = column_widths(@help_data);
    @cdata = map { $_ + 2 } @cdata;
    my $format = column_widths_to_format_string(@cdata);
    for my $d (@help_data)
    {
        printf "$format\n", @$d;
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
