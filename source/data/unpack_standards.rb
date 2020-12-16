require 'sqlite3'
require 'csv'
require 'FileUtils'

def schema
  query = <<-SQL
    CREATE TABLE catalogue (
      keywords text,
      identifier text PRIMARY KEY,
      isRelatedTo text,
      name text NOT NULL,
      description text,
      supersededBy text,
      organisation text,
      validFrom date,
      validThrough date,
      status text,
      dateModified date,
      startDate date,
      endDate date,
      useCase text,
      caseStudy text,
      guidance text,
      howTo text  
    );
  SQL

  query
end

def load_catalogue(tx, path)
  tx.execute(schema)

  catalogue = CSV.read(path, headers: true).map(&:to_h)

  insert_query = <<-SQL
    INSERT INTO catalogue VALUES (
      :keywords,
      :identifier,
      :isRelatedTo,
      :name,
      :description,
      :supersededBy,
      :organisation,
      :validFrom,
      :validThrough,
      :status,
      :dateModified,
      :startDate,
      :endDate,
      :useCase,
      :caseStudy,
      :guidance,
      :howTo
    );
  SQL
  stmt = tx.prepare(insert_query)

  catalogue.each do |record|
    stmt.execute(record)
  end


  
  # build the source folder and the department folder structure
  FileUtils.rm_rf "../Standards"
  FileUtils.mkdir_p "../Standards"
  #old apic needs
  #FileUtils.cp("top.index.erb", "source/index.html.md")
  #FileUtils.cp_r("stylesheets/", "source/")
  
  
  stans = tx.query("SELECT ROW_NUMBER() OVER (ORDER BY name) RowNum, name, count(*) AS number FROM catalogue GROUP BY name")

      stans.each { |row|
    
     stand = row["name"]
     #this is a hack to get round the ridiculous weighting in TDTs
     rank = row['RowNum'] * 10
     puts "Building folder for #{row["name"]}, #{rank}"
	}
	
end

def load_all
  db = SQLite3::Database.new ":memory:"
  db.results_as_hash = true
  db.transaction do |tx|
    load_catalogue(tx, "standardscat.csv")
  end
rescue SQLite3::Exception => e
  puts "Exception occurred"
  puts e
end


# Main
load_all
