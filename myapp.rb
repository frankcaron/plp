# ==============================
# PLP
# Frank Caron
# Feb 2015
#
# A simple Storefront app for connecting to the Points LCP
# 
# ==============================

# |||| Reqs ||||

require "sinatra"
require "rack-ssl-enforcer"
require "rest_client"

require "./rblcp"

# |||| Default Settings ||||

set :views, Proc.new { File.join(settings.root, "/plp") }
set :public_folder, Proc.new { File.join(root, "plp") }
set :show_exceptions, true
set :static_cache_control, [:public, max_age: 0]

session = false
sessionToken = ""
sessionMember = ""

configure :production do
  use Rack::SslEnforcer
end

# ------------------------------
# Main Routes
# ------------------------------

# Log In

get '/login' do
 	erb :login
end

get '/logged-in' do
	# Grab Token
	accessToken = params[:token]

	unless accessToken.nil?
		# Set Session
		session = true
		sessionToken = accessToken

		# Fetch account given token
		# fetch_deets(accessToken)

		# Create MV given token
		# create_mv(first_name,last_name,email)

		# Otherwise, create an account first
		# create_account()
	end
	# Redirect to profile once account created successfully
	redirect '/account/profile'
end

# Account Goodness

before '/account/*' do
	validate_session()
end

get '/account/profile' do
 	erb :profile
end

get '/account/give' do
 	erb :give
end

# Catch All

get '/*' do
 	erb :index
end

# ------------------------------
# Helpers
# ------------------------------
# Helper functions

helpers do

  # Validate the sessions
  def validate_session()
    unless session && sessionMember != nil
		redirect '/'
	end
  end

  # Fetch the member details
  def fetch_deets(token)
  	# GET https://www.googleapis.com/plus/v1/people/userId?access_token=token
  end  

  # Validate the sessions
  def create_account()
  	# https://plp-api.herokuapp.com/register
  end

  # Create an MV given some member details
  def create_mv(email)

  	# Set up basics
  	url = "https://staging.lcp.points.com/v1/lps/53678d34-92c7-46c3-942b-d195ccf33637"
	mac_key_identifier = ENV["PLP_MAC_ID"]
	mac_key = ENV["PLP_MAC_KEY"]
	content_type = "application/json"
	body = { "memberId" => email }.to_json

	# Generate Headers
	headers = generate_authorization_header_value("POST",url,mac_key_identifier,mac_key,content_type,body)
  
  	# Make Request
  	begin
		response = RestClient.post(
			url, body, 
			:content_type => :json, :accept => :json, :"Authorization" => headers)
	rescue => e
		# Log the response
		e.response

		# If the member doesn't exist, create an account.
		if e.response.code == 422 
			create_account()
		end 

	end

	# Dump MV vars into a session placeholder
	# session = true
	# sessionMember = response.to_s

  end

end





