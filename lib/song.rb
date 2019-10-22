require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    table_info.map { |row| row["name"] }.compact
  end

  attr_accessor *self.column_names

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end

  def save
    sql = "INSERT INTO #{table_name} (#{column_names.join(', ')}) VALUES (#{values_placeholder})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name}")[0][0]
  end

  private

  def table_name
    self.class.table_name
  end

  def values_placeholder
    (0..column_names.size).map { '?' }.join(', ')
  end

  def values
    column_names.map { |col_name| send(col_name) }
  end

  def column_names
    self.class.column_names - ['id']
  end
end
