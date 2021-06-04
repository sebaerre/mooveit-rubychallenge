require "socket"
require "thread"
require 'date'

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

WAITING_CAS_VALUE= "6"
WAITING_PREPEND_VALUE= "5"
WAITING_APPEND_VALUE= "4"
WAITING_REPLACE_VALUE = "3"
WAITING_ADD_VALUE = "2"
WAITING_SET_VALUE = "1"
WAITING_NEW_COMMAND = "0"
DAYS_30 = 2592000

# def pend (mode, var1, var2)#mode=ap/pre, ap=> var1+var2, pre=>var2+var1
#    if (mode=="ap")
#      return var1.to_s+var2.to_s
#    elsif (mode=="pre")
#      return var2.to_s + var1.to_s
#    end
# end

def checkExpirationNoUnix(value, expTime, key)
  date = DateTime.strptime(value.split("/sep")[5]).to_time #Get the date when the variable was SET
  diff = DateTime.now().to_time - date
  if (diff.to_f >= expTime.to_f)
    @data[key] = nil
  end
end

def checkExpirationUnix(expTime, key)
  date = Time.now.to_i
  if (expTime<=date)
    @data[key] = nil
  end
end

def updateData(line, varName, flag, size, ttl)
  @data[varName] = line.strip+"/sep#{flag}"+"/sep#{size}"+"/sep#{@i}"+"/sep#{ttl}"+"/sep"+DateTime.now().to_s
  @i += 1
end

def pendData(line, varName, size,mode)
  existingDataSplitted = @data[varName].split("/sep")
  aux = existingDataSplitted[2].to_i
  aux+=size.to_i
  existingDataSplitted[2] = aux.to_s
  existingDataSplitted[3] = @i
  if (mode=="ap")
    existingDataSplitted[0]<<line.strip
  elsif (mode=="pre")
    existingDataSplitted[0] = line.strip+existingDataSplitted[0]
  end
  @data[varName] = existingDataSplitted.join("/sep")
  @i += 1
end


