require 'uri'
require 'net/http'

class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update]
  before_action :fetch_seatable_data, only: %i[edit update]

  def edit; end

  def update
    if user_params[:password].present?
      update_user_with_password
    else
      update_user_without_password
    end
  rescue StandardError => e
    handle_update_error(e)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password)
  end

  def fetch_seatable_data
    return unless session[:seatable_access_token]

    url = URI("https://cloud.seatable.io/api-gateway/api/v2/dtables/#{session[:seatable_metadata]['dtable_uuid']}/sql")
    request = create_seatable_request(url, seatable_sql_query)

    response = perform_request(request)
    handle_seatable_response(response)
  end

  def update_user_with_password
    if @user.update_with_password(user_params)
      update_seatable_data if params[:seatable_data]
      redirect_to @user, notice: 'Profile updated successfully.'
    else
      render :edit
    end
  end

  def update_user_without_password
    if @user.update_without_password(user_params.except(:current_password, :password, :password_confirmation))
      update_seatable_data if params[:seatable_data]
      redirect_to @user, notice: 'Profile updated successfully.'
    else
      render :edit
    end
  end

  def update_seatable_data
    seatable_data = params[:seatable_data].to_unsafe_h
    seatable_data['E-Mail'] = params[:user][:email] if params[:user][:email].present?

    raise "Seatable data email is missing" unless seatable_data['E-Mail']

    changed_fields = JSON.parse(params[:changed_fields]) rescue []

    if changed_fields.empty?
      return
    end

    column_mapping = {
      "seatable_data[name]" => "Name",
      "seatable_data[vorname]" => "Vorname",
      "seatable_data[telefon]" => "Telefon",
      "seatable_data[art_der_behinderung]" => "Art der Behinderung",
      "seatable_data[arbeitszeit]" => "Arbeitszeit",
      "seatable_data[ortsbinding]" => "Ortsbindung",
      "seatable_data[grad_der_behinderung]" => "Grad der Behinderung",
      "seatable_data[berufsbezeichnung]" => "Berufsbezeichnung",
      "seatable_data[sprachkenntnisse]" => "Sprachkenntnisse"
    }

    mapped_changed_data = changed_fields.each_with_object({}) do |field, hash|
      key = field.match(/\[([^\]]+)\]/)[1] # Extract key inside brackets
      hash[column_mapping[field]] = seatable_data[key] if seatable_data[key].present?
    end

    set_clause = mapped_changed_data.map { |key, value| "`#{key}` = '#{value}'" }.join(", ")
    sql_query = "UPDATE Talente SET #{set_clause} WHERE `E-Mail` = '#{seatable_data['E-Mail']}';"
    puts ("SQL Query: #{sql_query}")

    url = URI("https://cloud.seatable.io/api-gateway/api/v2/dtables/#{session[:seatable_metadata]['dtable_uuid']}/sql")
    request = create_seatable_request(url, sql_query)

    response = perform_request(request)
    handle_update_response(response)
  end

  def handle_update_error(error)
    render :edit, alert: 'Update failed. Please try again.'
  end

  def create_seatable_request(url, sql_query)
    Net::HTTP::Post.new(url).tap do |request|
      request["accept"] = 'application/json'
      request["content-type"] = 'application/json'
      request["authorization"] = "Bearer #{session[:seatable_access_token]}"
      request.body = { convert_keys: true, sql: sql_query }.to_json
    end
  end

  def perform_request(request)
    http = Net::HTTP.new(request.uri.host, request.uri.port)
    http.use_ssl = true
    http.request(request)
  end

  def handle_seatable_response(response)
    if response.code == '200'
      rows = JSON.parse(response.body)["results"]
      @seatable_data = rows.first if rows && !rows.empty?
    end
  end

  def handle_update_response(response)
    if response.code != '200'
      raise "Failed to update Seatable data: #{response.body}"
    end
  end

  def seatable_sql_query
    "SELECT * FROM Talente WHERE `E-Mail` = '#{current_user.email}';"
  end
end
