class HashData
    def initialize(flags, ttl, bsize, caskey, value, date)
       @flags = flags
       @ttl = ttl
       @bsize = bsize
       @caskey = caskey
       @value = value
       @date = date
    end

    attr_reader :flags,:ttl,:bsize,:caskey,:value,:date
 end
