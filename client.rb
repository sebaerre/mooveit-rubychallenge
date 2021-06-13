require "socket"
require './utils/client_constants'

socket = TCPSocket.open("localhost", 28561)
=begin
This is set to run all rspec tests.
and to test with only one client.
To test multithreads, change to TCPSocket.open("192.168.1.8", 28561) or whatever is local IP on your network
Switch ip to localhost if test with only 1 client
=end

loop do
  input = gets.chomp  #Ask client for command
  socket.puts input # Send command to server

  line = socket.gets("\0") #Get server response
  if(line.strip == INSERT_VALUE)
    input = gets.chomp

    socket.puts input
    line = socket.gets("\0")
  end
  puts line


  break if input=="EXIT" #If client types EXIT terminate connection
end
socket.close
