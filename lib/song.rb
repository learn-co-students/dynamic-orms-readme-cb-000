require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'


class Song


  # This method is getting an 'un-capitalized' and pluralized name of
  # our class.
  def self.table_name
    self.to_s.downcase.pluralize
  end

  # This method is getting the column names for our tables inside of
  # our database.
  def self.column_names

    # if #results_as_hash is set to true anything that we get from our
    # queries will return as a hash instead of an array.
    DB[:conn].results_as_hash = true

    # We put our table name inside of the pragma table_info
    # this will show us a hash value of our columns inside the table.
    sql = "pragma table_info('#{table_name}')"

    # Save the key value pairs inside a variable.
    table_info = DB[:conn].execute(sql)
    column_names = []

    # We will save our value with the key 'name' inside our array.
    # the 'name' key basically contains our column names for the table.
    # The array will contain our column names.
    table_info.each do |row|
      column_names << row["name"]
    end
    # We use .compact to take out any nil elements.
    column_names.compact
  end


  # This dynamically creates our attributes.
  # Turns all of our column arrays into symbols and creates our attributes.
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  # This method takes a hash value and assigns the classes
  # attributes by key-value pairs and by using the .send method.
  # If a key-value pair that is present in the classes attributes
  # does not get passed initially then the default value for this attribute is nil.
  # I.E: id attribute.
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  # Saves the attributes into our database.
  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"

    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  # Returns our table name
  def table_name_for_insert
    self.class.table_name
  end

  # This method returns our attribute values as a string separated by
  # commas.
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  # This method returns our column names as a string and separates
  # them using a comma. This gets all the columns except for the
  # column id.
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  # This method finds our row with the same name.
  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end
