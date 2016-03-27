#!/usr/bin/env ruby
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
if (uri = ARGV.shift).nil?
    puts "Usage: #{File::basename $0} <url> [<num_entries>] [<watch_words>]"
    exit 1
end
watch = ["dea(th|d)", "die", "dying", "injured?", "kill(s|ed|ing)", 
         "egypt\\w*", "libya\\w*", "cairo", "mubarak", "israel", "oil", "iran\\w*", "pakistan\\w*",
         "korea\\w*", "chin(a|ese)", "indian?", "japan\\w*",
         "facebook", "hack\\w*"]
sat = "a1"
colors = {"red"=>[], "green"=>[], "blue"=>[]}
(0..255).each_slice(32) do |g| 
    colors["red"] << ["ff" + g[-1].to_s(16).rjust(2,"0") + sat,
                      g[-1].to_s(16).rjust(2,"0") + "ff" + sat]
    colors["green"] << [sat + g[-1].to_s(16).rjust(2,"0") + "ff",
                        "ff" + sat + g[-1].to_s(16).rjust(2,"0")]
    colors["blue"] << [g[-1].to_s(16).rjust(2,"0") + sat + "ff",
                       sat + "ff" + g[-1].to_s(16).rjust(2,"0")]
end
colors = (colors["red"].sort + colors["green"].sort + colors["blue"].sort).flatten
dpattern = nil
ll = 52
if ARGV[0].nil?
    num = 3
else
    ARGV.each do |arg|
        if !(arg.match("-r")).nil?
            ARGV.shift
            dpattern = Regexp.new(ARGV.shift)
        end
    end

    if (ARGV[0].to_i != 0)
        num = ARGV.shift.to_i
        if !ARGV[0].nil?
            watch = watch + ARGV
        end
    else
        num = 3
        watch = watch + ARGV
    end
end
open(uri) do |s|
    rss = RSS::Parser.parse(s.read, false)
    print "${color0}" + rss.channel.title + "\n"
    rss.items[0, num].each_with_index do |item,index|
        print lcolor = "${color#{index % 2 + 1}}"
        if !dpattern.nil?
            item.title.gsub!(dpattern, "")
        end
        item.title.gsub!(/#/, "no.")
        item.title.gsub!(/\$/, 'USD ')
        item.title.gsub!(%r"“|”", '"')
        item.title.gsub!(%r"’", '\'')
        item.title.gsub!(%r"—", '-')
        if item.title.size < ll
            title = item.title
        else
            title = item.title[0,ll] + ">"
        end
        watch.each_with_index do |item,index|
            if !(mdata = title.match(/\b#{item}\b/i)).nil?
                title.gsub!(mdata[0], '${color #' + colors[index % colors.size] + '}' + mdata[0] + lcolor)
            end
        end
        puts title
    end
end
print "$color$hr\n"
