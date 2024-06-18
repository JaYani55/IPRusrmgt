class SessionsController < Devise::SessionsController
  after_action :fetch_seatable_token, only: [:create]

  def destroy
    sign_out(current_user)
    redirect_to root_path, notice: 'Logged out successfully!'
  end

  private

  def fetch_seatable_token
    require 'uri'
    require 'net/http'

    url = URI("https://cloud.seatable.io/api/v2.1/dtable/app-access-token/")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["accept"] = 'application/json'
    request["authorization"] = "Bearer #{ENV['SEATABLE_API_TOKEN']}"

    response = http.request(request)
    response_data = JSON.parse(response.read_body)

    Rails.logger.info "Seatable token request response: #{response_data}"

    if response.code == '200'
      session[:seatable_access_token] = response_data["access_token"]
      session[:seatable_metadata] = response_data.except("access_token")
      Rails.logger.info "Seatable access token: #{session[:seatable_access_token]}"
    else
      Rails.logger.error "Failed to fetch Seatable access token: #{response.body}"
    end
  end
end
