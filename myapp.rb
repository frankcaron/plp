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
	enable :sessions
end

configure :production do
  use Rack::SslEnforcer
end

# ------------------------------
# Main Routes
# ------------------------------

# Log In

get '/login' do
	kill_session()
 	erb :login
end

get '/logged-in' do
	# Grab Token
	accessToken = params[:token]

	unless accessToken.nil?
		# Set Session
		session[:session] = true
		session[:sessionToken] = accessToken

		# Logging 
		puts "Session: " + session[:session].to_s
		puts "Session Token: " + session[:sessionToken]

		#Fetch the member details
		session[:sessionMember] = fetch_deets(session[:sessionToken])

		# Logging 
		puts "Session Member: " + session[:sessionMember].to_s
		puts "Session Member Name: " + session[:sessionMember]["name"]["givenName"]


		#Do an MV
		session[:sessionMV] = create_mv(session[:sessionMember]["name"]["givenName"],
									   session[:sessionMember]["name"]["familyName"],
									   session[:sessionMember]["emails"][0]["value"].to_s,
									   2000)

		# Logging
		puts session[:sessionMV].to_s

		# Redirect to profile once account created successfully
		redirect '/account/profile'
	end
	# Redirect back to log in page if something goes wrong
	redirect '/login'
end

# Account Goodness

before '/account/*' do
	validate_session(session[:session],session[:sessionToken])
end

get '/account/profile' do
	#Pass session details to view
	@member = session[:sessionMember]
	@mv = session[:sessionMV]
	@session = session[:session]

	#Load view
 	erb :profile
end

get '/account/give' do
	#Pass session details to view
	@member = session[:sessionMember]
	@mv = session[:sessionMV]
	@session = session[:session]

	# Load view
 	erb :give
end

get '/account/logout' do
	kill_session()
	erb :logout
end

# Catch All

get '/error' do
 	erb :error
end

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
  def kill_session
  	session[:session] = false
	session[:sessionToken] = ""
	session[:sessionMember] = ""
	session[:sessionMV] = ""
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
		puts "LOG | Details fetch error | " + e.response
		# Redirect to the error page
		redirect '/error'
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
		# If the member doesn't exist, create an account.
		if e.response.code == 422 
			create_account(firstName,lastName,email,points)
		else 
			# Log the response
			puts "LOG | MV create error | " + e.response
			# Redirect to the error page
			redirect '/error'
		end
	end
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
			puts "LOG | Account create error | " + e.response
			# Redirect to the error page
			redirect '/error'
		end
  end

end





