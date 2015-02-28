# ==============================
# PLP
# Frank Caron
# Feb 2015
#
# A simple Storefront and Fulfillment app for connecting to the Points LCP
# 
# ==============================

# |||| Depedencies ||||

require "sinatra"
require "rack-ssl-enforcer"
require "rest_client"
require "json"

# RbLCP
require "./rblcp"

# ------------------------------------------------------------------------------------------
# |||| Default Settings ||||
# ------------------------------------------------------------------------------------------

configure do
	set :views, Proc.new { File.join(settings.root, "/plp") }
	set :public_folder, Proc.new { File.join(root, "plp") }
	set :show_exceptions, true
	set :static_cache_control, [:public, max_age: 0]
	# enable :sessions
	use Rack::Session::Pool
end

configure :production do
  use Rack::SslEnforcer
end

# ------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------
# Main Routes
# ------------------------------------------------------------------------------------------

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

get '/account/give-points' do
	#Pass session details to view
	# admin_credit_member("Mladen","R","m@r.com",1234)
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








# ------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------------------
# Helper functions

helpers do

  # =====================
  # Session Validator
  #
  # Used to validate that a session is legitimate for security.
  # ======================

  def validate_session(session,token)
    unless session  && token != ""
		redirect '/'
	end
  end

  # =====================
  # Session Killer
  #
  # Used to kill a session for logout, etc.
  # ======================

  def kill_session
  	session[:session] = false
	session[:sessionToken] = ""
	session[:sessionMember] = ""
	session[:sessionMV] = ""
  end  


  # =====================
  # Fetch Google Account Details
  #
  # Used for Google Account login to fetch the member's details from Google
  # Primarily used for Single Sign-on
  # ======================

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

  # =====================
  # Create MV
  #
  # Creates an MV given the input
  # Special instance here will automatically create an account in the PLP
  # ======================

  def create_mv(firstName,lastName,email,points)

  	# Set up basics
  	url = "https://staging.lcp.points.com/v1/lps/53678d34-92c7-46c3-942b-d195ccf33637/mvs/"
	method = "POST"
	body = { "memberId" => email }.to_json

  	# Make Request
  	begin
		call_lcp(method,url,body)
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

  # =====================
  # Create Account
  #
  # Creates an account for a member in the PLP via its APIs
  # ======================

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

  # =====================
  # Credit member
  #
  # Creates a credit and order for a member
  # This special admin version is used for the activity awarding
  # ======================
  def admin_credit_member(memberFirstName,memberLastName,memberEmail,points)
  	# If the member is an admin
  	unless session[:sessionMV]["admin"].nil?
  		# Perform MV
  		# Create an order
  		# Patch MV
  		# If successful, create a credit
  			# If successful, let the user know
  			# If unsuccessful, let the user know why
		# If unsuccessful, system error 
		# redirect '/error'
  	end
  end

  def create_order
  end

  def create_recipient_mv
  end

  def patch_mv(order,mv)
  end

  def create_credit(lp,mv,amount)
  end

  # =====================
  # Call LCP
  #
  # Generic LCP call wrapper
  # ======================

	def call_lcp(method,url,body)
		mac_key_identifier = ENV["PLP_MAC_ID"]
		mac_key = ENV["PLP_MAC_KEY"]
		content_type = "application/json"
		method = method.upcase

		# Generate Headers
		headers = generate_authorization_header_value(method,url,mac_key_identifier,mac_key,content_type,body)

	  	# Make Request
	  	if method == "POST"
		  	return RestClient.post(url, 
								   body, 
								   :content_type => :json, 
								   :accept => :json,
								   :"Authorization" => headers)
		else 
			return RestClient.get(url, 
								  body, 
								  :content_type => :json, 
								  :accept => :json,
								  :"Authorization" => headers)
		end
	end 
#
end





