module Sampler
  
  @dict = {}
  @history = []
  
  def Sampler::sample
    memory_usage = `ps -o rss= -p #{Process.pid}`.to_i # in kilobytes 
    
    objCount = 0
    ObjectSpace.each_object(Object) do |obj|
    #  puts obj
      @dict[obj.class] ||= 0
      @dict[obj.class] += 1
      objCount += 1
    end
    
    puts "#{objCount} OBJECTS, #{memory_usage}KB"
    if (@history.length > 0)
      
      @dict.each do |k,v|        
        prev = @history[-1][k]||0
        puts "  #{k}  from #{prev} to #{v}       CHANGE: #{ v-prev }" if (v-prev).abs > 5
      end    
    end
    @history.push(@dict)
    @dict = {}  
  end
  
end