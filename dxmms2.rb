#!/usr/bin/env ruby
#require 'xc'
require 'xmmsclient'
require 'uri'
##########################
# simple xmms2 script    #
# for dmenu              #
##########################

#$CONFIG = File.join(Dir.home + ".config/dxmms2")
# default configs {{{
$SCREEN_WIDTH=500
$FONT_WIDTH=10 #in pixels
$BG_COLOR='"#000000"'
$FG_COLOR='"#dc322f"'
$SEL_BG_COLOR=$FG_COLOR
$SEL_FG_COLOR=$BG_COLOR
$FONT='"Sazanami Mincho":pixelsize=' + $FONT_WIDTH.to_s
$LIST_ENTRIES_PER_PAGE = 15
# }}}

#if [ -e $CONFIG ] ; then
    #source $CONFIG
#fi
class Integer
    def ms_to_time_string
        minutes=(self / 60000)
        seconds=(self % 60000) / 1000
        "%d:%02d" % [minutes, seconds]
    end
end

class String
    def initialize
        super
        force_encoding("utf-8")
    end
    def alignr(r, w)
        str = self + r.rjust(Rational(w, $FONT_WIDTH) - r.kanji_off - self.kanji_off - self.length + Integer(w / $FONT_WIDTH) - 2, '.') #+ " #{w/ $FONT_WIDTH}"
        puts str
        str
    end
    def kanji_off
        # Gives me the number of spaces "missing" with double-width
        # kanji characters. Used for formatting adjustment
        (self.bytes.count - self.length) / 2
    end

    def to_perc
        if self.ends_width("%")
            self.to_f / 100.0
        else
            self.to_f * 100
        end
    end
    def scrunch(size,dots='...')
        #self.force_encoding("utf-8")
        #puts "Scrunching"
        if self.length < size
            #puts "Well, that was pointless"
            self
        else
            sidelen = (size - dots.length - self.kanji_off) / 2
            # Not centered; intentional
            self[0..sidelen] + dots + self[-sidelen..-1]
        end
    end
    alias :| alignr
end

def my_dmenu (entries, prompt='dxmms2', height=entries.count, width=$SCREEN_WIDTH)
#width=$SCREEN_WIDTH
    res = ""
    entries.collect! do |line|
        l, r = line.split("|||")
        puts "width=" + width.to_s
        r ? l.alignr(r.scrunch(width / 10), width) : l
    end
    cmdline = "dmenu -f -p \"#{prompt}\" -nf #{$FG_COLOR} \
    -nb #{$BG_COLOR} \
    -sb #{$SEL_BG_COLOR} \
    -sf #{$SEL_FG_COLOR} \
    -i -l #{height} \
    -w #{width} \
    -fn #{$FONT}"
    IO.popen(cmdline, "w+") do |io|
        io.print(entries.join("\n"))
        io.close_write
        res = io.gets
    end
    res.to_s.chomp
end

# returns a hash of the passed in fields
# with the top values for the fields
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

