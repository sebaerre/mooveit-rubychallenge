require 'date'
require './utils/server_constants'
require './utils/store_conditions'
require_relative 'HashData'

class MemcachedHandler
  @@i=4 #initialize unique id implemented like a counter
  @@data = Hash.new {  }

  @instance = new

  private_class_method :new

  def self.instance
    @instance
  end

  def purge()
    @@data = {}
  end

  def checkExpirationNoUnix(expTime, key)
    datecreated = DateTime.strptime(@@data[key].date).to_time #Get the date when the variable was SET
    diff = DateTime.now().to_time - datecreated
    if (diff.to_f >= expTime.to_f)
      @@data[key] = nil
      return true
    end
    return false
  end

  def checkExpirationUnix(expTime, key)
    date = Time.now.to_i
    if (expTime<=date)
      @@data[key] = nil
      return true
    end
    return false
  end

  def updateData(varName,flags,ttl,size,value)
    newData = HashData.new(flags,ttl,size,@@i,value,DateTime.now().to_s)
    @@data[varName] = newData
    @@i += 1
  end

  def checkByteSize(value, expectedSize)
    return (expectedSize == value.strip.bytes.to_a.length().to_s and expectedSize[4]!=0)
  end

  def pendCommand(lineArr, session, mode)
    session.puts INSERT_VALUE
    value = session.gets.strip #Get the value of the data we are storing
    if(checkByteSize(value, lineArr[4]))
      if (@@data[lineArr[1]])#ONLY UPDATE IF IT EXISTS
        existingData = @@data[lineArr[1]]
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

  def checkAndExpireKey(dataitem, item)
    if (dataitem)
    expTime = dataitem.ttl.to_i
    expired = false
    if (expTime!=0) #If the variable is not set to last forever
      if(expTime > DAYS_30) #Interpret ttl as UNIX time
        return checkExpirationUnix(expTime, item)
      else #Interpret time as seconds from the time the variable was set
        return checkExpirationNoUnix(expTime, item)
      end
    end
  end
  return true
  end

  def retrievalCommand(line, session, isGets)
    response = ""
    keys = line.strip.split(" ")
    keys.each_with_index { |item, index|
      if(index!=0)#ignore get in [0]
        dataitem = @@data[item]
        if (dataitem)
          #item exists, check expiration time
          expired = checkAndExpireKey(dataitem, item)
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

  def storeCommand(lineArr, session, storeCondition, isCas)
    session.puts INSERT_VALUE
    value = session.gets.strip #Get the value of the data we are storing
    if(checkByteSize(value, lineArr[4]))
      expired = checkAndExpireKey(@@data[lineArr[1]], lineArr[1])
      if (isCas)
        if(@@data[lineArr[1]])  #Check variable exists
          existingData = @@data[lineArr[1]]
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
        case storeCondition
        when true
          shouldStore = true
        when DATA_EXISTS
          shouldStore = @@data[lineArr[1]]
        when NOT_DATA_EXISTS
          shouldStore = !@@data[lineArr[1]]
        else
          shouldStore = false
        end
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
end
