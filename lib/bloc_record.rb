module BlocRecord
  def self.connect_to(filename)
    if filename.count > 1
      filename_path = filename[0]
      filename_option = filename[1].to_s
  
      
      new_filename = filename_path.split('.')
      new_filename[-1] = filename_option
      
      @database_filename = new_filename.join('.')
    else
      @database_filename = filename[0]
    end
  end
  
  def self.database_filename
    @database_filename
  end
end
