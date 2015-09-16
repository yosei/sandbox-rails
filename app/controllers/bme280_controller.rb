class Bme280Controller < ApplicationController
  def index
    id = params[:id]
    db = connect_bme280
    st = (DateTime.now - 7.days).strftime("%F %T")
    en = DateTime.now.strftime("%F %T")
    sql = "SELECT * FROM logs WHERE raspi_id = #{id} AND ts BETWEEN '#{st}' AND '#{en}' ORDER BY ts"
    results = db.query(sql)
    respond_to do |format|
      format.html do
        @count = 0
        @temperatures = []
        @humidities = []
        @pressures = []
        results.each do |row|
          @temperatures += [row["temperature"]]
          @humidities += [row["humidity"]]
          @pressures += [row["pressure"]]
          @count += 1
        end
        @id = id
      end
      format.csv do
        @results = results
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
