require "socket"
require './utils/client_constants'

class Client

  def initialize(host, port)
    @socket = TCPSocket.open(host, port)
  end

  def exit
    @socket.puts EXIT
  end

  def storage_command(command, varname, flag, ttl, bytes,caskey, value)
    if (command==CAS)
      @socket.puts "#{command} #{varname} #{flag} #{ttl} #{bytes} #{caskey}"
    else
    @socket.puts "#{command} #{varname} #{flag} #{ttl} #{bytes}"
  end
    line = @socket.gets(END_TRANSMISSION_STRING)
    if line.strip!=INSERT_VALUE
      return line
    end
    @socket.puts "#{value}"
    line = @socket.gets(END_TRANSMISSION_STRING)
    return line
  end

  def purge_keys
    @socket.puts PURGE
  end

  def retrieval_command(command, varname)
    @socket.puts "#{command} #{varname.join(' ')}"
    line = @socket.gets(END_TRANSMISSION_STRING)
    return line
  end

  def start
    loop do
      input = gets.chomp  #Ask client for command
      socket.puts input # Send command to server

      line = socket.gets(END_TRANSMISSION_STRING) #Get server response
      puts line

      break if input==EXIT #If client types EXIT terminate connection
    end
    socket.close
  end

end
