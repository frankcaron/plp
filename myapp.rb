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
require "json"

require "./rblcp"

# |||| Default Settings ||||

configure do
	set :views, Proc.new { File.join(settings.root, "/plp") }
	set :public_folder, Proc.new { File.join(root, "plp") }
	set :show_exceptions, true
	set :static_cache_control, [:public, max_age: 0]

	set :session, false
	set :sessionToken, ""
	set :sessionMember, ""
	set :sessionMV, ""
end

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
		settings.session = true
		settings.sessionToken = accessToken

		#Fetch the member details
		settings.sessionMember = fetch_deets(settings.sessionToken)

		#Do an MV
		settings.sessionMV = create_mv(settings.sessionMember["name"]["givenName"], settings.sessionMember["name"]["familyName"],settings.sessionMember["emails"][0]["value"].to_s),2000)

		# Redirect to profile once account created successfully
		redirect '/account/profile'
	end
	# Redirect back to log in page if something goes wrong
	redirect '/login'
end

# Account Goodness

before '/account/*' do
	validate_session(settings.session,settings.sessionToken)
end

get '/account/profile' do
	#Pass session details to view
	@member = settings.sessionMember
	@session = settings.session

	#Load view
 	erb :profile
end

get '/account/give' do
	#Pass session details to view
	@member = settings.sessionMember
	@session = settings.session

	# Load view
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
  def validate_session(session,token)
    unless session  && token != ""
		redirect '/'
	end
  end

  # Kill the session
  def kill_session()
  	settings.session = false
	settings.sessionToken = ""
	settings.sessionMember = ""
	settings.sessionMV = ""
	redirect '/'
  end  

  # Fetch the member details
  def fetch_deets(token)
  	# GET 
  	url = "https://www.googleapis.com/plus/v1/people/me?access_token=" + token
  	# Make Request
  	begin
		response = RestClient.get(
			url, 
			:content_type => :json, :accept => :json)
		# Stuff response in
		return JSON.parse(response.to_str)
	rescue => e
		# Log the response
		e.response
	end
	return ""
  end  

  # Helper method to create an account when one doesn't exist
  def create_account(firstName,lastName,email,points)
  	# Create an account with Mihnea's LP
  	url = "https://plp-api.herokuapp.com/register"
	content_type = "application/json"
	body = { "memberId" => email, "firstName" => firstName, "lastName" => lastName, "points" => points,  }.to_json
	
	# Make Request
	begin
		response = RestClient.post(
			url, body, 
			:content_type => :json, :accept => :json)
			puts response.to_str
		rescue => e
			# Log the response
			e.response
			kill_session()
		end
  end

  # Create an MV given some member details
  def create_mv(firstName,lastName,email,points)

  	# Set up basics
  	url = "https://staging.lcp.points.com/v1/lps/53678d34-92c7-46c3-942b-d195ccf33637/mvs/"
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
		return JSON.parse(response.to_str)
	rescue => e
		# Log the response
		e.response

		# If the member doesn't exist, create an account.
		if e.response.code == 422 
			create_account(firstName,lastName,email,points)
		end 
	end
	return ""

	# Dump MV vars into a session placeholder
	# session = true
	# sessionMember = response.to_s

  end

end





