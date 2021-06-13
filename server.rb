require "socket"
require "thread"
require './utils/server_constants'

require './classes/UserCommandParser'

server = TCPServer.new("localhost", 28561)#TCPServer.new("localhost", 28561)
=begin
This is set to run all rspec tests.
and to test with only one client.
To test multithreads, change to TCPServer.new("192.168.1.8", 28561) or whatever is local IP on your network
Switch ip to localhost if test with only 1 client
=end

@mutex = Mutex.new

ucp = UserCommandParser.instance

loop do
  Thread.start(server.accept) do |session| #accept client
    while (line = session.gets) #get client command
      @mutex.synchronize do
      ucp.parseUserCommand(line,session)
      end
      break if line.strip == EXIT#break if while
    end
    session.close
  end
end
