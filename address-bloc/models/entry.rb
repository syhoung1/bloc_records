require 'bloc_record/base'
require 'bloc_record/selection'

class Entry < BlocRecord::Base
  def to_s
    "Name: #{name}\nPhone Number: #{phone_number}\nEmail: #{email}"
  end
end
