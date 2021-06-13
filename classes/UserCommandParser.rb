require_relative 'MemcachedHandler'
require './utils/server_constants'
require './utils/store_conditions'

class UserCommandParser
  @instance = new

  private_class_method :new

  def self.instance
    @instance
  end

  @@mc = MemcachedHandler.instance

  def parseUserCommand(line, session)
    lineArr = line.strip.split(" ")
    case line.strip
    when /^set \w* \d{1,2} -?\d{1,15} \d{1,7}$/
      @@mc.storeCommand(lineArr,session,true, false)
    when /^add \w* \d{1,2} -?\d{1,15} \d{1,7}$/
      @@mc.storeCommand(lineArr,session,NOT_DATA_EXISTS, false)
    when /^replace \w* \d{1,2} -?\d{1,15} \d{1,7}$/
      @@mc.storeCommand(lineArr,session,DATA_EXISTS, false)
    when /^append \w* \d{1,2} -?\d{1,15} \d{1,7}$/
      @@mc.pendCommand(lineArr,session,AP)
    when /^prepend \w* \d{1,2} -?\d{1,15} \d{1,7}$/
      @@mc.pendCommand(lineArr,session,PRE)
    when /^cas \w* \d{1,2} \d{1,7} -?\d{1,15} \d{1,4}$/
      @@mc.storeCommand(lineArr, session, false, true)
    when /^get [\w ]*$/ #get command, can have multiple keys
      @@mc.retrievalCommand(line,session,false)
    when /^gets [\w ]*$/ #gets command, can have multiple keys. We add CAS key
      @@mc.retrievalCommand(line,session,true)
    when EXIT #Exit
      session.close
    when PURGE #Exit
      @@mc.purge()
    else #No match with any known command
      session.puts ERROR
    end #END CASE
  end
end
