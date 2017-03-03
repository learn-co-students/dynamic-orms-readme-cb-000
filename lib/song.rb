require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

  def self.table_name 
    self.to_s.downcase.pluralize #takes the name of the class, turns it into a string, lowercases it and makes it plural
  end                            # example: A class Dog would equal a table name of "dogs"
                                 # .pluralize is available through 'active_support/inflector'

  def self.column_names
    DB[:conn].results_as_hash = true # returns an array of hashses describing the table itself.
                              # Here is one of the many hashes in the array it will return. Each has equals one column.
         #   [{"cid"=>0,               |
         #     "name"=>"id",           | \
         #     "type"=>"INTEGER",      |  \
         #     "notnull"=>0,           |   \
         #     "dflt_value"=>nil,      |    \  
         #     "pk"=>1,                |     \
         #     0=>0,                   | ----- >>>> This is all the information from one column of the table.
         #     1=>"id",                |     /
         #     2=>"INTEGER",           |    /
         #     3=>0,                   |   /
         #     4=>nil,                 |  /
         #     5=>1},                  | /


    sql = "pragma table_info('#{table_name}')" #=> SQL statement referencing the #table_name that holds our tables name.

    table_info = DB[:conn].execute(sql) #=> Iterate over the hashes to find the name of each columns.
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact #=> .compact just makes sure that there are no nil values included
                         # The return value here would look like.... ["id", "name", "album"]
                         # This now can be used to make our Song class attr_accessor names.
  end

  self.column_names.each do |col_name| #=> Iterates over the #column.names and creates a attr_accessor
    attr_accessor col_name.to_sym      # for each.  .to_sym converts it to a symbol.
  end

  def initialize(options={}) #=> Takes in an argument called options that defaults to an empty hash.
    options.each do |property, value| #Iterates over the hash and sets a #property=  equal to its value.
      self.send("#{property}=", value) # As long as each property has a corresponding attr_accessor this will work.
    end
  end

  def save #=> The final step after metaprogramming the other values.
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert #=> Grabs the table name that was created from the class method #table_name
    self.class.table_name   # and gives us access to it in an instance method.
  end

  def values_for_insert #= Iterates over the class #column_names and saves its values in an array.
    values = []         
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
      #When we insert these values into the chart we want each value to be sepearte strings.
      #INSERT INTO songs (name, album) VALUES ('Hello', '25') ... Therefore, we wrap the return value
      #into a string. Each value shoudl be a seperate strin so we also use ' ' as well. This will
      #return a values array of ["'Hello', '25'"].  ......................................
    end
    values.join(", ") # ............ #=> Returns 'Hello', '25'
  end

  def col_names_for_insert #=> Grabs the name created from the class method #col_names and gives us
    # access to it in an instance method. However self.col_names includes the id which we do not want
    # ["id", "name", "album"].The id should not be set when an instance is created, but when added to
    # the database. Thefore, we must remove the id.
    self.class.column_names.delete_if {|col| col == "id"}.join(", ") #=> Returns ["name", "album"] before the .join(", ")
    # But we don't insert an array into a table, but different values.
    # .join(", ") returns a string of "name, album" => This is what we need to insert columns into our table.
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



