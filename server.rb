require "socket"
require "thread"
require 'date'
require './classes/HashData'
require './utils/server_constants'

server = TCPServer.new("localhost", 28561)
=begin
This is set to run all rspec tests.
and to test with only one client.
To test multithreads, change to TCPServer.new("192.168.1.8", 28561) or whatever is local IP on your network
Switch ip to localhost if test with only 1 client
=end

@data = Hash.new {  }
@mutex = Mutex.new
@keysPurger = nil
@i=4 #initialize unique id implemented like a counter

def checkExpirationNoUnix(expTime, key)
  datecreated = DateTime.strptime(@data[key].date).to_time #Get the date when the variable was SET
  diff = DateTime.now().to_time - datecreated
  if (diff.to_f >= expTime.to_f)
    @data[key] = nil
    return true
  end
  return false
end

def checkExpirationUnix(expTime, key)
  puts expTime
  puts key
  date = Time.now.to_i
  puts date
  if (expTime<=date)
    @data[key] = nil
    return true
  end
  return false
end

def updateData(varName,flags,ttl,size,value)
  newData = HashData.new(flags,ttl,size,@i,value,DateTime.now().to_s)
  @data[varName] = newData
  @i += 1
end

def checkByteSize(value, expectedSize)
  return (expectedSize == value.strip.bytes.to_a.length().to_s and expectedSize[4]!=0)
end

def pendCommand(lineArr, session, mode)
  session.puts INSERT_VALUE
  value = session.gets.strip #Get the value of the data we are storing
  if(checkByteSize(value, lineArr[4]))
    if (@data[lineArr[1]])#ONLY UPDATE IF IT EXISTS
      existingData = @data[lineArr[1]]
      newSize = existingData.bsize.to_i + lineArr[4].to_i
      newValue = mode==AP ? existingData.value.to_s + value.to_s : value.to_s + existingData.value.to_s
      updateData(lineArr[1], existingData.flags, existingData.ttl, newSize, newValue)
      session.puts STORED
    else #DOES NOT EXIST
      session.puts NOT_STORED
    end #END IF DATA EXISTS ALREADY
  else#BYTE AMOUNTS DO NOT MATCH
    session.puts CLIENT_ERROR_BAD_CHUNK
  end
end

def retrievalCommand(line, session, isGets)
  response = ""
  keys = line.strip.split(" ")
  keys.each_with_index { |item, index|
    if(index!=0)#ignore get in [0]
      dataitem = @data[item]
      if (dataitem)
        #item exists, check expiration time
        expTime = dataitem.ttl.to_i
        expired = false
        if (expTime!=0) #If the variable is not set to last forever
          if(expTime > DAYS_30) #Interpret ttl as UNIX time
            puts "hello"
            expired = checkExpirationUnix(expTime, item)
          else #Interpret time as seconds from the time the variable was set
            expired = checkExpirationNoUnix(expTime, item)
          end
        end
        if (!expired) #if it did not expire, return it to the client
          response+="VALUE #{item} #{dataitem.flags} #{dataitem.bsize}"
          if (isGets)
            response+=" #{dataitem.caskey}\n"
          else
            response+="\n"
          end
          response+=dataitem.value+"\n"
        end #end if !expired

      end #end if dataitem
    end #end if index!=0
  }
  response+=END_STRING
  session.puts(response)
end

def storeCommand(lineArr, session, shouldStore, isCas)
  session.puts INSERT_VALUE
  value = session.gets.strip #Get the value of the data we are storing
  if(checkByteSize(value, lineArr[4]))
    if (isCas)
      if(@data[lineArr[1]])  #Check variable exists
        existingData = @data[lineArr[1]]

        if(lineArr[5].to_i==existingData.caskey.to_i)#Check if keys are the same
          if(lineArr[3].to_i>=0)
            updateData(lineArr[1], lineArr[2], lineArr[3], lineArr[4], value)
          end
          session.puts STORED
        else#IF KEYS DO NOT MATCH
          session.puts EXISTS
        end
      else
        session.puts NOT_FOUND
      end

    else
      if (shouldStore)
        if(lineArr[3].to_i>=0) #check ttl condition
          updateData(lineArr[1], lineArr[2], lineArr[3], lineArr[4], value)
        end
        session.puts STORED
      else
        session.puts NOT_STORED
      end
    end
  else#BYTE AMOUNTS DO NOT MATCH
    session.puts CLIENT_ERROR_BAD_CHUNK
  end
end

loop do
  Thread.start(server.accept) do |session| #accept client

    while (line = session.gets) #get client command
      @mutex.synchronize do
        lineArr = line.strip.split(" ")
        case line.strip
        when /^set \w* \d{1,2} -?\d{1,15} \d{1,7}$/
          storeCommand(lineArr,session,true, false)
        when /^add \w* \d{1,2} -?\d{1,15} \d{1,7}$/
          storeCommand(lineArr,session,!@data[lineArr[1]], false)
        when /^replace \w* \d{1,2} -?\d{1,15} \d{1,7}$/
          storeCommand(lineArr,session,@data[lineArr[1]], false)
        when /^append \w* \d{1,2} -?\d{1,15} \d{1,7}$/
          pendCommand(lineArr,session,AP)
        when /^prepend \w* \d{1,2} -?\d{1,15} \d{1,7}$/
          pendCommand(lineArr,session,PRE)
        when /^cas \w* \d{1,2} \d{1,7} -?\d{1,15} \d{1,4}$/
          storeCommand(lineArr, session, false, true)
        when /^get [\w ]*$/ #get command, can have multiple keys
          retrievalCommand(line,session,false)
        when /^gets [\w ]*$/ #gets command, can have multiple keys. We add CAS key
          retrievalCommand(line,session,true)
        when "EXIT" #Exit
          session.close
        when "PURGE" #Exit
          @data = {}
        else #No match with any known command
          session.puts ERROR
        end #END CASE
      end#end mutex
      break if line.strip == 'EXIT'#break if while
    end #END WHILE
    session.close
  end #end thread
end#end loop
