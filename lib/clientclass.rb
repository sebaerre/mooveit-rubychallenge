require "socket"
class Client

  def initialize(host, port)
    @socket = TCPSocket.open(host, port)
  end

  def exit
    @socket.puts "EXIT"
  end

  def set_command(varname, flag, ttl, bytes, value)
    @socket.puts "set #{varname} #{flag} #{ttl} #{bytes}"
    line = @socket.gets("\0")
    if line.strip!=""
      return line
    end
    @socket.puts "#{value}"
    line = @socket.gets("\0")
    return line
  end

  def add_command(varname, flag, ttl, bytes, value)
    @socket.puts "add #{varname} #{flag} #{ttl} #{bytes}"
    line = @socket.gets("\0")
    if line.strip!=""
      return line
    end
    @socket.puts "#{value}"
    line = @socket.gets("\0")
    return line
  end

  def cas_command(varname, flag, ttl, bytes, caskey, value)
    @socket.puts "cas #{varname} #{flag} #{ttl} #{bytes} #{caskey}"
    line = @socket.gets("\0")
    if line.strip!=""
      return line
    end
    @socket.puts "#{value}"
    line = @socket.gets("\0")
    return line
  end

  def purge_keys
    @socket.puts "PURGE"
  end

  def replace_command(varname, flag, ttl, bytes, value)
    @socket.puts "replace #{varname} #{flag} #{ttl} #{bytes}"
    line = @socket.gets("\0")
    if line.strip!=""
      return line
    end
    @socket.puts "#{value}"
    line = @socket.gets("\0")
    return line
  end

  def append_command(varname, flag, ttl, bytes, value)
    @socket.puts "append #{varname} #{flag} #{ttl} #{bytes}"
    line = @socket.gets("\0")
    if line.strip!=""
      return line
    end
    @socket.puts "#{value}"
    line = @socket.gets("\0")
    return line
  end

  def prepend_command(varname, flag, ttl, bytes, value)
    @socket.puts "prepend #{varname} #{flag} #{ttl} #{bytes}"
    line = @socket.gets("\0")
    if line.strip!=""
      return line
    end
    @socket.puts "#{value}"
    line = @socket.gets("\0")
    return line
  end

  def get_command(varname)
    @socket.puts "get #{varname.join(' ')}"
    line = @socket.gets("\0")
    return line
  end

  def gets_command(varname)
    @socket.puts "gets #{varname.join(' ')}"
    line = @socket.gets("\0")
    return line
  end

  def start
    loop do
      input = gets.chomp  #Ask client for command
      socket.puts input # Send command to server

      line = socket.gets("\0") #Get server response
      puts line

      break if input=="EXIT" #If client types EXIT terminate connection
    end
    socket.close
  end

end
