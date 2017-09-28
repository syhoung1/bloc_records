require_relative 'utility'
require_relative 'schema'
require_relative 'persistence'
require_relative 'selection'
require_relative 'connection'


module BlocRecord
  class Base
    include Persistence
    extend Selection
    extend Schema
    extend Connection
    
    def initialize(options={})
      options = BlocRecord::Utility.convert_keys(options)
      
      self.class.columns.each do |col|
        self.class.send(:attr_accessor, col)
        self.instance_variable_set("@#{col}", options[col])
      end
    end

    def self.method_missing(m, *args, &block)
      missing_method_name = m.to_s.split("_")
      attribute = missing_method_name.pop().to_sym
      method = missing_method_name.join("_").to_sym
      find_by(attribute, args[0])
    end
  end
end
