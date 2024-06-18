class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update]
  before_action :fetch_seatable_data, only: [:edit, :update]

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      update_seatable_data
      redirect_to @user, notice: 'Profile updated successfully.'
    else
      render :edit
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password)
  end

  def fetch_seatable_data
    url = URI("#{session[:seatable_metadata]['dtable_db']}dtable-server/api/v1/dtables/#{session[:seatable_metadata]['dtable_uuid']}/rows/")
    url.query = URI.encode_www_form({
      table_name: 'Table1',
      email: @user.email
    })

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["authorization"] = "Token #{session[:seatable_access_token]}"

    response = http.request(request)
    if response.code == '200'
      @seatable_data = JSON.parse(response.read_body)["rows"].first
    else
      Rails.logger.error "Failed to fetch Seatable data: #{response.body}"
    end
  end

  def update_seatable_data
    url = URI("#{session[:seatable_metadata]['dtable_db']}dtable-server/api/v1/dtables/#{session[:seatable_metadata]['dtable_uuid']}/rows/")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Put.new(url)
    request["authorization"] = "Token #{session[:seatable_access_token]}"
    request["Content-Type"] = "application/json"
    request.body = {
      row_id: @seatable_data['id'],
      updates: {
        name: @user.name,
        email: @user.email
      }
    }.to_json

    response = http.request(request)
    if response.code != '200'
      Rails.logger.error "Failed to update Seatable data: #{response.body}"
    end
  end
end
