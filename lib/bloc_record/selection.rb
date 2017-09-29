require 'sqlite3'

module Selection
  def find(*ids)
    validate(ids)

    if ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute(<<-SQL)
        SELECT #{columns.join(",")} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(rows)
    end
  end

  def find_one(id)
    row = connection.get_first_row(<<-SQL)
      SELECT #{columns.join(",")} FROM #{table}
      WHERE id = #{id};
    SQL
    
    init_object_from_row(row)
  end

  def find_by(attribute, value)
    row = connection.get_first_row(<<-SQL)
      SELECT #{columns.join(",")} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    init_object_from_row(row)
  end

  def take_one
    row = connection.get_first_row(<<-SQL)
      SELECT #{columns.join(",")} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def take(num=1)
    if num > 1
      row = connection.get_first_row(<<-SQL)
        SELECT #{columns.join(",")} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      init_object_from_row(row)
    else
      take_one
    end
  end

  def first
    row = connection.get_first_row(<<-SQL)
      SELECT #{columns.join(",")} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row(<<-SQL)
      SELECT #{columns.join(",")} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute(<<-SQL)
      SELECT #{columns.join(",")} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def find_in_batches(start=0, batch_size=10)
    batch_end = start + batch_size
    yield(all[start...batch_size])
  end

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
        when String
          expression = args.first
        when Hash
          expression_hash = BlocRecord::Utility.convert_keys(args.first)
          expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
        end
    end

    sql = (<<-SQL)
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL
    
    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    new_args = []
    args.each do |arg|
      if arg.class == String
        new_args.push(arg)
      elsif arg.class == Hash
        arg.each do |key, value|
          new_args.push("#{key.to_s} #{value.to_s.upcase}")
        end
      elsif arg.class == Symbol
        new_args.push(arg.to_s)
      end
    end
    order = new_args.join(",")

    rows = connection.execute(<<-SQL)
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1 
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute(<<-SQL)
        SELECT * FROM #{table} #{joins};
      SQL
    else
      case args.first
      when String
        rows = connection.execute(<<-SQL)
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(sql_string)};
        SQL
      when Symbol
        rows = connection.execute(<<-SQL)
          SELECT * FROM #{table}
          INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id;
        SQL
      when Hash
        key = args.first.keys.first
        first_table = key.to_s
        second_table = args.first[key].to_s
        
        row = connection.execute(<<-SQL)
          SELECT * FROM #{table}
          INNER JOIN #{first_table} ON #{first_table}.#{table}_id = #{table}.id
          INNER JOIN #{second_table} ON #{second_table}.{first_table}_id = #{first_table}.id
        SQL
        end
      end

    rows_to_array(row)
  end

  private

  def rows_to_array(rows)
    collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end

  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def validate(ids)
    if ids.is_a?(Array)
      ids.each do |id|
        if id.is_a?(Integer) && id > 0
          true
        else
          puts "#{id} is not a valid id"
          return false
        end
      end
    elsif ids.is_a?(Integer) && ids > 0
      true
    else
      "#{ids} is not a valid id"
    end
  end
end
