#!/usr/bin/env ruby

require 'xmmsclient'

puts "<openbox_pipe_menu>\n";
xc = Xmms::Client.new("obxmms2")
begin
xc.connect(ENV["XMMS_PATH"])
rescue
    puts "<item label=\"Cannot connect to XMMS2 daemon\"></item>
    </openbox_pipe_menu>"
    exit 1
end
pl = Xmms::Playlist.new(xc)
i = 1
pl.entries.wait.value.each do |id| 
    info = [xc.medialib_get_info(id).wait.value[:artist].to_a.collect{|n| n[1].to_s.gsub(%r{&},'&amp;').gsub(%r{<},'&lt;').gsub(%r{>},'&gt;')},
            xc.medialib_get_info(id).wait.value[:title].to_a.collect{|n| n[1].to_s.gsub(%r{&},'&amp;').gsub(%r{<},'&lt;').gsub(%r{>},'&gt;')},
            id]
    puts info
    if i == pl.current_pos.wait.value[:position]
        puts "<separator />"
    end
    puts "<item label=\""
    if info[0]
        puts "#{info[0]} - #{info[1]}\">\n";
    else 
        puts info[1];
        if info[2]
            puts " (#{info[2]})";
        end
        puts "\">\n";
    end
    puts "<action name=\"Execute\">\n";
    puts "<execute> xmms2 jump #{i} </execute>\n";
    puts "</action>\n";
    puts "<action name=\"Execute\">\n";
    puts "<execute> xmms2 play </execute>\n";
    puts "</action>\n";
    puts "</item>\n";
    if i == pl.current_pos.wait.value[:position]
        puts "<separator />";
    end
    i += 1
end
puts "</openbox_pipe_menu>\n";
