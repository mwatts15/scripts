#!/usr/bin/ruby
require 'fusefs'
require 'xmmsclient'
include FuseFS

def sanitise(str)
    str.gsub!(%r{/}, "::-")
    str.gsub(%r{\\}, "%5C")
end
def desanitise(str)
    str.gsub!(%r{::-}, '/')
    str.gsub(%r{%5C}, '\\')
end
class XmmsFS < FuseFS::FuseDir
    def initialize
        @xmms = Xmms::Client.new("XMMSFS")
        @xmms.connect(ENV["XMMS_PATH"])
  
        @xmms.on_disconnect do
            puts "daemon exited, shutting down"
            FuseFS.exit
        end
        @universe = Xmms::Collection.universe
        @collection = @universe
        @prop_cache = Array.new
    end
    def contents(path)
        items = scan_path(path)
        base = nil
        if !items.empty?
            if (items.size % 2 != 0)
                base = items.pop
            end
            if !items.empty?
                parse_string = ""
                items.each_slice(2) do |slice|
                    if !(sep = slice[1].slice!(/^(<=)|^(>=)|^<|^>/)).nil? 
                        if (slice[1].to_i != 0)
                            parse_string << "#{slice[0]}#{sep}#{slice[1]} "
                        end
                    else
                        parse_string << "#{slice[0]}:'#{desanitise(slice[1])}' "
                    end
                end
                @collection = Xmms::Collection.parse(parse_string)
            else
                @collection = @universe
            end
            if !base.nil?
                if (base == 'in')
                    return @xmms.coll_list(Xmms::Collection::NS_COLLECTIONS).wait.value.collect{ |name| 
                    "Collections::-" + name} + @xmms.coll_list(Xmms::Collection::NS_PLAYLISTS).wait.value.collect { |name| 
                    "Playlists::-" + name }
                end
                if !(base =~ /\d+/).nil?
                    files = []
                    base = base.to_i

                    if base != @prop_cache[0]
                        @prop_cache = [base, @xmms.medialib_get_info(base).wait.value]
                    end

                    @prop_cache[1].each do |value, dict|
                        files << sanitise(value.to_s)
                    end

                    return files
                end
                dict = @xmms.coll_query_info(@collection, base).wait.value
                if !dict.nil?
                    files = []
                    dict.collect{|b| b.collect{|t,j| j}}.flatten.compact.sort.each do |i|
                        files << sanitise(i.to_s)
                    end
                    return files
                end
            end
        else
            @collection = @universe
        end
        if (!(a = @xmms.coll_query_ids(@collection).wait.value).empty?)
            files = []
            a.each do |id| 
                files << id.to_s
            end
        end
        files
    end
    def directory?(path)
        !file?(path)
    end
    def file?(path)
        items = scan_path(path)
        if (items.size % 2 != 0)
            return false
        end
        id, property = items.pop(2)
        id = id.to_i
        if id == 0
            return false
        end
        if @prop_cache[0] != id
            @prop_cache = [id, @xmms.medialib_get_info(id).wait.value]
        end
        if !@prop_cache[1].nil? and @prop_cache[1].has_key?(:"#{desanitise(property)}")
            return true
        else
            return false
        end
    end
    def read_file(path)
        items = scan_path(path)
        property = items.pop
        @prop_cache[1][:"#{desanitise(property)}"].first.last.to_s
    end
end
if (File.basename($0) == File.basename(__FILE__))
  if (ARGV.size != 1)
    puts "Usage: #{$0} <directory>"
    exit
  end

  dirname = ARGV.shift

  unless File.directory?(dirname)
    puts "Usage: #{dirname} is not a directory."
    exit
  end
  root = XmmsFS.new
  FuseFS.set_root(root)

  FuseFS.mount_under(dirname)

  FuseFS.run # This doesn't return until we're unmounted.
  FuseFS.unmount
end
