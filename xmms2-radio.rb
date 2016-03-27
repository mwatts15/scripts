#!/usr/bin/env ruby
require 'xmmsclient'
require 'jcode'
#require 'unicode'
require "event-loop"
module Xmms
    class Client
        def add_to_event_loop
            @io = IO.for_fd(io_fd)

            @io.on_readable { io_in_handle }
            @io.on_writable { io_out_handle }

            EventLoop.on_before_sleep do
                if io_want_out
                    @io.monitor_event(:writable)
                else
                    @io.ignore_event(:writable)
                end
            end
        end
    end
end

$KCODE = 'UTF-8'
$xc = Xmms::Client.new("weblist")
$xc.connect(ENV["XMMS_PATH"])
$xc.add_to_event_loop
$xc.on_disconnect { EventLoop.quit }
$pl = Xmms::Playlist.new($xc, "Default")
$updating = false
if not $xc
    exit "Could not get connection to XMMS2 daemon"
end
if not $pl
    exit "Could not get playlist \"Radio\""
end
def update
    $updating = true
    $stderr.puts "In update()"
    out = File.open("/var/www/tracklist.html", "w:UTF-8")
    s_stdout = $stdout
    $stdout = out
    puts "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">"
    puts "<HTML>"
    puts "<HEAD>"
    puts "<meta http-equiv=\"Content-Type\"  content=\"text/html; charset=utf-8\" />"
    puts "<TITLE>Track Listing</TITLE>"
    puts "<link rel=\"icon\" type=\"image/png\" href=\"/icon.png\" />"
    puts "<link rel=\"stylesheet\" type=\"text/css\" media=\"screen\" href=\"radio.css\" />"
    puts "</HEAD>"
    puts "<body>"
    puts "<div id=\"chname\"><table width=\"700\" border=\"0\"><tr><td align=\"center\"><h1 class=\"blue\">2ck's Radio: Whatever I feel like playing.</h1></td></tr></table></div>"
    if $radio_inactive == true
        puts "<em style=\"font-size:30px\">Sorry but the radio is currently inactive. Please try again some other time.</em></body></html>"
        out.close
        return
    end
    puts "<div id=\"playinc\">"
    puts "<table width=\"700\" border=\"0\">"

    current_time = Time.new
    track_time = current_time
    entries = $pl.entries.wait.value

    playing_entry = 0
    if (val = $pl.current_pos.wait.value)
        playing_entry = val[:position]
    end

    current_entry = playing_entry - 5

    list_header_fmt = "<tr><td width=\"15%%\" class=\"boldblue\">%s</td><td width=\"25%%\" class=\"boldblue\">Artist</td><td width=\"25%%\" class=\"boldblue\">Title</td><td width=\"5%%\" class=\"boldblue\"></td></tr><tr><td colspan=\"5\"><img src=\"/img3/red.gif\" height=\"1\" width=\"100%%\" alt=\"\" /></td></tr>"
    puts list_header_fmt % "Played At"
    #PRINT LOOP
    entries[current_entry,10].each do |id| 
        if not playing_entry
            puts "</table></div></body></html>"
            out.close
            return
        end
        infos = $xc.medialib_get_info(id).wait.value
        artist, title, url =
            [:artist, :title, :url].map do |field|
            value = infos[field].to_a
            if not value.nil?
                value.collect do |source|
                    source[1].to_s.
                        gsub(%r{&},'&amp;').
                        gsub(%r{<},'&lt;').
                        gsub(%r{>},'&gt;')
                end
            end
            end
        duration, times_played, laststarted =
            [:duration, :timesplayed, :laststarted].map do |field|
            value = infos[field].to_a
            if not value.nil?
                value.flatten[1]
            end
            end
        if current_entry <= playing_entry
            if times_played > 0
                track_time = Time.at(laststarted);
            end
        end

        if current_entry == playing_entry
            puts "<meta http-equiv=\"refresh\" content=\"#{duration/1000}\"/>"
            print "<tr style=color:red>"
        else
            print "<tr>"
        end
        print "<td>#{track_time.strftime("%T")}</td>"
        print "<td>#{artist}</td><td>#{title}</td>"
        print "</tr>\n"

        if playing_entry == current_entry
            puts list_header_fmt % "Playing At"
        end
        current_entry += 1
        track_time += duration/1000
    end
    puts "</table>"
    puts "</div>"
    puts "<em>Current time is: #{current_time}</em><br /><br />"
    puts "</body></HTML>"
    out.close
ensure
    $stderr.puts "Leaving update()"
    $updating = false
end
    
$radio_inactive = false
$xc.broadcast_playlist_changed.notifier do |res|
    $stderr.puts "Playlist changed"
    if res[:name] == "Radio"
#        if res[:type] == Xmms::Playlist::CLEAR
#            $radio_inactive = true
#        end
        if not $updating
            update
        end
    end
    true
end
$xc.broadcast_playback_status.notifier do |res|
    $stderr.puts "Playlist playback status changed"
    if (res == Xmms::Client::STOP) or (res == Xmms::Client::PAUSE)
        $radio_inactive = true
    else
        $radio_inactive = false
    end
    if not $updating
        update
    end
    true
end
$xc.broadcast_playlist_current_pos.notifier do |res|
    $stderr.puts "Playlist position changed"
        if not $updating
            update
        end
    true
end
trap("SIGINT") { EventLoop.quit }
EventLoop.run
