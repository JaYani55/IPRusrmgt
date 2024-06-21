require 'uri'
require 'net/http'

class HomeController < ApplicationController
  def index
    fetch_seatable_data
  end

  private

  def fetch_seatable_data
    return unless session[:seatable_access_token]

    url = URI("https://cloud.seatable.io/api-gateway/api/v2/dtables/#{session[:seatable_metadata]['dtable_uuid']}/sql")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["accept"] = 'application/json'
    request["content-type"] = 'application/json'
    request["authorization"] = "Bearer #{session[:seatable_access_token]}"
    request.body = { convert_keys: true, sql: "SELECT * FROM Talente WHERE `E-Mail` = '#{current_user.email}';" }.to_json

    response = http.request(request)
    if response.code == '200'
      rows = JSON.parse(response.body)["results"]
      @seatable_data = rows.first if rows && !rows.empty?
    else
      Rails.logger.error "Failed to fetch Seatable data: #{response.body}"
    end
  end
end
