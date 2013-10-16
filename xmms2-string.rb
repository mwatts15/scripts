#!/usr/bin/env ruby

require 'xmmsclient'
require 'prelude'
require 'socket'

$PIPE_PATH = "/tmp/#{ENV["USER"]}-xmms2-string-ipc-pipe"

$xc = Xmms::Client.new("xmms2-stirg")
begin
    $xc.connect()
rescue Xmms::Client::ClientError => e
    $stderr.puts "Couldn't connect to daemon, trying to start it"
    `xmms2-launcher`
    ntries = 1
    while $? != 0
        if ntries > 4
            exit "Can't start xmms2d. Exiting."
        end
        $stderr.puts "Coludn't start the daemon, trying again..."
        sleep 3
        `xmms2-launcher -vvvv`
        ntries += 1
    end
    $stderr.puts "Connected."
end

def extract_medialib_info(id, *fields)
    infos = $xc.medialib_get_info(id).wait.value
    res = Hash.new

    fields = fields.map! {|f| f.to_sym }
    fields.each do |field|
        values = infos[field]
        if not values.nil?
            my_value = values.first[1] # actual value from the top source [0]
            if field == :url
                my_value = decode_xmms2_url(my_value)
            end
            res[field] = my_value.to_s.force_encoding("utf-8")
        end
    end
    res
end
$fields = [:title, :artist, :album]

$info = nil
$string = ""

def get_string(sep="::",undef_string="UNDEF")
    $current_id = $xc.playback_current_id.wait.value
    $info = extract_medialib_info($current_id, *$fields, :duration)
    info = $fields.map{|f| if $info[f] == nil then undef_string else $info[f] end}
    max_width = info.map{|k| k.real_length}.max
    begin
        string = info.map{|i| "#{i[0,max_width]}" }.join(sep) << "\n"
        max_width -= 1
        print "doing this\n"
    end while (string.real_length > 70)
    $string = string
end

$xc.broadcast_playback_current_id.notifier do |res|
    get_string
end

get_string

while true do
    begin
        p = $xc.playback_playtime.wait.value
    rescue TypeError => e
        p = $xc.playback_playtime.wait.value
    end
    d = $info[:duration].to_i
    r = (p * $string.length) / d
    print String.new($string).insert(r, "</fc>").insert(0,"<fc=#8aadb9>")
    STDOUT.flush
    sleep 1
end
