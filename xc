#!/usr/bin/env ruby
require 'socket'
require 'readline'
require 'terminfo'

$screen_width = TermInfo.screen_size[1]
Signal.trap('SIGWINCH', proc {
    $screen_width = TermInfo.screen_size[1]
    Readline.set_screen_size(TermInfo.screen_size[0], TermInfo.screen_size[1]) })
$SOCKET_PATH = `xce-serv`
$xce_connection = UNIXSocket.new($SOCKET_PATH)

while true
    input = Readline.readline('xmms2-coll> ', false)
    if input
        input << "\n"
        begin
        result = $xce_connection.send(input, Socket::MSG_PEEK)
        rescue Exception => e
            puts "got an exception #{e}"
        end
        if result != input.length
            break
        end
    else
        break
    end
    puts $xce_connection.recv(100)
end
