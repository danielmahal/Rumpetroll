
module Enumerable

  def compare_all
    
    for i in 0..(length-1)
      for j in (i+1)..(length-1)
        yield(self[i],self[j])
      end
    end
    
  end
  
end