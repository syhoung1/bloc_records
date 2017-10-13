require 'sqlite3'
require 'bloc_record/schema'

module Persistence
  def self.included(base)
    base.extend(ClassMethods)
  end

  def save!
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
      BlocRecord::Utility.reload_obj(self)
      return true
    end

    fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

    self.class.connection.execute(<<-SQL)
      UPDATE #{self.class.table}
      SET #{fields}
      WHERE id = #{self.id};
    SQL
    true
  end

  def update_attribute(attribute, value)
    self.class.update(self.id, {attribute => value })
  end

  def update_attributes(updates)
    self.class.update(self.id, updates)
  end

  module ClassMethods
    def update_all(updates)
      update(nil, updates)
    end

    def destroy(*id)
      if id.length > 1
        where_clause = "WHERE id IN (#{id.join(",")});"
      else
        where_clause = "WHERE id = #{id.first};"
      end
      
      connection.execute(<<-SQL)
        DELETE FROM #{table} #{where_clause}
      SQL

      true
    end

    def destroy
      self.class.destroy(self.id)
    end

    def destroy_all(conditions_hash=nil)
      if conditions_hash.class == String
        connection.execute(<<-SQL)
          DELETE FROM #{table}
          WHERE #{conditions_hash}
        SQL
      elsif conditions_hash.class == Array
        conditions = conditions_hash.shift() + conditions_hash.shift()
      elsif conditions_hash && !conditions_hash.empty?
        conditions_hash = BlocRecord::Utility.convert_keys(conditions_hash)
        conditions = conditions_hash.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")

        connection.execute(<<-SQL)
          DELETE FROM #{table}
          WHERE #{conditions};
        SQL
      else
        connection.execute(<<-SQL)
          DELETE FROM #{table}
        SQL
      end

      true
    end

    def create(attrs)
      attrs = BlocRecord::Utility.convert_keys(attrs)
      attrs.delete("id")
      vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }
      
      connection.execute(<<-SQL)
        INSERT INTO #{table} (#{attributes.join(",")})
        VALUES (#{vals.join(",")});
      SQL
      
      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end

    def update(ids, updates)
      updates_array = []
      if updates.class == Array
        updates.each do |update|
          update.each do |key, value|
            updates_array.push("#{key.to_s}=#{BlocRecord::Utility.sql_strings(value)}")
          end
        end

        ids.each do |id_num|
          connection.execute(<<-SQL)
            UPDATE #{table}
            SET #{updates_array[id_num - 1]} WHERE id = #{id_num};
          SQL
        end

        return true
      else
        updates = BlocRecord::Utility.convert_keys(updates)
        updates.delete("id")
        updates_array = updates.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}
      end

      if ids.class == FixNum
        where_clause = "WHERE id = #{ids};"
      elsif ids.class == Array
        where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
      else
        where_clause = ";"
      end

      connection.execute(<<-SQL)
        UPDATE #{table}
        SET #{updates_array * ","} #{where_clause}
      SQL

      true
    end
  end
end