def pl_list(start=nil,nentries=nil,prompt="Track: ")
    morestring="--More--"
    endstring="--End--"
    startstring="--Start--"
    backstring="--Back--"
    listing=1
    nentries = (nentries.nil? ? $LIST_ENTRIES_PER_PAGE : nentries)
    pos = nil
    current = $pl.current_pos.wait.value
    list_start = start.nil? ? 
        (!current.nil? ? current[:position] : 0) : start
    while ( listing == 1 ) do
        start_clamped = false
        end_clamped = false
        entries = $pl.entries.wait.value
        items = Array.new

        #clamps start
        (list_start <= 0) and (list_start = 0 ; start_clamped = true)

        list_end = list_start + nentries

        #clamps end
        (list_end > entries.length) and (list_end = entries.length ; end_clamped = true)


        nw = list_end.to_s.length
        i = list_start

        if not start_clamped
            items << backstring
            items << startstring
        end

        entries[list_start..list_end].each do |id| 
            my_info = extract_medialib_info(id, "artist", "title", "url", "duration")
            artist_part = "#{i.to_s.rjust(nw)}. #{my_info[:artist]}"
            some_title = (my_info[:title] or File.basename(my_info[:url]))
            duration = my_info[:duration].to_i.ms_to_time_string
            items << "#{artist_part}|||#{some_title} [#{duration}]"
            i += 1
        end

        if not end_clamped
            items << endstring
            items << morestring
        end

        choice = my_dmenu(items, prompt, items.length).gsub(/^\s+|\s+$/, "")
        pos = choice[/^-?\d+|#{morestring}|#{backstring}|#{startstring}|#{endstring}/]

        case pos
        when backstring
            list_start -= nentries
        when morestring
            list_start += nentries
        when endstring
            list_start = entries.length - nentries
        when startstring
            list_start = 0
        else
            listing = 0
        end
    end
    if pos.nil? then return nil end

    pos = pos.to_i
    if pos < 0 then entries.length + pos else pos end
end

def decode_xmms2_url (url)
    URI.decode_www_form_component(url)
    #echo "$(perl -MURI::Escape -e 'print uri_unescape($ARGV[0]);' "$url")" 
end

$commands=%w<toggle list +fav prev next stop info change-playlist clear edit-metadata search repeat-playlist repeat-track repeat-off>

$xc = Xmms::Client.new("dxmms2")
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
$pl = $xc.playlist

while (true) do
    command = my_dmenu($commands).chomp
    case command
        # NOTE: The *break statements* in here are for the *while loop*
        #       not for the switch
    when "list"
        # requires 
        #  CLASSIC_LIST=true
        #  CLASSIC_LIST_FORMAT=${artist}::${title}
        # in .config/xmms2/clients/nycli.conf
        pos = pl_list(nil, nil, "Play Track:")
        if not pos.nil?
            puts "moving to positon #{pos}"
            res = $xc.playlist_set_next(pos).wait.value
            #puts res
            $xc.playback_tickle.wait
            $xc.playback_stop.wait
            $xc.playback_start.wait
        end
        break
    when "info"
        entries = $pl.entries.wait.value
        if not entries.nil?
            pos = pl_list(nil,nil,"Track Info:")
            id = entries[pos]
            info = extract_medialib_info(id, *%w<artist title album tracknr favorite timesplayed url date duration laststarted added>)
            my_dmenu(info.map { |k,v| 
                k = k.to_s
                if %w<duration>.include?(k) 
                    v = v.to_i.ms_to_time_string 
                elsif %w<laststarted added lmod>.include?(k)
                    puts "making time"
                    v = Time.at(v.to_i).strftime("%F")
                end
                "#{k.to_s}|||#{v.to_s}"}, "Info", info.size)
        end
        break
    when "search"
        break
    when "+fav"
        id = $xc.playback_current_id.wait.value
        old_favorite = extract_medialib_info(id, :favorite)[:favorite].to_i
        $xc.medialib_entry_property_set(id, :favorite, old_favorite+1).wait
        break
    when "change-playlist"
        playlists = $xc.playlist_list.wait.value
        playlists = playlists.delete_if {|s| s.start_with?("_")}
        selected = my_dmenu(playlists)
        $xc.playlist(selected).load.wait
        #pls=`xmms2 playlist list`
        #nitems=`echo "$pls"|wc -l`
        #pl=`echo "$pls" | cut -c 3- | my_dmenu "Playlist: " ${nitems}`
        #xmms2 playlist switch $pl
        #when edit-metadata
        #url="$(decode_xmms2_url "`xmms2 info | grep url | sed 's/.*=[[:space:]]// ; s%^file://%% ; s%+% %'g`")"
        #picard "$url"
        break
    when %r{repeat-(off|track|playlist)}
        case command.split(%r{-})[1]
        when "off"
            `xmms2 server config playlist.repeat_one 0`
            `xmms2 server config playlist.repeat_all 0`
        when "track"
            `xmms2 server config playlist.repeat_one 1`
            `xmms2 server config playlist.repeat_all 0`
        when "playlist"
            `xmms2 server config playlist.repeat_one 0`
            `xmms2 server config playlist.repeat_all 1`
        end
        break
    else
        if not command.empty?
            `xmms2 #{command}`
        end
        break
    end
end
