class Bme280Controller < ApplicationController
  def index
    # TODO: list all raspi_id on logs table.
  end

  def show_graph
    id = params[:id]
    db = connect_bme280
    st = (DateTime.now - 1.days).strftime("%F %T")
    en = DateTime.now.strftime("%F %T")
    # Get stat.
    sql = "SELECT count(1) AS c,min(ts) AS mi,max(ts) AS ma FROM logs WHERE raspi_id = #{id}"
    results = db.query(sql)
    results.each do |row|
      @count = row["c"]
      @min = row["mi"]
      @max = row["ma"]
    end
    # Get latest records.
    @temperatures = []
    @humidities = []
    @pressures = []
    sql = "SELECT * FROM logs WHERE raspi_id = #{id} AND ts BETWEEN '#{st}' AND '#{en}' ORDER BY ts"
    results = db.query(sql)
    results.each do |row|
      @temperatures += [row["temperature"]]
      @humidities += [row["humidity"]]
      @pressures += [row["pressure"]]
    end
    # Get daily records.
    @temperatures_dailies = []
    @humidities_dailies = []
    @pressures_dailies = []
    sql = "SELECT * FROM logs_dailies WHERE raspi_id = #{id} ORDER BY ts"
    results = db.query(sql)
    results.each do |row|
      @temperatures_dailies += [row["temperature"]]
      @humidities_dailies += [row["humidity"]]
      @pressures_dailies += [row["pressure"]]
    end
    @id = id
  end

  def show_raw
    id = params[:id]
    db = connect_bme280
    st = (DateTime.now - 30.days).strftime("%F %T")
    en = DateTime.now.strftime("%F %T")
    sql = "SELECT * FROM logs WHERE raspi_id = #{id} AND ts BETWEEN '#{st}' AND '#{en}' ORDER BY ts"
    @results = db.query(sql)
    respond_to do |format|
      format.html
      format.csv do
        filename = "bme280_#{id}.csv"
        headers["Content-Type"] ||= 'text/csv'
        headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
        render layout: false
      end
    end
  end

  private
    def connect_bme280
      client = Mysql2::Client.new(host:"localhost",username:"root",database:"bme280")
    end
end