loop do
  Thread.start(server.accept) do |session| #accept client

    @mutex.synchronize do
      @keysPurger = Thread.start do
        loop do
          @data.each do |key, value|
            expTime = value.split("/sep")[4]
            if (expTime.to_i!=0) #If the variable is not set to last forever
              if(expTime.to_i > DAYS_30) #Interpret ttl as UNIX time
                checkExpirationUnix(expTime, key)
              else #Interpret time as seconds from the time the variable was set
                checkExpirationNoUnix(value, expTime, key)
              end
            end
          end
          sleep 1 #Wait 1sec in between each check
        end
      end
    end

    thread_status ||= WAITING_NEW_COMMAND #initialize thread status

    lineArr=[] #Initialize variables
    varName=""
    flag=""
    ttl=""
    size=""
    casKey = ""

    while (line = session.gets) #get client command
      @mutex.synchronize do
        if(thread_status == WAITING_NEW_COMMAND) #Check thread status, if waiting for command check command syntax
          case line.strip
          when /^set \w* \d{1,2} -?\d{1,12} \d{1,7}$/
            thread_status = WAITING_SET_VALUE
            lineArr = line.strip.split(" ")
            varName = lineArr[1]
            flag = lineArr[2]
            ttl = lineArr[3]
            size = lineArr[4]
            session.puts "\0"
          when /^add \w* \d{1,2} -?\d{1,12} \d{1,7}$/
            thread_status = WAITING_ADD_VALUE
            lineArr = line.strip.split(" ")
            varName = lineArr[1]
            flag = lineArr[2]
            ttl = lineArr[3]
            size = lineArr[4]
            session.puts "\0"
          when /^replace \w* \d{1,2} -?\d{1,12} \d{1,7}$/
            thread_status = WAITING_REPLACE_VALUE
            lineArr = line.strip.split(" ")
            varName = lineArr[1]
            flag = lineArr[2]
            ttl = lineArr[3]
            size = lineArr[4]
            session.puts "\0"
          when /^append \w* \d{1,2} -?\d{1,12} \d{1,7}$/
            thread_status = WAITING_APPEND_VALUE
            lineArr = line.strip.split(" ")
            varName = lineArr[1]
            flag = lineArr[2]
            ttl = lineArr[3]
            size = lineArr[4]
            session.puts "\0"
          when /^prepend \w* \d{1,2} -?\d{1,12} \d{1,7}$/
            thread_status = WAITING_PREPEND_VALUE
            lineArr = line.strip.split(" ")
            varName = lineArr[1]
            flag = lineArr[2]
            ttl = lineArr[3]
            size = lineArr[4]
            session.puts "\0"
          when /^cas \w* \d{1,2} \d{1,7} -?\d{1,12} \d{1,4}$/
            thread_status = WAITING_CAS_VALUE
            lineArr = line.strip.split(" ")
            varName = lineArr[1]
            flag = lineArr[2]
            ttl = lineArr[3]
            size = lineArr[4]
            casKey = lineArr[5]
            session.puts "\0"
          when /^get [\w ]*$/ #get command, can have multiple keys
            response = ""
            keys = line.strip.split(" ")
            keys.each_with_index { |item, index|
              if(index!=0)#ignore get in [0]
                dataitem = @data[item]
                if (dataitem)
                  datasplit = dataitem.split("/sep")
                  response+="VALUE #{item} #{datasplit[1]} #{datasplit[2]}\n"
                  response+=datasplit[0]+"\n"
                end #end if dataitem
              end #end if index!=0
            }
            response+="END\0"
            session.puts(response)
          when /^gets [\w ]*$/ #gets command, can have multiple keys. We add CAS key
            response = ""
            keys = line.strip.split(" ")
            keys.each_with_index { |item, index|
              if(index!=0)#ignore get in [0]
                dataitem = @data[item]
                if(dataitem)
                  datasplit = dataitem.split("/sep")
                  response+="VALUE #{item} #{datasplit[1]} #{datasplit[2]} #{datasplit[3]}\n"
                  response+=datasplit[0]+"\n"
                end
              end
            }
            response+="END\0"
            session.puts(response)
          when "EXIT" #Exit
            puts "EXITING.."
            session.close
          when "PURGE" #Exit
            puts "PURGING KEYS"
            @data = {}
          else #No match with any known command
            session.puts "ERROR\0"
          end #END CASE

        elsif(thread_status==WAITING_SET_VALUE) #If im waiting for the value of the set command
          if(line.strip.match(/^\w{1,}$/))
            if(size == line.strip.bytes.to_a.length().to_s and size!=0)
              if(ttl.to_i>=0)
                updateData(line, varName, flag, size, ttl)
              end
              session.puts "STORED\0"
            else#BYTE AMOUNTS DO NOT MATCH
              session.puts "CLIENT_ERROR bad data chunk\0"
            end
          else#NO MATCH FOR VALUE
            session.puts "ERROR\0"
          end#end if linestripmatches
          thread_status=WAITING_NEW_COMMAND
        elsif(thread_status==WAITING_ADD_VALUE) #If im waiting for the value of the add command
          if(line.strip.match(/^\w{1,}$/))
            if(size == line.strip.bytes.to_a.length().to_s and size!=0)
              if (@data[varName])#IF it exists we dont store anything
                session.puts "NOT_STORED\0"
              else
                if(ttl.to_i>=0)
                  updateData(line, varName, flag, size, ttl)
                end
                session.puts "STORED\0"
              end#END IF DATA EXISTS ALREADY
            else
              session.puts "CLIENT_ERROR bad data chunk\0"
            end#END BYTE CHECK
          else#NO MATCH FOR VALUE
            session.puts "ERROR\0"
          end #End if linestripmatches
          thread_status=WAITING_NEW_COMMAND
        elsif(thread_status==WAITING_REPLACE_VALUE) #If im waiting for the value of the replace command
          if(line.strip.match(/^\w{1,}$/))
            if(size == line.strip.bytes.to_a.length().to_s and size!=0)
              if (@data[varName])#We only update if it exists already
                if(ttl.to_i>=0)
                  updateData(line, varName, flag, size, ttl)
                end
                session.puts "STORED\0"
              else
                session.puts "NOT_STORED\0"
              end#END IF DATA EXISTS ALREADY
            else#BYTE AMOUNTS DO NOT MATCH
              session.puts "CLIENT_ERROR bad data chunk\0"
            end
          else#NO MATCH FOR VALUE
            session.puts "ERROR\0"
          end #End if line matches
          thread_status=WAITING_NEW_COMMAND
        elsif(thread_status==WAITING_APPEND_VALUE) #If im waiting for the value of the append command
          if(line.strip.match(/^\w{1,}$/))
            if(size == line.strip.bytes.to_a.length().to_s and size!=0)
              if (@data[varName])#ONLY UPDATE IF IT EXISTS
                pendData(line, varName, size, "ap")
                session.puts "STORED\0"
              else#DOES NOT EXIST
                session.puts "NOT_STORED\0"
              end#END IF DATA EXISTS ALREADY
            else#BYTE AMOUNTS DO NOT MATCH
              session.puts "CLIENT_ERROR bad data chunk\0"
            end
          else
            session.puts "ERROR\0"
          end#end if linestripmatches
          thread_status=WAITING_NEW_COMMAND
        elsif(thread_status==WAITING_PREPEND_VALUE) #If im waiting for the value of the prepend command
          if(line.strip.match(/^\w{1,}$/))
            if(size == line.strip.bytes.to_a.length().to_s and size!=0)
              if (@data[varName])
                pendData(line, varName, size, "pre")
                session.puts "STORED\0"
              else#DOES NOT EXIST
                session.puts "NOT_STORED\0"
              end#END IF DATA EXISTS ALREADY
            else#BYTE AMOUNTS DO NOT MATCH
              session.puts "CLIENT_ERROR bad data chunk\0"
            end
          else
            session.puts "ERROR\0"
          end#end if linestripmatches
          thread_status=WAITING_NEW_COMMAND
        elsif(thread_status==WAITING_CAS_VALUE) #If im waiting for the value of the prepend command
          if(line.strip.match(/^\w{1,}$/))#Check that line matches a good value
            if(size == line.strip.bytes.to_a.length().to_s and size!=0)#Check byte sizes
              if(@data[varName])#Check variable exists
                dataArray = @data[varName].split("/sep")
                if(casKey.to_i==dataArray[3].to_i)#Check if keys are the same
                  if(ttl.to_i>=0)
                    updateData(line, varName, flag, size, ttl)
                  end
                  session.puts "STORED\0"
                else#IF KEYS DO NOT MATCH
                  session.puts "EXISTS\0"
                end
              else
                session.puts "NOT_FOUND\0"
              end
            else
              session.puts "CLIENT_ERROR bad data chunk\0"
            end
          else
            session.puts "ERROR\0"
          end#end if linestripmatches
          thread_status=WAITING_NEW_COMMAND
        end#END IF THREAD_STATUS
      end#end mutex
      break if line.strip == 'EXIT'#break if while
    end #END WHILE
    @keysPurger.kill
    session.close
  end #end thread
end#end loop
