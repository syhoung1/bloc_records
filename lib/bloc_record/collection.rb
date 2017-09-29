require 'sqlite3'
require 'bloc_record/schema'

module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)

      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take
      self.first
    end

    def where(search)
      items = []
      self.each do |item|
        items.push(item.class.where(search))
      end
      items
    end

    def not(search)
      items = []
      self.each do |item|
        if !item.class.where(search)
          items.push(item)
        end
      end
      items
    end
  end
end
