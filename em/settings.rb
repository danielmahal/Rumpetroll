require "yaml"


class Settings
  
  def initialize(settingsFile)
    @yaml = File.open( settingsFile ) { |yf| YAML::load( yf ) }    
  end
  
  def [](*path)
    
    branch = @yaml
    
    while label = path.shift
      
      branch = branch[label.to_s] rescue nil
      
    end
    
    branch
    
  end
  


end