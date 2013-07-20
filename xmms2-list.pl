#!/usr/bin/perl

print "<openbox_pipe_menu>\n";
@items = `xmms2 list`; 
($current) = grep /^->/, @items;
$current =~ s%->\[(\d*)/\d*\].*%$1%;
$i = 1;
for (@items){
    s%^.{0,2}\[\d+/\d+\][ -]+%%;
    s%&%&amp;%g;
    s%>%&gt;%g;
    s%<%&lt;%g;
    s%"%&quot;%g;
    s%\(.*\)$%%;
    chomp;
    ($artist,$title,$id,$channel) = split /:/;
    if ($i == $current)
    {
        print "<separator />";
    }
    print "<item label=\"";
    if (! $artist)
    {
        print "$title";
        if ($channel)
        {
            print " ($channel)";
        }
        print "\">\n";
    } else {
        print "$artist - $title\">\n";
    }
    print "<action name=\"Execute\">\n";
    print "<execute> xmms2 jump $i </execute>\n";
    print "</action>\n";
    print "<action name=\"Execute\">\n";
    print "<execute> xmms2 play </execute>\n";
    print "</action>\n";
    print "</item>\n";
    if ($i == $current)
    {
        print "<separator />";
    }
    $i++;
}
print "</openbox_pipe_menu>\n";

