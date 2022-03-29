# Alex Luu
# 16 September 2021
# Ruby 2.7
# Program acquires the longitude, latitude, and elevation of inactive fires in California (year to date), then finds
# earthquakes that have happened within a 1000 km radius since 01 January 2020. Invalid data is then filtered out.
# Data is then exported to a CSV.

require 'net/http'
require 'json'
require 'csv'

# Response list for inactive fires. By default, the info is year to date.
fire_url = 'https://www.fire.ca.gov/umbraco/api/IncidentApi/List?inactive=true'
fire_uri = URI(fire_url)
fire_response = Net::HTTP.get(fire_uri)
fire_data = JSON.parse(fire_response)
counter = 0
csv_array = []

until fire_data[counter].nil?
  begin
    longitude = fire_data[counter]['Longitude']
    latitude = fire_data[counter]['Latitude']
    # Finds
    quakes_url = "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=2020-01-01&latitude=#{latitude}&longitude=#{longitude}&maxradiuskm=1000"
    quakes_uri = URI(quakes_url)
    quakes_response = Net::HTTP.get(quakes_uri)
    quakes_data = JSON.parse(quakes_response)
    num_quakes = quakes_data['metadata']['count']
    # Elevation is nested inside the weather API info under properties > forecast
    weather_url = "https://api.weather.gov/points/#{latitude.truncate(3)},#{longitude.truncate(3)}"
    weather_uri = URI(weather_url)
    weather_response = Net::HTTP.get(weather_uri)
    weather_data = JSON.parse(weather_response)
    # Redirects to the endpoint that has the elevation information
    altitude_url = weather_data['properties']['forecast']
    altitude_uri = URI(altitude_url)
    altitude_response = Net::HTTP.get(altitude_uri)
    altitude_data = JSON.parse(altitude_response)
    altitude = altitude_data['properties']['elevation']['value']
    # saves info to be saved in a CSV
    line_item = [latitude, longitude, num_quakes, altitude]
    csv_array.push(line_item)
  rescue
    # Skips rows that error out
  end
  counter += 1
end

# Exports data to a CSV in your working directory
CSV.open('earthquake_near_fires.csv', 'w') do |csv|
  count = 0
  csv << ['latitude', 'longitude', 'number of earthquakes', 'altitude in meters']
  while count < csv_array.length
    csv << csv_array[count]
    count += 1
  end
  end
