#! /usr/local/bin/ruby
require 'date'
require 'mysql2'
require 'optparse'

Version = '1.0.0'
DIR = '/opt/bme280logs'

opt = OptionParser.new
opt.on('--all') { |v| OPTS[:all] = true }
opt.on('--daily') { |v| OPTS[:daily] = true }
opt.on('-e env') { |v| OPTS[:e] = v }

OPTS = {}
opt.parse!(ARGV)

env = OPTS[:e] || "development"
@client = Mysql2::Client.new(host:"localhost",username:"root",database:"sandbox-rails_#{env}")

def to_jst(ts)
  t = DateTime.parse(ts).to_time
  # t += 9 * 60 * 60
  return t.strftime("%F %T")
end

def parsefile(f)
  print f+" "
  n = 0
  fh = open(f,"r")
  fh.each do |line|
    row = line.split(",").map { |v| v.strip }
    temp = row[0]
    press = row[1]
    humid = row[2]
    ts = to_jst(row[3])
    sql = "INSERT IGNORE INTO bme280_logs"
    sql += " (raspi_id,ts,temperature,pressure,humidity)"
    sql += " VALUES (0,'#{ts}',#{temp},#{press},#{humid})"
    @client.query(sql)
    n += @client.affected_rows
  end
  fh.close
  puts "(%d)" % [n]
  return n
end

files = []
Dir.entries(DIR).sort.each do |f|
  next unless f.end_with? ".log"
  files += [f]
end

daily_sql = <<EOT
INSERT IGNORE INTO bme280_logs_dailies SELECT raspi_id,date(ts),count(1),
avg(temperature),min(temperature),max(temperature),
avg(pressure),min(pressure),max(pressure),
avg(humidity),min(humidity),max(humidity),now()
FROM bme280_logs GROUP BY raspi_id,date(ts);
EOT

if OPTS[:all]
  n_rows = 0
  n_files = 0
  files.each do |f|
    n_rows += parsefile(DIR+"/"+f)
    n_files += 1
  end
  puts "%d files scanned, %d rows added." % [n_files,n_rows]
elsif OPTS[:daily]
  # Expected to run the first of the day.
  n_rows = parsefile(DIR+"/"+files[-2])
  @client.query(daily_sql)
else
  n_rows = parsefile(DIR+"/"+files[-1])
end


results = @client.query("SELECT max(ts) AS ts FROM bme280_logs")
results.each do |row|
  puts "Latest timestamp: %s" % [row["ts"]]
end
