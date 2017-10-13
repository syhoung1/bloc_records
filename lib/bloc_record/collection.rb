require 'sqlite3'
require 'bloc_record/schema'

module BlocRecord
  class Collection < Array
    include Persistence
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
        if item == item.class.where(search)
          items.push(item.class.where(search))
        end
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

    def destroy_all
      self.each do |item|
        item.class.connection.execute(<<-SQL)
          DELETE FROM #{item.class.table}
          WHERE id = #{item.id}
        SQL
      end
    end
  end
end
