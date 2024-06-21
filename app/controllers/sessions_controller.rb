require 'net/http'
require 'uri'

class SessionsController < Devise::SessionsController
  def create
    super do |resource|
      fetch_seatable_access_token(resource.email)
    end
  end

  def destroy
    sign_out(current_user)
    redirect_to root_path, notice: 'Logged out successfully!'
  end

  private

  def fetch_seatable_access_token(email)
    url = URI("https://cloud.seatable.io/api/v2.1/dtable/app-access-token/")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["accept"] = 'application/json'
    request["authorization"] = 'Bearer YOUR_SEATABLE_API_TOKEN' # Replace with your actual API token

    response = http.request(request)
    if response.code == '200'
      seatable_metadata = JSON.parse(response.body)
      session[:seatable_access_token] = seatable_metadata['access_token']
      session[:seatable_metadata] = seatable_metadata
    else
      Rails.logger.error "Failed to fetch Seatable access token: #{response.body}"
    end
  end
end
