#!/usr/bin/env ruby
require 'xmmsclient'
#require 'jcode'
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

# TODO: make this cleaner (only add fuzzy_insertion where needed)
#
class Hash
    def fuzzy_insertion(fuzzy, keyval) # only supporting hash[key] = fuzzy(key)
        fuzzy_keys = fuzzy.call(keyval)
        fuzzy_keys.each do |fuzzyk|
            if (self[fuzzyk].nil?)
                self[fuzzyk] = Hash.new
            end
            self[fuzzyk][keyval] = 1
        end
    end
end

$xc = Xmms::Client.new("weblist")
$xc.connect(ENV["XMMS_PATH"]) or exit "Could not get connection to XMMS2 daemon"
$xc.add_to_event_loop
$xc.on_disconnect { EventLoop.quit }
$updating = false
$fields = ["artist", "title", "album"]

$value_lists = Hash.new
$fields.each {|f| $value_lists[f] = Hash.new}

cachedir = File.join(Dir.home, ".cache/lister")
if not File.exists?(cachedir)
    Dir.mkdir(cachedir) or exit "couldn't create directory #{cachedir}"
end
$cache_files = Hash.new
$fields.each {|f| $cache_files[f] = File.open(File.join(cachedir, f), "w")}

def canonicalize_title(value)
    [value.downcase]
end
def canonicalize_album(value)
    [value.downcase]
end
def canonicalize_artist(value)
    res = value.dup
    alt_str = "%alt%"
    transforms = Hash['\b(?<initial>\w)(\.(\s|(?=\w))|\s)',  '\k<initial>.',
                      '^\s+|\s+$', '',
                      '\s*(&|,)\s*|\s+(?i:and|feat\.?)\s+', alt_str,
                     ]
    transforms.each do |k, v|
        res.gsub!(/#{k}/, v)
    end
    res.split(/#{alt_str}/).collect{|a| a.downcase}
end

def update_entry (dict, field)
    methodsym = "canonicalize_#{field}".to_sym
    $value_lists[field].fuzzy_insertion(method(methodsym), dict[field.to_sym].to_s)
end

def startup
    collection = Xmms::Collection.universe
    propdict = $xc.coll_query_info(collection, $fields).wait.value
    propdict.each do |dict|
        $fields.each { |field| update_entry(dict, field) }
    end
end

def update_files
    $updating = true
    # check the time on each of the files against the last
    # medialib_changed/added notification and print out
    # the changed data if the internal time is older than
    # the file time
    $stderr.puts "In update()"
ensure
    $stderr.puts "Leaving update()"
    $updating = false
end

$radio_inactive = false
$xc.broadcast_medialib_entry_changed.notifier do |res|
    puts res.value
    true
end
$xc.broadcast_medialib_entry_added.notifier do |res|
    info = $xc.medialib_get_info(res).wait.value
    $fields.each { |field| update_entry(info, field) }
    puts res.value
    true
end
tests = ["A. B. C. D E FG", "   artist  ", "kenny g.  and james dean and soleil",
"A R Rahman", " A. R. Rahman", "A.R.Rahman", "A.R. Rahman", 
"Kadar Ghulam Mustafa , Murtaza Ghulam Mustafa , Srinivas & A R Rahman",
"Marrion feat. Blu Feat. carmen",
"Bobby Digital - Gorious Day feat. Dexter Wiggles",
"Bobby Digital - Gorious Day feat. Dexter Wiggles",
"Bobby Digital - Insomnia feat. Jay Love",
"Bobby Digital - Insomnia feat. Jay Love",
"Bobby Digital - So Fly feat. Division",
"Bobby Digital - So Fly feat. Division",
"Bobby Digital - We All We Got feat. Black Knights",
"Bobby Digital - We All We Got feat. Black Knights"
]
tests.each do |test_string|
    puts "\"#{test_string}\" => #{canonicalize_artist(test_string)}"
end
startup
$fields.each do |field|
    $value_lists[field].each do |key, values|
        $cache_files[field].puts "#{key}\0#{values.size}\0#{values.keys.join("\0")}"
    end
end
