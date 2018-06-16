require 'sqlite3'


DB = {:conn => SQLite3::Database.new("db/songs.db")}
DB[:conn].execute("DROP TABLE IF EXISTS songs")

sql = <<-SQL
  CREATE TABLE IF NOT EXISTS songs (
  id INTEGER PRIMARY KEY,
  name TEXT,
  album TEXT
  )
SQL

DB[:conn].execute(sql)
DB[:conn].results_as_hash = true
# Results will be returned as a hash:
# {"id"=>1, "name"=>"Hello", "album"=>"25", 0 => 1, 1 => "Hello", 2 => "25"}
# as opposed to an array:
# [[1, "Hello", "25"]]
