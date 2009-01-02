module CampfireBot
  class Message < Hash
    def initialize(attributes)
      self.merge!(attributes)
    end
    
    def reply(str)
      speak(str)
    end
    
    def speak(str)
      self[:room].speak(str)
    end
    
    def paste(str)
      self[:room].paste(str)
    end
    
    def upload(file_path)
      self[:room].upload(file_path)
    end
  end
end